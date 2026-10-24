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

final class DataModelTests: XCTestCase {

    func testZeroOffsetIsRealtime() {
        XCTAssertTrue(TimeIntervalSelection(duration: 60, offset: 0).isRealtime)
        XCTAssertFalse(TimeIntervalSelection(duration: 60, offset: 30).isRealtime)
    }

    func testHistoryLowerLimitShrinksByDurationWhenLimited() {
        let history = History(timeIncrement: 30, range: 1440, limit: true)
        XCTAssertEqual(history.lowerLimit(of: TimeIntervalSelection(duration: 60, offset: 0)), -1380)
    }

    func testHistoryLowerLimitWhenUnlimited() {
        let history = History(timeIncrement: 30, range: 1440, limit: false)
        XCTAssertEqual(history.lowerLimit(of: TimeIntervalSelection(duration: 60, offset: 0)), -1440)
    }

    func testHistoryClampsPositionsToRange() {
        let history = History()
        XCTAssertEqual(history.clampedPosition(-10), 0)
        XCTAssertEqual(history.clampedPosition(100), 100)
        XCTAssertEqual(history.clampedPosition(History.maxRange + 50), History.maxRange)
    }

    func testDataAreaBoundsAreDerived() {
        let area = DataArea(x: 2, y: 10, scale: 5)
        XCTAssertEqual(area.x1, 10)
        XCTAssertEqual(area.x2, 15)
        XCTAssertEqual(area.y1, 50)
        XCTAssertEqual(area.y2, 55)
    }

    func testLocationEquality() {
        XCTAssertEqual(Location(latitude: 1.0, longitude: 2.0), Location(latitude: 1.0, longitude: 2.0))
        XCTAssertNotEqual(Location(latitude: 1.0, longitude: 2.0), Location(latitude: 1.0, longitude: 2.5))
    }

    func testStrikeConformsToEvent() {
        let strike = Strike(timestamp: 42, andMultiplicity: 3, andX: 1.0, andY: 2.0)
        let event: Event = strike
        XCTAssertEqual(event.timestamp, 42)
        XCTAssertEqual(event.multiplicity, 3)
    }
}
