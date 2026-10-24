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

    /// The smallest size a cell is drawn at, in points.
    ///
    /// A cell whose rendered size falls below this is not drawn at all: drawing
    /// it any smaller than this would be a sub-pixel speck, and drawing it any
    /// larger would spill into the neighbouring cells and overstate the area the
    /// activity covers.
    public static let minimumVisibleExtent: CGFloat = 1.0

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

    /// The size a cell occupies on screen, in points.
    public static func renderedSize(of mapRect: MKMapRect, zoomScale: MKZoomScale) -> CGSize {
        return CGSize(width: CGFloat(mapRect.width * Double(zoomScale)),
                      height: CGFloat(mapRect.height * Double(zoomScale)))
    }

    /// Whether a cell is large enough on screen to be drawn.
    ///
    /// The cell is drawn at exactly its own extent, so cells that pass this test
    /// tile without overlapping.
    public static func isVisible(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        let size = renderedSize(of: mapRect, zoomScale: zoomScale)
        return size.width >= minimumVisibleExtent && size.height >= minimumVisibleExtent
    }

    private static func clampLatitude(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: min(max(coordinate.latitude, -mercatorLatitudeLimit),
                                                    mercatorLatitudeLimit),
                                      longitude: coordinate.longitude)
    }
}
