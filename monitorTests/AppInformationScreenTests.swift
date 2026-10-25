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

/// A provider that answers at once with a preset version, for the update check.
final class StubAvailableVersionProvider: AvailableVersionProviding {
    var version: String?
    private(set) var calls = 0

    init(version: String?) {
        self.version = version
    }

    func availableVersion(completion: @escaping (String?) -> Void) {
        calls += 1
        completion(version)
    }
}

@MainActor
final class AppInformationScreenTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "AppInformationScreenTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        settings = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Helpers

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

    // MARK: - The menu

    func testTheMenuEntriesCarryTheirIdentifiersAndNames() {
        XCTAssertEqual(AppMenuEntry.allCases.map { $0.accessibilityIdentifier },
                       ["menu.settings", "menu.alarms", "menu.log",
                        "menu.changelog", "menu.information"])

        for entry in AppMenuEntry.allCases {
            XCTAssertFalse(entry.title.hasPrefix("menu."),
                           "\(entry.rawValue) shows its unresolved key")
        }
    }

    func testTheMenuShowsAButtonPerEntry() {
        let controller = AppMenuViewController { _ in }
        controller.loadViewIfNeeded()

        for entry in AppMenuEntry.allCases {
            XCTAssertNotNil(find(entry.accessibilityIdentifier, in: controller.view),
                            "\(entry.accessibilityIdentifier) is missing from the menu")
        }
    }

    func testChoosingAMenuEntryHandsItBack() {
        var chosen: AppMenuEntry?
        let controller = AppMenuViewController { chosen = $0 }
        controller.loadViewIfNeeded()

        guard let button = find(AppMenuEntry.log.accessibilityIdentifier, in: controller.view) as? UIButton else {
            return XCTFail("the log entry is missing")
        }
        button.sendActions(for: .touchUpInside)

        // The choice is handed over once the sheet dismisses, which the run loop
        // is pumped for here.
        let deadline = Date().addingTimeInterval(2)
        while chosen == nil, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(chosen, .log)
    }

    // MARK: - The application log

    func testTheLogScreenListsWhatWasRecorded() {
        settings.set(true, for: .diagnosticsEnabled)
        let log = AppLog(settings: settings, systemSink: { _ in })
        log.record("first message")
        log.record("second message")

        let controller = ApplicationLogViewController(appLog: log)
        controller.loadViewIfNeeded()

        XCTAssertEqual(controller.content.lines.count, 2)
        XCTAssertTrue(controller.content.lines.first?.hasSuffix("first message") ?? false)
        XCTAssertTrue(controller.content.lines.last?.hasSuffix("second message") ?? false)
        XCTAssertNotNil(find("appinfo.log.send", in: controller.view), "the send action is missing")
    }

    func testTheLogScreenShowsAnEmptyStateWhenNothingWasRecorded() {
        let log = AppLog(settings: settings, systemSink: { _ in })
        let controller = ApplicationLogViewController(appLog: log)
        controller.loadViewIfNeeded()

        XCTAssertTrue(controller.content.isEmpty)
        let empty = find("appinfo.log.empty", in: controller.view)
        XCTAssertNotNil(empty, "the empty state is missing")
        XCTAssertEqual(empty?.isHidden, false)
    }

    // MARK: - The change log

    func testTheChangeLogScreenListsVersionsNewestFirst() {
        let entries = [ChangeLogEntry(version: "2.0", changes: ["newest change"]),
                       ChangeLogEntry(version: "1.0", changes: ["oldest change"])]

        let controller = ChangeLogViewController(entries: entries)
        controller.loadViewIfNeeded()

        let table = UITableView()
        XCTAssertEqual(controller.numberOfSections(in: table), 2)
        XCTAssertEqual(controller.tableView(table, titleForHeaderInSection: 0), "2.0")
        XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), 1)
        XCTAssertEqual((find("appinfo.changelog.latest", in: controller.view) as? UILabel)?.text, "2.0")
    }

    func testTheChangeLogScreenShowsAnEmptyStateWithoutEntries() {
        let controller = ChangeLogViewController(entries: [])
        controller.loadViewIfNeeded()

        let empty = find("appinfo.changelog.empty", in: controller.view)
        XCTAssertNotNil(empty, "the empty state is missing")
        XCTAssertEqual(empty?.isHidden, false)
        XCTAssertEqual(find("appinfo.changelog.latest", in: controller.view)?.isHidden, true)
    }

    // MARK: - Information and the update check

    func testInformationShowsTheInstalledVersion() {
        let provider = StubAvailableVersionProvider(version: nil)
        let controller = InformationViewController(version: AppVersion(marketing: "1.0", build: "7"),
                                                   provider: provider)
        controller.loadViewIfNeeded()

        XCTAssertEqual(controller.content.version, "1.0 (7)")
        XCTAssertEqual((find("appinfo.version", in: controller.view) as? UILabel)?.text, "1.0 (7)")
        XCTAssertEqual(provider.calls, 1, "the screen must run the update check")
    }

    func testAnAvailableUpdateIsShown() {
        let controller = InformationViewController(version: AppVersion(marketing: "1.0", build: "1"),
                                                   provider: StubAvailableVersionProvider(version: "2.0"))
        controller.loadViewIfNeeded()

        XCTAssertEqual(controller.content.update, "Update available: 2.0")
        let label = find("appinfo.update", in: controller.view) as? UILabel
        XCTAssertEqual(label?.text, "Update available: 2.0")
        XCTAssertEqual(label?.isHidden, false)
    }

    func testBeingUpToDateIsShown() {
        let controller = InformationViewController(version: AppVersion(marketing: "1.0", build: "1"),
                                                   provider: StubAvailableVersionProvider(version: "1.0"))
        controller.loadViewIfNeeded()

        XCTAssertEqual(controller.content.update, "Up to date")
    }

    func testAnUnknownOutcomeShowsNoUpdateLine() {
        let controller = InformationViewController(version: AppVersion(marketing: "1.0", build: "1"),
                                                   provider: StubAvailableVersionProvider(version: nil))
        controller.loadViewIfNeeded()

        XCTAssertNil(controller.content.update)
        XCTAssertEqual(find("appinfo.update", in: controller.view)?.isHidden, true)
    }
}

