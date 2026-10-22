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

final class DataModeTests: XCTestCase {

    func testStartsInRealtime() {
        let model = TimeModel()
        XCTAssertEqual(model.mode, .realtime)
        XCTAssertTrue(model.isRealtime)
    }

    func testSelectingANonRightmostPositionEntersHistory() {
        var model = TimeModel()
        model.setPosition(0)

        XCTAssertEqual(model.mode, .history)
        XCTAssertFalse(model.isRealtime)
        XCTAssertEqual(model.interval.offset, -1380)
    }

    func testRightmostPositionReturnsToRealtime() {
        var model = TimeModel()
        model.setPosition(0)
        model.setPosition(model.maxPosition)

        XCTAssertEqual(model.mode, .realtime)
        XCTAssertEqual(model.interval.offset, 0)
    }

    func testGoRealtimeFromHistory() {
        var model = TimeModel()
        model.setPosition(10)
        model.goRealtime()

        XCTAssertEqual(model.mode, .realtime)
        XCTAssertEqual(model.interval.offset, 0)
    }

    func testAnimationStartsAndAdvances() {
        var model = TimeModel()
        model.startAnimation()
        XCTAssertEqual(model.mode, .animation)

        model.advanceAnimation()
        XCTAssertEqual(model.interval.offset, -1380)

        model.advanceAnimation()
        XCTAssertEqual(model.interval.offset, -1350)
        XCTAssertEqual(model.mode, .animation)
    }

    func testIntervalStartIsTheEndMinusTheDuration() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        let realtime = TimeModel()
        XCTAssertEqual(realtime.intervalStart(now: now), now.addingTimeInterval(-3600))

        var historical = TimeModel()
        historical.setPosition(0)
        XCTAssertEqual(historical.intervalStart(now: now), now.addingTimeInterval(-1440 * 60))
    }

    func testStoppingAnimationHoldsTheInterval() {
        var model = TimeModel()
        model.startAnimation()
        model.advanceAnimation()
        model.advanceAnimation()
        model.stopAnimation()

        XCTAssertEqual(model.mode, .history)
        XCTAssertEqual(model.interval.offset, -1350)
        XCTAssertFalse(model.isRealtime)
    }

    func testStoppingAnimationAtRealtimeStaysRealtime() {
        var model = TimeModel()
        model.startAnimation()
        model.stopAnimation()

        XCTAssertEqual(model.mode, .realtime)
        XCTAssertTrue(model.isRealtime)
    }
}
