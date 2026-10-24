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

import MapKit
import XCTest
@testable import monitor

/// Pins the label and marker rules used while drawing activity.
final class MapActivityShapesTests: XCTestCase {

    // MARK: - Tile labels

    func testLabelIsDrawnWhenTheTileIsLargeEnough() {
        let size = TileLabel.textSize(tileHeight: 20)

        XCTAssertNotNil(size)
        XCTAssertEqual(size ?? 0, 8, accuracy: 0.0001)
    }

    func testLabelIsOmittedWhenTheTileIsTooSmall() {
        XCTAssertNil(TileLabel.textSize(tileHeight: 19.9))
        XCTAssertNil(TileLabel.textSize(tileHeight: 0))
    }

    func testLabelSizeGrowsWithTheTile() {
        let small = TileLabel.textSize(tileHeight: 40)
        let large = TileLabel.textSize(tileHeight: 120)

        XCTAssertNotNil(small)
        XCTAssertNotNil(large)
        XCTAssertGreaterThan(large!, small!)
    }

    func testLabelAlphaFadesWithItsSize() {
        XCTAssertEqual(TileLabel.alpha(textSize: 20), 255)
        XCTAssertEqual(TileLabel.alpha(textSize: 80), 60)
        XCTAssertLessThan(TileLabel.alpha(textSize: 60), TileLabel.alpha(textSize: 30))
    }

    func testLabelAlphaStaysWithinItsBounds() {
        for size in stride(from: 8.0, through: 200.0, by: 1.0) {
            let alpha = TileLabel.alpha(textSize: CGFloat(size))
            XCTAssertGreaterThanOrEqual(alpha, 60)
            XCTAssertLessThanOrEqual(alpha, 255)
        }
    }

    // MARK: - Strike markers

    func testMarkerSizeMatchesTheReferenceAtTheSameZoomLevel() {
        // MapKit's zoom scale is 2^(zoomLevel - 20), and the reference draws a
        // marker 2 * (zoomLevel + 1) points wide.
        XCTAssertEqual(StrikeMarker.size(zoomScale: MKZoomScale(pow(2.0, -10.0))), 22, accuracy: 0.0001)
        XCTAssertEqual(StrikeMarker.size(zoomScale: MKZoomScale(pow(2.0, -5.0))), 32, accuracy: 0.0001)
    }

    func testMarkerGrowsAsTheMapIsZoomedIn() {
        let zoomedOut = StrikeMarker.size(zoomScale: MKZoomScale(pow(2.0, -12.0)))
        let zoomedIn = StrikeMarker.size(zoomScale: MKZoomScale(pow(2.0, -2.0)))

        XCTAssertGreaterThan(zoomedIn, zoomedOut)
    }

    func testMarkerNeverShrinksBelowItsMinimum() {
        XCTAssertGreaterThanOrEqual(StrikeMarker.size(zoomScale: MKZoomScale(0)), StrikeMarker.minimumSize)
        XCTAssertGreaterThanOrEqual(StrikeMarker.size(zoomScale: MKZoomScale(pow(2.0, -40.0))),
                                    StrikeMarker.minimumSize)
    }
}
