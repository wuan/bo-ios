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

/// Ports the Android `TimeIntervalTest` cases: steps clamp to the history
/// lower limit and align to the history increment.
final class TimeIntervalSteppingTests: XCTestCase {

    private let history = History(timeIncrement: 30, range: 120, limit: true)
    private let historyUnlimited = History(timeIncrement: 30, range: 120, limit: false)

    func testZeroOffsetIsRealtime() {
        XCTAssertTrue(TimeIntervalSelection().isRealtime)
        XCTAssertFalse(TimeIntervalSelection().withOffset(-30, history: history).isRealtime)
    }

    func testRewindStepsUntilTheLowerLimit() {
        var interval = TimeIntervalSelection()

        interval = interval.rewind(history: history)
        XCTAssertEqual(interval.offset, -30)

        interval = interval.rewind(history: history)
        XCTAssertEqual(interval.offset, -60)

        let again = interval.rewind(history: history)
        XCTAssertEqual(again.offset, -60)
        XCTAssertEqual(again, interval)
    }

    func testRewindAlignsToTheIncrement() {
        let history = History(timeIncrement: 45, range: 120, limit: true)
        var interval = TimeIntervalSelection()

        interval = interval.rewind(history: history)
        XCTAssertEqual(interval.offset, -45)

        let again = interval.rewind(history: history)
        XCTAssertEqual(again.offset, -45)
        XCTAssertEqual(again, interval)
    }

    func testFastForwardReturnsToRealtime() {
        var interval = TimeIntervalSelection().rewind(history: history)

        interval = interval.fastForward(history: history)
        XCTAssertEqual(interval.offset, 0)

        let again = interval.fastForward(history: history)
        XCTAssertEqual(again.offset, 0)
        XCTAssertEqual(again, interval)
    }

    func testGoRealtime() {
        let realtime = TimeIntervalSelection()
        XCTAssertEqual(realtime.goRealtime().offset, 0)
        XCTAssertEqual(realtime.goRealtime(), realtime)

        let historical = realtime.rewind(history: history)
        XCTAssertEqual(historical.goRealtime().offset, 0)
    }

    func testWithOffsetInRange() {
        XCTAssertEqual(TimeIntervalSelection().withOffset(-50, history: history).offset, -50)
    }

    func testWithPositiveOffsetIsIgnored() {
        XCTAssertEqual(TimeIntervalSelection().withOffset(1, history: history).offset, 0)
    }

    func testWithOffsetBeyondTheLimitedRangeIsIgnored() {
        XCTAssertEqual(TimeIntervalSelection().withOffset(-61, history: history).offset, 0)
    }

    func testWithOffsetWithinTheUnlimitedRange() {
        XCTAssertEqual(TimeIntervalSelection().withOffset(-120, history: historyUnlimited).offset, -120)
    }

    func testWithOffsetOutsideTheUnlimitedRangeIsIgnored() {
        XCTAssertEqual(TimeIntervalSelection().withOffset(-121, history: historyUnlimited).offset, 0)
    }

    func testAnimationStepsLoopAcrossTheRange() {
        var interval = TimeIntervalSelection()

        interval = interval.animationStep(history: history)
        XCTAssertEqual(interval.offset, -60)

        interval = interval.animationStep(history: history)
        XCTAssertEqual(interval.offset, -30)

        interval = interval.animationStep(history: history)
        XCTAssertEqual(interval.offset, 0)

        interval = interval.animationStep(history: history)
        XCTAssertEqual(interval.offset, -60)
    }

    func testAnimationStepsUnlimited() {
        var interval = TimeIntervalSelection()
        let expectedOffsets = [-120, -90, -60, -30, 0, -120]

        for expected in expectedOffsets {
            interval = interval.animationStep(history: historyUnlimited)
            XCTAssertEqual(interval.offset, expected)
        }
    }
}
