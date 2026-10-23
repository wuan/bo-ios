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

final class SelectableSettingsTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "SelectableSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func testDefaultsMatchTodaysBehaviour() {
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.choice(for: .region), Parameters.globalRegion, "region should default to global")
        XCTAssertEqual(store.choice(for: .intervalDuration), 60)
        XCTAssertEqual(store.choice(for: .historicTimestep), History.defaultOffsetIncrement)
    }

    func testValueSetsMatchTheReference() {
        XCTAssertEqual(SelectableSettings.regions.map { $0.value }, [-1, 0, 1, 3, 7, 5, 2, 4, 6])
        XCTAssertEqual(SelectableSettings.intervalDurations.map { $0.value }, [30, 60, 90, 120, 240])
        XCTAssertEqual(SelectableSettings.historicTimesteps.map { $0.value }, [15, 30, 60])
    }

    func testEverySelectableValueHasAName() {
        for key in [SettingsKey.region, .intervalDuration, .historicTimestep] {
            let values = SelectableSettings.values(for: key) ?? []
            XCTAssertFalse(values.isEmpty)
            for value in values {
                XCTAssertFalse(value.name.isEmpty, "\(value.value) of \(key.rawValue) has no name")
            }
        }
    }

    func testRegionNamesMatchTheReference() {
        let names = SelectableSettings.regions.map { $0.name }
        XCTAssertEqual(names, ["Local", "Global", "Europe", "N. America", "C. America",
                               "S. America", "Oceania", "Asia", "Africa"])
    }

    // MARK: - Persistence

    func testChangesPersistAcrossStoreInstances() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.setChoice(4, for: .region))
        XCTAssertTrue(store.setChoice(120, for: .intervalDuration))
        XCTAssertTrue(store.setChoice(15, for: .historicTimestep))

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.choice(for: .region), 4)
        XCTAssertEqual(reloaded.choice(for: .intervalDuration), 120)
        XCTAssertEqual(reloaded.choice(for: .historicTimestep), 15)
    }

    // MARK: - Rejection

    func testValueOutsideTheSetIsRejected() {
        let store = SettingsStore(defaults: defaults)

        XCTAssertFalse(store.setChoice(2, for: .intervalDuration), "2 is not an interval duration")
        XCTAssertFalse(store.setChoice(45, for: .historicTimestep), "45 is not a timestep")
        XCTAssertFalse(store.setChoice(99, for: .region), "99 is not a region")

        XCTAssertEqual(store.choice(for: .intervalDuration), 60)
        XCTAssertEqual(store.choice(for: .historicTimestep), History.defaultOffsetIncrement)
        XCTAssertEqual(store.choice(for: .region), Parameters.globalRegion)
    }

    func testRejectedValueDoesNotNotifyObservers() {
        let store = SettingsStore(defaults: defaults)
        let notChanged = expectation(description: "observer must not fire")
        notChanged.isInverted = true
        let token = store.observe(.intervalDuration) { notChanged.fulfill() }

        XCTAssertFalse(store.setChoice(7, for: .intervalDuration))

        wait(for: [notChanged], timeout: 0.2)
        store.removeObserver(token)
    }

    func testAcceptedValueNotifiesObservers() {
        let store = SettingsStore(defaults: defaults)
        let changed = expectation(description: "observer notified")
        let token = store.observe(.intervalDuration) { changed.fulfill() }

        XCTAssertTrue(store.setChoice(90, for: .intervalDuration))

        wait(for: [changed], timeout: 1)
        store.removeObserver(token)
    }

    func testStoredValueOutsideTheSetFallsBackToTheDefault() {
        defaults.set(12345, forKey: SettingsKey.region.rawValue)

        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.choice(for: .region), SelectableSettings.defaultRegion)
    }
}
