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
import CoreLocation
import Foundation
import MapKit

/// What the map should draw for the activity currently displayed.
///
/// The plan is the whole rendering decision - which items are visible, their
/// colours, opacity, labels, and the base-map dim - expressed without MapKit
/// types that cannot be compared, so it can be asserted in tests. The view
/// layer only turns it into MapKit overlays and annotations.
public struct ActivityRenderPlan: Equatable {

    /// A grid cell to fill.
    public struct TileFill: Equatable {
        /// The rectangle to fill, in map space, already at its minimum size.
        public let mapRect: MKMapRect
        public let color: UInt32
        /// The fill opacity, in `0...1`.
        public let alpha: Double

        public static func == (lhs: TileFill, rhs: TileFill) -> Bool {
            return lhs.mapRect.origin.x == rhs.mapRect.origin.x &&
                lhs.mapRect.origin.y == rhs.mapRect.origin.y &&
                lhs.mapRect.size.width == rhs.mapRect.size.width &&
                lhs.mapRect.size.height == rhs.mapRect.size.height &&
                lhs.color == rhs.color &&
                lhs.alpha == rhs.alpha
        }
    }

    /// The count shown inside a grid cell.
    public struct CountLabel: Equatable {
        public let coordinate: CLLocationCoordinate2D
        public let text: String
        /// The label size on screen, in points.
        public let textSize: CGFloat
        /// The label's colour, chosen for the active base map.
        public let textColor: UInt32
        /// The label opacity, in `0...1`.
        public let alpha: Double

        public static func == (lhs: CountLabel, rhs: CountLabel) -> Bool {
            return lhs.coordinate.latitude == rhs.coordinate.latitude &&
                lhs.coordinate.longitude == rhs.coordinate.longitude &&
                lhs.text == rhs.text &&
                lhs.textSize == rhs.textSize &&
                lhs.textColor == rhs.textColor &&
                lhs.alpha == rhs.alpha
        }
    }

    /// A single strike to draw as a marker.
    public struct StrikeMark: Equatable {
        public let coordinate: CLLocationCoordinate2D
        /// The marker's size on screen, in points.
        public let size: CGFloat
        public let color: UInt32

        public static func == (lhs: StrikeMark, rhs: StrikeMark) -> Bool {
            return lhs.coordinate.latitude == rhs.coordinate.latitude &&
                lhs.coordinate.longitude == rhs.coordinate.longitude &&
                lhs.size == rhs.size &&
                lhs.color == rhs.color
        }
    }

    /// The wash drawn over the base map, beneath the activity.
    public struct BaseMapDim: Equatable {
        public let mapRect: MKMapRect
        public let color: UInt32
        /// The wash opacity, in `0...1`.
        public let alpha: Double

        public static func == (lhs: BaseMapDim, rhs: BaseMapDim) -> Bool {
            return lhs.mapRect.origin.x == rhs.mapRect.origin.x &&
                lhs.mapRect.origin.y == rhs.mapRect.origin.y &&
                lhs.mapRect.size.width == rhs.mapRect.size.width &&
                lhs.mapRect.size.height == rhs.mapRect.size.height &&
                lhs.color == rhs.color &&
                lhs.alpha == rhs.alpha
        }
    }

    /// The grid cells to fill, in the order they should be drawn.
    public let tileFills: [TileFill]
    /// The counts to show.
    public let countLabels: [CountLabel]
    /// The strikes to draw.
    public let strikeMarks: [StrikeMark]
    /// The base-map wash, when the fade setting asks for one.
    public let baseMapDim: BaseMapDim?

    /// The range of rendered tile widths over which a tile fades, in points.
    public static let tileAlphaRange = (minValue: 10.0, maxValue: 40.0)
    /// The tile alpha bounds.
    public static let tileAlphaBounds = (maxAlpha: 255, minAlpha: 100)

    /// How much larger than the visible map rect a plan covers, so a small pan
    /// does not drop newly visible activity.
    public static let coverage: Double = 2.0

    /// The map rectangle a plan should cover for the given visible area.
    public static func coveringRect(for visibleMapRect: MKMapRect) -> MKMapRect {
        return MKMapRect(x: visibleMapRect.midX - visibleMapRect.width * coverage / 2,
                         y: visibleMapRect.midY - visibleMapRect.height * coverage / 2,
                         width: visibleMapRect.width * coverage,
                         height: visibleMapRect.height * coverage)
    }

