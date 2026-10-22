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

/// Remembers the reference timestamp of the most recently accepted result so an
/// out-of-order response cannot replace fresher data.
///
/// Android guards event ordering with a locally generated sequence number; iOS
/// has no backend sequence number, so the reference timestamp is the freshness
/// signal shared by every source.
public final class FreshnessValidator {

    private var lastAcceptedTimestamp: Int?
    private let lock = NSLock()

    public init() {}

    /// The reference timestamp of the most recently accepted result, if any.
    public var lastAccepted: Int? {
        lock.lock()
        defer { lock.unlock() }
        return lastAcceptedTimestamp
    }

    /// Returns whether a result with `referenceTimestamp` is newer than the last
    /// accepted result and, if so, records it as accepted.
    ///
    /// The first result is always accepted; a result equal to or older than the
    /// last accepted one is rejected.
    public func accept(referenceTimestamp: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if let lastAcceptedTimestamp = lastAcceptedTimestamp, referenceTimestamp <= lastAcceptedTimestamp {
            return false
        }
        lastAcceptedTimestamp = referenceTimestamp
        return true
    }

    /// Forgets the last accepted result.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        lastAcceptedTimestamp = nil
    }
}
