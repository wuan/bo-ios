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

import XCTest
@testable import monitor

final class BlitzortungHttpDataProviderTests: XCTestCase {

    private let baseEndpoint = "http://data.blitzortung.org/Data/Protected"
    private lazy var formatter = StrikeLogUrlFormatter(baseEndpoint: baseEndpoint)

    private func url(at timestamp: Int, region: Int = 1) -> URL {
        return formatter.url(region: region, at: Date(timeIntervalSince1970: TimeInterval(timestamp)))!
    }

    /// The 10-minute chunk URL whose file would carry a strike at `timestamp`.
    private func chunkUrl(containing timestamp: Int, region: Int = 1) -> URL {
        let chunkSeconds = 600
        return url(at: timestamp / chunkSeconds * chunkSeconds, region: region)
    }

    private func makeProvider(now: @escaping () -> Date,
                              transport: StubTransport,
                              credentials: Credentials = Credentials()) -> BlitzortungHttpDataProvider {
        return BlitzortungHttpDataProvider(endpoint: baseEndpoint,
                                           transport: transport,
                                           credentialStore: InMemoryCredentialStore(credentials: credentials),
                                           userAgent: UserAgent(buildNumber: "1"),
                                           now: now)
    }

    @discardableResult
    private func fetch(_ provider: BlitzortungHttpDataProvider, parameters: Parameters) -> Result? {
        var captured: Result?
        provider.fetchData(parameters: parameters) { result, _ in captured = result }
        return captured
    }

    // MARK: - Chunked fetching

