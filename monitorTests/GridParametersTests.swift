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

    func testCellCentersAreDerivedFromOffsets() {
        XCTAssertEqual(grid.getCenterLongitude(offset: 0), -10.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLatitude(offset: 0), 54.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLongitude(offset: 19), 8.5, accuracy: 0.0001)
        XCTAssertEqual(grid.getCenterLatitude(offset: 19), 35.5, accuracy: 0.0001)
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
