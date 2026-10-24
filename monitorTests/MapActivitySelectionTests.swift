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

/// Pins which activity a tap resolves to, and the details shown for it.
final class MapActivitySelectionTests: XCTestCase {

    /// A zoom level of 10 draws a strike marker 22 points wide.
    private let zoomScale = MKZoomScale(pow(2.0, -10.0))

    private func overlay(tiles: [MapActivity.Tile] = [],
                         points: [MapActivity.Point] = []) -> MapActivity {
        return MapActivity(tiles: tiles,
                                  points: points,
                                  referenceTimestamp: 1_700_000_000,
                                  intervalDuration: 60,
                                  colorHandler: ColorHandler())
    }

    private func tile(center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 50, longitude: 0),
                      count: Int = 3) -> MapActivity.Tile {
        return MapActivity.Tile(center: center,
                                       longitudeDelta: 1.0,
                                       latitudeDelta: 1.0,
                                       count: count,
                                       timestamp: 1_700_000_000)
    }

    private func strike(center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 50, longitude: 0))
        -> MapActivity.Point {
        return MapActivity.Point(coordinate: center, count: 1, timestamp: 1_700_000_000)
    }

    /// A distance in map points equivalent to a number of screen points at this zoom.
    private func mapPoint(offsetFrom coordinate: CLLocationCoordinate2D, screenPoints: Double) -> MKMapPoint {
        let origin = MKMapPoint(coordinate)
        let offset = screenPoints / Double(zoomScale)
        return MKMapPoint(x: origin.x + offset, y: origin.y)
    }

    // MARK: - Tiles

    func testTapInsideATileSelectsTheTile() {
        let center = CLLocationCoordinate2D(latitude: 50, longitude: 0)
        let activity = overlay(tiles: [tile(center: center)])

        let selection = activity.selection(at: MKMapPoint(center), zoomScale: zoomScale)

        guard case .tile(let selected)? = selection else {
            return XCTFail("expected a tile selection, got \(String(describing: selection))")
        }
        XCTAssertEqual(selected.count, 3)
    }

    func testTapInsideATileButAwayFromItsCenterSelectsIt() {
        let center = CLLocationCoordinate2D(latitude: 50, longitude: 0)
        let activity = overlay(tiles: [tile(center: center)])
        // A quarter of a degree east is inside a cell one degree wide.
        let near = CLLocationCoordinate2D(latitude: 50.1, longitude: 0.25)

        guard case .tile? = activity.selection(at: MKMapPoint(near), zoomScale: zoomScale) else {
            return XCTFail("a tap inside the cell should select it")
        }
    }

    func testTapOutsideATileSelectsNothing() {
        let activity = overlay(tiles: [tile()])
        let outside = CLLocationCoordinate2D(latitude: 50, longitude: 4)

        XCTAssertNil(activity.selection(at: MKMapPoint(outside), zoomScale: zoomScale))
    }

    // MARK: - Strikes

    func testTapInsideAStrikeSelectsTheStrike() {
        let center = CLLocationCoordinate2D(latitude: 50, longitude: 0)
        let activity = overlay(points: [strike(center: center)])
        // The marker is 22 points wide, so five points away is inside it.
        let near = mapPoint(offsetFrom: center, screenPoints: 5)

        guard case .strike(let selected)? = activity.selection(at: near, zoomScale: zoomScale) else {
            return XCTFail("expected a strike selection")
        }
        XCTAssertEqual(selected.count, 1)
    }

    func testTapOutsideAStrikeSelectsNothing() {
        let center = CLLocationCoordinate2D(latitude: 50, longitude: 0)
        let activity = overlay(points: [strike(center: center)])
        let far = mapPoint(offsetFrom: center, screenPoints: 12)

        XCTAssertNil(activity.selection(at: far, zoomScale: zoomScale))
    }

    func testTapOnEmptyMapSelectsNothing() {
        XCTAssertNil(overlay().selection(at: MKMapPoint(CLLocationCoordinate2D(latitude: 50, longitude: 0)),
                                         zoomScale: zoomScale))
        XCTAssertNil(overlay(tiles: [tile()], points: [strike()])
            .selection(at: MKMapPoint(CLLocationCoordinate2D(latitude: -20, longitude: 100)),
                       zoomScale: zoomScale))
    }

    // MARK: - Details

    func testTileDetailsShowTheTimeAndCount() {
        let selection = MapActivitySelection.tile(tile(count: 7))
        let text = selection.detailsText()

        XCTAssertTrue(text.contains("#7"), "expected the count in \(text)")
        XCTAssertFalse(text.isEmpty)
    }

    func testStrikeDetailsShowTheTimeAndPosition() {
        let selection = MapActivitySelection.strike(strike(center: CLLocationCoordinate2D(latitude: 50.5,
                                                                                           longitude: -3.25)))
        let text = selection.detailsText()

        XCTAssertTrue(text.contains("-3.2500"), "expected the longitude in \(text)")
        XCTAssertTrue(text.contains("50.5000"), "expected the latitude in \(text)")
    }

    func testSelectionCarriesThePopupAnchor() {
        let selection = MapActivitySelection.tile(tile(center: CLLocationCoordinate2D(latitude: 51, longitude: 2)))

        XCTAssertEqual(selection.coordinate.latitude, 51)
        XCTAssertEqual(selection.coordinate.longitude, 2)
        XCTAssertEqual(selection.timestamp, 1_700_000_000)
    }
}