    /// Builds the plan for the activity as it is displayed right now.
    ///
    /// - Parameters:
    ///   - activity: the displayed result.
    ///   - zoomScale: the scale the map is drawn at, in points per map point.
    ///   - visibleMapRect: the part of the map the user can see.
    public static func make(activity: MapActivity,
                            zoomScale: MKZoomScale,
                            visibleMapRect: MKMapRect) -> ActivityRenderPlan {
        return ActivityRenderPlan(tileFills: tileFills(activity: activity,
                                                       zoomScale: zoomScale,
                                                       visibleMapRect: visibleMapRect),
                                  countLabels: countLabels(activity: activity,
                                                           zoomScale: zoomScale,
                                                           visibleMapRect: visibleMapRect),
                                  strikeMarks: strikeMarks(activity: activity,
                                                           zoomScale: zoomScale,
                                                           visibleMapRect: visibleMapRect),
                                  baseMapDim: baseMapDim(activity: activity))
    }

    // MARK: - Tiles

    /// The fills for the cells that are on screen.
    static func tileFills(activity: MapActivity,
                          zoomScale: MKZoomScale,
                          visibleMapRect: MKMapRect) -> [TileFill] {
        return activity.tiles.filter { $0.mapRect.intersects(visibleMapRect) }.map { tile in
            let mapRect = TileGeometry.drawableRect(tile.mapRect, zoomScale: zoomScale)
            let renderedWidth = Double(mapRect.width * Double(zoomScale))
            let color = activity.colorHandler.color(referenceTime: activity.referenceTimestamp,
                                                    eventTime: tile.timestamp,
                                                    intervalDuration: activity.intervalDuration)
            let alpha = ShapeAlpha.drawingAlpha(value: renderedWidth,
                                                minValue: tileAlphaRange.minValue,
                                                maxValue: tileAlphaRange.maxValue,
                                                maxAlpha: tileAlphaBounds.maxAlpha,
                                                minAlpha: tileAlphaBounds.minAlpha)
            return TileFill(mapRect: mapRect, color: color, alpha: alpha)
        }
    }

    /// The counts for the cells on screen that are large enough to show them.
    static func countLabels(activity: MapActivity,
                            zoomScale: MKZoomScale,
                            visibleMapRect: MKMapRect) -> [CountLabel] {
        var labels: [CountLabel] = []
        for tile in activity.tiles where tile.mapRect.intersects(visibleMapRect) {
            let mapRect = TileGeometry.drawableRect(tile.mapRect, zoomScale: zoomScale)
            let renderedHeight = CGFloat(mapRect.height * Double(zoomScale))
            guard let textSize = TileLabel.textSize(tileHeight: renderedHeight) else { continue }

            labels.append(CountLabel(coordinate: tile.center,
                                     text: "\(tile.count)",
                                     textSize: textSize,
                                     textColor: activity.colorHandler.textColor,
                                     alpha: Double(TileLabel.alpha(textSize: textSize)) / 255.0))
        }
        return labels
    }

    // MARK: - Strikes

    /// The markers for the strikes that are on screen.
    static func strikeMarks(activity: MapActivity,
                            zoomScale: MKZoomScale,
                            visibleMapRect: MKMapRect) -> [StrikeMark] {
        let size = StrikeMarker.size(zoomScale: zoomScale)
        return activity.points.filter { visibleMapRect.contains($0.mapPoint) }.map { strike in
            StrikeMark(coordinate: strike.coordinate,
                       size: size,
                       color: activity.colorHandler.color(referenceTime: activity.referenceTimestamp,
                                                          eventTime: strike.timestamp,
                                                          intervalDuration: activity.intervalDuration))
        }
    }

    // MARK: - Base map dim

    /// The area the base-map wash covers: the whole map.
    public static let dimMapRect = MKMapRect.world

    /// The wash over the base map, when the fade setting asks for one.
    ///
    /// The wash covers the whole map rather than the visible area. MapKit builds
    /// an overlay's tiles asynchronously, so a wash sized to the viewport is
    /// composited from tiles rendered at different times while the map moves,
    /// and zooming out then shows rectangular patches of wash and undimmed
    /// areas. A wash over the whole map cannot be outrun by the camera.
    static func baseMapDim(activity: MapActivity) -> BaseMapDim? {
        guard activity.fadeAlpha > 0 else { return nil }

        return BaseMapDim(mapRect: dimMapRect,
                          color: activity.colorHandler.baseMapDimColor,
                          alpha: Double(activity.fadeAlpha) / 255.0)
    }
}
