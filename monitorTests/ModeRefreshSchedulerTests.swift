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

    func testAnimationFollowsTheConfiguredStepDuration() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 5)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(4)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(5)), .advanceAndRefresh)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(9)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(10)), .advanceAndRefresh)
    }

    func testAChangedStepDurationTakesEffectWithoutResettingTheStep() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 1)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)

        scheduler.configure(animationStepDuration: 10, animationCyclePause: 0)

        XCTAssertEqual(scheduler.animationPeriod, 10)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(1)), .none,
                       "the next step waits out the new duration")
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(10)), .advanceAndRefresh)
    }

    func testAWrapDefersTheNextStepByTheCyclePause() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 1, animationCyclePause: 5)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)
        scheduler.animationStepCompleted(wrapped: true, now: start)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(1)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(5)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(6)), .advanceAndRefresh)
    }

    func testAStepThatDoesNotWrapKeepsTheStepDuration() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 1, animationCyclePause: 5)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)
        scheduler.animationStepCompleted(wrapped: false, now: start)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(1)), .advanceAndRefresh)
    }

    /// A cycle pause of zero is the playback the app had before the setting
    /// existed: every step is due one step duration after the last.
    func testANoPauseCycleRepeatsAtTheStepDuration() {
        let scheduler = ModeRefreshScheduler(animationPeriod: 1, animationCyclePause: 0)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start), .advanceAndRefresh)
        scheduler.animationStepCompleted(wrapped: true, now: start)

        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(0.5)), .none)
        XCTAssertEqual(scheduler.tick(mode: .animation, now: start.addingTimeInterval(1)), .advanceAndRefresh)
    }

    func testSelectionChangeRefreshesAtOnce() {
        let scheduler = ModeRefreshScheduler()

        XCTAssertEqual(scheduler.selectionChanged(now: start), .refresh)
        XCTAssertTrue(scheduler.hasRefreshed)
    }
}
