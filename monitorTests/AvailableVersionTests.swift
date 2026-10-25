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

final class AvailableVersionTests: XCTestCase {

    // MARK: - Decoding a lookup response

    func testDecodeReadsTheOfferedVersion() {
        let data = Data(#"{"resultCount":1,"results":[{"version":"2.5"}]}"#.utf8)
        XCTAssertEqual(AppStoreVersionLookup.decode(data: data), "2.5")
    }

    func testDecodeTreatsAnEmptyResultAsUnknown() {
        let data = Data(#"{"resultCount":0,"results":[]}"#.utf8)
        XCTAssertNil(AppStoreVersionLookup.decode(data: data))
    }

    func testDecodeIgnoresAnUnreadableAnswer() {
        XCTAssertNil(AppStoreVersionLookup.decode(data: Data("not json".utf8)))
    }

    // MARK: - The lookup itself

    /// The production lookup is driven through a stubbed session, so the request
    /// it builds and the answer it decodes are checked with no network.
    func testTheLookupAsksTheStoreByBundleIdAndDecodesTheVersion() {
        StubURLProtocol.reset()
        StubURLProtocol.responseBody = Data(#"{"resultCount":1,"results":[{"version":"2.5"}]}"#.utf8)

        let lookup = AppStoreVersionLookup(bundleIdentifier: "net.wuerl.blitzortung.monitor",
                                           session: makeStubbedSession())
        var offered: String?
        let done = expectation(description: "lookup answered")
        lookup.availableVersion { offered = $0; done.fulfill() }
        wait(for: [done], timeout: 5)

        XCTAssertEqual(offered, "2.5")
        XCTAssertEqual(StubURLProtocol.capturedRequests.first?.url?.absoluteString,
                       "https://itunes.apple.com/lookup?bundleId=net.wuerl.blitzortung.monitor")
    }

    func testTheLookupReportsUnknownWhenTheStoreHasNoListing() {
        StubURLProtocol.reset()
        StubURLProtocol.responseBody = Data(#"{"resultCount":0,"results":[]}"#.utf8)

        let lookup = AppStoreVersionLookup(bundleIdentifier: "net.wuerl.blitzortung.monitor",
                                           session: makeStubbedSession())
        var offered: String?
        let done = expectation(description: "lookup answered")
        lookup.availableVersion { offered = $0; done.fulfill() }
        wait(for: [done], timeout: 5)

        XCTAssertNil(offered)
    }
}
