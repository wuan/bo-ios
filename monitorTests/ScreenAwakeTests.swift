/*

 Copyright 2026 Andreas Würl

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

import UIKit
import XCTest
@testable import monitor

/// The idle timer, standing in for the application.
private final class FakeIdleTimer: IdleTimerControlling {
    var isIdleTimerDisabled = false
}

final class ScreenAwakeTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var application: FakeIdleTimer!

    override func setUp() {
        super.setUp()
        suiteName = "ScreenAwakeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        application = FakeIdleTimer()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        application = nil
        settings = nil
        defaults = nil
        super.tearDown()
    }

    func testTheDefaultLeavesTheIdleTimerAlone() {
        ScreenAwakeController(settings: settings, application: application).start()

        XCTAssertFalse(application.isIdleTimerDisabled,
                       "keeping the screen awake is opt-in")
    }

    func testTheSettingKeepsTheScreenAwake() {
        settings.set(true, for: .keepScreenAwake)

        ScreenAwakeController(settings: settings, application: application).start()

        XCTAssertTrue(application.isIdleTimerDisabled)
    }

    func testAChangeTakesEffectWithoutARelaunch() {
        let controller = ScreenAwakeController(settings: settings, application: application)
        controller.start()

        settings.set(true, for: .keepScreenAwake)
        XCTAssertTrue(application.isIdleTimerDisabled)

        settings.set(false, for: .keepScreenAwake)
        XCTAssertFalse(application.isIdleTimerDisabled)
    }
}
