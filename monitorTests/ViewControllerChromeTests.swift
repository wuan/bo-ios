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
final class ViewControllerChromeTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var source: ManualLocationSource!
    private var manager: StubLocationManager!
    private var provider: ChromeRecordingProvider!
    private var controller: ViewController!
    private var signaller: StubAlertSignaller!
    private var notifier: StubAlertNotifier!

    private let referenceTime = 1_500_000_000
    private let grid = GridParameters(longitudeStart: 0,
                                     longitudeDelta: 1,
                                     longitudeCount: 20,
                                     latitudeStart: 60,
                                     latitudeDelta: 1,
                                     latitudeCount: 20)

    override func setUp() {
        super.setUp()
        suiteName = "ViewControllerChromeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        source = ManualLocationSource(settings: settings)
        manager = StubLocationManager()
        provider = ChromeRecordingProvider()
        signaller = StubAlertSignaller()
        notifier = StubAlertNotifier()

        controller = ViewController(dataSource: DataHandler(provider: provider),
                                    settings: settings,
                                    credentialStore: InMemoryCredentialStore(),
                                    locationSource: source,
                                    locationSourceFactory: LocationSourceFactory(managerFactory: { [manager] in
                                        manager!
                                    }),
                                    alertSignaller: signaller,
                                    alertNotifier: notifier)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        controller.pollingTimer?.invalidate()
    }

    override func tearDown() {
        controller = nil
        provider = nil
        manager = nil
        source = nil
        signaller = nil
        notifier = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    /// Lets MapKit finish an animated region change before it is read back.
    private func settleMap(_ seconds: TimeInterval = 1.0) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// A realtime grid result with one strike near the grid's centre.
    private func result(histogram: [Int]? = [0, 1, 4, 9]) -> Result {
        let strike = Strike(timestamp: referenceTime,
                            andMultiplicity: 1,
                            andX: 10.5,
                            andY: 50.5,
                            andWidth: 1,
                            andHeight: 1)
        return Result(parameters: Parameters(),
                      referenceTimestamp: referenceTime,
                      strikes: [strike],
                      rasterParameters: grid,
                      histogram: histogram)
    }

    // MARK: - Presentation (8.1)

    func testAResultRefreshesEveryComponent() {
        XCTAssertNil(controller.overviewContent)

        // A large extent keeps the RPC request global, so the legend has a
        // deterministic region to show. The region change applies on the next
        // run-loop pass, so settle the map before reading it.
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                       span: MKCoordinateSpan(latitudeDelta: 80, longitudeDelta: 160)),
                                     animated: false)
        settleMap()
        controller.mapViewDidChangeVisibleRegion(controller.mapView)

        controller.render(result: result())

        XCTAssertEqual(controller.legendContent?.regionName, "Global")
        XCTAssertEqual(controller.histogramContent?.bars.count, 12, "the bars cover the displayed period")
        XCTAssertEqual(controller.histogramContent?.bars.prefix(4).map { $0.count }, [0, 1, 4, 9])
        XCTAssertEqual(controller.radarContent?.state, .noLocation)
        XCTAssertNotNil(controller.overviewContent)
    }

    func testASettingChangeRefreshesTheLegend() throws {
        controller.render(result: result())
        let before = controller.legendContent

        settings.setChoice(240, for: .intervalDuration)

        XCTAssertNotEqual(controller.legendContent, before)
        XCTAssertEqual(controller.legendContent?.entries.last?.ageText, "> 200 min")
    }

    func testASettingChangeRefreshesTheRadarColours() {
        source.setLocation(Location(latitude: 50.5, longitude: 10.5))
        controller.render(result: result())
        XCTAssertEqual(controller.radarContent?.state, .active)

        settings.setChoice(240, for: .intervalDuration)

        // A longer interval gives the same age a newer colour section.
        XCTAssertEqual(controller.radarContent?.state, .active)
    }

    func testALocationChangeRefreshesTheRadar() {
        controller.render(result: result())
        XCTAssertEqual(controller.radarContent?.state, .noLocation)

        source.setLocation(Location(latitude: 50.5, longitude: 10.5))

        XCTAssertEqual(controller.radarContent?.state, .active)
    }

    func testAPanRefreshesTheOverviewButNotTheLegend() {
        controller.render(result: result())
        let legendBefore = controller.legendContent
        let overviewBefore = controller.overviewContent

        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50, longitude: 10),
                                                       span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)),
                                     animated: false)
        controller.mapViewDidChangeVisibleRegion(controller.mapView)

        XCTAssertNotEqual(controller.overviewContent?.viewport, overviewBefore?.viewport)
        XCTAssertEqual(controller.legendContent, legendBefore)
    }

    // MARK: - Interaction (8.2)

    func testRadarTapCentresTheMapAndLeavesTheRadarIntact() {
        controller.render(result: result())
        source.setLocation(Location(latitude: 49, longitude: 5))
        let radarBefore = controller.radarContent

        controller.radarTapped()

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, 49, accuracy: 1e-3)
        XCTAssertEqual(controller.mapView.centerCoordinate.longitude, 5, accuracy: 1e-3)
        XCTAssertEqual(controller.radarContent, radarBefore, "the radar's state must be left intact")
    }

    func testRadarTapWithoutALocationLeavesTheMapAndRadarAlone() {
        controller.render(result: result())
        let centreBefore = controller.mapView.centerCoordinate
        let radarBefore = controller.radarContent
        XCTAssertEqual(radarBefore?.state, .noLocation)

        controller.radarTapped()

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, centreBefore.latitude, accuracy: 1e-9)
        XCTAssertEqual(controller.mapView.centerCoordinate.longitude, centreBefore.longitude, accuracy: 1e-9)
        XCTAssertEqual(controller.radarContent?.state, .noLocation)
    }

    func testRadarTapKeepsTheZoomWhenTheChoiceIsOn() {
        controller.render(result: result())
        source.setLocation(Location(latitude: 49, longitude: 5))
        settings.set(true, for: .keepZoomOnCenter)
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                       span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)),
                                     animated: false)

        controller.radarTapped()
        settleMap()

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, 49, accuracy: 1e-3)
        XCTAssertEqual(controller.radarContent?.state, .active)
        // The zoom is kept: MapKit refits the span to the new latitude, but the
        // radar's range would show around nine degrees of longitude.
        XCTAssertLessThan(controller.mapView.region.span.longitudeDelta, 2,
                          "the radar's range must not be applied")
    }

    func testRadarTapZoomsToTheRadarRangeWhenTheChoiceIsOff() {
        controller.render(result: result())
        source.setLocation(Location(latitude: 49, longitude: 5))
        settings.set(false, for: .keepZoomOnCenter)
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                       span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)),
                                     animated: false)
        settleMap()
        let rectBefore = controller.mapView.visibleMapRect

        controller.radarTapped()
        settleMap()

        XCTAssertEqual(controller.mapView.centerCoordinate.latitude, 49, accuracy: 1e-3)
        XCTAssertGreaterThan(controller.mapView.visibleMapRect.size.height, rectBefore.size.height * 5,
                             "the map must show the radar's range around the location")
        XCTAssertGreaterThan(controller.mapView.region.span.longitudeDelta, 8,
                             "500 km either side is about 9 degrees")
    }

    /// A device position has to reach the marker and the radar without any
    /// wiring beyond the location source.
    func testADevicePositionReachesTheMarkerAndTheRadar() {
        controller.render(result: result())
        XCTAssertEqual(controller.radarContent?.state, .noLocation)

        settings.set(LocationMode.gps.rawValue, for: .locationMode)
        manager.report(Location(latitude: 50.5, longitude: 10.5))

        XCTAssertEqual(controller.ownLocationMarker?.location, Location(latitude: 50.5, longitude: 10.5))
        XCTAssertEqual(controller.radarContent?.state, .active)
    }

    func testHistogramTapZoomsOutToTheDataArea() {
        controller.render(result: result())

        controller.histogramTapped()

        XCTAssertEqual(controller.mapView.region.center.latitude, 50, accuracy: 0.5)
        XCTAssertEqual(controller.mapView.region.center.longitude, 10, accuracy: 0.5)
        // The map fits the area to its own aspect ratio, so the spans cover it.
        XCTAssertGreaterThanOrEqual(controller.mapView.region.span.latitudeDelta, 19.5)
        XCTAssertGreaterThanOrEqual(controller.mapView.region.span.longitudeDelta, 19.5)
    }

    func testHistogramTapWithoutADataAreaDoesNothing() {
        controller.render(result: Result(parameters: Parameters(),
                                         referenceTimestamp: referenceTime,
                                         strikes: []))
        let before = controller.mapView.region

        controller.histogramTapped()

        XCTAssertEqual(controller.mapView.region.center.latitude, before.center.latitude, accuracy: 1e-9)
    }

    // MARK: - Retired threshold (8.3)

    func testDefaultSettingsIssueTheUnchangedRequest() {
        let parameters = controller.baseParameters()

        XCTAssertEqual(parameters.region, Parameters.globalRegion, "the globe is the default region")
        XCTAssertEqual(parameters.rasterBaselength, 10000, "the default grid baseline is unchanged")
        XCTAssertEqual(parameters.intervalDuration, 60, "the default interval is unchanged")
        XCTAssertEqual(parameters.intervalOffset, 0, "realtime is still the default")
        XCTAssertEqual(JsonRpcDataProvider.countThresholdArgument, 0, "the retired threshold is still sent inactive")
    }

    // MARK: - Region (source-scoped)

    func testAnAutomaticLocalRpcRequestShowsLocalInTheLegend() {
        // A small extent yields a local data area that the RPC source upgrades to.
        controller.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50, longitude: 10),
                                                       span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)),
                                     animated: false)
        controller.mapViewDidChangeVisibleRegion(controller.mapView)

        let parameters = controller.requestCurrentParameters()
        controller.refreshLegend()

        XCTAssertEqual(parameters.region, Parameters.localRegion)
        XCTAssertEqual(controller.legendContent?.regionName, "Local")
        XCTAssertNotNil(controller.legendContent?.localRegionSize,
                        "a local region with a data area shows its size")
    }

    func testAnHttpRequestShowsItsNamedRegionInTheLegend() {
        settings.set(DataProviderType.http.rawValue, for: .dataSource)
        XCTAssertTrue(settings.setChoice(3, for: .region))

        controller.requestCurrentParameters()
        controller.refreshLegend()

        XCTAssertEqual(controller.legendContent?.regionName, "N. America")
        XCTAssertNil(controller.legendContent?.localRegionSize, "a named region has no local size")
    }

    // MARK: - Alerts (5.1, 5.2)

    func testAStrikeInsideTheLimitSignalsAndNotifiesOnce() {
        controller.render(result: result())
        XCTAssertTrue(signaller.signals.isEmpty)

        source.setLocation(Location(latitude: 50.5, longitude: 10.5))

        XCTAssertEqual(signaller.signals.count, 1)
        XCTAssertEqual(notifier.notifications.count, 1)
        XCTAssertTrue(controller.alertState.isActive)

        // The same activity evaluated again must not warn twice.
        controller.applyAlerts()

        XCTAssertEqual(signaller.signals.count, 1)
        XCTAssertEqual(notifier.notifications.count, 1)
    }

    func testTheRadarMarksAnActiveAlertAndClearsItWhenTheActivityLeavesTheRange() {
        controller.render(result: result())
        source.setLocation(Location(latitude: 50.5, longitude: 10.5))
        XCTAssertEqual(controller.radarContent?.alert, true, "a qualifying strike must mark the radar")

        // Far enough away that the strike falls outside the radar's outer ring.
        source.setLocation(Location(latitude: 50.5, longitude: 40.0))

        XCTAssertEqual(controller.radarContent?.alert, false)
        XCTAssertFalse(controller.alertState.isActive)
    }

    func testSwitchingAlertsOffStopsTheSignalsWithoutARelaunch() {
        source.setLocation(Location(latitude: 50.5, longitude: 10.5))
        controller.render(result: result())
        let signalled = signaller.signals.count

        settings.set(false, for: .alertEnabled)
        source.setLocation(Location(latitude: 50.5, longitude: 10.6))

        XCTAssertFalse(controller.alertState.isActive)
        XCTAssertEqual(signaller.signals.count, signalled)
        XCTAssertEqual(controller.radarContent?.alert, false)
    }

    func testAlertsAskForTheNotificationAuthorisationOnceALocationIsKnown() {
        settings.set(false, for: .alertEnabled)
        source.setLocation(Location(latitude: 50.5, longitude: 10.5))

        XCTAssertEqual(notifier.authorizationRequests, 0,
                       "alerts are off, so there is nothing to ask for")

        settings.set(true, for: .alertEnabled)

        XCTAssertEqual(notifier.authorizationRequests, 1)

        // Asked once, however often the location changes afterwards.
        source.setLocation(Location(latitude: 50.5, longitude: 10.6))

        XCTAssertEqual(notifier.authorizationRequests, 1)
    }

    func testAlertsDoNotAskForAuthorisationWithoutALocation() {
        source = ManualLocationSource(settings: settings)
        settings.set(false, for: .alertEnabled)
        settings.set(true, for: .alertEnabled)

        XCTAssertEqual(notifier.authorizationRequests, 0,
                       "a user the app cannot warn must not be asked")
    }

    func testALimitThatNoLongerCoversTheStrikeClearsTheAlert() {
        // Just outside the strike's grid cell, about 14 km away: inside both
        // limits, and outside a tightened one.
        source.setLocation(Location(latitude: 50.5, longitude: 11.2))
        controller.render(result: result())

        XCTAssertEqual(controller.radarContent?.alert, true)
        XCTAssertEqual(signaller.signals.count, 1)
        XCTAssertEqual(notifier.notifications.count, 1)

        settings.set(10.0, for: .notificationDistanceLimit)
        settings.set(10.0, for: .signalingDistanceLimit)

        XCTAssertEqual(controller.radarContent?.alert, false, "the smaller limit no longer covers the strike")
        XCTAssertEqual(signaller.signals.count, 1, "no further signal for the same activity")
        XCTAssertEqual(notifier.notifications.count, 1)
        XCTAssertEqual(settings.notificationDistanceLimit, 10)
    }

    // MARK: - Top status row

    func testTheStatusRowSitsBelowTheTopSafeArea() {
        XCTAssertEqual(controller.statusBar.frame.minY, controller.view.bounds.minY, accuracy: 0.5,
                       "the material must reach the top edge so there is no seam under the cutout")
        let statusTop = controller.view.convert(controller.statusText.bounds, from: controller.statusText).minY
        XCTAssertEqual(statusTop, controller.view.safeAreaInsets.top, accuracy: 0.5,
                       "the status text must clear the status bar / Dynamic Island")
    }

    func testTheMapIsFullBleedToTheTop() {
        XCTAssertEqual(controller.mapView.frame.minY, controller.view.bounds.minY, accuracy: 0.5)
    }

    func testTheStatusBarIsDrawnOverTheMap() {
        let centre = controller.view.convert(CGPoint(x: controller.statusText.bounds.midX,
                                                      y: controller.statusText.bounds.midY),
                                              from: controller.statusText)
        let hit = controller.view.hitTest(centre, with: nil)
        XCTAssertTrue(hit === controller.statusBar || (hit?.isDescendant(of: controller.statusBar) ?? false),
                      "the status row must be in front of the full-bleed map, not behind it")
    }

    func testTheLegendSitsBelowTheStatusRow() {
        let statusBottom = controller.view.convert(controller.statusText.bounds, from: controller.statusText).maxY
        XCTAssertGreaterThan(controller.legendView.frame.minY, statusBottom)
    }

    func testTheSystemStatusBarIsShown() {
        XCTAssertFalse(controller.prefersStatusBarHidden)
    }

    func testTheMapIsFullBleedToTheBottom() {
        XCTAssertEqual(controller.mapView.frame.maxY, controller.view.bounds.maxY, accuracy: 0.5)
    }

    func testTheBottomControlsSitInAMaterialBarOverTheMap() {
        XCTAssertNotNil(controller.modeBar)
        XCTAssertTrue(controller.timeSlider.isDescendant(of: controller.modeBar))
        let centre = controller.view.convert(CGPoint(x: controller.timeSlider.bounds.midX,
                                                      y: controller.timeSlider.bounds.midY),
                                              from: controller.timeSlider)
        let hit = controller.view.hitTest(centre, with: nil)
        XCTAssertTrue(hit === controller.modeBar || (hit?.isDescendant(of: controller.modeBar) ?? false),
                      "the bottom bar must be in front of the full-bleed map, not behind it")
    }

    func testTheRangeLabelsShareTheSliderRow() {
        XCTAssertTrue(controller.rangeStartLabel.superview === controller.timeSlider.superview)
        XCTAssertTrue(controller.rangeEndLabel.superview === controller.timeSlider.superview)
    }

    func testTheBottomControlsAreTwoRows() {
        let sliderRow = controller.timeSlider.superview as? UIStackView
        XCTAssertEqual(sliderRow?.axis, .horizontal)
        XCTAssertEqual(sliderRow?.arrangedSubviews.count, 3, "the range labels flank the slider")

        let controls = sliderRow?.superview as? UIStackView
        XCTAssertEqual(controls?.axis, .vertical)
        XCTAssertEqual(controls?.arrangedSubviews.count, 2, "the compact bar is two rows tall")
    }
}

/// Provider that records the parameters it is asked for.
private final class ChromeRecordingProvider: DataProvider {
    private(set) var received: [Parameters] = []

    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        received.append(parameters)
        completion(nil, nil)
    }
}
