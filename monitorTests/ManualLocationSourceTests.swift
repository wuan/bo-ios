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

final class ManualLocationSourceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "ManualLocationSourceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        settings = nil
        super.tearDown()
    }

    func testNoLocationBeforeAnythingIsSet() {
        let source = ManualLocationSource(settings: settings)

        XCTAssertNil(source.location, "a fresh install must not report a location")
    }

    func testCoordinatesAreReadBack() {
        let source = ManualLocationSource(settings: settings)
        let location = Location(latitude: 48.5, longitude: 9.25)

        source.setLocation(location)

        XCTAssertEqual(source.location, location)
    }

    func testReplacesAPreviousLocation() {
        let source = ManualLocationSource(settings: settings)

        source.setLocation(Location(latitude: 10, longitude: 20))
        source.setLocation(Location(latitude: -5, longitude: 130))

        XCTAssertEqual(source.location, Location(latitude: -5, longitude: 130))
    }

    func testExactlyOneUpdatePerChange() {
        let source = ManualLocationSource(settings: settings)
        var updates = 0
        let token = source.observe { updates += 1 }

        source.setLocation(Location(latitude: 10, longitude: 20))
        XCTAssertEqual(updates, 1)

        source.setLocation(Location(latitude: 11, longitude: 21))
        XCTAssertEqual(updates, 2)

        source.removeObserver(token)
    }

    func testSettingTheSameLocationDoesNotNotify() {
        let source = ManualLocationSource(settings: settings)
        let location = Location(latitude: 10, longitude: 20)
        source.setLocation(location)

        var updates = 0
        let token = source.observe { updates += 1 }
        source.setLocation(location)

        XCTAssertEqual(updates, 0)
        source.removeObserver(token)
    }

    func testUpdatesStopAfterRemovingTheObserver() {
        let source = ManualLocationSource(settings: settings)
        var updates = 0
        let token = source.observe { updates += 1 }
        source.removeObserver(token)

        source.setLocation(Location(latitude: 1, longitude: 2))

        XCTAssertEqual(updates, 0)
    }

    func testUpdatesDoNotLeakBetweenSources() {
        let source = ManualLocationSource(settings: settings)
        let other = ManualLocationSource(settings: SettingsStore(defaults: UserDefaults(suiteName: "\(suiteName!).other")!))
        var updates = 0
        let token = source.observe { updates += 1 }

        other.setLocation(Location(latitude: 1, longitude: 2))

        XCTAssertEqual(updates, 0)
        source.removeObserver(token)
    }

    // MARK: - Persistence

    func testLocationPersistsAcrossSourceInstances() {
        let location = Location(latitude: 49.0, longitude: 8.4)
        ManualLocationSource(settings: settings).setLocation(location)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(ManualLocationSource(settings: reloaded).location, location)
    }

    func testLocationModeDefaultsToManualAndPersists() {
        XCTAssertEqual(settings.locationMode, .manual)

        settings.set(LocationMode.manual.rawValue, for: .locationMode)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.locationMode, .manual)
    }

    func testEveryLocationModeRoundTripsAndOnlyManualIsManual() {
        for mode in LocationMode.allCases {
            settings.set(mode.rawValue, for: .locationMode)

            let reloaded = SettingsStore(defaults: defaults)
            XCTAssertEqual(reloaded.locationMode, mode, "\(mode.rawValue) did not round-trip")
            XCTAssertEqual(mode.isDeviceBacked, mode != .manual, "\(mode.rawValue) has the wrong device flag")
        }
    }

    func testUnknownLocationModeFallsBackToManual() {
        settings.set("cell", for: .locationMode)

        XCTAssertEqual(settings.locationMode, .manual)
    }

    // MARK: - Display and centring settings

    func testOwnLocationDisplayIsOnByDefault() {
        XCTAssertTrue(settings.showOwnLocation)
        XCTAssertEqual(settings.ownLocationDiameter, OwnLocationMarker.defaultDiameter)
    }

    func testOwnLocationSizeSettingDrivesTheDiameter() {
        settings.set(200, for: .ownLocationSize)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.ownLocationDiameter, OwnLocationMarker.defaultDiameter * 2)
    }

    func testOwnLocationSizeIsClampedToTheSettableRange() {
        settings.set(10, for: .ownLocationSize)
        XCTAssertEqual(settings.ownLocationDiameter, OwnLocationMarker.diameter(percent: OwnLocationMarker.minimumSizePercent))

        settings.set(100000, for: .ownLocationSize)
        XCTAssertEqual(settings.ownLocationDiameter, OwnLocationMarker.diameter(percent: OwnLocationMarker.maximumSizePercent))
    }

    func testKeepZoomIsOffByDefaultAndPersists() {
        XCTAssertFalse(settings.keepZoomOnCenter)

        settings.set(true, for: .keepZoomOnCenter)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertTrue(reloaded.keepZoomOnCenter)
    }
}
