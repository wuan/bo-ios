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

final class HistogramParsingTests: XCTestCase {

    /// A grid response that carries a strike-rate histogram for the period.
    private let responseWithHistogram = """
    {"id":1,"result":{"x0":-10.0,"xd":1.0,"xc":20,"y1":55.0,"yd":1.0,"yc":20,"t":"20160101T12:00:00","r":[[0,0,1,0]],"h":[0,1,4,9]}}
    """

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        StubURLProtocol.responseBody = Data("{}".utf8)
    }

    override func tearDown() {
        StubURLProtocol.reset()
        StubURLProtocol.responseBody = Data("{}".utf8)
        super.tearDown()
    }

    func testHistogramIsParsedWithGridResults() throws {
        let parser = StrikeDataParser()

        let result = try parser.parse(result: Fixtures.decode(responseWithHistogram)["result"] as! [String: AnyObject],
                                      parameters: Parameters())

        XCTAssertEqual(result.histogram, [0, 1, 4, 9])
    }

    func testResultWithoutAHistogramIsEmptyRatherThanFailing() throws {
        let parser = StrikeDataParser()

        let result = try parser.parse(result: Fixtures.decode(Fixtures.completeResponseJSON)["result"] as! [String: AnyObject],
                                      parameters: Parameters())

        XCTAssertNil(result.histogram)
        XCTAssertEqual(result.strikes.count, 3, "the rest of the result still parses")
    }

    func testAHistogramIsAlreadyEmptyRatherThanFailing() throws {
        let parser = StrikeDataParser()
        let json = """
        {"id":1,"result":{"x0":-10.0,"xd":1.0,"xc":20,"y1":55.0,"yd":1.0,"yc":20,"t":"20160101T12:00:00","r":[],"h":[]}}
        """

        let result = try parser.parse(result: Fixtures.decode(json)["result"] as! [String: AnyObject],
                                      parameters: Parameters())

        XCTAssertEqual(result.histogram, [])
    }

    func testNoSeparateRequestIsIssuedForTheHistogram() async throws {
        StubURLProtocol.responseBody = Data(responseWithHistogram.utf8)
        let provider = JsonRpcDataProvider(serviceEndpoint: "http://example.com",
                                           session: makeStubbedSession())

        var received: Result?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: Parameters()) { result, _ in
                received = result
                continuation.resume()
            }
        }

        XCTAssertEqual(StubURLProtocol.capturedRequests.count, 1, "the histogram must ride along with the grid request")
        XCTAssertEqual(try XCTUnwrap(received).histogram, [0, 1, 4, 9])
    }

    // MARK: - Non-grid source

    func testNonGridResultReportsNoHistogramAndStillRenders() async throws {
        let provider = BlitzortungHttpDataProvider(endpoint: "http://example.com",
                                                   transport: StubTransport())

        var received: Result?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            provider.fetchData(parameters: Parameters(region: 1)) { result, _ in
                received = result
                continuation.resume()
            }
        }

        let result = try XCTUnwrap(received)
        XCTAssertNil(result.histogram)
        XCTAssertNotNil(result.referenceTimestamp)
    }
}
