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

/// The parameters of a single data request.
///
/// This is a value type so it can be compared and used as a cache key; two
/// parameter sets built from equal values are equal.
public struct Parameters: Equatable, Hashable, TimeIntervalWithOffset {
    public let region: Int
    public let rasterBaselength: Int
    public let intervalDuration: Int
    public let intervalOffset: Int
    public let countThreshold: Int

    public init(region: Int = 1, rasterBaselength: Int = 10000, intervalDuration: Int = 60, intervalOffset: Int = 0, countThreshold: Int = 0) {
        self.region = region
        self.rasterBaselength = rasterBaselength
        self.intervalDuration = intervalDuration
        self.intervalOffset = intervalOffset
        self.countThreshold = countThreshold
    }

    public func isRealtime() -> Bool {
        return intervalOffset == 0
    }

    public func isRaster() -> Bool {
        return rasterBaselength != 0
    }
}
