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

@MainActor
final class SettingsViewControllerTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var credentials: InMemoryCredentialStore!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsViewControllerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        credentials = InMemoryCredentialStore()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        credentials = nil
        settings = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeController() -> SettingsViewController {
        let controller = SettingsViewController(settings: settings, credentialStore: credentials)
        layOut(controller)
        return controller
    }

    /// Lays the screen out tall enough that every row's cell exists, because a
    /// table view only builds the cells it shows.
    private func layOut(_ controller: SettingsViewController) {
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 2600)
        controller.view.layoutIfNeeded()
    }

    /// Selects a source through the control the screen shows.
    private func selectSource(_ index: Int, in controller: SettingsViewController) {
        guard let control = find("settings.source", in: controller.view) as? UISegmentedControl else {
            return XCTFail("the source selector is missing")
        }
        control.selectedSegmentIndex = index
        control.sendActions(for: .valueChanged)
        layOut(controller)
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

    // MARK: - Categories

    func testTheScreenShowsEveryCategoryWithItsSettings() {
        let controller = makeController()
        let table = UITableView()
        let categories = PreferencesModel.categories

        XCTAssertEqual(controller.numberOfSections(in: table), categories.count)
        for (index, category) in categories.enumerated() {
            XCTAssertEqual(controller.tableView(table, titleForHeaderInSection: index), category.title)
            XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: index),
                           controller.items(in: index).count,
                           "\(category.id) shows the wrong number of rows")
            XCTAssertFalse(controller.items(in: index).isEmpty, "\(category.id) has no settings")
        }
    }

    func testEveryUserFacingSettingHasAControlOnTheScreen() {
        // The credentials belong to the source that authenticates, so that
        // source is selected for the check.
        settings.set(DataProviderType.http.rawValue, for: .dataSource)
        let controller = makeController()

        for category in PreferencesModel.categories {
            for item in category.items {
                let identifier = controller.identifier(for: item)
                XCTAssertNotNil(find(identifier, in: controller.view),
                                "\(identifier) has no control on the settings screen")
            }
        }
    }

    func testTheBackupCategoryOffersItsActions() {
        let controller = makeController()

        for action in PreferenceAction.allCases {
            XCTAssertNotNil(find("settings.action.\(action.rawValue)", in: controller.view),
                            "\(action.rawValue) is missing from the backup category")
        }
    }

    // MARK: - Settings reach the store

    func testAChoiceChangeReachesTheStore() {
        let controller = makeController()
        guard let control = find("settings.animationStepDuration", in: controller.view) as? UISegmentedControl else {
            return XCTFail("the animation step duration selector is missing")
        }

        control.selectedSegmentIndex = SelectableSettings.animationStepDurations.firstIndex { $0.value == 5 } ?? 0
        control.sendActions(for: .valueChanged)

        XCTAssertEqual(settings.choice(for: .animationStepDuration), 5)
    }

    /// A choice with too many values for a segmented control writes the value the
    /// picker's row selects.
    func testAPickedChoiceReachesTheStore() {
        let controller = makeController()
        let item = PreferencesModel.item(.intervalDuration)

        XCTAssertFalse(controller.usesSegmentedControl(item),
                       "a nine-value choice cannot share a row with its title")

        guard let index = item.choiceValues.firstIndex(of: "120") else {
            return XCTFail("120 min is not an interval duration")
        }
        controller.select(index: index, for: item)

        XCTAssertEqual(settings.choice(for: .intervalDuration), 120)
    }

    func testAToggleChangeReachesTheStore() {
        let controller = makeController()
        guard let control = find("settings.keepScreenAwake", in: controller.view) as? UISwitch else {
            return XCTFail("the keep-awake switch is missing")
        }

        control.isOn = true
        control.sendActions(for: .valueChanged)

        XCTAssertTrue(settings.bool(for: .keepScreenAwake))
    }

    func testASliderChangeReachesTheStore() {
        let controller = makeController()
        guard let control = find("settings.mapFade", in: controller.view) as? UISlider else {
            return XCTFail("the fade slider is missing")
        }

        control.value = 80
        control.sendActions(for: .valueChanged)

        XCTAssertEqual(settings.int(for: .mapFade), 80)
    }

    /// A slider spans its row under the title rather than sitting in the cell's
    /// trailing accessory slot, where it would be a fraction of the width.
    func testASliderSpansTheRow() {
        let controller = makeController()
        controller.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        controller.view.layoutIfNeeded()

        guard let slider = find("settings.mapFade", in: controller.view) as? UISlider else {
            return XCTFail("the fade slider is missing")
        }
        let frame = slider.convert(slider.bounds, to: controller.view)

        XCTAssertGreaterThan(frame.width, 250,
                             "the slider must span the row, not the trailing slot (was \(frame.width))")
        XCTAssertLessThan(frame.minX, 80,
                          "the slider must start near the row's leading edge (was \(frame.minX))")
    }

    /// An entry field sits beside its title on the trailing side, never over it,
    /// which is what the cell's accessory slot got wrong.
    func testAnEntryFieldSitsBesideItsTitleRatherThanOverIt() {
        let controller = makeController()

        guard let field = find("settings.manualLatitude", in: controller.view) as? UITextField else {
            return XCTFail("the latitude field is missing")
        }
        let frame = field.convert(field.bounds, to: controller.view)

        XCTAssertGreaterThan(frame.minX, 150,
                             "the field must sit on the trailing side, not at the leading edge (was \(frame.minX))")

        guard let title = findLabel(text: PreferencesModel.item(.manualLatitude).title,
                                    in: controller.view) else {
            return XCTFail("the latitude title is missing")
        }
        let titleFrame = title.convert(title.bounds, to: controller.view)
        XCTAssertLessThanOrEqual(titleFrame.maxX, frame.minX,
                                 "the title must not run under the field")
    }

    private func findLabel(text: String, in view: UIView) -> UILabel? {
        if let label = view as? UILabel, label.text == text {
            return label
        }
        for subview in view.subviews {
            if let found = findLabel(text: text, in: subview) {
                return found
            }
        }
        return nil
    }

    func testManualCoordinatesBecomeTheCurrentLocation() {
        let controller = makeController()
        XCTAssertFalse(settings.bool(for: .manualLocationSet))

        guard let latitude = find("settings.manualLatitude", in: controller.view) as? UITextField,
              let longitude = find("settings.manualLongitude", in: controller.view) as? UITextField else {
            return XCTFail("the manual coordinate fields are missing")
        }
        latitude.text = "48.5"
        longitude.text = "9.25"
        longitude.sendActions(for: .editingDidEnd)

        XCTAssertEqual(settings.double(for: .manualLatitude), 48.5)
        XCTAssertEqual(settings.double(for: .manualLongitude), 9.25)
        XCTAssertTrue(settings.bool(for: .manualLocationSet),
                      "an entered coordinate becomes the current location")
    }

    // MARK: - Backup actions

    /// The export the screen writes is a file the app can read back.
    func testExportWritesAFileThatCanBeReadBack() throws {
        settings.set("satellite", for: .mapMode)
        let controller = makeController()

        let data = try PreferencesBackup.encode(PreferencesBackup.export(settings: settings))
        guard let url = SettingsExportFile.write(data, directory: FileManager.default.temporaryDirectory) else {
            return XCTFail("the export wrote no file")
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try PreferencesBackup.decode(Data(contentsOf: url))
        XCTAssertEqual(document.settings[SettingsKey.mapMode.rawValue], .string("satellite"))
        _ = controller
    }

    /// Importing through the screen applies a document the app exported.
    func testImportingThroughTheScreenAppliesTheDocument() throws {
        let controller = makeController()
        settings.set("hybrid", for: .mapMode)

        let document = PreferencesDocument(settings: [SettingsKey.mapMode.rawValue: .string("satellite"),
                                                      SettingsKey.intervalDuration.rawValue: .int(120)])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("import-\(UUID().uuidString).json")
        try PreferencesBackup.encode(document).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        controller.documentPicker(UIDocumentPickerViewController(forOpeningContentTypes: [.json]),
                                  didPickDocumentsAt: [url])

        XCTAssertEqual(settings.string(for: .mapMode), "satellite")
        XCTAssertEqual(settings.choice(for: .intervalDuration), 120)
    }

    /// An unreadable file reports a failure and changes nothing.
    func testImportingAnInvalidFileLeavesTheSettingsUnchanged() throws {
        let controller = makeController()
        settings.set("hybrid", for: .mapMode)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("import-\(UUID().uuidString).json")
        try Data("not a document".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        controller.documentPicker(UIDocumentPickerViewController(forOpeningContentTypes: [.json]),
                                  didPickDocumentsAt: [url])

        XCTAssertEqual(settings.string(for: .mapMode), "hybrid",
                       "a failed import must change nothing")
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
        settings.set(DataProviderType.http.rawValue, for: .dataSource)

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
        let http = DataProviderType.allCases.firstIndex(of: .http) ?? 1
        let controller = makeController()
        selectSource(http, in: controller)

        (find("settings.username", in: controller.view) as? UITextField)?.text = "typed"
        (find("settings.password", in: controller.view) as? UITextField)?.text = "typed-secret"
        (find("settings.save", in: controller.view) as? UIButton)?.sendActions(for: .touchUpInside)

        XCTAssertEqual(credentials.load().username, "typed")
        XCTAssertEqual(credentials.load().password, "typed-secret")
    }
}
