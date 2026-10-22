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

final class GridGatingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    private final class CapturingProvider: DataProvider {
        let capabilities: DataProviderCapabilities
        private(set) var received: [Parameters] = []

        init(capabilities: DataProviderCapabilities) {
            self.capabilities = capabilities
        }

        func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
            received.append(parameters)
            completion(nil, nil)
        }
    }

    private let gridCapable = DataProviderCapabilities(supportsGrid: true, supportsClusters: true)
    private let nonGrid = DataProviderCapabilities(supportsGrid: false, supportsClusters: false)

    func testNonGridSourceCarriesNoGridSize() {
        let parameters = Parameters(rasterBaselength: 5000)

        let gated = parameters.gatingGrid(on: nonGrid)

        XCTAssertEqual(gated.rasterBaselength, 0)
        XCTAssertFalse(gated.isRaster())
    }

    func testGridSourceKeepsTheGridSize() {
        let parameters = Parameters(rasterBaselength: 5000)

        XCTAssertEqual(parameters.gatingGrid(on: gridCapable), parameters)
    }

    func testNonGridSourceIssuesNoGridRequest() {
        let provider = CapturingProvider(capabilities: nonGrid)
        let parameters = Parameters(rasterBaselength: 5000).gatingGrid(on: provider.capabilities)

        provider.fetchData(parameters: parameters) { _, _ in }

        XCTAssertEqual(provider.received.map { $0.rasterBaselength }, [0])
    }

    func testGridCapableSourceIssuesTheGridSize() {
        let provider = CapturingProvider(capabilities: gridCapable)
        let parameters = Parameters(rasterBaselength: 5000).gatingGrid(on: provider.capabilities)

        provider.fetchData(parameters: parameters) { _, _ in }

        XCTAssertEqual(provider.received.map { $0.rasterBaselength }, [5000])
    }

    /// The threshold is no longer a parameter, but the provider's method is
    /// positional and still expects the argument last.
    func testGridRequestCarriesTheThresholdArgumentInItsPosition() async throws {
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: Parameters(region: 1)) { _, _ in
                continuation.resume()
            }
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        let body = try XCTUnwrap(Self.body(of: request))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let values = try XCTUnwrap(json["params"] as? [Any])

        XCTAssertEqual(values.count, 5)
        XCTAssertEqual(values.last as? Int, JsonRpcDataProvider.countThresholdArgument)
    }

    /// A request captured by `URLProtocol` exposes its body as a stream, not as
    /// `httpBody`, so read whichever is present.
    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }
}
