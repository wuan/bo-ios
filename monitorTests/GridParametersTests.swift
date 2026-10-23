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
