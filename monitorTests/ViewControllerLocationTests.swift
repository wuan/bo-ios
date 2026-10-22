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

@MainActor
final class ViewControllerLocationTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var source: ManualLocationSource!
    private var controller: ViewController!

    override func setUp() {
        super.setUp()
        suiteName = "ViewControllerLocationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        source = ManualLocationSource(settings: settings)

        let provider = RecordingLocationProvider()
        controller = ViewController(dataSource: DataHandler(provider: provider),
                                    settings: settings,
                                    credentialStore: InMemoryCredentialStore(),
                                    locationSource: source)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        controller.pollingTimer?.invalidate()
    }

    override func tearDown() {
        controller = nil
        source = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Setting the location by long press

    func testGestureCoordinateMappingMatchesTheMapCentre() {
        let centre = CGPoint(x: controller.mapView.bounds.midX,
                             y: controller.mapView.bounds.midY)

        let mapped = controller.location(for: centre)

        XCTAssertEqual(mapped.latitude, controller.mapView.centerCoordinate.latitude, accuracy: 1e-6)
        XCTAssertEqual(mapped.longitude, controller.mapView.centerCoordinate.longitude, accuracy: 1e-6)
    }

    func testSettingByPointReachesTheLocationSource() throws {
        let centre = CGPoint(x: controller.mapView.bounds.midX,
                             y: controller.mapView.bounds.midY)

        controller.setLocation(at: centre)

        let location = try XCTUnwrap(source.location)
        XCTAssertEqual(location.latitude,
                       controller.mapView.centerCoordinate.latitude,
                       accuracy: 1e-6)
    }

    func testSettingByPointReplacesAPreviousLocation() {
        let centre = CGPoint(x: controller.mapView.bounds.midX,
                             y: controller.mapView.bounds.midY)
        controller.setLocation(at: centre)
        let first = try? XCTUnwrap(source.location)

        controller.setLocation(at: CGPoint(x: controller.mapView.bounds.maxX - 1,
                                           y: controller.mapView.bounds.maxY - 1))

        XCTAssertNotEqual(source.location, first)
    }

    // MARK: - Own-location marker

    func testNoMarkerWithoutALocation() {
        XCTAssertNil(controller.ownLocationMarker)
        XCTAssertTrue(controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }.isEmpty)
    }

    func testMarkerContentMatchesTheLocation() throws {
        let location = Location(latitude: 48.5, longitude: 9.25)

        source.setLocation(location)

        let marker = try XCTUnwrap(controller.ownLocationMarker)
        XCTAssertEqual(marker.location, location)
        XCTAssertEqual(marker.diameter, OwnLocationMarker.defaultDiameter)

        let annotations = controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }
        XCTAssertEqual(annotations.count, 1)
        let annotation = try XCTUnwrap(annotations.first)
        XCTAssertEqual(annotation.coordinate.latitude, location.latitude, accuracy: 1e-9)
        XCTAssertEqual(annotation.coordinate.longitude, location.longitude, accuracy: 1e-9)
    }

    func testMarkerFollowsALocationChange() throws {
        source.setLocation(Location(latitude: 10, longitude: 20))
        source.setLocation(Location(latitude: -30, longitude: 140))

        let annotations = controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }
        XCTAssertEqual(annotations.count, 1, "the marker must be moved rather than duplicated")
        XCTAssertEqual(try XCTUnwrap(annotations.first).coordinate.latitude, -30, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(annotations.first).coordinate.longitude, 140, accuracy: 1e-9)
    }

    // MARK: - Centering

    func testCenteringMovesTheMapToTheLocation() {
        let location = Location(latitude: 12.5, longitude: 77.25)
        source.setLocation(location)

        controller.centerOnLocation(animated: false)

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, location.latitude, accuracy: 1e-6)
        XCTAssertEqual(controller.mapView.centerCoordinate.longitude, location.longitude, accuracy: 1e-6)
    }

    func testCenteringLeavesTheMapUnchangedWithoutALocation() {
        let before = controller.mapView.centerCoordinate

        controller.centerOnLocation(animated: false)

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, before.latitude, accuracy: 1e-9)
        XCTAssertEqual(controller.mapView.centerCoordinate.longitude, before.longitude, accuracy: 1e-9)
    }
}

/// Provider that never returns data; these tests exercise the map, not the data.
private final class RecordingLocationProvider: DataProvider {
    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        completion(nil, nil)
    }
}
