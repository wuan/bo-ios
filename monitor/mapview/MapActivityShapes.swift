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

import CoreGraphics
import Foundation
import MapKit

/// The label drawn inside a grid tile.
public enum TileLabel {

    /// The fraction of the tile's height used for the label.
    public static let sizeDivisor: CGFloat = 2.5

    /// The smallest label that is still drawn, in points.
    public static let minimumSize: CGFloat = 8

    /// The size for a label of a tile of the given rendered height.
    ///
    /// - Returns: `nil` when the tile is too small for a legible label, so the
    ///   tile is drawn without a count.
    public static func textSize(tileHeight: CGFloat) -> CGFloat? {
        let size = tileHeight / sizeDivisor
        return size >= minimumSize ? size : nil
    }

    /// The alpha, in `0...255`, for a label of the given size.
    public static func alpha(textSize: CGFloat) -> Int {
        return ShapeAlpha.alpha(value: Double(textSize),
                                minValue: 20,
                                maxValue: 80,
                                maxAlpha: 255,
                                minAlpha: 60)
    }
}

/// The marker drawn for a single strike.
public enum StrikeMarker {

    /// The offset that turns MapKit's zoom scale into a zoom level.
    ///
    /// MapKit's `MKZoomScale` is `2^(zoomLevel - 20)`, so adding this recovers
    /// the zoom level the reference client uses to size its markers.
    public static let zoomScaleExponentOffset: Double = 20

    /// The smallest marker, in points, so a lone strike stays visible.
    public static let minimumSize: CGFloat = 4

    /// The size of a marker at the given zoom scale.
    public static func size(zoomScale: MKZoomScale) -> CGFloat {
        let zoomLevel = log2(max(Double(zoomScale), 0.000001)) + zoomScaleExponentOffset
        return max(CGFloat(2 * (zoomLevel + 1)), minimumSize)
    }
}
