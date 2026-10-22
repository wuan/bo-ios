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

/// Stub provider that returns a preset result or error.
private final class StubProvider: DataProvider {
    var result: Result?
    var error: Error?
    private(set) var requestCount = 0

    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        requestCount += 1
        completion(result, error)
    }
}

private struct StubError: Error {}

final class DataHandlerTests: XCTestCase {

    private let parameters = Parameters()

    private func makeResult() -> Result {
        return Result(parameters: Parameters(), referenceTimestamp: 100, strikes: [], rasterParameters: nil)
    }

    func testSuccessfulRequestEmitsStartedThenReceived() async {
        let provider = StubProvider()
        provider.result = makeResult()
        let handler = DataHandler(provider: provider)

        var events: [DataEvent] = []
        let stream = handler.events()
        let task = Task {
            for await event in stream { events.append(event) }
        }

        handler.requestData(parameters: parameters)
        await waitUntil { events.count >= 2 }
        task.cancel()

        XCTAssertEqual(events.count, 2)
        guard case .requestStarted = events[0] else { return XCTFail("Expected requestStarted, got \(events[0])") }
        guard case .dataReceived = events[1] else { return XCTFail("Expected dataReceived, got \(events[1])") }
        XCTAssertEqual(provider.requestCount, 1)
    }

    func testFailedRequestEmitsStartedThenFailed() async {
        let provider = StubProvider()
        provider.error = StubError()
        let handler = DataHandler(provider: provider)

        var events: [DataEvent] = []
        let stream = handler.events()
        let task = Task {
            for await event in stream { events.append(event) }
        }

        handler.requestData(parameters: parameters)
        await waitUntil { events.count >= 2 }
        task.cancel()

        XCTAssertEqual(events.count, 2)
        guard case .failed = events[1] else { return XCTFail("Expected failed, got \(events[1])") }
        XCTAssertNil(handler.latest)
    }

    func testRetainsPriorDataAfterFailure() async {
        let provider = StubProvider()
        provider.result = makeResult()
        let handler = DataHandler(provider: provider)

        handler.requestData(parameters: parameters)
        await waitUntil { handler.latest != nil }
        XCTAssertNotNil(handler.latest)

        provider.result = nil
        provider.error = StubError()
        handler.requestData(parameters: parameters)

        XCTAssertNotNil(handler.latest)
    }

    func testCancellingSubscriptionEndsDelivery() async {
        let provider = StubProvider()
        provider.result = makeResult()
        let handler = DataHandler(provider: provider)

        let stream = handler.events()
        let task = Task { () -> Int in
            var count = 0
            for await _ in stream { count += 1 }
            return count
        }

        handler.requestData(parameters: parameters)
        await waitUntil { handler.latest != nil }
        task.cancel()
        let delivered = await task.value
        XCTAssertGreaterThanOrEqual(delivered, 1)
    }

    /// Polls the main queue until `condition` is true or a short timeout elapses.
    private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
