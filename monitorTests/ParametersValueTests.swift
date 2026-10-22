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

final class ParametersValueTests: XCTestCase {

    func testEqualParameterSetsCompareEqual() {
        let first = Parameters(region: 1, rasterBaselength: 10000, intervalDuration: 60, intervalOffset: 0)
        let second = Parameters(region: 1, rasterBaselength: 10000, intervalDuration: 60, intervalOffset: 0)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.hashValue, second.hashValue)
    }

    func testDifferentParameterSetsAreNotEqual() {
        XCTAssertNotEqual(Parameters(intervalOffset: 0), Parameters(intervalOffset: 30))
        XCTAssertNotEqual(Parameters(region: 1), Parameters(region: 0))
    }

    func testParametersCanKeyACollection() {
        var cache: [Parameters: String] = [:]
        cache[Parameters(region: 1)] = "rpc"
        cache[Parameters(region: 0)] = "global"

        XCTAssertEqual(cache[Parameters(region: 1)], "rpc")
        XCTAssertEqual(cache[Parameters(region: 0)], "global")
        XCTAssertNil(cache[Parameters(region: 2)])
    }

    func testDerivedBehaviourIsPreserved() {
        XCTAssertTrue(Parameters(intervalOffset: 0).isRealtime())
        XCTAssertFalse(Parameters(intervalOffset: 30).isRealtime())
        XCTAssertTrue(Parameters(rasterBaselength: 10000).isRaster())
        XCTAssertFalse(Parameters(rasterBaselength: 0).isRaster())
    }

    func testCopyingIsIndependent() {
        let original = Parameters()
        let copy = original

        XCTAssertEqual(copy, original)
    }
}
