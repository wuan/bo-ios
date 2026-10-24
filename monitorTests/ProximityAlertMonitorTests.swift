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

final class ProximityAlertMonitorTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var signaller: StubAlertSignaller!
    private var notifier: StubAlertNotifier!
    private var monitor: ProximityAlertMonitor!

    private let geometry = AlertGeometry.standard

    override func setUp() {
        super.setUp()
        suiteName = "ProximityAlertMonitorTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        signaller = StubAlertSignaller()
        notifier = StubAlertNotifier()
        monitor = ProximityAlertMonitor(settings: settings, signaller: signaller, notifier: notifier)
    }

    override func tearDown() {
        monitor = nil
        notifier = nil
        signaller = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Settings

    func testTheAlertSettingsStartAtTheReferenceDefaults() {
        XCTAssertTrue(settings.alertsEnabled)
        XCTAssertEqual(settings.notificationDistanceLimit, 50)
        XCTAssertEqual(settings.signalingDistanceLimit, 25)
        XCTAssertEqual(settings.suppressionTime, 0)
        XCTAssertEqual(settings.alertVibrationStrength, 3)
        XCTAssertEqual(settings.alertSoundSignal, "")
    }

    func testAlertSettingsPersist() {
        settings.set(100.0, for: .notificationDistanceLimit)
        settings.set(50.0, for: .signalingDistanceLimit)
        settings.set(15.0, for: .signalingSuppressionTime)
        settings.set(30, for: .alertVibrationSignal)
        settings.set("1005", for: .alertSoundSignal)

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.notificationDistanceLimit, 100)
        XCTAssertEqual(reloaded.signalingDistanceLimit, 50)
        XCTAssertEqual(reloaded.suppressionTime, 15 * 60)
        XCTAssertEqual(reloaded.alertVibrationStrength, 30)
        XCTAssertEqual(reloaded.alertSoundSignal, "1005")
    }

    func testALimitOutsideTheValueSetFallsBackToTheDefault() {
        settings.set(37.0, for: .notificationDistanceLimit)
        settings.set(12.0, for: .signalingDistanceLimit)

        XCTAssertEqual(settings.notificationDistanceLimit,
                       AlertSettingsValues.defaultNotificationDistanceLimit)
        XCTAssertEqual(settings.signalingDistanceLimit,
                       AlertSettingsValues.defaultSignalingDistanceLimit)
    }

    func testASuppressionTimeOutsideTheValueSetFallsBackToTheDefault() {
        settings.set(7.0, for: .signalingSuppressionTime)

        XCTAssertEqual(settings.suppressionTime, AlertSettingsValues.defaultSuppressionTime * 60)
    }

    func testAVibrationStrengthOutsideTheRangeIsClamped() {
        settings.set(-5, for: .alertVibrationSignal)
        XCTAssertEqual(settings.alertVibrationStrength, 0)

        settings.set(400, for: .alertVibrationSignal)
        XCTAssertEqual(settings.alertVibrationStrength, AlertSettingsValues.maximumVibrationStrength)
    }

    // MARK: - Gating

    func testDisabledAlertsSignalAndNotifyNothingAndReportCancelled() {
        settings.set(false, for: .alertEnabled)

        let state = monitor.evaluate(aggregation(distance: 5, timestamp: 1000))

        XCTAssertEqual(state, .cancelled)
        XCTAssertTrue(signaller.signals.isEmpty)
        XCTAssertTrue(notifier.notifications.isEmpty)
    }

    func testNoLocationNoDataAndAnOutsideLocationAllCancel() {
        for cancelled in [AlertAggregation.noLocation, .noData, .outsideDataArea] {
            signaller = StubAlertSignaller()
            notifier = StubAlertNotifier()
            monitor = ProximityAlertMonitor(settings: settings, signaller: signaller, notifier: notifier)

            let state = monitor.evaluate(cancelled)

            XCTAssertEqual(state, .cancelled)
            XCTAssertTrue(signaller.signals.isEmpty)
            XCTAssertTrue(notifier.notifications.isEmpty)
        }
    }

    // MARK: - Limits

    func testAStrikeInsideTheSignallingLimitSignalsAndNotifies() {
        settings.set(25.0, for: .signalingDistanceLimit)
        settings.set(50.0, for: .notificationDistanceLimit)

        let state = monitor.evaluate(aggregation(distance: 20, timestamp: 1000))

        XCTAssertEqual(signaller.signals.count, 1)
        XCTAssertEqual(notifier.notifications.count, 1)
        XCTAssertTrue(state.isActive)
    }

    func testAStrikeBetweenTheLimitsNotifiesWithoutSignalling() {
        settings.set(25.0, for: .signalingDistanceLimit)
        settings.set(50.0, for: .notificationDistanceLimit)

        let state = monitor.evaluate(aggregation(distance: 40, timestamp: 1000))

        XCTAssertTrue(signaller.signals.isEmpty)
        XCTAssertEqual(notifier.notifications.count, 1)
        XCTAssertTrue(state.isActive)
    }

    func testAStrikeOutsideTheNotificationLimitDoesNeitherAndCancels() {
        settings.set(50.0, for: .notificationDistanceLimit)

        let state = monitor.evaluate(aggregation(distance: 120, timestamp: 1000))

        XCTAssertTrue(signaller.signals.isEmpty)
        XCTAssertTrue(notifier.notifications.isEmpty)
        XCTAssertEqual(state, .cancelled)
    }

    func testADistanceEqualToALimitCountsAsInsideIt() {
        settings.set(25.0, for: .signalingDistanceLimit)
        settings.set(25.0, for: .notificationDistanceLimit)

        let state = monitor.evaluate(aggregation(distance: 25, timestamp: 1000))

        XCTAssertEqual(signaller.signals.count, 1, "a strike exactly on the signalling limit signals")
        XCTAssertEqual(notifier.notifications.count, 1, "a strike exactly on the notification limit notifies")
        XCTAssertTrue(state.isActive)
    }

    func testALimitOfZeroSwitchesThatSignalOff() {
        settings.set(0.0, for: .notificationDistanceLimit)
        settings.set(0.0, for: .signalingDistanceLimit)

        let state = monitor.evaluate(aggregation(distance: 5, timestamp: 1000))

        XCTAssertTrue(signaller.signals.isEmpty)
        XCTAssertTrue(notifier.notifications.isEmpty)
        XCTAssertEqual(state, .cancelled)
    }

    // MARK: - Suppression and the once-only notification

    func testTheSameActivitySignalsAndNotifiesOnlyOnce() {
        let activity = aggregation(distance: 10, timestamp: 1000)

        monitor.evaluate(activity)
        monitor.evaluate(activity)
        monitor.evaluate(activity)

        XCTAssertEqual(signaller.signals.count, 1)
        XCTAssertEqual(notifier.notifications.count, 1)
    }

    func testASuppressionWindowHoldsASecondSignalBack() {
        settings.set(15.0, for: .signalingSuppressionTime)

        monitor.evaluate(aggregation(distance: 10, timestamp: 1000))
        // Newer activity, but inside the window measured from the strike that
        // caused the first signal.
        monitor.evaluate(aggregation(distance: 10, timestamp: 1000 + 60))

        XCTAssertEqual(signaller.signals.count, 1, "the suppression window must hold the second signal back")

        monitor.evaluate(aggregation(distance: 10, timestamp: 1000 + 15 * 60 + 1))

        XCTAssertEqual(signaller.signals.count, 2, "a strike after the window signals again")
    }

    func testANewerStrikeNotifiesAgain() {
        monitor.evaluate(aggregation(distance: 10, timestamp: 1000))
        monitor.evaluate(aggregation(distance: 10, timestamp: 1060))

        XCTAssertEqual(notifier.notifications.count, 2)
    }

    func testAnOlderStrikeDoesNotNotify() {
        monitor.evaluate(aggregation(distance: 10, timestamp: 2000))
        monitor.evaluate(aggregation(distance: 10, timestamp: 1500))

        XCTAssertEqual(notifier.notifications.count, 1)
    }

    // MARK: - Reported state

    func testTheActiveStateCarriesTheClosestStrike() throws {
        let state = monitor.evaluate(aggregation(distance: 12.5, timestamp: 1000))

        let closest = try XCTUnwrap(state.closestStrike)
        XCTAssertEqual(closest.distance, 12.5)
        XCTAssertEqual(closest.direction, "N")
        XCTAssertEqual(closest.age, 60)
    }

    func testTheStateStopsBeingActiveOnceTheStrikeIsOutOfRange() {
        XCTAssertTrue(monitor.evaluate(aggregation(distance: 10, timestamp: 1000)).isActive)

        XCTAssertFalse(monitor.evaluate(aggregation(distance: 300, timestamp: 1100)).isActive)
    }

    // MARK: - Configurable signal

    func testTheConfiguredSoundAndStrengthReachTheSignal() {
        settings.set(12, for: .alertVibrationSignal)
        settings.set("1005", for: .alertSoundSignal)

        monitor.evaluate(aggregation(distance: 10, timestamp: 1000))

        XCTAssertEqual(signaller.signals.first?.sound, "1005")
        XCTAssertEqual(signaller.signals.first?.vibrationStrength, 12)
    }

    // MARK: - Helpers

    /// An aggregation whose closest strike is `distance` kilometres away and
    /// whose cells carry `timestamp` in the rings that reach it.
    private func aggregation(distance: Double,
                             timestamp: Int,
                             direction: String = "N") -> AlertAggregation {
        let closest = AlertClosestStrike(direction: direction, distance: distance, age: 60)
        let sectors = geometry.directions.map { dir -> AlertSectorActivity in
            let cells = geometry.ranges.map { range -> AlertCellActivity in
                let inside = distance <= range.maximum
                return AlertCellActivity(range: range,
                                         strikeCount: inside ? 1 : 0,
                                         latestStrikeTimestamp: inside ? timestamp : 0)
            }
            return AlertSectorActivity(direction: dir,
                                       cells: cells,
                                       closestStrike: dir.label == direction ? closest : nil)
        }
        return .activity(AlertActivity(ranges: geometry.ranges, sectors: sectors, closest: closest))
    }
}

/// Records the signals an alert emitted.
final class StubAlertSignaller: AlertSignalling {

    private(set) var signals: [(sound: String, vibrationStrength: Int)] = []

    func signal(sound: String, vibrationStrength: Int) {
        signals.append((sound, vibrationStrength))
    }
}

/// Records the notifications an alert raised.
final class StubAlertNotifier: AlertNotifying {

    private(set) var notifications: [AlertClosestStrike] = []
    private(set) var authorizationRequests = 0

    func requestAuthorization() {
        authorizationRequests += 1
    }

    func notify(closest: AlertClosestStrike) {
        notifications.append(closest)
    }
}
