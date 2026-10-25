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

final class ApplicationLogContentTests: XCTestCase {

    /// A formatter pinned to UTC, so the expected line does not depend on the
    /// machine's time zone.
    private func utcFormatter() -> DateFormatter {
        let formatter = ApplicationLogContent.timestampFormatter
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    func testLinesCarryTheTimestampAndMessageOldestFirst() {
        let entries = [AppLogEntry(date: Date(timeIntervalSince1970: 0), message: "first"),
                       AppLogEntry(date: Date(timeIntervalSince1970: 61), message: "second")]

        let content = ApplicationLogContent.make(entries: entries, formatter: utcFormatter())

        XCTAssertEqual(content.lines, ["1970-01-01 00:00:00  first",
                                       "1970-01-01 00:01:01  second"])
        XCTAssertEqual(content.text, "1970-01-01 00:00:00  first\n1970-01-01 00:01:01  second")
        XCTAssertFalse(content.isEmpty)
    }

    func testAnEmptyRingHasAnEmptyState() {
        let content = ApplicationLogContent.make(entries: [], formatter: utcFormatter())

        XCTAssertTrue(content.isEmpty)
        XCTAssertTrue(content.lines.isEmpty)
        XCTAssertEqual(content.text, "")
    }
}
