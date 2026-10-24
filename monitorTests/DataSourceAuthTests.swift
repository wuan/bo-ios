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

final class DataSourceAuthTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testTransportSendsAuthorizationWhenCredentialsAreSet() async throws {
        let transport = URLSessionHttpTransport(session: makeStubbedSession())
        let url = try XCTUnwrap(URL(string: "http://example.com/a.log"))

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            transport.get(url: url,
                          credentials: Credentials(username: "u", password: "p"),
                          userAgent: UserAgent(buildNumber: "9")) { _, _ in
                continuation.resume()
            }
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dTpw")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "bo-ios-9")
    }

    func testTransportSendsNoAuthorizationWithoutCredentials() async throws {
        let transport = URLSessionHttpTransport(session: makeStubbedSession())
        let url = try XCTUnwrap(URL(string: "http://example.com/a.log"))

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            transport.get(url: url,
                          credentials: nil,
                          userAgent: UserAgent(buildNumber: "9")) { _, _ in
                continuation.resume()
            }
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testHttpProviderForwardsStoredCredentialsToTheTransport() {
        let credentials = Credentials(username: "u", password: "p")
        let transport = StubTransport()
        let provider = BlitzortungHttpDataProvider(endpoint: "http://example.com",
                                                   transport: transport,
                                                   credentialStore: InMemoryCredentialStore(credentials: credentials))

        provider.fetchData(parameters: Parameters(region: 1, intervalDuration: 10)) { _, _ in }

        XCTAssertEqual(transport.receivedCredentials.last, credentials)
    }

    func testJsonRpcRequestSendsNoAuthorization() async throws {
        let client = JsonRpcClient(withServiceEndpoint: "http://example.com",
                                   userAgent: UserAgent(buildNumber: "9"),
                                   session: makeStubbedSession())

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.call(callback: { _, _ in
                continuation.resume()
            }, methodName: "get_strikes_grid", withArguments: 60)
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "bo-ios-9")
    }
}
