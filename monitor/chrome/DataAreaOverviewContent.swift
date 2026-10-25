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

/// The part of the data area the map is currently showing.
///
/// Expressed as fractions of the data area, so the whole area is `0...1` on
/// both axes. A viewport that reaches past the area gives values outside that
/// range, which the view clips.
public struct OverviewViewport: Equatable {

    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Whether the viewport lies entirely within the data area.
    public var isInside: Bool {
        return x >= 0 && y >= 0 && x + width <= 1 && y + height <= 1
    }
}

/// What the data-area overview displays.
public struct DataAreaOverviewContent: Equatable {

    /// The box's original fixed shape, used until the map reports an extent.
    public static let defaultAspectRatio: Double = 90.0 / 130.0

    /// The area's longitude range as shown, e.g. `-10.0..10.0`.
    public let longitudeText: String
    /// The area's latitude range as shown, e.g. `40.0..60.0`.
    public let latitudeText: String
    /// The area's cell size as shown, e.g. `1.0 1.0`.
    public let cellSizeText: String
    /// The part of the area the map shows.
    public let viewport: OverviewViewport
    /// The zoom level as shown, e.g. `Zoom 7.0`.
    public let zoomText: String
    /// The box's height over its width, from the visible extent's proportions.
    public let aspectRatio: Double

    public init(longitudeText: String,
                latitudeText: String,
                cellSizeText: String,
                viewport: OverviewViewport,
                zoomText: String,
                aspectRatio: Double = DataAreaOverviewContent.defaultAspectRatio) {
        self.longitudeText = longitudeText
        self.latitudeText = latitudeText
        self.cellSizeText = cellSizeText
        self.viewport = viewport
        self.zoomText = zoomText
        self.aspectRatio = aspectRatio
    }
}

/// Builds the data-area overview's content.
///
/// The overview is drawn only while the diagnostics setting is on and the
/// displayed result carries a data area; either being false produces no content
/// and no view.
public enum DataAreaOverviewContentBuilder {

    /// Builds the overview content.
    ///
    /// - Parameters:
    ///   - grid: the geometry of the displayed result's data area, or `nil`.
    ///   - viewport: the visible map extent, or `nil` before the map reports
    ///     one.
    ///   - zoomLevel: the map's current zoom level.
    ///   - diagnosticsEnabled: whether the diagnostics setting is on; the
    ///     overview is a diagnostics aid and shows nothing while it is off.
    public static func make(grid: GridParameters?,
                            viewport: ViewExtent?,
                            zoomLevel: Double,
                            diagnosticsEnabled: Bool) -> DataAreaOverviewContent? {
        guard diagnosticsEnabled, let grid = grid else { return nil }

        let longitudeText = String(format: NSLocalizedString("overview.range",
                                                            comment: "Data area range, e.g. -10.0..10.0"),
                                   grid.longitudeStart,
                                   grid.longitudeEnd)
        let latitudeText = String(format: NSLocalizedString("overview.range",
                                                           comment: "Data area range, e.g. -10.0..10.0"),
                                  grid.latitudeEnd,
                                  grid.latitudeStart)
        let cellSizeText = String(format: NSLocalizedString("overview.cellSize",
                                                           comment: "Data area cell size, e.g. 1.0 1.0"),
                                  grid.longitudeDelta,
                                  grid.latitudeDelta)
        let zoomText = String(format: NSLocalizedString("overview.zoom",
                                                       comment: "Map zoom level, e.g. Zoom 7.0"),
                              zoomLevel)

        return DataAreaOverviewContent(longitudeText: longitudeText,
                                       latitudeText: latitudeText,
                                       cellSizeText: cellSizeText,
                                       viewport: viewportBox(grid: grid, viewport: viewport),
                                       zoomText: zoomText,
                                       aspectRatio: aspectRatio(for: viewport))
    }

    /// The box's height over its width: the visible extent's latitude span over
    /// its longitude span, so the panel keeps the map's proportions. The fixed
    /// shape is kept until the map reports an extent.
    private static func aspectRatio(for viewport: ViewExtent?) -> Double {
        guard let viewport = viewport, viewport.longitudeSpan > 0 else {
            return DataAreaOverviewContent.defaultAspectRatio
        }
        return viewport.latitudeSpan / viewport.longitudeSpan
    }

    /// The visible extent as fractions of the data area.
    private static func viewportBox(grid: GridParameters, viewport: ViewExtent?) -> OverviewViewport {
        guard let viewport = viewport else {
            return OverviewViewport(x: 0, y: 0, width: 1, height: 1)
        }

        let longitudeSpan = grid.longitudeEnd - grid.longitudeStart
        let latitudeSpan = grid.latitudeStart - grid.latitudeEnd
        guard longitudeSpan > 0, latitudeSpan > 0 else {
            return OverviewViewport(x: 0, y: 0, width: 1, height: 1)
        }

        let west = viewport.center.longitude - viewport.longitudeSpan / 2
        let north = viewport.center.latitude + viewport.latitudeSpan / 2

        return OverviewViewport(x: (west - grid.longitudeStart) / longitudeSpan,
                                y: (grid.latitudeStart - north) / latitudeSpan,
                                width: viewport.longitudeSpan / longitudeSpan,
                                height: viewport.latitudeSpan / latitudeSpan)
    }
}
