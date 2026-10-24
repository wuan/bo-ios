/*

Copyright 2026 Andreas Würl

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

/// Maps a rendered size to an alpha, so larger shapes fade and labels stay legible.
///
/// The same curve is used for tiles and their counts, which is why the bounds
/// and the size range are parameters rather than constants.
public enum ShapeAlpha {

    /// The alpha, in `0...255`, for a `value` within `minValue...maxValue`.
    ///
    /// Values at or below `minValue` take `maxAlpha`, values at or above
    /// `maxValue` take `minAlpha`, and the range in between is interpolated.
    /// An inverted or empty range takes `maxAlpha`, so a caller that cannot
    /// derive a size still draws a visible shape.
    public static func alpha(value: Double,
                             minValue: Double,
                             maxValue: Double,
                             maxAlpha: Int,
                             minAlpha: Int) -> Int {
        guard maxValue > minValue else { return maxAlpha }

        let target = min(max((value - minValue) / (maxValue - minValue), 0.0), 1.0)
        return minAlpha + Int(Double(maxAlpha - minAlpha) * (1.0 - target))
    }

    /// The same value as a drawing alpha in `0...1`.
    public static func drawingAlpha(value: Double,
                                    minValue: Double,
                                    maxValue: Double,
                                    maxAlpha: Int,
                                    minAlpha: Int) -> Double {
        return Double(alpha(value: value,
                            minValue: minValue,
                            maxValue: maxValue,
                            maxAlpha: maxAlpha,
                            minAlpha: minAlpha)) / 255.0
    }
}
