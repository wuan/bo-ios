/*

Copyright 2015-2016 Andreas Würl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

import Foundation

/// Builds the URL of a per-minute strike log.
///
/// The Blitzortung HTTP source serves one log per minute at
/// `<base>/Strikes_<region>/yyyy/MM/dd/HH/mm.log`.
public struct StrikeLogUrlFormatter {

    public let baseEndpoint: String
    private let pathFormatter: DateFormatter

    public init(baseEndpoint: String) {
        self.baseEndpoint = baseEndpoint

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd/HH/mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        self.pathFormatter = formatter
    }

    /// The log URL for a region at a point in time, or `nil` when the base URL is unusable.
    public func url(region: Int, at date: Date) -> URL? {
        let base = baseEndpoint.hasSuffix("/") ? String(baseEndpoint.dropLast()) : baseEndpoint
        let path = pathFormatter.string(from: date)
        return URL(string: "\(base)/Strikes_\(region)/\(path).log")
    }
}

/// ``DataProvider`` backed by the Blitzortung HTTP strike logs.
///
/// The source is not interchangeable with JSON-RPC: it serves accumulated strike
/// lists only, cannot serve grid-aggregated data or clusters, and requires
/// authentication. It fetches the interval in bounded chunks, accumulates the
/// strikes seen, drops those that fall outside the current window, and remembers
/// the latest minute fetched so a poll only reads what is new.
public final class BlitzortungHttpDataProvider: DataProvider {

    /// The HTTP source serves strike lists only.
    public let capabilities = DataProviderCapabilities(supportsGrid: false, supportsClusters: false)

    /// Default number of minutes between log reads.
    public static let defaultChunkMinutes = 10

    private let urlFormatter: StrikeLogUrlFormatter
    private let transport: HttpTransport
    private let credentialStore: CredentialStore
    private let userAgent: UserAgent
    private let parser: StrikeLogParser
    private let now: () -> Date
    private let chunkMinutes: Int

    private var lastParameters: Parameters?
    private var accumulated: [Strike] = []
    private var latestFetched: Date?
    private let lock = NSLock()

    public init(endpoint: String,
                transport: HttpTransport = URLSessionHttpTransport(),
                credentialStore: CredentialStore = KeychainCredentialStore(),
                userAgent: UserAgent = UserAgent(),
                parser: StrikeLogParser = StrikeLogParser(),
                now: @escaping () -> Date = Date.init,
                chunkMinutes: Int = BlitzortungHttpDataProvider.defaultChunkMinutes) {
        self.urlFormatter = StrikeLogUrlFormatter(baseEndpoint: endpoint)
        self.transport = transport
        self.credentialStore = credentialStore
        self.userAgent = userAgent
        self.parser = parser
        self.now = now
        self.chunkMinutes = chunkMinutes
    }

    public func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        let credentials = credentialStore.load()

        lock.lock()
        if lastParameters != parameters {
            accumulated = []
            latestFetched = nil
            lastParameters = parameters
        }
        let priorLatest = latestFetched
        let priorStrikes = accumulated
        lock.unlock()

        let intervalEnd = now().addingTimeInterval(TimeInterval(parameters.intervalOffset * 60))
        let intervalStart = intervalEnd.addingTimeInterval(TimeInterval(-parameters.intervalDuration * 60))
        let urls = makeUrls(parameters: parameters, start: intervalStart, end: intervalEnd, latestFetched: priorLatest)

        retrieve(urls: urls, credentials: credentials) { [weak self] fresh in
            guard let self = self else { return }

            let windowStart = intervalStart.timeIntervalSince1970
            let retained = priorLatest == nil ? [] : priorStrikes.filter { Double($0.timestamp) > windowStart }
            var strikes = Self.merge(retained: retained, fresh: fresh)

            self.lock.lock()
            self.accumulated = strikes
            if !fresh.isEmpty {
                self.latestFetched = intervalEnd.addingTimeInterval(-60)
            }
            self.lock.unlock()

            let result = Result(parameters: parameters,
                                referenceTimestamp: Int(intervalEnd.timeIntervalSince1970),
                                strikes: strikes,
                                rasterParameters: nil)
            completion(result, nil)
        }
    }

    /// Merges retained and newly read strikes, dropping duplicates.
    ///
    /// The chunk rewind re-reads the previous chunk, so the same strike can be
    /// seen twice; identity is its position and timestamp.
    static func merge(retained: [Strike], fresh: [Strike]) -> [Strike] {
        var seen = Set<StrikeKey>()
        var merged: [Strike] = []
        for strike in retained + fresh where seen.insert(StrikeKey(strike)).inserted {
            merged.append(strike)
        }
        return merged.sorted {
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            if $0.envelope.center.latitude != $1.envelope.center.latitude {
                return $0.envelope.center.latitude < $1.envelope.center.latitude
            }
            return $0.envelope.center.longitude < $1.envelope.center.longitude
        }
    }

    /// The log URLs to read for a fetch, from the later of the window start and
    /// the last fetched minute up to the interval end, at chunk boundaries.
    func makeUrls(parameters: Parameters, start: Date, end: Date, latestFetched: Date?) -> [URL] {
        guard parameters.intervalDuration > 0, chunkMinutes > 0 else {
            return []
        }

        let chunkSeconds = TimeInterval(chunkMinutes * 60)
        let wanted = max(start, latestFetched ?? start)
        let roundedStart = Date(timeIntervalSince1970: floor(wanted.timeIntervalSince1970 / chunkSeconds) * chunkSeconds)

        var urls: [URL] = []
        var cursor = roundedStart
        while cursor <= end {
            if let url = urlFormatter.url(region: parameters.region, at: cursor) {
                urls.append(url)
            }
            cursor = cursor.addingTimeInterval(chunkSeconds)
        }
        return urls
    }

    /// Reads every URL in order, tolerating per-file failures, and returns the strikes parsed.
    private func retrieve(urls: [URL], credentials: Credentials, completion: @escaping ([Strike]) -> Void) {
        var collected: [Strike] = []
        var index = 0

        func loadNext() {
            guard index < urls.count else {
                completion(collected)
                return
            }
            let url = urls[index]
            index += 1

            transport.get(url: url, credentials: credentials, userAgent: userAgent) { [parser] data, _ in
                if let data = data, let contents = String(data: data, encoding: .utf8) {
                    collected.append(contentsOf: parser.parse(contents: contents))
                }
                loadNext()
            }
        }

        loadNext()
    }
}

/// Identity of a strike for duplicate suppression when merging fetched chunks.
private struct StrikeKey: Hashable {
    let timestamp: Int
    let latitude: Double
    let longitude: Double

    init(_ strike: Strike) {
        timestamp = strike.timestamp
        latitude = strike.envelope.center.latitude
        longitude = strike.envelope.center.longitude
    }
}
