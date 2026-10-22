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

final class CountThresholdTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testZeroThresholdLeavesParametersUnchanged() {
        XCTAssertEqual(Parameters().withCountThreshold(0), Parameters())
    }

    func testNegativeThresholdIsInactive() {
        XCTAssertEqual(Parameters(countThreshold: 5).withCountThreshold(-1).countThreshold, 0)
    }

    func testNonZeroThresholdIsCarried() {
        XCTAssertEqual(Parameters().withCountThreshold(3).countThreshold, 3)
    }

    func testNonZeroThresholdAppearsInTheIssuedRequest() async throws {
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())
        let parameters = Parameters(region: 1,
                                    rasterBaselength: 10000,
                                    intervalDuration: 60,
                                    intervalOffset: 0,
                                    countThreshold: 3)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: parameters) { _, _ in
                continuation.resume()
            }
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        let body = try XCTUnwrap(Self.body(of: request))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let values = try XCTUnwrap(json["params"] as? [Any])

        XCTAssertEqual(values.count, 5)
        XCTAssertEqual(values.last as? Int, 3)
    }

    func testZeroThresholdAppearsAsZeroInTheIssuedRequest() async throws {
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())
        let parameters = Parameters(region: 1).withCountThreshold(0)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: parameters) { _, _ in
                continuation.resume()
            }
        }

        let request = try XCTUnwrap(StubURLProtocol.capturedRequests.last)
        let body = try XCTUnwrap(Self.body(of: request))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let values = try XCTUnwrap(json["params"] as? [Any])

        XCTAssertEqual(values.last as? Int, 0)
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
