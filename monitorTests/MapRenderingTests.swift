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

/// Provider that returns a preset result.
private final class StubGridProvider: DataProvider {
    var result: Result?

    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        completion(result, nil)
    }
}

@MainActor
final class MapRenderingTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "MapRenderingTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeGrid() -> GridParameters {
        return GridParameters(longitudeStart: -10.0,
                              longitudeDelta: 1.0,
                              longitudeCount: 20,
                              latitudeStart: 55.0,
                              latitudeDelta: 1.0,
                              latitudeCount: 20)
    }

    private func makeResult(strikes: [Strike], rasterParameters: GridParameters?) -> Result {
        return Result(parameters: Parameters(),
                      referenceTimestamp: 1_700_000_000,
                      strikes: strikes,
                      rasterParameters: rasterParameters)
    }

    private func buildController(settings: SettingsStore? = nil) -> ViewController {
        let provider = StubGridProvider()
        provider.result = nil
        let handler = DataHandler(provider: provider)
        let controller = ViewController(dataSource: handler,
                                        settings: settings ?? SettingsStore(defaults: defaults))
        controller.loadViewIfNeeded()
        // Pin the viewport so the plan's culling is deterministic in tests.
        controller.mapView.frame = CGRect(x: 0, y: 0, width: 400, height: 700)
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50, longitude: 10),
                                                        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)),
                                     animated: false)
        return controller
    }

    private func makeTile(atLongitude longitude: Double, count: Int) -> Strike {
        return Strike(timestamp: 1_700_000_000,
                      andMultiplicity: count,
                      andX: longitude,
                      andY: 50.0,
                      andWidth: 1.0,
                      andHeight: 1.0)
    }

    private func tilePolygons(in controller: ViewController) -> [ActivityTilePolygon] {
        return controller.mapView.overlays.compactMap { $0 as? ActivityTilePolygon }
    }

    private func dimPolygons(in controller: ViewController) -> [ActivityDimPolygon] {
        return controller.mapView.overlays.compactMap { $0 as? ActivityDimPolygon }
    }

    private func countAnnotations(in controller: ViewController) -> [ActivityCountAnnotation] {
        return controller.mapView.annotations.compactMap { $0 as? ActivityCountAnnotation }
    }

    private func shownPopupCount(in controller: ViewController) -> Int {
        return controller.mapView.annotations.filter { $0 is ActivitySelectionAnnotation }.count
    }

    // MARK: - 2.1 Drawing the displayed activity with MapKit's renderers

    func testRendersOnePolygonPerVisibleCell() {
        let controller = buildController()
        let strikes = [makeTile(atLongitude: 8.0, count: 3), makeTile(atLongitude: 12.0, count: 5)]

        controller.render(result: makeResult(strikes: strikes, rasterParameters: makeGrid()))

        XCTAssertEqual(tilePolygons(in: controller).count, 2)
    }

    func testCellOutsideTheViewportIsNotDrawn() {
        let controller = buildController()
        let farAway = makeTile(atLongitude: 140.0, count: 1)

        controller.render(result: makeResult(strikes: [farAway], rasterParameters: makeGrid()))

        XCTAssertTrue(tilePolygons(in: controller).isEmpty)
    }

    func testSecondResultReplacesTheFirst() {
        let controller = buildController()

        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 9.0, count: 1)],
                                             rasterParameters: makeGrid()))
        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 11.0, count: 9)],
                                             rasterParameters: makeGrid()))

        let fills = tilePolygons(in: controller)
        XCTAssertEqual(fills.count, 1, "the previous activity must not linger")
        XCTAssertEqual(fills.first?.pointCount, 4)
    }

    func testPointStrikesBecomePolygonMarkers() {
        let controller = buildController()
        let point = Strike(timestamp: 1_700_000_000, andMultiplicity: 1, andX: 10.0, andY: 50.0)

        controller.render(result: makeResult(strikes: [point], rasterParameters: nil))

        let marks = controller.mapView.overlays.compactMap { $0 as? ActivityStrikePolygon }
        XCTAssertEqual(marks.count, 1)
        XCTAssertEqual(marks.first?.pointCount, 12, "a point strike is drawn as a plus")
        XCTAssertTrue(tilePolygons(in: controller).isEmpty)
    }

    func testDataAreaIsStillDrawn() {
        let controller = buildController()

        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 10.0, count: 1)],
                                             rasterParameters: makeGrid()))

        let plainPolygons = controller.mapView.overlays.filter {
            !($0 is ActivityTilePolygon) && !($0 is ActivityStrikePolygon) && !($0 is ActivityDimPolygon)
        }
        XCTAssertEqual(plainPolygons.count, 1, "the data area outline keeps its own overlay")
    }

    func testCellsOfDifferentAgesRenderDifferentColours() throws {
        let controller = buildController()
        // The fixture's cells sit between 55N and 36N, astride 10E.
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 45, longitude: 0),
                                                        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)),
                                     animated: false)
        let response = Fixtures.decode(Fixtures.completeResponseJSON)
        let result = try StrikeDataParser().parse(response: response, parameters: Parameters())

        controller.render(result: result)

        // The cells are 0 s, 2 min, and 50 min old: with the delay in seconds
        // they land in different sections of the palette.
        let fills = tilePolygons(in: controller).map { $0.fillColor }
        XCTAssertGreaterThanOrEqual(fills.count, 2)
        let distinct = Set(fills.map { "\($0.cgColor.components ?? [])" })
        XCTAssertGreaterThan(distinct.count, 1,
                             "cells of different ages must not all take the oldest colour")
    }

    // MARK: - 2.3 Counts

    func testLargeCellShowsACountAnnotation() {
        let controller = buildController()
        let strike = Strike(timestamp: 1_700_000_000,
                            andMultiplicity: 7,
                            andX: 10.0,
                            andY: 50.0,
                            andWidth: 3.0,
                            andHeight: 3.0)

        controller.render(result: makeResult(strikes: [strike], rasterParameters: makeGrid()))

        XCTAssertEqual(countAnnotations(in: controller).count, 1)
        XCTAssertEqual(countAnnotations(in: controller).first?.text, "7")
    }

    func testSmallCellIsDrawnWithoutACount() {
        let controller = buildController()
        let strike = Strike(timestamp: 1_700_000_000,
                            andMultiplicity: 7,
                            andX: 10.0,
                            andY: 50.0,
                            andWidth: 0.02,
                            andHeight: 0.02)

        controller.render(result: makeResult(strikes: [strike], rasterParameters: makeGrid()))

        XCTAssertEqual(tilePolygons(in: controller).count, 1)
        XCTAssertTrue(countAnnotations(in: controller).isEmpty)
    }

    func testRedrawingReplacesCountAnnotations() {
        let controller = buildController()
        let strike = Strike(timestamp: 1_700_000_000,
                            andMultiplicity: 7,
                            andX: 10.0,
                            andY: 50.0,
                            andWidth: 3.0,
                            andHeight: 3.0)

        controller.render(result: makeResult(strikes: [strike], rasterParameters: makeGrid()))
        controller.drawActivity()

        XCTAssertEqual(countAnnotations(in: controller).count, 1)
    }

    // MARK: - 2.6 Base-map dim

    func testDimFollowsTheFadeSetting() {
        let store = SettingsStore(defaults: defaults)
        let controller = buildController(settings: store)
        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 10.0, count: 1)],
                                             rasterParameters: makeGrid()))

        XCTAssertEqual(dimPolygons(in: controller).count, 1)
        XCTAssertEqual(dimPolygons(in: controller).first?.fillColor.cgColor.alpha ?? 0,
                       CGFloat(140) / 255.0,
                       accuracy: 0.01)

        store.set(0, for: .mapFade)
        XCTAssertTrue(dimPolygons(in: controller).isEmpty)
    }

    // MARK: - 3.2 Details popup

    func testPresentingASelectionShowsOnePopupAndDismissalRemovesIt() {
        let controller = buildController()

        controller.present(.tile(tileModel(count: 4)))
        XCTAssertEqual(shownPopupCount(in: controller), 1)

        controller.dismissSelection()
        XCTAssertEqual(shownPopupCount(in: controller), 0)
    }

    func testPresentingASecondSelectionLeavesOnePopup() {
        let controller = buildController()

        controller.present(.tile(tileModel(count: 4)))
        controller.dismissSelection()
        controller.present(.strike(strikeModel()))

        XCTAssertEqual(shownPopupCount(in: controller), 1)
        XCTAssertEqual(controller.mapView.annotations.compactMap { $0 as? ActivitySelectionAnnotation }
            .first?.coordinate.latitude, 51)
    }

    func testTappingWhereNoActivityIsRenderedShowsNoPopup() {
        let controller = buildController()
        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 10.0, count: 2)],
                                             rasterParameters: makeGrid()))
        let farAway = CLLocationCoordinate2D(latitude: -40, longitude: 120)

        XCTAssertNil(controller.selection(at: MKMapPoint(farAway)),
                     "a tap where nothing is drawn must not resolve to activity")
        XCTAssertEqual(shownPopupCount(in: controller), 0)
    }

    func testTappingActivityResolvesToIt() {
        let controller = buildController()
        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 10.0, count: 2)],
                                             rasterParameters: makeGrid()))

        guard case .tile(let selected)? = controller.selection(at: MKMapPoint(CLLocationCoordinate2D(latitude: 50,
                                                                                                        longitude: 10))) else {
            return XCTFail("expected the tapped cell")
        }
        XCTAssertEqual(selected.count, 2)
    }

    func testRenderingAgainClearsAShownPopup() {
        let controller = buildController()
        controller.present(.tile(tileModel(count: 4)))

        controller.render(result: makeResult(strikes: [], rasterParameters: nil))

        XCTAssertEqual(shownPopupCount(in: controller), 0)
    }

    private func tileModel(count: Int) -> MapActivity.Tile {
        return MapActivity.Tile(center: CLLocationCoordinate2D(latitude: 50, longitude: 0),
                                longitudeDelta: 1.0,
                                latitudeDelta: 1.0,
                                count: count,
                                timestamp: 1_700_000_000)
    }

    private func strikeModel() -> MapActivity.Point {
        return MapActivity.Point(coordinate: CLLocationCoordinate2D(latitude: 51, longitude: 1),
                                 count: 1,
                                 timestamp: 1_700_000_100)
    }

    // MARK: - 4.1 to 4.3 Settings wiring

    func testColorSchemeSettingSelectsThePalette() {
        let store = SettingsStore(defaults: defaults)
        let controller = buildController(settings: store)

        XCTAssertEqual(controller.colorHandler.scheme, .blitzortung)

        store.set(ColorScheme.rainbow.rawValue, for: .colorScheme)

        XCTAssertEqual(controller.colorHandler.scheme, .rainbow)
    }

    func testChangingTheSchemeRedrawsWithTheNewPalette() {
        let store = SettingsStore(defaults: defaults)
        let controller = buildController(settings: store)
        controller.render(result: makeResult(strikes: [makeTile(atLongitude: 10.0, count: 3)],
                                             rasterParameters: makeGrid()))

        store.set(ColorScheme.temperature.rawValue, for: .colorScheme)

        XCTAssertEqual(controller.activityColorHandler.scheme, .temperature)
        guard let components = tilePolygons(in: controller).first?.fillColor.cgColor.components,
              components.count >= 3 else {
            return XCTFail("expected the cell fill colour")
        }
        let expected = ColorScheme.temperature.strikeColors[0]
        XCTAssertEqual(components[0], CGFloat((expected & 0xff0000) >> 16) / 255.0, accuracy: 0.005)
        XCTAssertEqual(components[1], CGFloat((expected & 0x00ff00) >> 8) / 255.0, accuracy: 0.005)
        XCTAssertEqual(components[2], CGFloat(expected & 0x0000ff) / 255.0, accuracy: 0.005)
    }

    func testFadeSettingDrivesTheBaseMapDim() {
        let store = SettingsStore(defaults: defaults)
        let controller = buildController(settings: store)

        // The stored default of 55 percent is 140 of 255.
        XCTAssertEqual(controller.baseMapDimAlpha, 140)

        store.set(90, for: .mapFade)
        XCTAssertEqual(controller.baseMapDimAlpha, 230)

        store.set(0, for: .mapFade)
        XCTAssertEqual(controller.baseMapDimAlpha, 0)
    }

    func testMapModeSettingDrivesTheMapTypeAndBaseColors() {
        let store = SettingsStore(defaults: defaults)
        let controller = buildController(settings: store)

        XCTAssertEqual(controller.mapView.mapType, .hybrid)
        XCTAssertEqual(controller.colorHandler.baseType, .satellite)

        store.set("standard", for: .mapMode)
        XCTAssertEqual(controller.mapView.mapType, .standard)
        XCTAssertEqual(controller.colorHandler.baseType, .streetMap)

        store.set("satellite", for: .mapMode)
        XCTAssertEqual(controller.mapView.mapType, .satellite)
        XCTAssertEqual(controller.colorHandler.baseType, .satellite)
    }

    func testMapModeNamesMapToMapTypes() {
        XCTAssertEqual(ViewController.mapType(for: "hybrid"), .hybrid)
        XCTAssertEqual(ViewController.mapType(for: "satellite"), .satellite)
        XCTAssertEqual(ViewController.mapType(for: "standard"), .standard)
        XCTAssertEqual(ViewController.mapType(for: "HYBRID"), .hybrid)
        XCTAssertEqual(ViewController.mapType(for: "something-else"), .hybrid)
    }
}
