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

final class DataProviderCoordinatorTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "DataProviderCoordinatorTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeResult(timestamp: Int = 100) -> Result {
        return Result(parameters: Parameters(), referenceTimestamp: timestamp, strikes: [], rasterParameters: nil)
    }

    func testStartsWithTheSelectedSource() {
        let settings = SettingsStore(defaults: defaults)
        var built: [DataProviderType] = []
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in
            built.append(type)
            return RecordingProvider(type: type)
        }
        defer { coordinator.stop() }

        XCTAssertEqual(coordinator.source, .rpc)
        XCTAssertEqual(built, [.rpc])
        XCTAssertEqual(coordinator.rebuildCount, 0)
    }

    func testDefaultsToRpcForAnUnknownStoredValue() {
        let settings = SettingsStore(defaults: defaults)
        settings.set("bogus", for: .dataSource)

        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in RecordingProvider(type: type) }
        defer { coordinator.stop() }

        XCTAssertEqual(coordinator.source, .rpc)
    }

    func testSwitchingTheSourceRebuildsTheHandler() {
        let settings = SettingsStore(defaults: defaults)
        var built: [DataProviderType] = []
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in
            built.append(type)
            return RecordingProvider(type: type)
        }
        defer { coordinator.stop() }

        settings.set("http", for: .dataSource)

        XCTAssertEqual(built, [.rpc, .http])
        XCTAssertEqual(coordinator.source, .http)
        XCTAssertEqual(coordinator.rebuildCount, 1)
    }

    func testSwitchingTheEndpointRebuildsTheHandler() {
        let settings = SettingsStore(defaults: defaults)
        var endpoints: [String] = []
        let coordinator = DataProviderCoordinator(settings: settings) { _, endpointOverride in
            endpoints.append(endpointOverride)
            return RecordingProvider()
        }
        defer { coordinator.stop() }

        settings.set("http://custom.example", for: .serviceEndpoint)

        XCTAssertEqual(endpoints, ["", "http://custom.example"])
        XCTAssertEqual(coordinator.rebuildCount, 1)
    }

    func testRequestsGoThroughTheNewlySelectedProvider() {
        let settings = SettingsStore(defaults: defaults)
        var providers: [DataProviderType: RecordingProvider] = [:]
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in
            let provider = RecordingProvider(type: type, result: self.makeResult())
            providers[type] = provider
            return provider
        }
        defer { coordinator.stop() }

        coordinator.requestData(parameters: Parameters())

        XCTAssertEqual(providers[.rpc]?.requestCount, 1)

        settings.set("http", for: .dataSource)
        coordinator.requestData(parameters: Parameters())

        XCTAssertEqual(providers[.rpc]?.requestCount, 1)
        XCTAssertEqual(providers[.http]?.requestCount, 1)
    }

    func testSwitchingTheSourceClearsCachedResultsSoAFreshRequestIsMade() {
        let settings = SettingsStore(defaults: defaults)
        var providers: [DataProviderType: RecordingProvider] = [:]
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in
            let provider = RecordingProvider(type: type, result: self.makeResult())
            providers[type] = provider
            return provider
        }
        defer { coordinator.stop() }

        coordinator.requestData(parameters: Parameters())
        XCTAssertEqual(providers[.rpc]?.requestCount, 1)

        // Without a cache clear the second request would be served from cache.
        settings.set("http", for: .dataSource)
        coordinator.requestData(parameters: Parameters())

        XCTAssertEqual(providers[.http]?.requestCount, 1)
    }

    func testCapabilitiesFollowTheActiveProvider() {
        let settings = SettingsStore(defaults: defaults)
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ -> DataProvider in
            if type == .http {
                return BlitzortungHttpDataProvider(endpoint: "http://example.com",
                                                   transport: StubTransport(),
                                                   credentialStore: InMemoryCredentialStore())
            }
            return JsonRpcDataProvider(serviceEndpoint: "http://example.com")
        }
        defer { coordinator.stop() }

        XCTAssertEqual(coordinator.capabilities, DataProviderCapabilities(supportsGrid: true, supportsClusters: true))

        settings.set("http", for: .dataSource)

        XCTAssertEqual(coordinator.capabilities, DataProviderCapabilities(supportsGrid: false, supportsClusters: false))
    }

    func testEventsSurviveARebuild() async {
        let settings = SettingsStore(defaults: defaults)
        let coordinator = DataProviderCoordinator(settings: settings) { type, _ in
            return RecordingProvider(type: type, result: self.makeResult())
        }
        defer { coordinator.stop() }

        var events: [DataEvent] = []
        let stream = coordinator.events()
        let task = Task {
            for await event in stream { events.append(event) }
        }

        coordinator.requestData(parameters: Parameters())
        await waitUntil { events.count >= 1 }

        settings.set("http", for: .dataSource)
        coordinator.requestData(parameters: Parameters(intervalOffset: 30))
        await waitUntil { events.count >= 2 }

        task.cancel()

        XCTAssertGreaterThanOrEqual(events.count, 2)
    }

    private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
