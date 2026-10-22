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

import CoreLocation
import MapKit
import XCTest
@testable import monitor

/// Pins what the map draws for the displayed activity: tiles, counts, strikes,
/// the base-map wash, and what is left out.
final class ActivityRenderPlanTests: XCTestCase {

    private let referenceTime = 1_700_000_000

    /// A scale that draws a one degree cell at roughly 45 points.
    private let zoomScale = MKZoomScale(45.0 / 745654.0)

    private func activity(tiles: [MapActivity.Tile] = [],
                          points: [MapActivity.Point] = [],
                          intervalDuration: Int = 60,
                          scheme: ColorScheme = .blitzortung,
                          baseType: MapBaseType = .satellite,
                          fadeAlpha: Int = 0) -> MapActivity {
        return MapActivity(tiles: tiles,
                           points: points,
                           referenceTimestamp: referenceTime,
                           intervalDuration: intervalDuration,
                           colorHandler: ColorHandler(scheme: scheme, baseType: baseType),
                           fadeAlpha: fadeAlpha)
    }

    private func tile(center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 50, longitude: 10),
                      delta: Double = 1.0,
                      count: Int = 1,
                      age: Int = 0) -> MapActivity.Tile {
        return MapActivity.Tile(center: center,
                                longitudeDelta: delta,
                                latitudeDelta: delta,
                                count: count,
                                timestamp: referenceTime - age)
    }

    /// A viewport around central Europe, where the fixtures put their activity.
    private var viewport: MKMapRect {
        let center = MKMapPoint(CLLocationCoordinate2D(latitude: 50, longitude: 10))
        return MKMapRect(x: center.x - 2500000,
                         y: center.y - 2500000,
                         width: 5000000,
                         height: 5000000)
    }

    private func plan(_ activity: MapActivity, visible: MKMapRect? = nil) -> ActivityRenderPlan {
        return ActivityRenderPlan.make(activity: activity,
                                       zoomScale: zoomScale,
                                       visibleMapRect: visible ?? viewport)
    }

    // MARK: - Coverage

    func testCoveringRectIsLargerThanTheVisibleArea() {
        let visible = MKMapRect(x: 100, y: 200, width: 1000, height: 2000)
        let covered = ActivityRenderPlan.coveringRect(for: visible)

        XCTAssertEqual(covered.midX, visible.midX, accuracy: 0.001)
        XCTAssertEqual(covered.midY, visible.midY, accuracy: 0.001)
        XCTAssertGreaterThan(covered.width, visible.width)
        XCTAssertGreaterThan(covered.height, visible.height)
        XCTAssertTrue(covered.contains(visible))
    }

    // MARK: - Tiles

    func testVisibleTileIsFilledWithTheNewestColour() {
        let renderPlan = plan(activity(tiles: [tile()]))

        XCTAssertEqual(renderPlan.tileFills.count, 1)
        XCTAssertEqual(renderPlan.tileFills.first?.color, ColorScheme.blitzortung.strikeColors[0])
    }

    func testOlderTileUsesAnOlderColourSection() {
        // A 60 minute interval over six colours is ten minutes per section.
        let renderPlan = plan(activity(tiles: [tile(age: 45 * 60)]))

        XCTAssertEqual(renderPlan.tileFills.first?.color, ColorScheme.blitzortung.strikeColors[4])
    }

    func testTileOutsideTheVisibleAreaIsNotFilled() {
        let farAway = tile(center: CLLocationCoordinate2D(latitude: -40, longitude: 120))
        let renderPlan = plan(activity(tiles: [farAway]))

        XCTAssertTrue(renderPlan.tileFills.isEmpty)
        XCTAssertTrue(renderPlan.countLabels.isEmpty)
    }

    func testSmallTileIsDrawnAtTheMinimumSize() {
        let renderPlan = plan(activity(tiles: [tile(delta: 0.00001)]))
        guard let drawn = renderPlan.tileFills.first?.mapRect else {
            return XCTFail("expected the tiny cell to be filled")
        }

        XCTAssertEqual(drawn.width, Double(TileGeometry.minimumSize(zoomScale: zoomScale)), accuracy: 1)
    }

    func testSmallTileIsDrawnFullyOpaque() {
        guard let fill = plan(activity(tiles: [tile(delta: 0.14)])).tileFills.first else {
            return XCTFail("expected the cell to be filled")
        }

        XCTAssertEqual(fill.alpha, 1.0, accuracy: 0.001)
    }

    func testLargerTileIsDrawnLighter() {
        guard let smaller = plan(activity(tiles: [tile(delta: 0.4)])).tileFills.first,
              let larger = plan(activity(tiles: [tile(delta: 1.0)])).tileFills.first else {
            return XCTFail("expected both cells to be filled")
        }

        XCTAssertLessThan(larger.alpha, smaller.alpha)
        XCTAssertEqual(larger.alpha,
                       Double(ActivityRenderPlan.tileAlphaBounds.minAlpha) / 255.0,
                       accuracy: 0.0001,
                       "a cell past the ramp keeps the minimum opacity")
    }

    // MARK: - Counts

    func testSmallTileHasNoCountLabel() {
        let renderPlan = plan(activity(tiles: [tile(delta: 0.14, count: 3)]))

        XCTAssertTrue(renderPlan.countLabels.isEmpty, "a tile this small cannot show a count")
    }

    func testLargeTileShowsItsCount() {
        let renderPlan = plan(activity(tiles: [tile(delta: 4.0, count: 12)]))

        XCTAssertEqual(renderPlan.countLabels.count, 1)
        XCTAssertEqual(renderPlan.countLabels.first?.text, "12")
        XCTAssertEqual(renderPlan.countLabels.first?.coordinate.latitude, 50)
        XCTAssertEqual(renderPlan.countLabels.first?.textColor, ColorScheme.blitzortung.textColor(for: .satellite))
    }

    func testCountTextGrowsWithTheTile() {
        let small = plan(activity(tiles: [tile(delta: 1.0, count: 2)])).countLabels.first
        let large = plan(activity(tiles: [tile(delta: 4.0, count: 2)])).countLabels.first

        XCTAssertNotNil(small)
        XCTAssertNotNil(large)
        XCTAssertGreaterThan(large?.textSize ?? 0, small?.textSize ?? 0)
    }

    func testCountLabelColourFollowsTheBaseMap() {
        let renderPlan = plan(activity(tiles: [tile(delta: 4.0)], baseType: .streetMap))

        XCTAssertEqual(renderPlan.countLabels.first?.textColor, ColorScheme.blitzortung.textColor(for: .streetMap))
    }

    // MARK: - Strikes

    func testVisibleStrikeBecomesAMark() {
        let renderPlan = plan(activity(points: [MapActivity.Point(
            coordinate: CLLocationCoordinate2D(latitude: 50, longitude: 10),
            count: 1,
            timestamp: referenceTime)]))

        XCTAssertEqual(renderPlan.strikeMarks.count, 1)
        XCTAssertEqual(renderPlan.strikeMarks.first?.size, StrikeMarker.size(zoomScale: zoomScale))
        XCTAssertEqual(renderPlan.strikeMarks.first?.color, ColorScheme.blitzortung.strikeColors[0])
    }

    func testStrikeOutsideTheVisibleAreaIsNotMarked() {
        let renderPlan = plan(activity(points: [MapActivity.Point(
            coordinate: CLLocationCoordinate2D(latitude: -40, longitude: 120),
            count: 1,
            timestamp: referenceTime)]))

        XCTAssertTrue(renderPlan.strikeMarks.isEmpty)
    }

    // MARK: - Base-map wash

    func testNoDimWhenTheFadeSettingIsZero() {
        XCTAssertNil(plan(activity(tiles: [tile()], fadeAlpha: 0)).baseMapDim)
    }

    func testDimCoversTheWholeMapWithTheConfiguredOpacity() {
        let dim = plan(activity(tiles: [tile()], fadeAlpha: 140)).baseMapDim

        XCTAssertEqual(dim?.alpha ?? 0, 140.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(dim?.color, ColorHandler(baseType: .satellite).baseMapDimColor)
        XCTAssertEqual(dim?.mapRect.origin.x ?? 0, MKMapRect.world.origin.x)
        XCTAssertEqual(dim?.mapRect.origin.y ?? 0, MKMapRect.world.origin.y)
        XCTAssertEqual(dim?.mapRect.size.width ?? 0, MKMapRect.world.size.width)
        XCTAssertEqual(dim?.mapRect.size.height ?? 0, MKMapRect.world.size.height)
    }

    /// The wash is drawn over the whole map, so no zoom level can show a part of
    /// the map that it does not cover.
    func testDimCoversTheVisibleAreaAtEveryZoomLevel() {
        for width in [1_000.0, 1_000_000.0, 200_000_000.0] {
            let visible = MKMapRect(x: MKMapRect.world.midX - width / 2,
                                    y: MKMapRect.world.midY - width / 2,
                                    width: width,
                                    height: width)
            let dim = ActivityRenderPlan.make(activity: activity(tiles: [tile()], fadeAlpha: 140),
                                              zoomScale: 1,
                                              visibleMapRect: visible).baseMapDim

            XCTAssertNotNil(dim)
            XCTAssertTrue(dim?.mapRect.contains(visible) ?? false,
                          "the wash does not cover a \(width) point wide view")
        }
    }

    func testDimColourFollowsTheBaseMap() {
        let dim = plan(activity(tiles: [tile()], baseType: .streetMap, fadeAlpha: 140)).baseMapDim

        XCTAssertEqual(dim?.color, ColorHandler(baseType: .streetMap).baseMapDimColor)
    }

    func testSchemeChangeChangesThePlannedColours() {
        let blitzortung = plan(activity(tiles: [tile()], scheme: .blitzortung)).tileFills.first?.color
        let rainbow = plan(activity(tiles: [tile()], scheme: .rainbow)).tileFills.first?.color

        XCTAssertEqual(blitzortung, ColorScheme.blitzortung.strikeColors[0])
        XCTAssertEqual(rainbow, ColorScheme.rainbow.strikeColors[0])
        XCTAssertNotEqual(blitzortung, rainbow)
    }
}
