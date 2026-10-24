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

final class StrikeLogParserTests: XCTestCase {

    private let parser = StrikeLogParser()

    func testParsesValidLine() throws {
        let strike = try XCTUnwrap(parser.parse(line: Fixtures.strikeLogLine()))

        XCTAssertEqual(strike.timestamp, Fixtures.strikeLogTimestamp0615)
        XCTAssertEqual(strike.multiplicity, 1)
        XCTAssertEqual(strike.location.latitude, 37.714012, accuracy: 0.000001)
        XCTAssertEqual(strike.location.longitude, 26.801138, accuracy: 0.000001)
    }

    func testParsesAndroidFixtureLine() throws {
        let line = "2019-02-13 06:07:24.748241830 pos;37.714012;26.801138;0 str;0 dev;7013 "
            + "sta;18;85;1903,2326,2325,1870"

        let strike = try XCTUnwrap(parser.parse(line: line))

        XCTAssertEqual(strike.timestamp, 1_550_038_044)
        XCTAssertEqual(strike.multiplicity, 1)
        XCTAssertEqual(strike.location.latitude, 37.714012, accuracy: 0.000001)
        XCTAssertEqual(strike.location.longitude, 26.801138, accuracy: 0.000001)
    }

    func testSkipsMalformedLinesWithoutFailingTheBatch() {
        let log = Fixtures.strikeLog([
            Fixtures.strikeLogLine(),
            Fixtures.malformedStrikeLogLine,
            Fixtures.positionlessStrikeLogLine,
            "",
            Fixtures.strikeLogLine(time: "06:25:00.000000000", latitude: 10.0, longitude: 20.0),
        ])

        let strikes = parser.parse(contents: log)

        XCTAssertEqual(strikes.count, 2)
        XCTAssertEqual(strikes[0].timestamp, Fixtures.strikeLogTimestamp0615)
        XCTAssertEqual(strikes[1].timestamp, Fixtures.strikeLogTimestamp0625)
    }

    func testMalformedLinesReturnNil() {
        XCTAssertNil(parser.parse(line: Fixtures.malformedStrikeLogLine))
        XCTAssertNil(parser.parse(line: Fixtures.positionlessStrikeLogLine))
        XCTAssertNil(parser.parse(line: "2019-02-13 06:15:00.000000000"))
        XCTAssertNil(parser.parse(line: ""))
    }
}
