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

final class UserAgentTests: XCTestCase {

    func testValueCombinesPrefixAndBuildNumber() {
        XCTAssertEqual(UserAgent(buildNumber: "42").value, "bo-ios-42")
    }

    func testChangedBuildNumberChangesHeaderValue() {
        XCTAssertNotEqual(UserAgent(buildNumber: "1").value, UserAgent(buildNumber: "2").value)
    }

    func testMissingBuildNumberFallsBackToPrefix() {
        XCTAssertEqual(UserAgent(buildNumber: nil).value, "bo-ios")
        XCTAssertEqual(UserAgent(buildNumber: "").value, "bo-ios")
    }

    func testApplySetsTheUserAgentHeader() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/data"))
        var request = URLRequest(url: url)

        UserAgent(buildNumber: "7").apply(to: &request)

        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "bo-ios-7")
    }

    func testBundleInitializerUsesTheBundleBuildNumber() throws {
        let bundle = Bundle(for: UserAgentTests.self)
        let build = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        XCTAssertFalse(build.isEmpty)

        XCTAssertEqual(UserAgent(bundle: bundle).value, "bo-ios-\(build)")
    }
}
