/*

Copyright 2026 Andreas Würl

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

/// Pins the size-to-alpha curve used for tiles and their labels.
final class ShapeAlphaTests: XCTestCase {

    /// The tile ramp from the reference client.
    private func tileAlpha(_ width: Double) -> Int {
        return ShapeAlpha.alpha(value: width, minValue: 10, maxValue: 40, maxAlpha: 255, minAlpha: 100)
    }

    func testSmallSizesTakeTheMaximumAlpha() {
        XCTAssertEqual(tileAlpha(0), 255)
        XCTAssertEqual(tileAlpha(10), 255)
    }

    func testLargeSizesTakeTheMinimumAlpha() {
        XCTAssertEqual(tileAlpha(40), 100)
        XCTAssertEqual(tileAlpha(500), 100)
    }

    func testSizesInBetweenAreInterpolated() {
        XCTAssertEqual(tileAlpha(25), 177)
    }

    func testAlphaDecreasesAsSizeGrows() {
        var previous = tileAlpha(10)
        for size in stride(from: 11.0, through: 40.0, by: 1.0) {
            let alpha = tileAlpha(size)
            XCTAssertLessThanOrEqual(alpha, previous, "alpha rose at size \(size)")
            previous = alpha
        }
    }

    func testAlphaStaysWithinTheConfiguredBounds() {
        for size in stride(from: -100.0, through: 200.0, by: 2.5) {
            let alpha = tileAlpha(size)
            XCTAssertGreaterThanOrEqual(alpha, 100)
            XCTAssertLessThanOrEqual(alpha, 255)
        }
    }

    func testCountLabelRampFromTheReferenceClient() {
        // The label ramp is narrower than the tile ramp and never fully opaque.
        XCTAssertEqual(ShapeAlpha.alpha(value: 20, minValue: 20, maxValue: 80, maxAlpha: 255, minAlpha: 60), 255)
        XCTAssertEqual(ShapeAlpha.alpha(value: 80, minValue: 20, maxValue: 80, maxAlpha: 255, minAlpha: 60), 60)
        XCTAssertEqual(ShapeAlpha.alpha(value: 0, minValue: 20, maxValue: 80, maxAlpha: 255, minAlpha: 60), 255)
    }

    func testDegenerateRangeTakesTheMaximumAlpha() {
        XCTAssertEqual(ShapeAlpha.alpha(value: 12, minValue: 10, maxValue: 10, maxAlpha: 255, minAlpha: 100), 255)
        XCTAssertEqual(ShapeAlpha.alpha(value: 12, minValue: 40, maxValue: 10, maxAlpha: 255, minAlpha: 100), 255)
    }

    func testDrawingAlphaConvertsToAFraction() {
        XCTAssertEqual(ShapeAlpha.drawingAlpha(value: 10,
                                               minValue: 10,
                                               maxValue: 40,
                                               maxAlpha: 255,
                                               minAlpha: 100), 1.0, accuracy: 0.0001)
        XCTAssertEqual(ShapeAlpha.drawingAlpha(value: 40,
                                               minValue: 10,
                                               maxValue: 40,
                                               maxAlpha: 255,
                                               minAlpha: 100), 100.0 / 255.0, accuracy: 0.0001)
    }
}
