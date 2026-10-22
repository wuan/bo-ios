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

/// The lightning activity currently displayed on the map.
///
/// This is the model the map draws from; it carries the displayed result's
/// tiles and strikes together with the colours and interval they are read
/// against. Turning it into drawable shapes is `ActivityRenderPlan`'s job.
public final class MapActivity: NSObject {

    /// A grid cell: the events the grid aggregated into one rectangle.
    public struct Tile: Equatable {
        public let center: CLLocationCoordinate2D
        public let longitudeDelta: Double
        public let latitudeDelta: Double
        /// The number of events recorded in the cell.
        public let count: Int
        /// When the cell's most recent event happened, in seconds since the epoch.
        public let timestamp: Int

        public init(center: CLLocationCoordinate2D,
                    longitudeDelta: Double,
                    latitudeDelta: Double,
                    count: Int,
                    timestamp: Int) {
            self.center = center
            self.longitudeDelta = longitudeDelta
            self.latitudeDelta = latitudeDelta
            self.count = count
            self.timestamp = timestamp
        }

        /// The map rectangle the cell covers.
        public var mapRect: MKMapRect {
            return TileGeometry.mapRect(center: center,
                                        longitudeDelta: longitudeDelta,
                                        latitudeDelta: latitudeDelta)
        }

        public static func == (lhs: Tile, rhs: Tile) -> Bool {
            return lhs.center.latitude == rhs.center.latitude &&
                lhs.center.longitude == rhs.center.longitude &&
                lhs.longitudeDelta == rhs.longitudeDelta &&
                lhs.latitudeDelta == rhs.latitudeDelta &&
                lhs.count == rhs.count &&
                lhs.timestamp == rhs.timestamp
        }
    }

    /// A single strike, drawn as a marker without extent.
    public struct Point: Equatable {
        public let coordinate: CLLocationCoordinate2D
        /// The number of events the strike represents.
        public let count: Int
        public let timestamp: Int

        public init(coordinate: CLLocationCoordinate2D, count: Int, timestamp: Int) {
            self.coordinate = coordinate
            self.count = count
            self.timestamp = timestamp
        }

        /// The position of the marker in map space.
        public var mapPoint: MKMapPoint {
            return MKMapPoint(coordinate)
        }

        public static func == (lhs: Point, rhs: Point) -> Bool {
            return lhs.coordinate.latitude == rhs.coordinate.latitude &&
                lhs.coordinate.longitude == rhs.coordinate.longitude &&
                lhs.count == rhs.count &&
                lhs.timestamp == rhs.timestamp
        }
    }

    /// The grid cells to draw.
    public let tiles: [Tile]
    /// The individual strikes to draw.
    public let points: [Point]
    /// The time the displayed result is referenced to, in seconds since the epoch.
    public let referenceTimestamp: Int
    /// The interval the active palette spans, in minutes.
    public let intervalDuration: Int
    /// Resolves the colours for the active scheme and base map.
    public let colorHandler: ColorHandler
    /// The opacity of the base-map dim, in `0...255`.
    public let fadeAlpha: Int

    public init(tiles: [Tile] = [],
                points: [Point] = [],
                referenceTimestamp: Int,
                intervalDuration: Int,
                colorHandler: ColorHandler,
                fadeAlpha: Int = 0) {
        self.tiles = tiles
        self.points = points
        self.referenceTimestamp = referenceTimestamp
        self.intervalDuration = intervalDuration
        self.colorHandler = colorHandler
        self.fadeAlpha = fadeAlpha
    }

    // MARK: - Selection

    /// The activity under a point in map space.
    ///
    /// - Parameters:
    ///   - mapPoint: the point to test, in map space.
    ///   - zoomScale: the scale the map is drawn at, which sizes a strike marker.
    public func selection(at mapPoint: MKMapPoint, zoomScale: MKZoomScale) -> MapActivitySelection? {
        for tile in tiles where tile.mapRect.contains(mapPoint) {
            return .tile(tile)
        }

        // The marker is drawn a fixed size on screen, so its map-space reach
        // depends on how large a map point currently is.
        let reach = zoomScale > 0
            ? Double(StrikeMarker.size(zoomScale: zoomScale)) / Double(zoomScale) / 2
            : 0
        for strike in points where abs(strike.mapPoint.x - mapPoint.x) <= reach
            && abs(strike.mapPoint.y - mapPoint.y) <= reach {
            return .strike(strike)
        }

        return nil
    }
}

/// The activity item resolved from a tap on the map.
public enum MapActivitySelection {

    case tile(MapActivity.Tile)
    case strike(MapActivity.Point)

    /// Where the details popup is anchored.
    public var coordinate: CLLocationCoordinate2D {
        switch self {
        case .tile(let tile):
            return tile.center
        case .strike(let strike):
            return strike.coordinate
        }
    }

    /// The time the popup describes, in seconds since the epoch.
    public var timestamp: Int {
        switch self {
        case .tile(let tile):
            return tile.timestamp
        case .strike(let strike):
            return strike.timestamp
        }
    }

    /// The text shown in the details popup.
    ///
    /// A grid cell is identified by its count and a single strike by its
    /// position, matching the reference client. Locale-aware formatting
    /// arrives with the localization phase.
    public func detailsText() -> String {
        let time = MapActivitySelection.timeFormatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(timestamp)))

        switch self {
        case .tile(let tile):
            return String(format: NSLocalizedString("selection.tile",
                                                    comment: "Strike details popup for a grid cell: time and count"),
                          time,
                          tile.count)
        case .strike(let strike):
            return String(format: NSLocalizedString("selection.strike",
                                                    comment: "Strike details popup for a single strike: time and position"),
                          time,
                          strike.coordinate.longitude,
                          strike.coordinate.latitude)
        }
    }

    /// Renders a selection's time as a wall-clock time, e.g. `14:30:05`.
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
