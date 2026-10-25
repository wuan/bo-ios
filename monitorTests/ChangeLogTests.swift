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

final class ChangeLogTests: XCTestCase {

    private let fixture = """
    # Changelog

    A paragraph of prose before any release is ignored.

    ## 2.0

    - Second release, first change.
    - Second release, second change.

    ## 1.5

    Prose inside a release section is ignored.

    - First release change.

    ## 1.0

    """

    func testParsesVersionsAndTheirChangesInFileOrder() {
        let entries = ChangeLog.parse(fixture)

        XCTAssertEqual(entries.map { $0.version }, ["2.0", "1.5"])
        XCTAssertEqual(entries.first?.changes, ["Second release, first change.",
                                                "Second release, second change."])
        XCTAssertEqual(entries.last?.changes, ["First release change."])
    }

    /// A heading without any bullet is not a change worth listing, and prose
    /// alone names no version.
    func testAHeadingWithoutChangesIsDropped() {
        let entries = ChangeLog.parse(fixture)
        XCTAssertFalse(entries.contains { $0.version == "1.0" },
                       "a release heading without changes must not become an entry")
    }

    func testEmptyInputHasNoEntries() {
        XCTAssertTrue(ChangeLog.parse("").isEmpty)
    }

    func testProseOnlyInputHasNoEntries() {
        XCTAssertTrue(ChangeLog.parse("# Changelog\n\nNothing here.\n").isEmpty)
    }

    func testBulletsBeforeAnyHeadingAreIgnored() {
        XCTAssertTrue(ChangeLog.parse("- a stray bullet\n").isEmpty)
    }

    /// The shipped file is the file the screen parses, so it must parse itself.
    func testTheBundledChangeLogParses() {
        let entries = ChangeLog.load()
        XCTAssertFalse(entries.isEmpty, "the bundled change log carries no entries")
        XCTAssertEqual(entries.first?.version, "1.0")
        XCTAssertFalse(entries.first?.changes.isEmpty ?? true)
    }
}
