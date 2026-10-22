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

final class ModeRefreshSchedulerTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 0)

    func testRealtimeRefreshesOnTheQueryPeriod() {
        let scheduler = ModeRefreshScheduler(realtimePeriod: 60)

        XCTAssertEqual(scheduler.tick(mode: .realtime, now: start), .refresh)
        XCTAssertEqual(scheduler.tick(mode: .realtime, now: start.addingTimeInterval(30)), .none)
        XCTAssertEqual(scheduler.tick(mode: .realtime, now: start.addingTimeInterval(60)), .refresh)
    }

    func testHistoryDoesNotRefreshOnATick() {
        let scheduler = ModeRefreshScheduler()
        scheduler.tick(mode: .history, now: start)

        XCTAssertEqual(scheduler.tick(mode: .history, now: start.addingTimeInterval(600)), .none)
    }

    func testAnimationAdvancesEachTick() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 1)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(0.5)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(1)), .advanceAndRefresh)
    }

    func testSelectionChangeRefreshesAtOnce() {
        let scheduler = ModeRefreshScheduler()

        XCTAssertEqual(scheduler.selectionChanged(now: start), .refresh)
        XCTAssertTrue(scheduler.hasRefreshed)
    }
}
