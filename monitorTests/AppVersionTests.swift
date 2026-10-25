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

final class AppVersionTests: XCTestCase {

    // MARK: - Version comparison

    func testANewerPatchVersionIsAnUpdate() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "1.0.1"),
                       .updateAvailable("1.0.1"))
    }

    func testANewerMinorVersionIsAnUpdate() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "1.1"),
                       .updateAvailable("1.1"))
    }

    func testANewerMajorVersionIsAnUpdate() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.9", available: "2.0"),
                       .updateAvailable("2.0"))
    }

    /// The comparison is numeric, so `1.10` is newer than `1.9`, which a
    /// lexical comparison would get backwards.
    func testVersionComponentsAreComparedNumericallyNotLexically() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.10", available: "1.9"), .upToDate)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.9", available: "1.10"),
                       .updateAvailable("1.10"))
    }

    func testEqualVersionsAreUpToDate() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "1.0"), .upToDate)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "1.0.0"), .upToDate)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.2.0", available: "1.2"), .upToDate)
    }

    func testAnOlderAvailableVersionIsUpToDate() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "2.0", available: "1.9"), .upToDate)
    }

    func testAMalformedAvailableVersionIsUnknown() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "1.x"), .unknown)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: "next"), .unknown)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: ""), .unknown)
        XCTAssertEqual(UpdateCheck.evaluate(installed: "1.0", available: nil), .unknown)
    }

    func testAMalformedInstalledVersionIsUnknown() {
        XCTAssertEqual(UpdateCheck.evaluate(installed: "one", available: "2.0"), .unknown)
    }

    // MARK: - The installed version

    func testDisplayTextCarriesTheBuildWhenThereIsOne() {
        XCTAssertEqual(AppVersion(marketing: "1.0", build: "7").displayText, "1.0 (7)")
        XCTAssertEqual(AppVersion(marketing: "1.0", build: "").displayText, "1.0")
    }

    func testTheVersionIsReadFromTheBundle() {
        let version = AppVersion.read(bundle: Bundle(for: type(of: self)))
        XCTAssertFalse(version.marketing.isEmpty, "the bundle carries no marketing version")
        XCTAssertFalse(version.build.isEmpty, "the bundle carries no build number")
    }
}
