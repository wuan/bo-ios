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

/// Turns a grid cell into the rectangle it occupies on the map.
public enum TileGeometry {

    /// The smallest half-extent a tile is drawn with, in points.
    ///
    /// A cell whose rendered size falls below this still gets drawn, so sparse
    /// activity is never invisible.
    public static let minimumHalfExtent: CGFloat = 1.5

    /// The latitude beyond which the map projection does not extend.
    static let mercatorLatitudeLimit = 85.05112878

    /// The width of the world in map points, and so the size of one degree.
    static var mapPointsPerDegree: Double {
        return MKMapSize.world.width / 360.0
    }

    /// The map rectangle a grid cell covers.
    ///
    /// The rectangle is built from the cell's western edge and extends east by
    /// the cell's width, so a cell that straddles the antimeridian does not
    /// accidentally span the whole world. Latitudes are clamped to the range
    /// the projection covers.
    public static func mapRect(center: CLLocationCoordinate2D,
                               longitudeDelta: Double,
                               latitudeDelta: Double) -> MKMapRect {
        let west = MKMapPoint(clampLatitude(CLLocationCoordinate2D(
            latitude: center.latitude,
            longitude: center.longitude - longitudeDelta / 2)))
        let north = MKMapPoint(clampLatitude(CLLocationCoordinate2D(
            latitude: center.latitude + latitudeDelta / 2,
            longitude: center.longitude)))
        let south = MKMapPoint(clampLatitude(CLLocationCoordinate2D(
            latitude: center.latitude - latitudeDelta / 2,
            longitude: center.longitude)))

        return MKMapRect(x: west.x,
                         y: min(north.y, south.y),
                         width: abs(longitudeDelta) * mapPointsPerDegree,
                         height: abs(south.y - north.y))
    }

    /// The rectangle to draw a cell in.
    ///
    /// A cell that would render smaller than the supported minimum is enlarged
    /// around its center, so sparse activity is never invisible.
    ///
    /// - Parameters:
    ///   - mapRect: the cell's rectangle in map space.
    ///   - zoomScale: the scale the map is drawn at, in points per map point.
    public static func drawableRect(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> MKMapRect {
        let minimum = minimumSize(zoomScale: zoomScale)
        let width = max(mapRect.width, Double(minimum))
        let height = max(mapRect.height, Double(minimum))

        return MKMapRect(x: mapRect.midX - width / 2,
                         y: mapRect.midY - height / 2,
                         width: width,
                         height: height)
    }

    /// The size a cell occupies on screen, in points.
    public static func renderedSize(of mapRect: MKMapRect, zoomScale: MKZoomScale) -> CGSize {
        return CGSize(width: CGFloat(mapRect.width * Double(zoomScale)),
                      height: CGFloat(mapRect.height * Double(zoomScale)))
    }

    /// The smallest size a tile is drawn with, in map space.
    ///
    /// The map is drawn in map coordinates, so the on-screen minimum has to be
    /// scaled back into those units.
    public static func minimumSize(zoomScale: MKZoomScale) -> CGFloat {
        guard zoomScale > 0 else { return 2 * minimumHalfExtent }
        return 2 * minimumHalfExtent / CGFloat(zoomScale)
    }

    private static func clampLatitude(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: min(max(coordinate.latitude, -mercatorLatitudeLimit),
                                                    mercatorLatitudeLimit),
                                      longitude: coordinate.longitude)
    }
}
