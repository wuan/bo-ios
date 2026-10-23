//
//  monitorUITests.swift
//  monitorUITests
//
//  Created by Andreas Würl on 19.10.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import XCTest

class monitorUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Exercises the minimal data source surface: open it, change the source,
    /// save, reopen, and confirm the selection persisted. Restores JSON-RPC so
    /// later runs start from the documented default.
    func testDataSourceSelectionPersistsAcrossReopening() {
        let app = XCUIApplication()

        let open = app.buttons["settings.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()

        selectSource(app, named: "HTTP")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        let reopen = app.buttons["settings.open"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 10))
        reopen.tap()

        let reopened = app.segmentedControls["settings.source"]
        XCTAssertTrue(reopened.waitForExistence(timeout: 10))
        XCTAssertTrue(reopened.buttons["HTTP"].isSelected)

        // Restore the default source.
        selectSource(app, named: "JSON-RPC")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()
    }

    /// Exercises the 24-hour time slider: the rightmost position activates
    /// realtime, and any other position selects that historical interval. Needs
    /// no backend because the mode indicator changes as soon as the slider moves.
    func testTimeSliderRightmostActivatesRealtime() {
        let app = XCUIApplication()
        app.launch()

        let slider = app.sliders["time.slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 15))

        let indicator = app.staticTexts["mode.indicator"]
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))
        XCTAssertEqual(indicator.label, "Realtime")

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForStatus(status, matching: "[0-9]+/[0-9]+ s"), "status was '\(status.label)'")

        slider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertTrue(waitForLabel(indicator, toEqual: "History"), "mode was '\(indicator.label)'")
        XCTAssertTrue(waitForStatus(status, matching: "@ [0-9]{2}:[0-9]{2}"), "status was '\(status.label)'")

        slider.adjust(toNormalizedSliderPosition: 1.0)
        XCTAssertTrue(waitForLabel(indicator, toEqual: "Realtime"), "mode was '\(indicator.label)'")
        XCTAssertTrue(waitForStatus(status, matching: "[0-9]+/[0-9]+ s"), "status was '\(status.label)'")
    }

    /// LIVE CHECK: requires network access. Selects the JSON-RPC source with no
    /// endpoint override and confirms the app renders a non-zero strike count.
    ///
    /// The backend answers with data only for a `bo-ios-<build>` user agent, so a
    /// rendered strike count also proves the request was identified correctly.
    func testLiveRpcSourceRendersStrikes() throws {
        try requireLiveBackend()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, named: "JSON-RPC")
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// LIVE CHECK: requires network access. Drives the time slider into history,
    /// then starts animation, and confirms each mode selects an interval and
    /// keeps rendering from the live backend (the status line keeps reporting an
    /// interval instead of freezing on the realtime frame).
    func testLiveModesRenderHistoricalAndAnimatedIntervals() throws {
        try requireLiveBackend()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, named: "JSON-RPC")
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertTrue(waitForStatusWithInterval(status, timeout: 90), "status was '\(status.label)'")

        let indicator = app.staticTexts["mode.indicator"]
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))

        let slider = app.sliders["time.slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))

        // History: a non-rightmost position selects a historical interval.
        slider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertTrue(waitForLabel(indicator, toEqual: "History"), "mode was '\(indicator.label)'")
        XCTAssertTrue(waitForStatusWithInterval(status, timeout: 90), "history status was '\(status.label)'")

        // Animation: playback advances and keeps rendering.
        app.buttons["animation.toggle"].tap()
        XCTAssertTrue(waitForLabel(indicator, toEqual: "Animation"), "mode was '\(indicator.label)'")
        XCTAssertTrue(waitForStatusWithInterval(status, timeout: 90), "animation status was '\(status.label)'")

        // Stopping holds the interval; the slider's rightmost position then
        // returns to realtime.
        app.buttons["animation.toggle"].tap()
        XCTAssertTrue(waitForLabel(indicator, toEqual: "History"), "mode was '\(indicator.label)'")
        slider.adjust(toNormalizedSliderPosition: 1.0)
        XCTAssertTrue(waitForLabel(indicator, toEqual: "Realtime"), "mode was '\(indicator.label)'")
    }

    /// LIVE CHECK: requires the stub server in the development notes, listening on
    /// port 8099 and demanding HTTP Basic `test:test` for strike logs. Confirms a
    /// custom endpoint and stored credentials are used by the HTTP source.
    func testLiveHttpSourceUsesCustomEndpointAndCredentials() throws {
        try requireStubServer()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, named: "HTTP")
        replaceText(in: app.textFields["settings.endpoint"], with: "http://127.0.0.1:8099")
        replaceText(in: app.textFields["settings.username"], with: "test")
        replaceText(in: app.secureTextFields["settings.password"], with: "test")

        // Dismiss the keyboard so the buttons below are reachable.
        app.otherElements["settings.root"].tap()

        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// LIVE CHECK: requires the same stub server as the test above. Configures
    /// credentials on the authenticated source, then selects the unauthenticated
    /// JSON-RPC source against a custom endpoint, confirming the saved
    /// credentials neither break it nor are sent to it.
    func testLiveRpcSourceIgnoresStoredCredentials() throws {
        try requireStubServer()

        let app = XCUIApplication()
        app.launch()

        // The JSON-RPC source takes no credentials, so they are entered on the
        // HTTP source, which is the one that authenticates.
        openSettings(app)
        selectSource(app, named: "HTTP")
        replaceText(in: app.textFields["settings.endpoint"], with: "http://127.0.0.1:8099")
        replaceText(in: app.textFields["settings.username"], with: "test")
        replaceText(in: app.secureTextFields["settings.password"], with: "test")
        app.otherElements["settings.root"].tap()
        app.buttons["settings.save"].tap()

        selectSource(app, named: "JSON-RPC")
        XCTAssertFalse(app.textFields["settings.username"].exists,
                       "the JSON-RPC source must not offer a username")
        XCTAssertFalse(app.secureTextFields["settings.password"].exists,
                       "the JSON-RPC source must not offer a password")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// Sets the own location by long-pressing the map, and confirms the drawn
    /// marker moves to each pressed position. Needs no backend: the marker is
    /// drawn from the manual location alone.
    func testLongPressSetsAndMovesTheOwnLocationMarker() {
        let app = XCUIApplication()
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))

        let marker = app.descendants(matching: .any)["own.location"]
        // A run before this one may have left a location, and the marker drawn
        // from it.
        let existing = marker.exists ? marker.value as? String : nil

        // Both presses stay clear of the chrome - the legend sits top-left and
        // the radar, overview, and histogram along the bottom - so the map
        // receives them.
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.35)).press(forDuration: 1.2)
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "no own-location marker after a long press")
        XCTAssertTrue(waitForMarkerValue(of: marker, toDifferFrom: existing),
                      "the marker did not move to the first position: was \(existing ?? "nil"), now \(marker.value ?? "nil")")

        let firstValue = marker.value as? String
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.35)).press(forDuration: 1.2)

        XCTAssertTrue(waitForMarkerValue(of: marker, toDifferFrom: firstValue),
                      "the marker did not move to the second position: was \(firstValue ?? "nil"), now \(marker.value ?? "nil")")
        attachScreenshot("own-location-marker")
    }

    // MARK: - Chrome

    /// Taps the legend and confirms the quick-settings dialog opens with every
    /// entry present.
    func testLegendTapOpensQuickSettingsWithEveryEntry() {
        let app = XCUIApplication()
        app.launch()

        let legend = app.descendants(matching: .any)["legend.view"]
        XCTAssertTrue(legend.waitForExistence(timeout: 15), "the legend is not shown")
        legend.tap()

        XCTAssertTrue(app.otherElements["quick.root"].waitForExistence(timeout: 10),
                      "tapping the legend did not open quick settings")

        for identifier in ["quick.region", "quick.intervalDuration", "quick.historicTimestep",
                           "quick.dataSource", "quick.colorScheme", "quick.mapMode", "quick.fade"] {
            XCTAssertTrue(app.descendants(matching: .any)[identifier].exists, "\(identifier) is missing")
        }
    }

    /// Changes the region in quick settings and confirms the map's legend shows
    /// it after the dialog closes, with the map still up.
    func testQuickSettingAppliesToTheMapWithoutLeavingIt() {
        let app = XCUIApplication()
        app.launch()

        let legend = app.descendants(matching: .any)["legend.view"]
        XCTAssertTrue(legend.waitForExistence(timeout: 15))
        legend.tap()

        let picker = app.pickerWheels.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.adjust(toPickerWheelValue: "Asia")

        app.buttons["quick.close"].tap()

        XCTAssertTrue(waitForValue(of: legend, toContain: "Asia"),
                      "the legend still reads '\(legend.value ?? "")'")
        XCTAssertTrue(app.descendants(matching: .any)["map.view"].exists,
                      "the map must still be there after the dialog closes")

        // Restore the default region for later runs.
        legend.tap()
        let reopened = app.pickerWheels.firstMatch
        XCTAssertTrue(reopened.waitForExistence(timeout: 10))
        reopened.adjust(toPickerWheelValue: "Europe")
        app.buttons["quick.close"].tap()
    }

    /// Long-presses the radar to open the enlarged radar, and dismissing it
    /// leaves the map with the radar unchanged.
    func testRadarLongPressOpensTheEnlargedRadar() {
        let app = XCUIApplication()
        app.launch()

        let radar = app.descendants(matching: .any)["radar.view"]
        XCTAssertTrue(radar.waitForExistence(timeout: 15), "the radar is not shown")
        radar.press(forDuration: 1.2)

        XCTAssertTrue(app.descendants(matching: .any)["radar.enlarged"].waitForExistence(timeout: 10),
                      "the enlarged radar did not open")
        attachScreenshot("enlarged-radar")

        app.buttons["radar.close"].tap()
        XCTAssertTrue(radar.waitForExistence(timeout: 10), "the radar is gone after dismissing the enlarged one")
    }

    /// Taps the radar and confirms the map centres on the own location.
    func testRadarTapCentresTheMapOnTheLocation() {
        let app = XCUIApplication()
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))

        // Set a location well away from the map's centre.
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.8)).press(forDuration: 1.2)

        let marker = app.descendants(matching: .any)["own.location"]
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "no own-location marker after a long press")
        XCTAssertGreaterThan(distance(from: map, to: marker), 60,
                             "the location is too close to the centre to show a move")

        app.descendants(matching: .any)["radar.view"].tap()

        XCTAssertTrue(waitForMarker(marker, near: map), "the map did not centre on the location")
        attachScreenshot("centred-on-location")
    }

    /// LIVE CHECK: requires network access. Taps the histogram and confirms the
    /// map zooms out to the data area, which the overview's zoom level reflects.
    func testHistogramTapZoomsOutToTheDataArea() throws {
        try requireLiveBackend()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, named: "JSON-RPC")
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()
        relaunch(app)

        let histogram = app.descendants(matching: .any)["histogram.view"]
        XCTAssertTrue(histogram.waitForExistence(timeout: 90), "no histogram arrived from the grid result")

        let overview = app.descendants(matching: .any)["overview.view"]
        XCTAssertTrue(overview.waitForExistence(timeout: 30), "no data-area overview")

        let before = overview.value as? String
        histogram.tap()

        XCTAssertTrue(waitForValue(of: overview, toDifferFrom: before),
                      "the map's visible region did not change to the data area")
    }

    /// Changes every quick setting without leaving the map, relaunches once, and
    /// confirms each change survived. Restores the defaults afterwards.
    func testEveryQuickSettingAppliesAndSurvivesARelaunch() {
        let app = XCUIApplication()
        app.launch()

        let legend = app.descendants(matching: .any)["legend.view"]
        XCTAssertTrue(legend.waitForExistence(timeout: 15))
        legend.tap()

        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 10))
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Asia")
        app.segmentedControls["quick.intervalDuration"].buttons.element(boundBy: 3).tap()   // 120 min
        app.segmentedControls["quick.historicTimestep"].buttons.element(boundBy: 2).tap()  // 60 min
        app.segmentedControls["quick.dataSource"].buttons.element(boundBy: 1).tap()        // HTTP
        app.segmentedControls["quick.colorScheme"].buttons.element(boundBy: 1).tap()       // RAINBOW
        app.segmentedControls["quick.mapMode"].buttons.element(boundBy: 2).tap()           // standard
        app.sliders["quick.fade"].adjust(toNormalizedSliderPosition: 0.2)
        let fadeBefore = app.sliders["quick.fade"].value as? String

        app.buttons["quick.close"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["map.view"].exists,
                      "the map must be there after changing every entry")

        relaunch(app)

        XCTAssertTrue(legend.waitForExistence(timeout: 15))
        legend.tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 10))

        XCTAssertEqual(app.pickerWheels.firstMatch.value as? String, "Asia")
        XCTAssertTrue(app.segmentedControls["quick.intervalDuration"].buttons.element(boundBy: 3).isSelected)
        XCTAssertTrue(app.segmentedControls["quick.historicTimestep"].buttons.element(boundBy: 2).isSelected)
        XCTAssertTrue(app.segmentedControls["quick.dataSource"].buttons.element(boundBy: 1).isSelected)
        XCTAssertTrue(app.segmentedControls["quick.colorScheme"].buttons.element(boundBy: 1).isSelected)
        XCTAssertTrue(app.segmentedControls["quick.mapMode"].buttons.element(boundBy: 2).isSelected)
        XCTAssertNotEqual(fadeBefore, "55 %", "the fade did not change")
        XCTAssertEqual(app.sliders["quick.fade"].value as? String, fadeBefore)

        // Restore the documented defaults for later runs.
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Europe")
        app.segmentedControls["quick.intervalDuration"].buttons.element(boundBy: 1).tap()
        app.segmentedControls["quick.historicTimestep"].buttons.element(boundBy: 1).tap()
        app.segmentedControls["quick.dataSource"].buttons.element(boundBy: 0).tap()
        app.segmentedControls["quick.colorScheme"].buttons.element(boundBy: 0).tap()
        app.segmentedControls["quick.mapMode"].buttons.element(boundBy: 0).tap()
        app.sliders["quick.fade"].adjust(toNormalizedSliderPosition: 0.55)
        app.buttons["quick.close"].tap()
    }

    // MARK: - Location modes

    /// LIVE CHECK: needs a simulated device location and network access for the
    /// radar's activity. Selects the GPS mode, captures the permission prompt,
    /// and confirms the device position reaches both the marker and the radar.
    ///
    /// Set the simulated position first:
    /// `xcrun simctl location booted set 50.5,10.5`.
    func testDeviceModePromptsForPermissionAndShowsThePosition() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-locationMode", "gps"]
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))

        // The explanation iOS shows is built from the app's usage description, so
        // it is captured as it appears. A run that already answered it - or one
        // whose permission was reset to granted - goes straight to the marker.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        let sawAlert = alert.waitForExistence(timeout: 5)
        if sawAlert {
            attachScreenshot("location-permission-prompt")
            let allow = alert.buttons["Allow While Using App"]
            if allow.exists {
                allow.tap()
            } else {
                alert.buttons.element(boundBy: 0).tap()
            }
        }

        let marker = app.descendants(matching: .any)["own.location"]
        if !marker.waitForExistence(timeout: 45) {
            try XCTSkipIf(!sawAlert,
                          "the location permission is decided, so neither prompt nor position appears; "
                          + "reset it with `xcrun simctl privacy booted reset location net.wuerl.blitzortung.monitor`")
            XCTFail("the simulated device location did not reach the marker")
        }
        XCTAssertTrue(waitForValue(of: marker, toContain: "50.5", timeout: 20),
                      "the marker is not at the simulated position: '\(marker.value ?? "")'")
        attachScreenshot("device-location-marker")

        // The radar aggregates the position against the displayed data, so it has
        // to leave its no-location state; which state it reaches depends on the
        // activity the backend reports in range.
        let radar = app.descendants(matching: .any)["radar.view"]
        XCTAssertTrue(radar.waitForExistence(timeout: 15))
        XCTAssertTrue(waitForValue(of: radar, toDifferFrom: "No location", timeout: 30),
                      "the device position did not reach the radar: '\(radar.value ?? "")'")
        attachScreenshot("device-location-radar")
    }

    /// A refused permission leaves the app usable: the map keeps rendering and no
    /// marker is drawn, because a device mode has nothing to set by hand.
    ///
    /// The check refuses the system prompt itself; when the permission has
    /// already been decided by an earlier test it skips, because iOS only asks
    /// once. To exercise it on its own:
    /// `xcrun simctl privacy booted revoke location net.wuerl.blitzortung.monitor`.
    func testDeviceModeWithRefusedPermissionKeepsTheAppUsable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-locationMode", "gps"]
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        let marker = app.descendants(matching: .any)["own.location"]
        if alert.waitForExistence(timeout: 5) {
            // The system label uses a typographic apostrophe, so it is matched by
            // prefix; the refusal is the last button either way.
            let deny = alert.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Don")).firstMatch
            if deny.exists {
                deny.tap()
            } else {
                alert.buttons.element(boundBy: alert.buttons.count - 1).tap()
            }
        } else {
            try XCTSkipIf(marker.waitForExistence(timeout: 5),
                          "the location permission is already granted; revoke it to exercise a refusal")
        }

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15), "the app stopped working after a refusal")
        XCTAssertFalse(marker.waitForExistence(timeout: 10),
                       "a refused permission must not produce a position")
        attachScreenshot("refused-permission-still-usable")
    }

    /// Switches own-location display off: a long press sets the position, but no
    /// marker is drawn - before and after a relaunch with the setting in effect.
    func testOwnLocationDisplayOffHidesTheMarker() {
        let app = XCUIApplication()
        app.launchArguments += ["-showOwnLocation", "NO"]
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.35)).press(forDuration: 1.2)

        let marker = app.descendants(matching: .any)["own.location"]
        XCTAssertFalse(marker.waitForExistence(timeout: 10),
                       "the marker must be hidden while own-location display is off")
        attachScreenshot("own-location-hidden")

        relaunch(app)

        XCTAssertTrue(map.waitForExistence(timeout: 15))
        XCTAssertFalse(marker.waitForExistence(timeout: 5),
                       "the marker must stay hidden while own-location display is off")
    }

    /// The size setting scales the drawn marker: 100 percent is the 14 pt base,
    /// 200 percent draws it twice as wide.
    func testOwnLocationSizeScalesTheDrawnMarker() {
        let base = drawnMarkerWidth(launchArguments: [])
        let doubled = drawnMarkerWidth(launchArguments: ["-ownLocationSize", "200"])
        attachScreenshot("own-location-size-200")

        XCTAssertGreaterThan(base, 0, "no marker was drawn at the default size")
        XCTAssertEqual(doubled, base * 2, accuracy: base * 0.2,
                       "the marker was not drawn at twice the default size")
    }

    /// LIVE CHECK: needs the backend for the data-area overview that reports the
    /// zoom level. Zooms the map in, then taps the radar: the mapping either
    /// keeps that zoom or zooms out to the radar's range, as the stored choice
    /// says. The launch zoom is left alone because it is already about the
    /// radar's range, which would make the two choices look the same.
    func testCentringFollowsTheKeepZoomChoice() throws {
        try requireLiveBackend()

        let afterTappingTheRadar = { (keepZoom: Bool) -> (before: Double, after: Double) in
            let app = XCUIApplication()
            app.launchArguments += ["-keepZoomOnCenter", keepZoom ? "YES" : "NO"]
            app.launch()

            let map = app.descendants(matching: .any)["map.view"]
            XCTAssertTrue(map.waitForExistence(timeout: 15))
            map.pinch(withScale: 4, velocity: 4)

            // A location well away from the centre, so centring moves the map.
            map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.35)).press(forDuration: 1.2)
            let marker = app.descendants(matching: .any)["own.location"]
            XCTAssertTrue(marker.waitForExistence(timeout: 10), "no location was set to centre on")

            let overview = app.descendants(matching: .any)["overview.view"]
            XCTAssertTrue(overview.waitForExistence(timeout: 90), "no data-area overview from the backend")

            let zoomBefore = self.zoom(from: overview)

            app.descendants(matching: .any)["radar.view"].tap()

            // Centring is what moves the marker to the middle of the map.
            XCTAssertTrue(self.waitForMarker(marker, near: map, timeout: 20),
                          "the map did not centre on the location")
            // The zoom follows the centre, so let the animation finish.
            usleep(700_000)
            return (zoomBefore, self.zoom(from: overview))
        }

        let kept = afterTappingTheRadar(true)
        attachScreenshot("centred-keep-zoom")
        let zoomedOut = afterTappingTheRadar(false)
        attachScreenshot("centred-radar-range")

        XCTAssertEqual(kept.after, kept.before, accuracy: 1.0,
                       "keep-zoom must leave the zoom alone: was \(kept.before), now \(kept.after)")
        XCTAssertGreaterThan(zoomedOut.before - zoomedOut.after, 1.0,
                            "without keep-zoom the map must zoom out to the radar's range: "
                            + "was \(zoomedOut.before), now \(zoomedOut.after)")
    }

    /// The zoom level the overview reports at the end of its accessibility value,
    /// e.g. 7.0 out of "Zoom 7.0".
    private func zoom(from overview: XCUIElement) -> Double {
        let value = (overview.value as? String) ?? ""
        let parts = value.components(separatedBy: "Zoom ")
        guard parts.count > 1, let text = parts[1].split(separator: " ").first else { return 0 }
        return Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Long-presses the map with a given set of launch-argument settings and
    /// reports the width the drawn marker was given.
    private func drawnMarkerWidth(launchArguments: [String]) -> CGFloat {
        let app = XCUIApplication()
        app.launchArguments += launchArguments
        app.launch()

        let map = app.descendants(matching: .any)["map.view"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.35)).press(forDuration: 1.2)

        let marker = app.descendants(matching: .any)["own.location"]
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "no own-location marker after a long press")
        let width = marker.frame.width
        app.terminate()
        return width
    }

    // MARK: - Helpers

    /// Keeps a screenshot of the current screen in the test result.
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Distance between an element and the centre of another, in points.
    private func distance(from container: XCUIElement, to element: XCUIElement) -> CGFloat {        let center = CGPoint(x: container.frame.midX, y: container.frame.midY)
        return hypot(element.frame.midX - center.x, element.frame.midY - center.y)
    }

    /// Polls until the marker sits at the container's centre.
    private func waitForMarker(_ marker: XCUIElement,
                               near container: XCUIElement,
                               timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if distance(from: container, to: marker) <= 60 {
                return true
            }
            usleep(200_000)
        }
        return false
    }

    /// Polls an element's accessibility value until it contains a string.
    private func waitForValue(of element: XCUIElement,
                              toContain expected: String,
                              timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = element.value as? String, value.contains(expected) {
                return true
            }
            usleep(200_000)
        }
        return false
    }

    /// Polls an element's accessibility value until it differs from a string.
    private func waitForValue(of element: XCUIElement,
                              toDifferFrom previous: String?,
                              timeout: TimeInterval = 20) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = element.value as? String, value != previous {
                return true
            }
            usleep(200_000)
        }
        return false
    }

    /// Polls the own-location marker until it reports a different position.
    private func waitForMarkerValue(of element: XCUIElement,
                                    toDifferFrom previous: String?,
                                    timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = element.value as? String, value != previous {
                return true
            }
            usleep(200_000)
        }
        return false
    }

    /// LIVE CHECK: requires Blitzortung credentials and network access. Points the
    /// HTTP source at the real endpoint, enters the credentials, and confirms
    /// authenticated strike logs render.
    ///
    /// Credentials are supplied out of band — through `BO_DATA_USERNAME` /
    /// `BO_DATA_PASSWORD` in the environment when present, otherwise through the
    /// same build settings substituted into this bundle's Info.plist by an
    /// `.xcconfig`. They are never written to the repository.
    func testLiveHttpSourceAuthenticatesAgainstRealBackend() throws {
        let credentials = liveCredentials()
        try XCTSkipIf(credentials == nil,
                      "no Blitzortung credentials supplied (BO_DATA_USERNAME/BO_DATA_PASSWORD)")
        let credentials_ = credentials!

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, named: "HTTP")
        // Leave the endpoint empty so the provider uses its built-in default.
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        replaceText(in: app.textFields["settings.username"], with: credentials_.username)
        replaceText(in: app.secureTextFields["settings.password"], with: credentials_.password)
        app.otherElements["settings.root"].tap()

        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// Reads the Blitzortung credentials from the environment or the test bundle.
    private func liveCredentials() -> (username: String, password: String)? {
        let environment = ProcessInfo.processInfo.environment
        let bundle = Bundle(for: type(of: self))

        let username = environment["BO_DATA_USERNAME"]
            ?? (bundle.object(forInfoDictionaryKey: "BOTestDataUsername") as? String)
            ?? ""
        let password = environment["BO_DATA_PASSWORD"]
            ?? (bundle.object(forInfoDictionaryKey: "BOTestDataPassword") as? String)
            ?? ""

        guard !username.isEmpty, !password.isEmpty else {
            return nil
        }
        return (username, password)
    }

    /// Skips the live backend checks when the stub is not running locally.
    private func requireStubServer() throws {
        let (_, status) = probe(URLRequest(url: URL(string: "http://127.0.0.1:8099/x.log")!))
        try XCTSkipIf(status == nil, "stub server not reachable on 127.0.0.1:8099")
    }

    /// Skips the live backend check when the public backend returns no strike data.
    private func requireLiveBackend() throws {
        var request = URLRequest(url: URL(string: "http://bo-test.tryb.de")!)
        request.httpMethod = "POST"
        request.setValue("text/json", forHTTPHeaderField: "Content-Type")
        request.setValue("bo-ios-1", forHTTPHeaderField: "User-Agent")
        request.httpBody = Data(#"{"id":1,"method":"get_strikes_grid","params":[60,10000,0,1,0]}"#.utf8)

        let (body, status) = probe(request)
        let text = body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        try XCTSkipUnless(status == 200 && text.contains("\"t\""),
                          "live RPC backend did not return strike data")
    }

    /// Performs a request and returns its body and status, or `nil` status on failure.
    private func probe(_ request: URLRequest, timeout: TimeInterval = 5) -> (Data?, Int?) {
        var request = request
        request.timeoutInterval = timeout

        let semaphore = DispatchSemaphore(value: 0)
        var body: Data?
        var status: Int?
        URLSession.shared.dataTask(with: request) { data, response, _ in
            body = data
            status = (response as? HTTPURLResponse)?.statusCode
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 2)
        return (body, status)
    }

    private func openSettings(_ app: XCUIApplication) {
        let open = app.buttons["settings.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()

        let source = app.segmentedControls["settings.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
    }

    /// Selects the data source by the name its segment shows, rather than by an
    /// index that has to be kept in step with the order of the segments.
    private func selectSource(_ app: XCUIApplication, named name: String) {
        let source = app.segmentedControls["settings.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        source.buttons[name].tap()
    }

    /// Replaces a field's contents rather than appending to whatever it holds.
    private func replaceText(in element: XCUIElement, with value: String) {
        element.tap()

        let clear = element.buttons["Clear text"]
        if clear.exists {
            clear.tap()
        } else if let current = element.value as? String, !current.isEmpty,
                  current != element.placeholderValue {
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }

        if !value.isEmpty {
            element.typeText(value)
        }
    }

    private func relaunch(_ app: XCUIApplication) {
        // Relaunch so the first poll fires immediately rather than after a period.
        app.terminate()
        app.launch()
    }

    /// Polls a label until it shows the expected value, for controls whose state
    /// updates asynchronously with the UI query.
    private func waitForLabel(_ element: XCUIElement,
                              toEqual expected: String,
                              timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.label == expected {
                return true
            }
            usleep(100_000)
        }
        return false
    }

    /// Polls a label until it matches a regular expression, for status text that
    /// the app updates on its own cadence.
    private func waitForStatus(_ element: XCUIElement,
                               matching pattern: String,
                               timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.label.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
            usleep(200_000)
        }
        return false
    }

    /// Polls the status label until it reports any interval, including a zero
    /// strike count, which still proves a result was rendered.
    private func waitForStatusWithInterval(_ element: XCUIElement,
                                           timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.label.range(of: "^[0-9]+ strikes/[0-9]+ minutes", options: .regularExpression) != nil {
                return true
            }
            usleep(500_000)
        }
        return false
    }

    /// Polls the status label until it reports a non-zero strike count.
    ///
    /// Returns the last observed label so a failure shows what the app actually
    /// displayed instead of only a timeout.
    private func waitForStrikeCount(in element: XCUIElement,
                                    timeout: TimeInterval) -> (matched: Bool, label: String) {
        let deadline = Date().addingTimeInterval(timeout)
        var label = ""
        while Date() < deadline {
            label = element.label
            if label.range(of: "^[1-9][0-9]* strikes/", options: .regularExpression) != nil {
                return (true, label)
            }
            usleep(500_000)
        }
        return (false, label)
    }
}
