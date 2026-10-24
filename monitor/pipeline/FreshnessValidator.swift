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

/// Remembers the reference timestamp most recently accepted for each set of
/// request parameters, so an out-of-order response cannot replace fresher data
/// for the same selection.
///
/// Android guards event ordering with a locally generated sequence number; iOS
/// has no backend sequence number, so the reference timestamp is the freshness
/// signal shared by every source. Scoping it to a selection matters once the app
/// can ask for historical intervals: a realtime refresh and a historical
/// selection are different queries, and an older historical timestamp is not a
/// stale answer to the realtime query.
public final class FreshnessValidator {

    private var lastAcceptedTimestamps: [Parameters: Int] = [:]
    private let lock = NSLock()

    public init() {}

    /// The reference timestamp most recently accepted for `parameters`, if any.
    public func lastAccepted(for parameters: Parameters) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return lastAcceptedTimestamps[parameters]
    }

    /// Returns whether a result with `referenceTimestamp` is newer than the last
    /// accepted result for the same `parameters` and, if so, records it.
    ///
    /// The first result for a given selection is always accepted; a result equal
    /// to or older than the last accepted one for the same selection is rejected.
    /// A result for a different selection is always accepted.
    public func accept(referenceTimestamp: Int, for parameters: Parameters) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if let lastAcceptedTimestamp = lastAcceptedTimestamps[parameters], referenceTimestamp <= lastAcceptedTimestamp {
            return false
        }
        lastAcceptedTimestamps[parameters] = referenceTimestamp
        return true
    }

    /// Forgets every accepted result.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        lastAcceptedTimestamps.removeAll()
    }
}
