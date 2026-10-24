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

final class PreferencesBackupTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var credentials: InMemoryCredentialStore!

    override func setUp() {
        super.setUp()
        suiteName = "PreferencesBackupTests.\(UUID().uuidString)"
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

    // MARK: - Export contents

    func testAnExportCarriesExactlyTheUserFacingSettings() {
        let document = PreferencesBackup.export(settings: settings)

        XCTAssertEqual(Set(document.settings.keys), Set(SettingsKey.userFacing.map { $0.rawValue }))
        XCTAssertEqual(document.version, PreferencesDocument.currentVersion)
    }

    func testAnExportLeavesTheInternalBookkeepingBehind() {
        settings.set(true, for: .manualLocationSet)
        settings.set(42, for: .lastNotifiedStrikeTimestamp)

        let document = PreferencesBackup.export(settings: settings)

        for key in SettingsKey.internalKeys {
            XCTAssertNil(document.settings[key.rawValue], "\(key.rawValue) must not travel in an export")
        }
    }

    // MARK: - Credentials

    func testCredentialsAreExcludedByDefault() {
        credentials.save(Credentials(username: "user", password: "secret"))

        let document = PreferencesBackup.export(settings: settings,
                                                credentials: credentials.load())

        XCTAssertNil(document.credentials)
    }

    func testCredentialsAreIncludedOnRequest() {
        credentials.save(Credentials(username: "user", password: "secret"))

        let document = PreferencesBackup.export(settings: settings,
                                                credentials: credentials.load(),
                                                includeCredentials: true)

        XCTAssertEqual(document.credentials?.username, "user")
        XCTAssertEqual(document.credentials?.password, "secret")
    }

    func testAnImportRestoresExportedCredentials() throws {
        let document = PreferencesDocument(
            settings: [:],
            credentials: .init(username: "user", password: "secret"))

        try PreferencesBackup.apply(document, to: settings, credentialStore: credentials)

        XCTAssertEqual(credentials.load().username, "user")
        XCTAssertEqual(credentials.load().password, "secret")
    }

    // MARK: - Round trip

    func testARoundTripRestoresEverySetting() throws {
        settings.set("satellite", for: .mapMode)
        settings.set(20, for: .mapFade)
        settings.set(true, for: .showOwnLocation)
        settings.set(150, for: .ownLocationSize)
        settings.set(true, for: .keepZoomOnCenter)
        XCTAssertTrue(settings.setChoice(5, for: .animationStepDuration))
        XCTAssertTrue(settings.setChoice(2, for: .animationCyclePause))
        settings.set(DataProviderType.http.rawValue, for: .dataSource)
        settings.set("http://data.example.org", for: .serviceEndpoint)
        XCTAssertTrue(settings.setChoice(3, for: .region))
        XCTAssertTrue(settings.setChoice(120, for: .intervalDuration))
        XCTAssertTrue(settings.setChoice(15, for: .historicTimestep))
        settings.set(LocationMode.gps.rawValue, for: .locationMode)
        settings.set(48.5, for: .manualLatitude)
        settings.set(9.25, for: .manualLongitude)
        settings.set(false, for: .alertEnabled)
        XCTAssertTrue(settings.setChoice(300, for: .backgroundQueryPeriod))
        settings.set(100.0, for: .notificationDistanceLimit)
        settings.set(10.0, for: .signalingDistanceLimit)
        settings.set(30.0, for: .signalingSuppressionTime)
        settings.set(7, for: .alertVibrationSignal)
        settings.set("1005", for: .alertSoundSignal)
        settings.set(MeasurementUnit.imperial.rawValue, for: .measurementUnit)
        settings.set(true, for: .keepScreenAwake)
        settings.set(true, for: .diagnosticsEnabled)

        let data = try PreferencesBackup.encode(PreferencesBackup.export(settings: settings))

        let fresh = SettingsStore(defaults: UserDefaults(suiteName: "PreferencesBackupTests.fresh.\(UUID().uuidString)")!)
        try PreferencesBackup.apply(try PreferencesBackup.decode(data), to: fresh, credentialStore: credentials)

        for key in SettingsKey.userFacing {
            XCTAssertEqual(PreferencesBackup.value(for: key, in: fresh),
                           PreferencesBackup.value(for: key, in: settings),
                           "\(key.rawValue) did not survive the round trip")
        }
    }

    // MARK: - Rejected imports

    /// Each rejected document leaves every setting as it was.
    private func assertRejected(_ document: PreferencesDocument,
                                _ expected: PreferencesBackupError,
                                file: StaticString = #filePath,
                                line: UInt = #line) {
        settings.set("satellite", for: .mapMode)
        settings.set(20, for: .mapFade)

        XCTAssertThrowsError(try PreferencesBackup.apply(document, to: settings, credentialStore: credentials),
                             file: file, line: line) { error in
            XCTAssertEqual(error as? PreferencesBackupError, expected, file: file, line: line)
        }

        XCTAssertEqual(settings.string(for: .mapMode), "satellite",
                       "a rejected import must change nothing", file: file, line: line)
        XCTAssertEqual(settings.int(for: .mapFade), 20, file: file, line: line)
    }

    func testAnUnknownSettingIsRejected() {
        assertRejected(PreferencesDocument(settings: ["notASetting": .bool(true)]),
                       .unknownSetting("notASetting"))
    }

    func testAnInternalSettingIsRejected() {
        assertRejected(PreferencesDocument(settings: [SettingsKey.lastNotifiedStrikeTimestamp.rawValue: .int(1)]),
                       .unknownSetting(SettingsKey.lastNotifiedStrikeTimestamp.rawValue))
    }

    func testAValueOfTheWrongTypeIsRejected() {
        assertRejected(PreferencesDocument(settings: [SettingsKey.mapFade.rawValue: .string("20")]),
                       .wrongType(SettingsKey.mapFade.rawValue))
    }

    func testAValueOutsideItsSetIsRejected() {
        assertRejected(PreferencesDocument(settings: [SettingsKey.intervalDuration.rawValue: .int(7)]),
                       .valueNotAllowed(SettingsKey.intervalDuration.rawValue))
        assertRejected(PreferencesDocument(settings: [SettingsKey.mapMode.rawValue: .string("street")]),
                       .valueNotAllowed(SettingsKey.mapMode.rawValue))
        assertRejected(PreferencesDocument(settings: [SettingsKey.notificationDistanceLimit.rawValue: .double(37.0)]),
                       .valueNotAllowed(SettingsKey.notificationDistanceLimit.rawValue))
    }

    func testAValueOutsideASliderRangeIsRejected() {
        assertRejected(PreferencesDocument(settings: [SettingsKey.mapFade.rawValue: .int(140)]),
                       .valueNotAllowed(SettingsKey.mapFade.rawValue))
    }

    func testADocumentFromAnotherLayoutIsRejected() {
        assertRejected(PreferencesDocument(version: 99, settings: [:]),
                       .unsupportedVersion(99))
    }

    func testUnreadableDataIsRejected() throws {
        XCTAssertThrowsError(try PreferencesBackup.decode(Data("not a document".utf8))) { error in
            XCTAssertEqual(error as? PreferencesBackupError, .unreadable)
        }
    }

    func testValidImportsAreApplied() throws {
        let document = PreferencesDocument(settings: [SettingsKey.mapMode.rawValue: .string("satellite"),
                                                      SettingsKey.mapFade.rawValue: .int(20),
                                                      SettingsKey.intervalDuration.rawValue: .int(120)])

        try PreferencesBackup.apply(document, to: settings, credentialStore: credentials)

        XCTAssertEqual(settings.string(for: .mapMode), "satellite")
        XCTAssertEqual(settings.int(for: .mapFade), 20)
        XCTAssertEqual(settings.choice(for: .intervalDuration), 120)
    }

    // MARK: - Reset

    func testResetRestoresEveryUserFacingSetting() {
        settings.set("satellite", for: .mapMode)
        XCTAssertTrue(settings.setChoice(5, for: .animationStepDuration))
        settings.set(true, for: .keepScreenAwake)

        PreferencesBackup.reset(settings: settings)

        for key in SettingsKey.userFacing {
            XCTAssertEqual(PreferencesBackup.value(for: key, in: settings),
                           PreferencesBackup.value(for: key, in: SettingsStore(defaults: UserDefaults(suiteName: "PreferencesBackupTests.defaults.\(UUID().uuidString)")!)),
                           "\(key.rawValue) did not return to its default")
        }
    }

    func testResetLeavesTheStoredCredentials() {
        credentials.save(Credentials(username: "user", password: "secret"))

        PreferencesBackup.reset(settings: settings)

        XCTAssertEqual(credentials.load().username, "user")
        XCTAssertEqual(credentials.load().password, "secret")
    }

    func testResetClearsTheDiagnosticsRing() {
        settings.set(true, for: .diagnosticsEnabled)
        let log = AppLog(settings: settings, systemSink: { _ in })
        log.record("message")

        PreferencesBackup.reset(settings: settings, log: log)

        XCTAssertTrue(log.entries.isEmpty)
    }
}
