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

/// One distance ring of the radar face.
public struct AlertRange: Equatable {

    /// The ring's inner edge in kilometres; zero for the innermost ring.
    public let minimum: Double
    /// The ring's outer edge in kilometres.
    public let maximum: Double

    public init(minimum: Double, maximum: Double) {
        self.minimum = minimum
        self.maximum = maximum
    }
}

/// One direction sector of the radar face.
public struct AlertDirection: Equatable {

    /// The name shown for the direction, e.g. `N`.
    public let label: String
    /// The sector's centre bearing in degrees, clockwise from north.
    public let centerBearing: Double
    /// The lowest bearing the sector covers, wrapped into `0..<360` when the
    /// sector crosses due south so a plain comparison would fail.
    public let minimumBearing: Double
    /// The highest bearing the sector covers.
    public let maximumBearing: Double

    public init(label: String,
                centerBearing: Double,
                minimumBearing: Double,
                maximumBearing: Double) {
        self.label = label
        self.centerBearing = centerBearing
        self.minimumBearing = minimumBearing
        self.maximumBearing = maximumBearing
    }

    /// Whether the sector covers a bearing.
    ///
    /// A sector whose minimum has been wrapped past the end of the circle
    /// covers both ends of it, which the two comparisons below express.
    public func contains(bearing: Double) -> Bool {
        if maximumBearing > minimumBearing {
            return bearing < maximumBearing && bearing >= minimumBearing
        }
        if maximumBearing < minimumBearing {
            return bearing >= minimumBearing || bearing < maximumBearing
        }
        return true
    }
}

/// The radar's fixed geometry: distance rings and direction sectors.
///
/// The constants are the reference client's own, fixed rather than settings, so
/// the geometry does not change with the displayed interval or region.
public struct AlertGeometry: Equatable {

    /// The rings' outer edges in kilometres, from the location outwards.
    public static let rangeSteps: [Double] = [10, 25, 50, 100, 250, 500]
    /// The direction names, starting due south and continuing clockwise.
    public static let directionLabels = ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
    /// The geometry a fresh install uses.
    public static let standard = AlertGeometry()

    /// The rings, from the location outwards.
    public let ranges: [AlertRange]
    /// The direction sectors, in the radar's order.
    public let directions: [AlertDirection]

    public init(rangeSteps: [Double] = AlertGeometry.rangeSteps,
                directionLabels: [String] = AlertGeometry.directionLabels) {
        var innerEdge = 0.0
        self.ranges = rangeSteps.map { outerEdge in
            let range = AlertRange(minimum: innerEdge, maximum: outerEdge)
            innerEdge = outerEdge
            return range
        }

        let width = 360.0 / Double(max(1, directionLabels.count))
        var bearing = -180.0
        self.directions = directionLabels.map { label in
            var minimum = bearing - width / 2
            if minimum < -180 {
                minimum += 360
            }
            let direction = AlertDirection(label: label,
                                           centerBearing: bearing,
                                           minimumBearing: minimum,
                                           maximumBearing: bearing + width / 2)
            bearing += width
            return direction
        }
    }

    /// The index of the ring that contains a distance, or `nil` when the
    /// distance lies beyond the outermost ring.
    public func ringIndex(forDistance distance: Double) -> Int? {
        return ranges.firstIndex { distance <= $0.maximum }
    }

    /// The index of the sector that contains a bearing.
    public func sectorIndex(forBearing bearing: Double) -> Int? {
        return directions.firstIndex { $0.contains(bearing: bearing) }
    }

    // MARK: - Geometry

    /// Mean earth radius in kilometres.
    static let earthRadius = 6371.0088

    /// The great-circle distance between two locations in kilometres.
    public static func distance(from: Location, to: Location) -> Double {
        let latitudeDelta = radians(to.latitude - from.latitude)
        let longitudeDelta = radians(to.longitude - from.longitude)
        let fromLatitude = radians(from.latitude)
        let toLatitude = radians(to.latitude)

        let half = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(fromLatitude) * cos(toLatitude) * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * earthRadius * asin(min(1, sqrt(half)))
    }

    /// The initial bearing from one location to another, in degrees within
    /// `-180...180`, clockwise from north.
    public static func bearing(from: Location, to: Location) -> Double {
        let fromLatitude = radians(from.latitude)
        let toLatitude = radians(to.latitude)
        let longitudeDelta = radians(to.longitude - from.longitude)

        let y = sin(longitudeDelta) * cos(toLatitude)
        let x = cos(fromLatitude) * sin(toLatitude)
            - sin(fromLatitude) * cos(toLatitude) * cos(longitudeDelta)
        return degrees(atan2(y, x))
    }

    private static func radians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }

    private static func degrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
}
