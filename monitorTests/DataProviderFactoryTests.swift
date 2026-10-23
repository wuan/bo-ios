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

final class DataProviderFactoryTests: XCTestCase {

    private func makeFactory() -> DataProviderFactory {
        return DataProviderFactory(credentialStore: InMemoryCredentialStore(), transport: StubTransport())
    }

    // MARK: - Capabilities

    func testJsonRpcProviderDeclaresGridAndClusterSupport() {
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com")

        XCTAssertEqual(provider.capabilities, DataProviderCapabilities(supportsGrid: true, supportsClusters: true))
    }

    func testHttpProviderDeclaresStrikeOnlySupport() {
        let provider = BlitzortungHttpDataProvider(endpoint: "http://example.com",
                                                   transport: StubTransport(),
                                                   credentialStore: InMemoryCredentialStore())

        XCTAssertEqual(provider.capabilities, DataProviderCapabilities(supportsGrid: false, supportsClusters: false))
    }

    // MARK: - Default endpoints

    func testBuiltInDefaultEndpoints() {
        XCTAssertEqual(DataProviderDefaults.endpoint(for: .rpc), "http://bo-test.tryb.de")
        XCTAssertEqual(DataProviderDefaults.endpoint(for: .http), "http://data.blitzortung.org/Data/Protected")
    }

    func testOverrideIsUsedWhenSet() {
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .rpc, override: "http://custom.example"),
                       "http://custom.example")
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .http, override: "http://custom.example"),
                       "http://custom.example")
    }

    func testUnsetOrBlankOverrideFallsBackToTheDefault() {
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .rpc, override: ""),
                       DataProviderDefaults.rpcEndpoint)
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .http, override: "   "),
                       DataProviderDefaults.httpEndpoint)
    }

    func testUnusableOverrideFallsBackToTheDefault() {
        // A user-editable override can contain anything; none of these may reach a provider.
        let duplicated = "http://127.0.0.1:8099http://127.0.0.1:8099"
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .rpc, override: duplicated),
                       DataProviderDefaults.rpcEndpoint)
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .http, override: "not a url"),
                       DataProviderDefaults.httpEndpoint)
        XCTAssertEqual(DataProviderFactory.resolvedEndpoint(for: .rpc, override: "://nope"),
                       DataProviderDefaults.rpcEndpoint)
    }

    func testUsableEndpointDetection() {
        XCTAssertTrue(DataProviderFactory.isUsableEndpoint("http://127.0.0.1:8099"))
        XCTAssertTrue(DataProviderFactory.isUsableEndpoint("https://data.example.org/base"))
        XCTAssertFalse(DataProviderFactory.isUsableEndpoint(""))
        XCTAssertFalse(DataProviderFactory.isUsableEndpoint("   "))
        XCTAssertFalse(DataProviderFactory.isUsableEndpoint("not a url"))
        XCTAssertFalse(DataProviderFactory.isUsableEndpoint("http://127.0.0.1:8099http://127.0.0.1:8099"))
    }

    func testMalformedEndpointFailsInsteadOfCrashingTheRpcProvider() {
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://127.0.0.1:8099http://127.0.0.1:8099")

        var captured: Error?
        provider.fetchData(parameters: Parameters()) { _, error in captured = error }

        XCTAssertNotNil(captured)
    }

    // MARK: - Factory

    func testFactoryBuildsAProviderForEachSource() {
        let factory = makeFactory()

        XCTAssertTrue(factory.makeProvider(type: .rpc, endpointOverride: "") is JsonRpcDataProvider)
        XCTAssertTrue(factory.makeProvider(type: .http, endpointOverride: "") is BlitzortungHttpDataProvider)
    }

    func testFactoryResolvesTheOverrideIntoTheRequestedURLs() throws {
        let provider = try XCTUnwrap(makeFactory().makeProvider(type: .http, endpointOverride: "http://custom.example")
            as? BlitzortungHttpDataProvider)

        let urls = provider.makeUrls(parameters: Parameters(region: 1, intervalDuration: 10),
                                     start: Date(timeIntervalSince1970: 0),
                                     end: Date(timeIntervalSince1970: 0),
                                     latestFetched: nil)

        XCTAssertEqual(urls.map { $0.absoluteString }, ["http://custom.example/Strikes_1/1970/01/01/00/00.log"])
    }

    func testFactoryFallsBackToTheDefaultEndpointWhenUnset() throws {
        let provider = try XCTUnwrap(makeFactory().makeProvider(type: .http, endpointOverride: ""))

        XCTAssertTrue(provider is BlitzortungHttpDataProvider)
    }

    // MARK: - Source selection values

    func testProviderTypeRoundTripsPersistedValues() {
        XCTAssertEqual(DataProviderType(rawValue: "rpc"), .rpc)
        XCTAssertEqual(DataProviderType(rawValue: "http"), .http)
        XCTAssertNil(DataProviderType(rawValue: "unknown"))
    }

    /// Only the Blitzortung HTTP source applies the stored region; the JSON-RPC
    /// source always derives its region from the visible extent.
    func testOnlyTheHttpSourceSelectsTheStoredRegion() {
        let expected: [DataProviderType: Bool] = [.rpc: false, .http: true]

        XCTAssertEqual(expected.count, DataProviderType.allCases.count,
                       "every case must be covered")
        for type in DataProviderType.allCases {
            XCTAssertEqual(type.selectsRegion, expected[type], "unexpected policy for \(type.rawValue)")
        }
    }
}
