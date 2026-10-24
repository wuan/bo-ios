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

import CoreLocation
import XCTest
@testable import monitor

final class DeviceLocationSourceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var manager: StubLocationManager!

    override func setUp() {
        super.setUp()
        suiteName = "DeviceLocationSourceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        manager = StubLocationManager()
    }

    override func tearDown() {
        manager = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeSource(mode: LocationMode) -> DeviceLocationSource {
        return DeviceLocationSource(mode: mode, manager: manager)
    }

    // MARK: - Mode configuration

    func testEachDeviceModeHasItsOwnAccuracyAndUpdateStyle() throws {
        let network = try XCTUnwrap(DeviceLocationConfiguration.forMode(.network))
        XCTAssertEqual(network.accuracy, kCLLocationAccuracyKilometer)
        XCTAssertFalse(network.usesSignificantChanges)

        let gps = try XCTUnwrap(DeviceLocationConfiguration.forMode(.gps))
        XCTAssertEqual(gps.accuracy, kCLLocationAccuracyBest)
        XCTAssertFalse(gps.usesSignificantChanges)

        let passive = try XCTUnwrap(DeviceLocationConfiguration.forMode(.passive))
        XCTAssertEqual(passive.accuracy, kCLLocationAccuracyThreeKilometers)
        XCTAssertTrue(passive.usesSignificantChanges)
    }

    func testManualModeAsksTheDeviceForNothing() {
        XCTAssertNil(DeviceLocationConfiguration.forMode(.manual))
    }

    func testTheModeSetsTheAccuracyTheManagerIsAskedFor() {
        for mode in [LocationMode.network, .gps, .passive] {
            manager.desiredAccuracy = 0

            _ = makeSource(mode: mode)

            XCTAssertEqual(manager.desiredAccuracy,
                           DeviceLocationConfiguration.forMode(mode)?.accuracy,
                           "\(mode.rawValue) asked for the wrong accuracy")
        }
    }

    func testPassiveModeUsesSignificantChangesAndTheOthersContinuousUpdates() {
        _ = makeSource(mode: .passive)
        XCTAssertEqual(manager.startedSignificantChanges, 1)
        XCTAssertEqual(manager.startedUpdates, 0)

        manager = StubLocationManager()
        _ = makeSource(mode: .network)
        XCTAssertEqual(manager.startedUpdates, 1)
        XCTAssertEqual(manager.startedSignificantChanges, 0)
    }

    // MARK: - Positions

    func testNoPositionUntilTheDeviceReportsOne() {
        let source = makeSource(mode: .gps)

        XCTAssertNil(source.location)
    }

    func testAReportedPositionBecomesTheCurrentLocation() {
        let source = makeSource(mode: .network)
        let reported = Location(latitude: 48.5, longitude: 9.25)

        manager.report(reported)

        XCTAssertEqual(source.location, reported)
    }

    func testEachNewPositionNotifiesObserversExactlyOnce() {
        let source = makeSource(mode: .network)
        var updates = 0
        let token = source.observe { updates += 1 }

        manager.report(Location(latitude: 10, longitude: 20))
        XCTAssertEqual(updates, 1)

        manager.report(Location(latitude: 11, longitude: 21))
        XCTAssertEqual(updates, 2)

        source.removeObserver(token)
    }

    func testAnUnchangedPositionNotifiesNothing() {
        let source = makeSource(mode: .network)
        let reported = Location(latitude: 10, longitude: 20)
        manager.report(reported)

        var updates = 0
        let token = source.observe { updates += 1 }
        manager.report(reported)

        XCTAssertEqual(updates, 0)
        source.removeObserver(token)
    }

    func testStoppingTheSourceGoesQuiet() {
        let source = makeSource(mode: .network)
        var updates = 0
        let token = source.observe { updates += 1 }

        source.stop()
        manager.report(Location(latitude: 10, longitude: 20))

        XCTAssertEqual(updates, 0)
        XCTAssertNil(source.location)
        source.removeObserver(token)
    }

    // MARK: - Permissions

    func testThePermissionIsAskedForWhenItIsNotYetDecided() {
        manager = StubLocationManager(authorizationStatus: .notDetermined)

        _ = makeSource(mode: .network)

        XCTAssertEqual(manager.whenInUseRequests, 1)
        XCTAssertEqual(manager.startedUpdates, 0, "updates must wait for the permission")
    }

    func testUpdatesStartWhenThePermissionIsGranted() {
        manager = StubLocationManager(authorizationStatus: .notDetermined)
        let source = makeSource(mode: .network)

        manager.grant()

        XCTAssertEqual(manager.startedUpdates, 1)
        XCTAssertNil(source.location)
    }

    func testAGrantedPermissionStartsUpdatesWithoutAsking() {
        manager = StubLocationManager(authorizationStatus: .authorizedAlways)

        _ = makeSource(mode: .gps)

        XCTAssertEqual(manager.whenInUseRequests, 0)
        XCTAssertEqual(manager.startedUpdates, 1)
    }

    func testARefusedPermissionLeavesTheSourceWithoutAPosition() {
        manager = StubLocationManager(authorizationStatus: .denied)
        let source = makeSource(mode: .network)

        XCTAssertEqual(manager.whenInUseRequests, 0, "a refusal must not be asked again")
        XCTAssertEqual(manager.startedUpdates, 0)
        XCTAssertNil(source.location)
    }

    func testARestrictedPermissionLeavesTheSourceWithoutAPosition() {
        manager = StubLocationManager(authorizationStatus: .restricted)
        let source = makeSource(mode: .gps)

        XCTAssertEqual(manager.whenInUseRequests, 0)
        XCTAssertEqual(manager.startedUpdates, 0)
        XCTAssertNil(source.location)
    }

    func testNoDeviceModeAsksForBackgroundAuthorisation() {
        for mode in [LocationMode.network, .gps, .passive] {
            manager = StubLocationManager(authorizationStatus: .notDetermined)

            _ = makeSource(mode: mode)
            manager.grant()

            XCTAssertEqual(manager.alwaysRequests, 0, "\(mode.rawValue) must not ask for background location")
        }
    }

    // MARK: - Factory

    func testManualModeYieldsAManualSourceAndAsksTheDeviceForNothing() {
        var managersBuilt = 0
        let factory = LocationSourceFactory(managerFactory: {
            managersBuilt += 1
            return StubLocationManager()
        })

        let source = factory.makeSource(for: .manual, settings: settings)

        XCTAssertTrue(source is ManualLocationSource)
        XCTAssertEqual(managersBuilt, 0, "manual mode must not touch the device")
    }

    func testEveryDeviceModeYieldsADeviceSource() {
        for mode in [LocationMode.network, .gps, .passive] {
            let factory = LocationSourceFactory(managerFactory: { StubLocationManager() })

            let source = factory.makeSource(for: mode, settings: settings)

            let device = source as? DeviceLocationSource
            XCTAssertEqual(device?.mode, mode)
        }
    }

    func testADeviceSourceIsNotSettable() {
        let factory = LocationSourceFactory(managerFactory: { StubLocationManager() })

        let source = factory.makeSource(for: .gps, settings: settings)

        XCTAssertNil(source as? SettableLocationSource,
                     "a long press must have nothing to set in a device mode")
    }
}
