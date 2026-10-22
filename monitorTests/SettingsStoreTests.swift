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

final class SettingsStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testUnsetKeysReturnRegisteredDefaults() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.string(for: .mapMode), "hybrid")
        XCTAssertEqual(store.int(for: .mapScale), 75)
        XCTAssertEqual(store.bool(for: .alertEnabled), true)
        XCTAssertEqual(store.string(for: .measurementUnit), "metric")
    }

    func testEveryKeyHasDefault() {
        let values = SettingsKey.defaultValues
        for key in SettingsKey.allCases {
            XCTAssertNotNil(values[key.rawValue], "Missing default for \(key.rawValue)")
        }
    }

    func testChangesPersistAcrossStoreInstances() {
        let store = SettingsStore(defaults: defaults)
        store.set("satellite", for: .mapMode)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.string(for: .mapMode), "satellite")
    }

    func testResetRestoresDefaults() {
        let store = SettingsStore(defaults: defaults)
        store.set("satellite", for: .mapMode)
        store.set(10, for: .mapScale)

        store.reset()

        XCTAssertEqual(store.string(for: .mapMode), "hybrid")
        XCTAssertEqual(store.int(for: .mapScale), 75)
    }

    func testProviderSettingsDefaults() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.string(for: .dataSource), "rpc")
        XCTAssertEqual(store.string(for: .serviceEndpoint), "")
    }

    func testProviderSettingsPersistAcrossStoreInstances() {
        let store = SettingsStore(defaults: defaults)
        store.set("http", for: .dataSource)
        store.set("http://data.example.org", for: .serviceEndpoint)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.string(for: .dataSource), "http")
        XCTAssertEqual(reloaded.string(for: .serviceEndpoint), "http://data.example.org")
    }

    func testResetRestoresProviderSettingsDefaults() {
        let store = SettingsStore(defaults: defaults)
        store.set("http", for: .dataSource)
        store.set("http://data.example.org", for: .serviceEndpoint)

        store.reset()

        XCTAssertEqual(store.string(for: .dataSource), "rpc")
        XCTAssertEqual(store.string(for: .serviceEndpoint), "")
    }

    func testColorSchemeDefaultsToBlitzortung() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.string(for: .colorScheme), "BLITZORTUNG")
        XCTAssertEqual(ColorScheme(rawValue: store.string(for: .colorScheme)), ColorScheme.blitzortung)
    }

    func testColorSchemeChangePersistsAndResets() {
        let store = SettingsStore(defaults: defaults)
        store.set(ColorScheme.temperature.rawValue, for: .colorScheme)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.string(for: .colorScheme), "TEMPERATURE")

        reloaded.reset()
        XCTAssertEqual(reloaded.string(for: .colorScheme), "BLITZORTUNG")
    }

    func testObserverNotifiedForChangedKey() {
        let store = SettingsStore(defaults: defaults)
        let changed = expectation(description: "observer notified")
        let token = store.observe(.mapMode) { changed.fulfill() }

        store.set("satellite", for: .mapMode)

        wait(for: [changed], timeout: 1)
        store.removeObserver(token)
    }

    func testObserverNotNotifiedForOtherKey() {
        let store = SettingsStore(defaults: defaults)
        let notChanged = expectation(description: "observer must not fire")
        notChanged.isInverted = true
        let token = store.observe(.mapMode) { notChanged.fulfill() }

        store.set(10, for: .mapScale)

        wait(for: [notChanged], timeout: 0.2)
        store.removeObserver(token)
    }
}
