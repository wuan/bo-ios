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

import XCTest
@testable import monitor

@MainActor
final class SettingsViewControllerTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var credentials: InMemoryCredentialStore!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsViewControllerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        credentials = InMemoryCredentialStore()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        credentials = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeController() -> SettingsViewController {
        let controller = SettingsViewController(settings: SettingsStore(defaults: defaults),
                                                credentialStore: credentials)
        controller.loadViewIfNeeded()
        return controller
    }

    /// Selects a source through the control the screen shows.
    private func selectSource(_ index: Int, in controller: SettingsViewController) {
        guard let control = find("settings.source", in: controller.view) as? UISegmentedControl else {
            return XCTFail("the source selector is missing")
        }
        control.selectedSegmentIndex = index
        control.sendActions(for: .valueChanged)
    }

    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier {
            return view
        }
        for subview in view.subviews {
            if let found = find(identifier, in: subview) {
                return found
            }
        }
        return nil
    }

    private func isVisible(_ identifier: String, in controller: SettingsViewController) -> Bool {
        guard let control = find(identifier, in: controller.view) else { return false }
        return !control.isHidden
    }

    // MARK: - Credentials belong to the authenticated source

    /// The JSON-RPC source takes no username or password, so they are offered
    /// only while the Blitzortung.org HTTP source is selected.
    func testCredentialsAreOfferedOnlyForTheAuthenticatedSource() {
        let controller = makeController()

        XCTAssertFalse(isVisible("settings.username", in: controller),
                       "the JSON-RPC source must not ask for a username")
        XCTAssertFalse(isVisible("settings.password", in: controller),
                       "the JSON-RPC source must not ask for a password")

        selectSource(1, in: controller)
        XCTAssertTrue(isVisible("settings.username", in: controller))
        XCTAssertTrue(isVisible("settings.password", in: controller))

        selectSource(0, in: controller)
        XCTAssertFalse(isVisible("settings.username", in: controller))
        XCTAssertFalse(isVisible("settings.password", in: controller))
    }

    /// A screen opened on the authenticated source shows the credentials it has
    /// stored.
    func testCredentialsAreShownWhenTheAuthenticatedSourceIsSelected() {
        credentials.save(Credentials(username: "user", password: "secret"))
        let store = SettingsStore(defaults: defaults)
        store.set(DataProviderType.http.rawValue, for: .dataSource)

        let controller = makeController()

        XCTAssertTrue(isVisible("settings.username", in: controller))
        XCTAssertEqual((find("settings.username", in: controller.view) as? UITextField)?.text, "user")
        XCTAssertEqual((find("settings.password", in: controller.view) as? UITextField)?.text, "secret")
    }

    /// Saving with the unauthenticated source selected must not discard the
    /// credentials stored for the other one.
    func testSavingForTheRpcSourceKeepsTheStoredCredentials() {
        credentials.save(Credentials(username: "user", password: "secret"))
        let controller = makeController()

        guard let save = find("settings.save", in: controller.view) as? UIButton else {
            return XCTFail("the save button is missing")
        }
        save.sendActions(for: .touchUpInside)

        XCTAssertEqual(credentials.load().username, "user")
        XCTAssertEqual(credentials.load().password, "secret")
    }

    /// Saving with the authenticated source selected stores what the fields hold.
    func testSavingForTheAuthenticatedSourceStoresTheEnteredCredentials() {
        let controller = makeController()
        selectSource(1, in: controller)

        (find("settings.username", in: controller.view) as? UITextField)?.text = "typed"
        (find("settings.password", in: controller.view) as? UITextField)?.text = "typed-secret"
        (find("settings.save", in: controller.view) as? UIButton)?.sendActions(for: .touchUpInside)

        XCTAssertEqual(credentials.load().username, "typed")
        XCTAssertEqual(credentials.load().password, "typed-secret")
    }
}
