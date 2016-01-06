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

public class Parameters: TimeIntervalWithOffset {
    let region: Int
    let rasterBaselength: Int
    let intervalDuration: Int
    let intervalOffset: Int
    let countThreshold: Int

    init(region: Int = 1, rasterBaselength: Int = 10000, intervalDuration: Int = 60, intervalOffset: Int = 0, countThreshold: Int = 0) {
        self.region = region
        self.rasterBaselength = rasterBaselength
        self.intervalDuration = intervalDuration
        self.intervalOffset = intervalOffset
        self.countThreshold = countThreshold
    }

    func isRealtime() -> Bool {
        return intervalOffset == 0
    }

    func isRaster() -> Bool {
        return rasterBaselength != 0
    }
}
