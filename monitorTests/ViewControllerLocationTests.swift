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

import MapKit
import XCTest
@testable import monitor

@MainActor
final class ViewControllerLocationTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var source: ManualLocationSource!
    private var manager: StubLocationManager!
    private var controller: ViewController!

    override func setUp() {
        super.setUp()
        suiteName = "ViewControllerLocationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        source = ManualLocationSource(settings: settings)
        manager = StubLocationManager()

        let provider = RecordingLocationProvider()
        controller = ViewController(dataSource: DataHandler(provider: provider),
                                    settings: settings,
                                    credentialStore: InMemoryCredentialStore(),
                                    locationSource: source,
                                    locationSourceFactory: LocationSourceFactory(managerFactory: { [manager] in
                                        manager!
                                    }))
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        controller.pollingTimer?.invalidate()
    }

    override func tearDown() {
        controller = nil
        manager = nil
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

    // MARK: - Own-location display settings

    func testMarkerIsHeldBackWhileOwnLocationDisplayIsOff() throws {
        source.setLocation(Location(latitude: 48.5, longitude: 9.25))
        XCTAssertNotNil(controller.ownLocationMarker)

        settings.set(false, for: .showOwnLocation)

        XCTAssertNil(controller.ownLocationMarker)
        XCTAssertTrue(controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }.isEmpty)
    }

    func testMarkerAppearsAgainWhenOwnLocationDisplayIsSwitchedOn() throws {
        source.setLocation(Location(latitude: 48.5, longitude: 9.25))
        settings.set(false, for: .showOwnLocation)

        settings.set(true, for: .showOwnLocation)

        let annotations = controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }
        XCTAssertEqual(annotations.count, 1)
    }

    func testTheSizeSettingDrivesTheDrawnMarker() throws {
        source.setLocation(Location(latitude: 48.5, longitude: 9.25))
        let annotation = try XCTUnwrap(controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }.first)
        let view = try XCTUnwrap(controller.mapView(controller.mapView, viewFor: annotation) as? OwnLocationAnnotationView)
        XCTAssertEqual(view.bounds.width, OwnLocationMarker.defaultDiameter, accuracy: 0.001)

        settings.set(200, for: .ownLocationSize)

        // The content the marker is drawn from carries the chosen size...
        let marker = try XCTUnwrap(controller.ownLocationMarker)
        XCTAssertEqual(marker.diameter, OwnLocationMarker.defaultDiameter * 2, accuracy: 0.001)
        // ...and the view the map builds for it draws that size.
        let refreshed = try XCTUnwrap(controller.mapView(controller.mapView, viewFor: annotation) as? OwnLocationAnnotationView)
        XCTAssertEqual(refreshed.bounds.width, OwnLocationMarker.defaultDiameter * 2, accuracy: 0.001,
                       "the drawn marker must be refreshed at the chosen size")
    }

    // MARK: - Marker content

    func testTheMarkerIsHiddenWhileDisplayIsOffAndTheLocationIsKnown() {
        XCTAssertNil(OwnLocationMarker.make(location: Location(latitude: 1, longitude: 2), visible: false))
        XCTAssertNil(OwnLocationMarker.make(location: nil, visible: true))
        XCTAssertNotNil(OwnLocationMarker.make(location: Location(latitude: 1, longitude: 2), visible: true))
    }

    func testTheSizePercentageScalesTheDefaultDiameter() {
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 100), OwnLocationMarker.defaultDiameter)
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 200), OwnLocationMarker.defaultDiameter * 2)
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 50), OwnLocationMarker.defaultDiameter / 2)
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 400), OwnLocationMarker.defaultDiameter * 4)
    }

    func testASizeOutsideTheRangeIsClamped() {
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 0), OwnLocationMarker.diameter(percent: OwnLocationMarker.minimumSizePercent))
        XCTAssertEqual(OwnLocationMarker.diameter(percent: 10_000), OwnLocationMarker.diameter(percent: OwnLocationMarker.maximumSizePercent))
    }

    // MARK: - Centring with keep-zoom

    func testTheCentringSpanCoversTheRadarRange() {
        let span = ViewController.span(aroundRadiusKilometres: ViewController.centerRadiusKilometres,
                                       latitude: 0)

        let expected = 2 * ViewController.centerRadiusKilometres / ViewController.kilometresPerDegree
        XCTAssertEqual(span.latitudeDelta, expected, accuracy: 1e-9)
        XCTAssertEqual(span.longitudeDelta, expected, accuracy: 1e-9, "a degree of longitude is the same at the equator")
    }

    func testTheCentringSpanWidensWithTheLatitude() {
        let equator = ViewController.span(aroundRadiusKilometres: 500, latitude: 0)
        let north = ViewController.span(aroundRadiusKilometres: 500, latitude: 60)

        XCTAssertEqual(north.longitudeDelta, equator.longitudeDelta / cos(60 * .pi / 180), accuracy: 1e-9)
    }

    func testCenteringKeepsTheZoomWhenItIsOn() {
        let location = Location(latitude: 12.5, longitude: 77.25)
        source.setLocation(location)
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                       span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)),
                                     animated: false)
        // The visible map rect is the zoom scale the map is showing; the span
        // alone changes with the centre's latitude, the rect does not.
        let rectBefore = controller.mapView.visibleMapRect
        settings.set(true, for: .keepZoomOnCenter)

        controller.centerOnLocation(animated: false)

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, location.latitude, accuracy: 1e-3)
        XCTAssertEqual(controller.mapView.centerCoordinate.longitude, location.longitude, accuracy: 1e-3)
        XCTAssertEqual(controller.mapView.visibleMapRect.size.width, rectBefore.size.width,
                       accuracy: rectBefore.size.width * 0.05, "the radar's range must not be applied")
        XCTAssertEqual(controller.mapView.visibleMapRect.size.height, rectBefore.size.height,
                       accuracy: rectBefore.size.height * 0.05, "the radar's range must not be applied")
    }

    func testCenteringAppliesTheRadarRangeWhenKeepZoomIsOff() {
        let location = Location(latitude: 12.5, longitude: 77.25)
        source.setLocation(location)
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                       span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)),
                                     animated: false)
        settings.set(false, for: .keepZoomOnCenter)
        let expected = ViewController.span(aroundRadiusKilometres: ViewController.centerRadiusKilometres,
                                           latitude: location.latitude)

        controller.centerOnLocation(animated: false)

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, location.latitude, accuracy: 1e-3)
        XCTAssertEqual(controller.mapView.region.span.longitudeDelta, expected.longitudeDelta, accuracy: 0.5,
                       "the map must zoom out to the radar's range")
        XCTAssertGreaterThan(controller.mapView.region.span.longitudeDelta, 8,
                             "500 km either side is about 9 degrees")
    }

    // MARK: - The mode selects the source

    func testTheStoredModeSelectsTheSourceAtLaunch() {
        settings.set(LocationMode.gps.rawValue, for: .locationMode)

        let controller = ViewController(dataSource: DataHandler(provider: RecordingLocationProvider()),
                                        settings: settings,
                                        credentialStore: InMemoryCredentialStore(),
                                        locationSourceFactory: LocationSourceFactory(managerFactory: { [manager] in
                                            manager!
                                        }))
        controller.loadViewIfNeeded()
        controller.pollingTimer?.invalidate()

        let device = controller.locationSource as? DeviceLocationSource
        XCTAssertEqual(device?.mode, .gps)
        XCTAssertGreaterThanOrEqual(manager.startedUpdates, 1,
                                    "the stored device mode must start asking the device for positions")
    }

    func testAChangedModeReplacesTheSource() {
        XCTAssertTrue(controller.locationSource is ManualLocationSource)

        settings.set(LocationMode.network.rawValue, for: .locationMode)

        XCTAssertTrue(controller.locationSource is DeviceLocationSource)
    }

    func testTheReplacedSourceNoLongerDeliversUpdates() {
        source.setLocation(Location(latitude: 1, longitude: 2))
        XCTAssertNotNil(controller.ownLocationMarker)

        settings.set(LocationMode.gps.rawValue, for: .locationMode)
        XCTAssertNil(controller.ownLocationMarker, "a device source starts without a position")

        source.setLocation(Location(latitude: 3, longitude: 4))

        XCTAssertNil(controller.ownLocationMarker, "the replaced source must be silent")
    }

    func testADevicePositionReachesTheMarker() {
        settings.set(LocationMode.passive.rawValue, for: .locationMode)

        manager.report(Location(latitude: 10, longitude: 20))

        XCTAssertEqual(controller.ownLocationMarker?.location, Location(latitude: 10, longitude: 20))
        let annotations = controller.mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }
        XCTAssertEqual(annotations.count, 1)
        XCTAssertEqual(annotations.first?.coordinate.latitude ?? 0, 10, accuracy: 1e-9)
    }

    func testSwitchingBackToManualAdoptsTheStoredCoordinates() {
        let manual = Location(latitude: 48.5, longitude: 9.25)
        source.setLocation(manual)
        settings.set(LocationMode.gps.rawValue, for: .locationMode)

        settings.set(LocationMode.manual.rawValue, for: .locationMode)

        XCTAssertTrue(controller.locationSource is ManualLocationSource)
        XCTAssertEqual(controller.ownLocationMarker?.location, manual,
                       "the position the user picked must come back")
    }

    func testALongPressSetsNothingInADeviceMode() {
        settings.set(LocationMode.gps.rawValue, for: .locationMode)
        let centre = CGPoint(x: controller.mapView.bounds.midX, y: controller.mapView.bounds.midY)

        controller.setLocation(at: centre)

        XCTAssertNil(controller.ownLocationMarker)
    }
}

/// Provider that never returns data; these tests exercise the map, not the data.
private final class RecordingLocationProvider: DataProvider {
    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        completion(nil, nil)
    }
}
