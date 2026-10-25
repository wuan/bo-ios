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

final class InformationContentTests: XCTestCase {

    func testTheContentNamesTheInstalledVersionAndProject() {
        let content = InformationContent.make(version: AppVersion(marketing: "1.0", build: "7"),
                                              outcome: .unknown)

        XCTAssertEqual(content.version, "1.0 (7)")
        XCTAssertEqual(content.project, InformationContent.projectURL)
        XCTAssertFalse(content.name.isEmpty)
        XCTAssertFalse(content.copyright.isEmpty)
    }

    /// An unknown outcome shows no update line, so an unreachable store leaves
    /// the screen silent.
    func testAnUnknownOutcomeShowsNoUpdateLine() {
        let content = InformationContent.make(version: AppVersion(marketing: "1.0", build: "1"),
                                              outcome: .unknown)
        XCTAssertNil(content.update)
    }

    func testAnAvailableUpdateNamesTheStoreVersion() {
        let content = InformationContent.make(version: AppVersion(marketing: "1.0", build: "1"),
                                              outcome: .updateAvailable("1.1"))
        XCTAssertEqual(content.update, "Update available: 1.1")
    }

    func testBeingUpToDateIsShown() {
        let content = InformationContent.make(version: AppVersion(marketing: "1.0", build: "1"),
                                              outcome: .upToDate)
        XCTAssertEqual(content.update, "Up to date")
    }

    func testEveryOutcomeMapsToItsLine() {
        XCTAssertNil(InformationContent.updateText(for: .unknown))
        XCTAssertEqual(InformationContent.updateText(for: .upToDate), "Up to date")
        XCTAssertEqual(InformationContent.updateText(for: .updateAvailable("3.2.1")),
                       "Update available: 3.2.1")
    }
}
