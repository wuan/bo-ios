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

/// The JSON-RPC backend serves global and local grid data through separate
/// methods. Sending a global or local region to the generic named-region method
/// does not fail: the backend clamps the region into its named range, so a global
/// request silently becomes a named region (Europe). The app never sends a named
/// region on this source, so these tests pin the method the provider dispatches
/// to for each region kind and the fallback for an unexpected one.
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

    func testUnexpectedRegionFallsBackToTheGlobalMethod() {
        let request = JsonRpcDataProvider.gridRequest(
            for: Parameters(region: 3,
                            rasterBaselength: 10000,
                            intervalDuration: 60,
                            intervalOffset: 0))

        XCTAssertEqual(request.method, "get_global_strikes_grid",
                       "the named method is unreachable, so a named region falls back to global")
        XCTAssertEqual(request.arguments,
                       [60, 10000, 0, JsonRpcDataProvider.countThresholdArgument])
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

    /// A world-spanning response numbers its cells from the origin, so column
    /// 10 / row 30 is at 10.5, -30.5 and column -45 / row -20 at -44.5, 19.5.
    /// The corner anchor would have decoded them to 169.5, 59.5 and 134.5,
    /// 109.5 instead.
    func testGlobalResponseDecodesItsCellsFromTheOrigin() async throws {
        StubURLProtocol.responseBody = Data(Self.globalResponse.utf8)
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())

        let result = try await fetchResult(from: provider,
                                           parameters: Parameters(region: Parameters.globalRegion,
                                                                  rasterBaselength: 100000))

        let grid = try XCTUnwrap(result.rasterParameters)
        XCTAssertTrue(grid.isGlobal)
        XCTAssertEqual(result.strikes.count, 2)

        XCTAssertEqual(result.strikes[0].location.longitude, 10.5, accuracy: 0.0001)
        XCTAssertEqual(result.strikes[0].location.latitude, -30.5, accuracy: 0.0001)
        XCTAssertEqual(result.strikes[1].location.longitude, -44.5, accuracy: 0.0001)
        XCTAssertEqual(result.strikes[1].location.latitude, 19.5, accuracy: 0.0001)
    }

    private static let globalResponse = #"""
    {"id":1,"result":{"x0":-180.0,"xd":1.0,"xc":360,"y1":90.0,"yd":1.0,"yc":180,"t":"20160101T12:00:00","r":[[10,30,5,-120],[-45,-20,1,-60]]}}
    """#

    /// Fetches once and returns the parsed result, failing on a provider error.
    private func fetchResult(from provider: JsonRpcDataProvider,
                             parameters: Parameters) async throws -> Result {
        return try await withCheckedThrowingContinuation { continuation in
            provider.fetchData(parameters: parameters) { result, error in
                if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: error ?? StrikeDataParserError.missingResult)
                }
            }
        }
    }

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
