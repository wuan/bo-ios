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

final class BackgroundQueryPeriodTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "BackgroundQueryPeriodTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func testDefaultsToOff() {
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.backgroundQueryPeriod, 0)
        XCTAssertFalse(store.backgroundMonitoringEnabled)
    }

    func testValuesMatchTheReference() {
        XCTAssertEqual(SelectableSettings.backgroundQueryPeriods.map { $0.value },
                       [0, 60, 120, 300, 600, 900, 1800, 3600, 7200])
        XCTAssertEqual(SelectableSettings.backgroundQueryPeriods.first?.name, "off")
        XCTAssertEqual(SelectableSettings.backgroundQueryPeriods.dropFirst().map { $0.name },
                       ["1 min", "2 min", "5 min", "10 min", "15 min", "30 min", "60 min", "120 min"])
    }

    // MARK: - Persistence

    func testEachOfferedValueIsAcceptedAndReadBack() {
        let store = SettingsStore(defaults: defaults)

        for value in SelectableSettings.backgroundQueryPeriods.map({ $0.value }) {
            XCTAssertTrue(store.setChoice(value, for: .backgroundQueryPeriod), "\(value) should be accepted")
            XCTAssertEqual(store.backgroundQueryPeriod, value)
        }
    }

    func testChangesPersistAcrossStoreInstances() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.setChoice(600, for: .backgroundQueryPeriod))

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.backgroundQueryPeriod, 600)
    }

    // MARK: - Rejection

    func testValueOutsideTheSetIsRejected() {
        let store = SettingsStore(defaults: defaults)

        XCTAssertFalse(store.setChoice(42, for: .backgroundQueryPeriod))

        XCTAssertEqual(store.backgroundQueryPeriod, 0)
    }

    func testStoredValueOutsideTheSetFallsBackToOff() {
        defaults.set(42, forKey: SettingsKey.backgroundQueryPeriod.rawValue)

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.backgroundQueryPeriod, 0)
    }

    // MARK: - Gating

    func testMonitoringNeedsBothAlertsAndAPeriod() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.alertsEnabled, "alerts default on")
        XCTAssertFalse(store.backgroundMonitoringEnabled, "but the period is off")

        store.setChoice(600, for: .backgroundQueryPeriod)
        XCTAssertTrue(store.backgroundMonitoringEnabled)

        store.set(false, for: .alertEnabled)
        XCTAssertFalse(store.backgroundMonitoringEnabled, "alerts off disables monitoring")
    }
}