/// The status row's menu control and the mode-appropriate controls beside the
/// map, exercised through the controller's own state.
@MainActor
final class ViewControllerModeControlTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var controller: ViewController!

    override func setUp() {
        super.setUp()
        suiteName = "ViewControllerModeControlTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        controller = ViewController(dataSource: DataHandler(provider: RecordingProvider()),
                                    settings: settings,
                                    credentialStore: InMemoryCredentialStore(),
                                    locationSource: ManualLocationSource(settings: settings),
                                    alertSignaller: StubAlertSignaller(),
                                    alertNotifier: StubAlertNotifier())
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        controller.pollingTimer?.invalidate()
    }

    override func tearDown() {
        controller = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testTheStatusRowOffersTheMenu() {
        XCTAssertEqual(controller.menuButton.accessibilityIdentifier, "menu.open")
    }

    /// The jump to realtime is offered only while history is selected: in
    /// realtime there is nothing to return to, and animation stops first.
    func testTheRealtimeControlIsOfferedOnlyInHistory() {
        controller.timeModel.setPosition(controller.timeModel.maxPosition - 1)
        controller.syncModeControls()
        XCTAssertEqual(controller.timeModel.mode, .history)
        XCTAssertFalse(controller.realtimeButton.isHidden, "history must offer the jump to realtime")

        controller.timeModel.goRealtime()
        controller.syncModeControls()
        XCTAssertEqual(controller.timeModel.mode, .realtime)
        XCTAssertTrue(controller.realtimeButton.isHidden, "realtime must not offer the jump to itself")

        controller.timeModel.startAnimation()
        controller.syncModeControls()
        XCTAssertEqual(controller.timeModel.mode, .animation)
        XCTAssertTrue(controller.realtimeButton.isHidden, "animation must not offer the jump while it plays")
    }

    /// A manual slider selection leaves realtime, so the controls must follow it
    /// without waiting for the indicator to be read.
    func testAManualSelectionOffersTheRealtimeControl() {
        controller.timeSlider.maximumValue = Float(controller.timeModel.maxPosition)
        controller.timeSlider.value = Float(controller.timeModel.maxPosition - 1)
        controller.sliderChanged(controller.timeSlider)

        XCTAssertEqual(controller.timeModel.mode, .history)
        XCTAssertFalse(controller.realtimeButton.isHidden,
                       "a slider selection into history must offer the jump to realtime")
    }

    /// The animation control starts playback in realtime and history and stops
    /// it while it plays.
    func testTheAnimationControlFollowsTheMode() {
        controller.timeModel.goRealtime()
        controller.syncModeControls()
        let startTitle = controller.animationButton.title(for: .normal)

        controller.timeModel.startAnimation()
        controller.syncModeControls()
        let stopTitle = controller.animationButton.title(for: .normal)

        XCTAssertNotEqual(startTitle, stopTitle, "the animation control must change with the mode")
        XCTAssertFalse(stopTitle?.hasPrefix("animation.") ?? true, "the label must resolve")
    }
}
