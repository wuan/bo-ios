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

/// Bounds and stepping for historical time selection.
public struct History: Equatable {

    /// Default step between history positions in minutes.
    public static let defaultOffsetIncrement = 30
    /// Maximum history range in minutes (24 hours).
    public static let maxRange = 24 * 60

    public let timeIncrement: Int
    public let range: Int
    public let limit: Bool

    public init(timeIncrement: Int = History.defaultOffsetIncrement,
                range: Int = History.maxRange,
                limit: Bool = true) {
        self.timeIncrement = timeIncrement
        self.range = range
        self.limit = limit
    }

    /// Lower bound of the history window for a given interval.
    public func lowerLimit(of interval: TimeIntervalSelection) -> Int {
        return -range + (limit ? interval.duration : 0)
    }

    /// Clamps a history position to the available range.
    public func clampedPosition(_ position: Int) -> Int {
        return max(0, min(position, range))
    }
}