    func testRequestsOneLogPerChunkAcrossTheInterval() {
        let transport = StubTransport()
        let provider = makeProvider(now: { Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620)) },
                                    transport: transport)

        let result = fetch(provider, parameters: Parameters(region: 1, intervalDuration: 60, intervalOffset: 0))

        XCTAssertEqual(transport.requestedURLs.count, 7)
        XCTAssertEqual(transport.requestedURLs.first?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/05/20.log")
        XCTAssertEqual(transport.requestedURLs.last?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/06/20.log")
        XCTAssertEqual(result?.referenceTimestamp, Fixtures.strikeLogTimestamp0620)
    }

    func testRequestedMinutesAdvanceInChunkSteps() {
        let transport = StubTransport()
        let provider = makeProvider(now: { Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620)) },
                                    transport: transport)

        fetch(provider, parameters: Parameters(region: 1, intervalDuration: 60, intervalOffset: 0))

        let minutes = transport.requestedURLs.map { $0.deletingPathExtension().lastPathComponent }
        XCTAssertEqual(minutes, ["20", "30", "40", "50", "00", "10", "20"])
    }

    func testToleratesMissingLogFiles() {
        let transport = StubTransport()
        let provider = makeProvider(now: { Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620)) },
                                    transport: transport)

        let result = fetch(provider, parameters: Parameters(region: 1, intervalDuration: 60, intervalOffset: 0))

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.strikes.count, 0)
    }

    func testHistoricalOffsetMovesTheWindow() {
        let transport = StubTransport()
        let now = Fixtures.strikeLogTimestamp0730
        let provider = makeProvider(now: { Date(timeIntervalSince1970: TimeInterval(now)) }, transport: transport)

        let result = fetch(provider, parameters: Parameters(region: 1, intervalDuration: 60, intervalOffset: -60))

        // Interval ends one hour in the past: 06:30, covering 05:30..06:30.
        XCTAssertEqual(result?.referenceTimestamp, Fixtures.strikeLogTimestamp0630)
        XCTAssertEqual(transport.requestedURLs.first?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/05/30.log")
        XCTAssertEqual(transport.requestedURLs.last?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/06/30.log")
    }

    // MARK: - Incremental accumulation

    func testSecondFetchResumesFromTheLastFetchedMinute() {
        let transport = StubTransport()
        var clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620))
        let provider = makeProvider(now: { clock }, transport: transport)
        let parameters = Parameters(region: 1, intervalDuration: 60, intervalOffset: 0)

        transport.responses[chunkUrl(containing: Fixtures.strikeLogTimestamp0615)] =
            Fixtures.strikeLog([Fixtures.strikeLogLine()])
        fetch(provider, parameters: parameters)
        XCTAssertEqual(transport.requestedURLs.count, 7)

        transport.resetRequests()
        clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0630))
        fetch(provider, parameters: parameters)

        XCTAssertEqual(transport.requestedURLs.count, 3)
        XCTAssertEqual(transport.requestedURLs.first?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/06/10.log")
        XCTAssertEqual(transport.requestedURLs.last?.absoluteString,
                       "\(baseEndpoint)/Strikes_1/2019/02/13/06/30.log")
    }

    func testAccumulatesStrikesAndSuppressesDuplicatesFromTheRewoundChunk() {
        let transport = StubTransport()
        var clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620))
        let provider = makeProvider(now: { clock }, transport: transport)
        let parameters = Parameters(region: 1, intervalDuration: 60, intervalOffset: 0)

        transport.responses[chunkUrl(containing: Fixtures.strikeLogTimestamp0615)] = Fixtures.strikeLog([Fixtures.strikeLogLine()])
        let first = fetch(provider, parameters: parameters)
        XCTAssertEqual(first?.strikes.count, 1)

        // The next fetch re-reads the 06:10 chunk, so the first strike is seen twice.
        transport.responses[chunkUrl(containing: Fixtures.strikeLogTimestamp0625)] =
            Fixtures.strikeLog([Fixtures.strikeLogLine(time: "06:25:00.000000000", latitude: 10.0, longitude: 20.0)])
        clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0630))
        let second = fetch(provider, parameters: parameters)

        XCTAssertEqual(second?.strikes.count, 2)
        XCTAssertEqual(second?.strikes.map { $0.timestamp },
                       [Fixtures.strikeLogTimestamp0615, Fixtures.strikeLogTimestamp0625])
    }

    func testExpiresStrikesThatFallOutsideTheWindow() {
        let transport = StubTransport()
        var clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620))
        let provider = makeProvider(now: { clock }, transport: transport)
        let parameters = Parameters(region: 1, intervalDuration: 60, intervalOffset: 0)

        transport.responses[chunkUrl(containing: Fixtures.strikeLogTimestamp0615)] = Fixtures.strikeLog([Fixtures.strikeLogLine()])
        XCTAssertEqual(fetch(provider, parameters: parameters)?.strikes.count, 1)

        // Window moves to 06:30..07:30, so the 06:15 strike is expired.
        clock = Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0730))
        let later = fetch(provider, parameters: parameters)

        XCTAssertEqual(later?.strikes.count, 0)
    }

    func testChangingParametersResetsTheAccumulation() {
        let transport = StubTransport()
        let provider = makeProvider(now: { Date(timeIntervalSince1970: TimeInterval(Fixtures.strikeLogTimestamp0620)) },
                                    transport: transport)

        transport.responses[chunkUrl(containing: Fixtures.strikeLogTimestamp0615, region: 1)] =
            Fixtures.strikeLog([Fixtures.strikeLogLine()])
        XCTAssertEqual(fetch(provider, parameters: Parameters(region: 1, intervalDuration: 60))?.strikes.count, 1)

        let regionTwo = fetch(provider, parameters: Parameters(region: 2, intervalDuration: 60))

        XCTAssertEqual(regionTwo?.strikes.count, 0)
        XCTAssertEqual(transport.requestedURLs.last?.absoluteString,
                       "\(baseEndpoint)/Strikes_2/2019/02/13/06/20.log")
    }

    func testHttpProviderDeclaresStrikeOnlyCapabilities() {
        let provider = makeProvider(now: Date.init, transport: StubTransport())

        XCTAssertEqual(provider.capabilities, DataProviderCapabilities(supportsGrid: false, supportsClusters: false))
    }
}
