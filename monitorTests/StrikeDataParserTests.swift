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

final class StrikeDataParserTests: XCTestCase {

    private let parser = StrikeDataParser()
    private let parameters = Parameters()

    func testParsesReferenceTimestampAndStrikes() throws {
        let response = Fixtures.decode(Fixtures.completeResponseJSON)

        let result = try parser.parse(response: response, parameters: parameters)

        XCTAssertEqual(result.referenceTimestamp, Fixtures.referenceTimestamp)
        XCTAssertEqual(result.strikes.count, 3)
        XCTAssertNotNil(result.rasterParameters)

        let first = result.strikes[0]
        XCTAssertEqual(first.multiplicity, 1)
        XCTAssertEqual(first.timestamp, Fixtures.referenceTimestamp)

        let third = result.strikes[2]
        XCTAssertEqual(third.multiplicity, 2)
        // The delay is in seconds, subtracted from the reference time.
        XCTAssertEqual(third.timestamp, Fixtures.referenceTimestamp - 3_000)
        // The cell is offset 19 of 20 in a grid spanning -10.0...10.0, so it is
        // the last column and its centre is half a cell inside the 10.0 edge.
        XCTAssertEqual(third.location.longitude, 9.5, accuracy: 0.0001)
        XCTAssertEqual(third.location.latitude, 35.5, accuracy: 0.0001)
    }

    func testCellAgeFallsInsideTheRequestedInterval() throws {
        let response = Fixtures.decode(Fixtures.completeResponseJSON)

        let result = try parser.parse(response: response, parameters: parameters)
        let interval = parameters.intervalDuration * 60

        for strike in result.strikes {
            let age = result.referenceTimestamp - strike.timestamp
            XCTAssertGreaterThanOrEqual(age, 0, "a cell cannot be newer than the reference time")
            XCTAssertLessThanOrEqual(age, interval,
                                     "the delay is seconds; scaling it would push every cell past the interval")
        }
    }

    func testParsesResponseWithoutGridParameters() throws {
        let response = Fixtures.decode(Fixtures.responseWithoutGridJSON)

        let result = try parser.parse(response: response, parameters: parameters)

        XCTAssertEqual(result.referenceTimestamp, Fixtures.referenceTimestamp)
        XCTAssertNil(result.rasterParameters)
        XCTAssertTrue(result.strikes.isEmpty)
    }

    func testThrowsForInvalidReferenceTime() {
        let response = Fixtures.decode(Fixtures.responseWithInvalidTimeJSON)

        XCTAssertThrowsError(try parser.parse(response: response, parameters: parameters)) { error in
            guard case StrikeDataParserError.invalidReferenceTime = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testThrowsForMissingResult() {
        let response: [String: AnyObject] = ["id": 1 as AnyObject]
        XCTAssertThrowsError(try parser.parse(response: response, parameters: parameters))
    }
}
