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

final class BackgroundLocationPermissionTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var manager: StubLocationManager!
    private var permission: BackgroundLocationPermission!

    override func setUp() {
        super.setUp()
        suiteName = "BackgroundLocationPermissionTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        manager = StubLocationManager(authorizationStatus: .notDetermined)
        permission = BackgroundLocationPermission(settings: settings)
    }

    override func tearDown() {
        permission = nil
        manager = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testManualModeRequestsNothing() {
        var disclosed = false

        let requested = permission.request(for: .manual, manager: manager, disclosing: { disclosed = true })

        XCTAssertFalse(requested)
        XCTAssertFalse(disclosed, "a manual location needs no explanation")
        XCTAssertEqual(manager.alwaysRequests, 0)
    }

    func testDisclosureIsPresentedBeforeTheRequest() {
        var disclosed = false

        let requested = permission.request(for: .gps, manager: manager, disclosing: { disclosed = true })

        XCTAssertTrue(disclosed, "the explanation comes first")
        XCTAssertFalse(requested)
        XCTAssertEqual(manager.alwaysRequests, 0, "nothing is requested while the explanation is due")
        XCTAssertTrue(permission.isDue)
    }

    func testRequestedAfterAcknowledgement() {
        permission.acknowledge()
        var disclosed = false

        let requested = permission.request(for: .gps, manager: manager, disclosing: { disclosed = true })

        XCTAssertTrue(requested)
        XCTAssertFalse(disclosed)
        XCTAssertFalse(permission.isDue)
        XCTAssertEqual(manager.alwaysRequests, 1)
    }

    func testAlreadyAuthorizedRequestsNothing() {
        manager.authorizationStatus = .authorizedAlways
        permission.acknowledge()

        let requested = permission.request(for: .gps, manager: manager, disclosing: {})

        XCTAssertTrue(requested)
        XCTAssertEqual(manager.alwaysRequests, 0)
    }
}
