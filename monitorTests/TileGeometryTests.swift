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
import MapKit
import XCTest
@testable import monitor

/// Pins the geometry of a grid cell in map space and when drawn.
final class TileGeometryTests: XCTestCase {

    private let center = CLLocationCoordinate2D(latitude: 50, longitude: 0)

    private var oneDegree: Double {
        return TileGeometry.mapPointsPerDegree
    }

    // MARK: - Map rect

    func testTileCoversItsCell() {
        let rect = TileGeometry.mapRect(center: center, longitudeDelta: 1.0, latitudeDelta: 1.0)

        XCTAssertEqual(rect.width, oneDegree, accuracy: 0.001)
        XCTAssertEqual(rect.origin.x,
                       MKMapPoint(CLLocationCoordinate2D(latitude: 50, longitude: -0.5)).x,
                       accuracy: 0.001,
                       "the cell should start at its western edge")
    }

    func testTileContainsItsOwnCenter() {
        let rect = TileGeometry.mapRect(center: center, longitudeDelta: 1.0, latitudeDelta: 1.0)

        XCTAssertTrue(rect.contains(MKMapPoint(center)))
    }

    func testTileIsCenteredOnTheCellLongitude() {
        let rect = TileGeometry.mapRect(center: center, longitudeDelta: 2.0, latitudeDelta: 2.0)

        XCTAssertEqual(rect.midX, MKMapPoint(center).x, accuracy: 0.001)
    }

    func testTileGrowsWithTheGridDeltas() {
        let coarse = TileGeometry.mapRect(center: center, longitudeDelta: 10.0, latitudeDelta: 10.0)
        let fine = TileGeometry.mapRect(center: center, longitudeDelta: 5.0, latitudeDelta: 5.0)

        XCTAssertEqual(coarse.width, 10 * oneDegree, accuracy: 0.001)
        XCTAssertGreaterThan(coarse.width, fine.width)
        XCTAssertGreaterThan(coarse.height, fine.height)
    }

    func testGlobalScaleTileSpansItsDeltas() {
        let rect = TileGeometry.mapRect(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                        longitudeDelta: 90,
                                        latitudeDelta: 90)

        XCTAssertEqual(rect.width, 90 * oneDegree, accuracy: 0.001)
        XCTAssertLessThan(rect.width, MKMapSize.world.width, "a cell must not span the world")
    }

    func testTileStraddlingTheAntimeridianStaysOneCellWide() {
        let rect = TileGeometry.mapRect(center: CLLocationCoordinate2D(latitude: 0, longitude: 180),
                                        longitudeDelta: 0.5,
                                        latitudeDelta: 0.5)

        XCTAssertEqual(rect.width, 0.5 * oneDegree, accuracy: 0.001)
        XCTAssertLessThan(rect.width, MKMapSize.world.width / 4, "the cell wrapped around the world")
    }

    func testLatitudeIsClampedToTheProjection() {
        let rect = TileGeometry.mapRect(center: CLLocationCoordinate2D(latitude: 89, longitude: 0),
                                        longitudeDelta: 1.0,
                                        latitudeDelta: 10.0)

        XCTAssertGreaterThan(rect.height, 0)
        XCTAssertLessThanOrEqual(rect.maxY, MKMapSize.world.height)
        XCTAssertGreaterThanOrEqual(rect.minY, 0)
    }

    // MARK: - Drawn size

    func testRenderedSizeTurnsMapUnitsIntoPoints() {
        let mapRect = TileGeometry.mapRect(center: center, longitudeDelta: 1.0, latitudeDelta: 1.0)
        let size = TileGeometry.renderedSize(of: mapRect, zoomScale: 0.5)

        XCTAssertEqual(size.width, CGFloat(mapRect.width * 0.5), accuracy: 0.001)
        XCTAssertEqual(size.height, CGFloat(mapRect.height * 0.5), accuracy: 0.001)
    }

    func testDrawableRectKeepsALargeCellUnchanged() {
        let mapRect = TileGeometry.mapRect(center: center, longitudeDelta: 1.0, latitudeDelta: 1.0)
        let drawn = TileGeometry.drawableRect(mapRect, zoomScale: 0.5)

        XCTAssertEqual(drawn.width, mapRect.width, accuracy: 0.001)
        XCTAssertEqual(drawn.height, mapRect.height, accuracy: 0.001)
        XCTAssertEqual(drawn.midX, mapRect.midX, accuracy: 0.001)
        XCTAssertEqual(drawn.midY, mapRect.midY, accuracy: 0.001)
    }

    func testDrawableRectEnlargesATinyCellToTheMinimum() {
        let tiny = TileGeometry.mapRect(center: center, longitudeDelta: 0.000001, latitudeDelta: 0.000001)
        let drawn = TileGeometry.drawableRect(tiny, zoomScale: 0.1)
        let minimum = TileGeometry.minimumSize(zoomScale: 0.1)

        XCTAssertEqual(drawn.width, Double(minimum), accuracy: 0.001)
        XCTAssertEqual(drawn.height, Double(minimum), accuracy: 0.001)
        XCTAssertEqual(drawn.midX, tiny.midX, accuracy: 0.001, "the cell stays centered")
    }

    func testMinimumSizeTurnsScreenPointsIntoMapUnits() {
        XCTAssertEqual(TileGeometry.minimumSize(zoomScale: 0.5),
                       2 * TileGeometry.minimumHalfExtent / 0.5,
                       accuracy: 0.001)
        XCTAssertEqual(TileGeometry.minimumSize(zoomScale: 0),
                       2 * TileGeometry.minimumHalfExtent,
                       accuracy: 0.001)
    }
}
