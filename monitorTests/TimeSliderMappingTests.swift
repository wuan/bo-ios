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

/// Ports the Android `ParametersTest` slider-position cases: a position
/// converts to an offset and back, and the rightmost position is realtime.
final class TimeSliderMappingTests: XCTestCase {

    private let history = History()

    func testDefaultSliderPositions() {
        let interval = TimeIntervalSelection(duration: 60)
        XCTAssertEqual(interval.position(history: history), 46)
        XCTAssertEqual(interval.maxPosition(history: history), 46)
    }

    func testUnlimitedHistoryPositions() {
        let history = History(timeIncrement: 5, range: 120, limit: false)
        let interval = TimeIntervalSelection(duration: 60)
        XCTAssertEqual(interval.position(history: history), 24)
        XCTAssertEqual(interval.maxPosition(history: history), 24)
    }

    func testPositionAfterAnimationStep() {
        let start = TimeIntervalSelection().animationStep(history: history)
        XCTAssertEqual(start.position(history: history), 0)
        XCTAssertEqual(start.maxPosition(history: history), 46)
    }

    func testPositionAtStartAndEnd() {
        XCTAssertEqual(TimeIntervalSelection().withPosition(0, history: history).offset, -1380)
        XCTAssertEqual(TimeIntervalSelection().withPosition(46, history: history).offset, 0)
    }

    func testRightmostPositionIsZeroOffset() {
        let interval = TimeIntervalSelection(duration: 60)
        let realtime = interval.withPosition(interval.maxPosition(history: history), history: history)
        XCTAssertEqual(realtime.offset, 0)
        XCTAssertTrue(realtime.isRealtime)
    }

    func testPositionsRoundTrip() {
        for position in [0, 1, 5, 23, 45, 46] {
            let interval = TimeIntervalSelection(duration: 60).withPosition(position, history: history)
            XCTAssertEqual(interval.position(history: history), position)
        }
    }

    func testDurationChangesTheMaximumPosition() {
        XCTAssertEqual(TimeIntervalSelection(duration: 120).maxPosition(history: history), 44)
    }
}
