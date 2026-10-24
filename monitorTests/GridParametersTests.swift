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

final class GridParametersTests: XCTestCase {

    private let grid = GridParameters(longitudeStart: -10.0,
                                      longitudeDelta: 1.0,
                                      longitudeCount: 20,
                                      latitudeStart: 55.0,
                                      latitudeDelta: 1.0,
                                      latitudeCount: 20)

    /// The first cell's centre lies half a cell inside the grid's western and
    /// northern edges, and the last half a cell inside the eastern and southern
    /// ones - on both axes, as the reference client has it. A centre placed on
    /// the wrong side of the edge shifts every cell by one whole cell.
    func testCellCentersAreDerivedFromOffsets() {
        XCTAssertEqual(grid.getCenterLongitude(offset: 0), -9.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLatitude(offset: 0), 54.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLongitude(offset: 19), 9.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLatitude(offset: 19), 35.5, accuracy: 0.0001)

        XCTAssertEqual(grid.getCenterLongitude(offset: 0) - grid.longitudeStart,
                       grid.longitudeDelta / 2,
                       accuracy: 0.0001,
                       "the first column's centre is half a cell inside the western edge")
        XCTAssertEqual(grid.longitudeEnd - grid.getCenterLongitude(offset: 19),
                       grid.longitudeDelta / 2,
                       accuracy: 0.0001,
                       "the last column's centre is half a cell inside the eastern edge")
        XCTAssertEqual(grid.latitudeStart - grid.getCenterLatitude(offset: 0),
                       grid.latitudeDelta / 2,
                       accuracy: 0.0001,
                       "the first row's centre is half a cell inside the northern edge")
        XCTAssertEqual(grid.getCenterLatitude(offset: 19) - grid.latitudeEnd,
                       grid.latitudeDelta / 2,
                       accuracy: 0.0001,
                       "the last row's centre is half a cell inside the southern edge")
    }

    func testGridBoundsAreDerived() {
        XCTAssertEqual(grid.longitudeEnd, 10.0, accuracy: 0.0001)
        XCTAssertEqual(grid.latitudeEnd, 35.0, accuracy: 0.0001)
        XCTAssertEqual(grid.rectCenterLongitude, 0.0, accuracy: 0.0001)
        XCTAssertEqual(grid.rectCenterLatitude, 45.0, accuracy: 0.0001)
    }

    /// A world-spanning grid as the global strike-grid method reports it: the
    /// endpoints are the live values from `get_global_strikes_grid` at a 25 km
    /// grid size.
    private let globalGrid = GridParameters(longitudeStart: -180.0,
                                            longitudeDelta: 0.318399,
                                            longitudeCount: 1130,
                                            latitudeStart: 90.0263,
                                            latitudeDelta: 0.235637,
                                            latitudeCount: 763)

    /// A world-spanning grid numbers its offsets from the origin, not from its
    /// reported north-western corner: the backend measures them east of the
    /// prime meridian and south of the equator. Anchoring them at the corner
    /// displaced every global cell about 180° west and 90° north, drawing a
    /// storm over Queensland at Greenland instead.
    func testWorldSpanningGridCellCentersAreDerivedFromTheOrigin() {
        XCTAssertEqual(globalGrid.getCenterLongitude(offset: 455), 145.0, accuracy: 0.05,
                       "column 455 of the live response lies over Queensland")
        XCTAssertEqual(globalGrid.getCenterLatitude(offset: 99), -23.4, accuracy: 0.05,
                       "row 99 of the live response is in the southern hemisphere")
    }

    /// Every offset a live response carries decodes to a centre inside the
    /// globe. The corner anchor produced latitudes above 90° and longitudes
    /// below -180° for the same offsets.
    func testWorldSpanningGridCellCentersStayInsideTheGlobe() {
        // The offsets whose centres fall inside the globe for the live deltas:
        // ±180 / xd and ±90 / yd, within half a cell.
        for offset in -565...564 {
            XCTAssertTrue((-180.0...180.0).contains(globalGrid.getCenterLongitude(offset: offset)),
                          "longitude for column offset \(offset)")
        }
        for offset in -382...381 {
            XCTAssertTrue((-90.0...90.0).contains(globalGrid.getCenterLatitude(offset: offset)),
                          "latitude for row offset \(offset)")
        }
    }

    /// The reported bounds of a world-spanning grid still describe the area the
    /// grid covers, because containment, the data-area overview and the
    /// histogram zoom read them.
    func testWorldSpanningGridKeepsItsGeographicBounds() {
        XCTAssertTrue(globalGrid.isGlobal)
        XCTAssertEqual(globalGrid.longitudeStart, -180.0, accuracy: 0.0001)
        XCTAssertEqual(globalGrid.longitudeEnd, -180.0 + 0.318399 * 1130, accuracy: 0.0001)
        XCTAssertEqual(globalGrid.latitudeStart, 90.0263, accuracy: 0.0001)
        XCTAssertEqual(globalGrid.latitudeEnd, 90.0263 - 0.235637 * 763, accuracy: 0.0001)
    }

    /// Containment follows the reported bounds, not the offset anchor: a
    /// location inside the covered area is inside, one beyond an edge is not.
    func testWorldSpanningGridContainmentKeepsItsResult() {
        XCTAssertTrue(globalGrid.contains(Location(latitude: -23.4, longitude: 145.0)))
        XCTAssertTrue(globalGrid.contains(Location(latitude: 52.0, longitude: 13.4)))
        XCTAssertFalse(globalGrid.contains(Location(latitude: 0.0, longitude: 179.9)),
                       "east of the reported eastern edge")
        XCTAssertFalse(globalGrid.contains(Location(latitude: 0.0, longitude: -180.5)),
                       "west of the reported western edge")
    }

    func testParsesFromDictionary() {
        let dict: [String: AnyObject] = [
            "x0": -10.0 as AnyObject,
            "xd": 1.0 as AnyObject,
            "xc": 20 as AnyObject,
            "y1": 55.0 as AnyObject,
            "yd": 1.0 as AnyObject,
            "yc": 20 as AnyObject,
        ]
        let parsed = GridParameters(fromDict: dict)
        XCTAssertEqual(parsed, grid)
    }

    func testReturnsNilWhenKeysMissing() {
        let dict: [String: AnyObject] = ["x0": -10.0 as AnyObject]
        XCTAssertNil(GridParameters(fromDict: dict))
    }
}
