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

/// A bounded time-to-live cache of fetched results keyed by request parameters.
///
/// The cache lives above the providers so a result can be shared across them.
/// The default time-to-live matches the Android client's five minutes.
public final class DataCache {

    /// The default time-to-live in seconds (five minutes).
    public static let defaultTimeToLive: TimeInterval = 5 * 60

    private struct Entry {
        let result: Result
        let storedAt: Date
    }

    private var entries: [Parameters: Entry] = [:]
    private let timeToLive: TimeInterval
    private let now: () -> Date
    private let lock = NSLock()

    /// Creates a cache.
    ///
    /// - Parameters:
    ///   - timeToLive: How long a stored result stays valid, in seconds.
    ///   - now: Clock used for expiry, injectable for tests.
    public init(timeToLive: TimeInterval = DataCache.defaultTimeToLive, now: @escaping () -> Date = Date.init) {
        self.timeToLive = timeToLive
        self.now = now
    }

    /// Returns a stored result for `parameters` while it is still valid, or `nil`.
    ///
    /// An expired entry is discarded as it is read.
    public func result(for parameters: Parameters) -> Result? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = entries[parameters] else {
            return nil
        }
        if now().timeIntervalSince(entry.storedAt) >= timeToLive {
            entries[parameters] = nil
            return nil
        }
        return entry.result
    }

    /// Stores `result` for `parameters`, replacing any existing entry.
    public func store(_ result: Result, for parameters: Parameters) {
        lock.lock()
        defer { lock.unlock() }
        entries[parameters] = Entry(result: result, storedAt: now())
    }

    /// Removes every stored result.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }

    /// The number of stored entries, whether expired or not.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }
}
