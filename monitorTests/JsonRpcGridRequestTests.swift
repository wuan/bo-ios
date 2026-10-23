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

/// The JSON-RPC backend serves global, local, and named-region grid data through
/// separate methods. Sending a global or local region to the named-region method
/// does not fail: the backend clamps the region into its named range, so a global
/// request silently becomes a named region (Europe). These tests pin the method
/// the provider dispatches to for each region kind.
final class JsonRpcGridRequestTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Method selection

    func testGlobalRegionUsesTheGlobalMethod() {
        let request = JsonRpcDataProvider.gridRequest(
            for: Parameters(region: Parameters.globalRegion,
                            rasterBaselength: 100000,
                            intervalDuration: 60,
                            intervalOffset: 0))

        XCTAssertEqual(request.method, "get_global_strikes_grid")
        XCTAssertEqual(request.arguments,
                       [60, 100000, 0, JsonRpcDataProvider.countThresholdArgument])
    }

    func testLocalRegionUsesTheLocalMethodWithItsDataArea() {
        let area = DataArea(x: -3, y: 9, scale: 10)
        let request = JsonRpcDataProvider.gridRequest(
            for: Parameters(region: Parameters.localRegion,
                            rasterBaselength: 5000,
                            intervalDuration: 30,
                            intervalOffset: -60,
                            dataArea: area))

        XCTAssertEqual(request.method, "get_local_strikes_grid")
        XCTAssertEqual(request.arguments,
                       [-3, 9, 5000, 30, -60, JsonRpcDataProvider.countThresholdArgument, 10])
    }

    func testLocalRegionWithoutADataAreaFallsBackToTheGlobalMethod() {
        let request = JsonRpcDataProvider.gridRequest(
            for: Parameters(region: Parameters.localRegion, rasterBaselength: 5000))

        XCTAssertEqual(request.method, "get_global_strikes_grid")
    }

    func testNamedRegionUsesTheGenericMethodWithItsRegion() {
        let request = JsonRpcDataProvider.gridRequest(
            for: Parameters(region: 3,
                            rasterBaselength: 10000,
                            intervalDuration: 60,
                            intervalOffset: 0))

        XCTAssertEqual(request.method, "get_strikes_grid")
        XCTAssertEqual(request.arguments,
                       [60, 10000, 0, 3, JsonRpcDataProvider.countThresholdArgument])
    }

    // MARK: - Wire format

    func testGlobalRequestCarriesTheGlobalMethodAndArity() async throws {
        StubURLProtocol.responseBody = Data(Self.globalResponse.utf8)
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: Parameters(region: Parameters.globalRegion,
                                                      rasterBaselength: 100000)) { _, _ in
                continuation.resume()
            }
        }

        let json = try capturedRequestJSON()
        XCTAssertEqual(json["method"] as? String, "get_global_strikes_grid")
        XCTAssertEqual((json["params"] as? [Any])?.count, 4)
    }

    private static let globalResponse = #"""
    {"id":1,"result":{"x0":-180.0,"xd":1.0,"xc":360,"y1":90.0,"yd":1.0,"yc":180,"t":"20160101T12:00:00","r":[]}}
    """#

    private func capturedRequestJSON() throws -> [String: Any] {
        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        let body = try XCTUnwrap(Self.body(of: request))
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
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
