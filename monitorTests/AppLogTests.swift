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

final class AppLogTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "AppLogTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        settings = nil
        super.tearDown()
    }

    private func makeLog(capacity: Int = 500) -> AppLog {
        return AppLog(settings: settings, capacity: capacity, systemSink: { _ in })
    }

    func testDiagnosticsAreOffByDefault() {
        XCTAssertFalse(makeLog().isEnabled, "diagnostics must be opt-in")
    }

    func testRecordsOnlyWhileDiagnosticsAreEnabled() {
        let log = makeLog()

        log.record("before")
        XCTAssertTrue(log.entries.isEmpty, "nothing is kept while diagnostics are off")

        settings.set(true, for: .diagnosticsEnabled)
        log.record("while on")

        XCTAssertEqual(log.entries.map { $0.message }, ["while on"])

        settings.set(false, for: .diagnosticsEnabled)
        log.record("after")

        XCTAssertEqual(log.entries.map { $0.message }, ["while on"],
                       "the toggle off stops the recording")
    }

    func testKeepsTheMessagesInOrderWithTheirTime() {
        settings.set(true, for: .diagnosticsEnabled)
        let log = AppLog(settings: settings, clock: { Date(timeIntervalSince1970: 42) }, systemSink: { _ in })

        log.record("first")
        log.record("second")

        XCTAssertEqual(log.entries, [AppLogEntry(date: Date(timeIntervalSince1970: 42), message: "first"),
                                     AppLogEntry(date: Date(timeIntervalSince1970: 42), message: "second")])
    }

    func testTheRingStaysBounded() {
        settings.set(true, for: .diagnosticsEnabled)
        let log = makeLog(capacity: 3)

        for index in 1...5 {
            log.record("message \(index)")
        }

        XCTAssertEqual(log.entries.map { $0.message }, ["message 3", "message 4", "message 5"])
    }

    func testClearingDropsTheMessages() {
        settings.set(true, for: .diagnosticsEnabled)
        let log = makeLog()
        log.record("message")

        log.clear()

        XCTAssertTrue(log.entries.isEmpty)
    }

    func testEveryMessageReachesTheSystemSink() {
        var system: [String] = []
        let log = AppLog(settings: settings, systemSink: { system.append($0) })

        log.record("off but logged")
        settings.set(true, for: .diagnosticsEnabled)
        log.record("on")

        XCTAssertEqual(system, ["off but logged", "on"],
                       "the system log sees every message regardless of the setting")
    }
}
