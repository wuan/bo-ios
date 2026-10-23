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

final class BackgroundLocationDisclosureTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var disclosure: BackgroundLocationDisclosure!

    override func setUp() {
        super.setUp()
        suiteName = "BackgroundLocationDisclosureTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        disclosure = BackgroundLocationDisclosure(settings: settings)
    }

    override func tearDown() {
        disclosure = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testTheExplanationIsDueUntilItHasBeenAcknowledged() {
        XCTAssertTrue(disclosure.isDue)
    }

    func testAnAcknowledgedExplanationIsNotDueAgain() {
        disclosure.acknowledge()

        XCTAssertFalse(disclosure.isDue)
    }

    func testTheAcknowledgementSurvivesARelaunch() {
        disclosure.acknowledge()

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertFalse(BackgroundLocationDisclosure(settings: reloaded).isDue)
    }

    func testTheRequestWaitsWhileTheExplanationIsDue() {
        var explained = 0
        var requested = 0

        let ran = disclosure.request(disclosing: { explained += 1 },
                                     requesting: { requested += 1 })

        XCTAssertFalse(ran)
        XCTAssertEqual(explained, 1)
        XCTAssertEqual(requested, 0, "the permission must not be asked for before the explanation")
    }

    func testTheRequestRunsOnceTheExplanationIsAcknowledged() {
        disclosure.acknowledge()
        var explained = 0
        var requested = 0

        let ran = disclosure.request(disclosing: { explained += 1 },
                                     requesting: { requested += 1 })

        XCTAssertTrue(ran)
        XCTAssertEqual(requested, 1)
        XCTAssertEqual(explained, 0, "an acknowledged explanation is not shown again")
    }

    func testNoBackgroundAuthorisationIsAskedForBeforeTheAcknowledgement() {
        let manager = StubLocationManager(authorizationStatus: .authorizedWhenInUse)

        _ = disclosure.request(disclosing: {},
                               requesting: { manager.requestAlwaysAuthorization() })
        XCTAssertEqual(manager.alwaysRequests, 0)

        disclosure.acknowledge()
        _ = disclosure.request(disclosing: {},
                               requesting: { manager.requestAlwaysAuthorization() })
        XCTAssertEqual(manager.alwaysRequests, 1)
    }
}
