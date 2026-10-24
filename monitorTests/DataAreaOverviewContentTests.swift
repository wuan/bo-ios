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

import XCTest
@testable import monitor

final class DataAreaOverviewContentTests: XCTestCase {

    /// A 20 by 20 degree area over Europe.
    private let grid = GridParameters(longitudeStart: -10,
                                      longitudeDelta: 1,
                                      longitudeCount: 20,
                                      latitudeStart: 60,
                                      latitudeDelta: 1,
                                      latitudeCount: 20)

    private func extent(center: Location,
                        latitudeSpan: Double,
                        longitudeSpan: Double) -> ViewExtent {
        return ViewExtent(center: center, latitudeSpan: latitudeSpan, longitudeSpan: longitudeSpan)
    }

    func testNoOverviewWithoutADataArea() {
        let content = DataAreaOverviewContentBuilder.make(grid: nil,
                                                          viewport: nil,
                                                          zoomLevel: 7)

        XCTAssertNil(content)
    }

    func testAreaExtentAndCellSizeAreShown() throws {
        let content = try XCTUnwrap(DataAreaOverviewContentBuilder.make(grid: grid,
                                                                       viewport: nil,
                                                                       zoomLevel: 7))

        XCTAssertEqual(content.longitudeText, "-10.0..10.0")
        XCTAssertEqual(content.latitudeText, "40.0..60.0")
        XCTAssertEqual(content.cellSizeText, "1.0 1.0")
        XCTAssertEqual(content.zoomText, "Zoom 7.0")
    }

    func testViewportFullyInsideTheDataArea() throws {
        let content = try XCTUnwrap(DataAreaOverviewContentBuilder.make(
            grid: grid,
            viewport: extent(center: Location(latitude: 50, longitude: 0),
                             latitudeSpan: 5,
                             longitudeSpan: 5),
            zoomLevel: 7))

        XCTAssertEqual(content.viewport.x, 0.375, accuracy: 1e-9)
        XCTAssertEqual(content.viewport.y, 0.375, accuracy: 1e-9)
        XCTAssertEqual(content.viewport.width, 0.25, accuracy: 1e-9)
        XCTAssertEqual(content.viewport.height, 0.25, accuracy: 1e-9)
        XCTAssertTrue(content.viewport.isInside)
    }

    func testViewportPartlyOutsideTheDataArea() throws {
        let content = try XCTUnwrap(DataAreaOverviewContentBuilder.make(
            grid: grid,
            viewport: extent(center: Location(latitude: 50, longitude: 0),
                             latitudeSpan: 30,
                             longitudeSpan: 30),
            zoomLevel: 7))

        XCTAssertEqual(content.viewport.x, -0.25, accuracy: 1e-9)
        XCTAssertEqual(content.viewport.width, 1.5, accuracy: 1e-9)
        XCTAssertFalse(content.viewport.isInside)
    }

    func testViewportFallsBackToTheWholeAreaBeforeTheMapReportsOne() throws {
        let content = try XCTUnwrap(DataAreaOverviewContentBuilder.make(grid: grid,
                                                                       viewport: nil,
                                                                       zoomLevel: 7))

        XCTAssertEqual(content.viewport, OverviewViewport(x: 0, y: 0, width: 1, height: 1))
    }

    func testAZoomLevelIsAlwaysShown() throws {
        let content = try XCTUnwrap(DataAreaOverviewContentBuilder.make(
            grid: grid,
            viewport: extent(center: Location(latitude: 50, longitude: 0),
                             latitudeSpan: 5,
                             longitudeSpan: 5),
            zoomLevel: 12.5))

        XCTAssertEqual(content.zoomText, "Zoom 12.5")
    }
}
