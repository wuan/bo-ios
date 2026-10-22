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

import CoreLocation
import Foundation
import MapKit
import UIKit

/// A filled grid cell.
///
/// The colour lives on the overlay so the map's renderer delegate can hand it
/// to MapKit's own polygon renderer, which does the projection itself.
final class ActivityTilePolygon: MKPolygon {
    var fillColor: UIColor = .clear
}

/// A filled marker for a single strike.
final class ActivityStrikePolygon: MKPolygon {
    var fillColor: UIColor = .clear
}

/// The wash drawn over the base map, beneath the activity.
///
/// It is a single overlay made of the map's two halves. MapKit works out a
/// polygon's points and bounds by taking the shorter way round the globe, so one
/// polygon covering the whole map collapses to a line at the antimeridian; two
/// halves that meet at the prime meridian keep their shape. Keeping them in one
/// overlay means MapKit draws them together, so they never appear apart while
/// the map moves.
final class ActivityDimPolygon: MKMultiPolygon {
    var fillColor: UIColor = .clear
}

/// Turns a render plan into the MapKit objects that draw it.
enum ActivityOverlayBuilder {

    /// The fraction of a strike marker's size used as its arm thickness.
    static let strikeArmRatio: CGFloat = 0.25

    // MARK: - Tiles

    /// The polygon filling a grid cell.
    static func tilePolygon(for fill: ActivityRenderPlan.TileFill) -> ActivityTilePolygon {
        let polygon = ActivityTilePolygon(coordinates: corners(of: fill.mapRect),
                                          count: 4)
        polygon.fillColor = UIColor(packed: fill.color, alpha: CGFloat(fill.alpha))
        return polygon
    }

    // MARK: - Strikes

    /// The plus-shaped polygon marking a single strike.
    ///
    /// The shape mirrors the reference client's double line: a marker of `size`
    /// points whose arms are a quarter of that wide.
    static func strikePolygon(for mark: ActivityRenderPlan.StrikeMark,
                              zoomScale: MKZoomScale) -> ActivityStrikePolygon {
        let center = MKMapPoint(mark.coordinate)
        let half = Double(mark.size) / Double(zoomScale) / 2
        let arm = half * Double(strikeArmRatio)

        let points = [
            MKMapPoint(x: center.x - half, y: center.y - arm),
            MKMapPoint(x: center.x - arm, y: center.y - arm),
            MKMapPoint(x: center.x - arm, y: center.y - half),
            MKMapPoint(x: center.x + arm, y: center.y - half),
            MKMapPoint(x: center.x + arm, y: center.y - arm),
            MKMapPoint(x: center.x + half, y: center.y - arm),
            MKMapPoint(x: center.x + half, y: center.y + arm),
            MKMapPoint(x: center.x + arm, y: center.y + arm),
            MKMapPoint(x: center.x + arm, y: center.y + half),
            MKMapPoint(x: center.x - arm, y: center.y + half),
            MKMapPoint(x: center.x - arm, y: center.y + arm),
            MKMapPoint(x: center.x - half, y: center.y + arm),
        ]

        let polygon = ActivityStrikePolygon(coordinates: points.map { $0.coordinate },
                                            count: points.count)
        polygon.fillColor = UIColor(packed: mark.color)
        return polygon
    }

    // MARK: - Base map dim

    /// The wash covering the base map, drawn as the map's two halves.
    static func dimPolygon(for dim: ActivityRenderPlan.BaseMapDim) -> ActivityDimPolygon {
        let halves = halves(of: dim.mapRect).map { MKPolygon(coordinates: corners(of: $0), count: 4) }
        let polygon = ActivityDimPolygon(halves)
        polygon.fillColor = UIColor(packed: dim.color, alpha: CGFloat(dim.alpha))
        return polygon
    }

    // MARK: - Corners

    /// A map rectangle split into the two halves that meet at the middle
    /// meridian, which MapKit can draw without folding either of them around the
    /// globe.
    static func halves(of mapRect: MKMapRect) -> [MKMapRect] {
        let width = mapRect.size.width / 2
        return [MKMapRect(x: mapRect.minX, y: mapRect.minY, width: width, height: mapRect.size.height),
                MKMapRect(x: mapRect.midX, y: mapRect.minY, width: width, height: mapRect.size.height)]
    }

    /// The four corners of a map rectangle, wound around its edge.
    static func corners(of mapRect: MKMapRect) -> [CLLocationCoordinate2D] {
        let minX = max(mapRect.minX, MKMapRect.world.minX)
        let maxX = min(mapRect.maxX, MKMapRect.world.maxX)
        let minY = max(mapRect.minY, MKMapRect.world.minY)
        let maxY = min(mapRect.maxY, MKMapRect.world.maxY)

        return [
            MKMapPoint(x: minX, y: minY).coordinate,
            MKMapPoint(x: maxX, y: minY).coordinate,
            MKMapPoint(x: maxX, y: maxY).coordinate,
            MKMapPoint(x: minX, y: maxY).coordinate,
        ]
    }
}

extension UIColor {

    /// Builds a colour from a packed `0xRRGGBB` value.
    convenience init(packed color: UInt32, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((color & 0xff0000) >> 16) / 255.0,
                  green: CGFloat((color & 0x00ff00) >> 8) / 255.0,
                  blue: CGFloat(color & 0x0000ff) / 255.0,
                  alpha: alpha)
    }
}
