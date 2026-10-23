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

/// Records what the monitor asks the scheduler to do.
final class RecordingBackgroundScheduler: BackgroundMonitoringScheduling {

    private(set) var registerCount = 0
    private(set) var submittedIntervals: [TimeInterval] = []
    private(set) var cancelCount = 0

    private var handler: ((@escaping () -> Void) -> Void)?

    func register(handler: @escaping (@escaping () -> Void) -> Void) {
        registerCount += 1
        self.handler = handler
    }

    func submit(after interval: TimeInterval) {
        submittedIntervals.append(interval)
    }

    func cancel() {
        cancelCount += 1
    }

    /// Simulates a system wake-up.
    func fire() {
        handler?({})
    }
}

/// Returns a canned realtime result without a network.
final class StubBackgroundFetcher: BackgroundDataFetching {

    var result: Result?
    private(set) var fetchCount = 0

    func fetchRealtime(completion: @escaping (Result?) -> Void) {
        fetchCount += 1
        completion(result)
    }
}

final class BackgroundMonitoringTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var scheduler: RecordingBackgroundScheduler!
    private var fetcher: StubBackgroundFetcher!
    private var signaller: StubAlertSignaller!
    private var notifier: StubAlertNotifier!
    private var location: Location?

    private let referenceTimestamp = 1_000_000

    override func setUp() {
        super.setUp()
        suiteName = "BackgroundMonitoringTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        scheduler = RecordingBackgroundScheduler()
        fetcher = StubBackgroundFetcher()
        signaller = StubAlertSignaller()
        notifier = StubAlertNotifier()
        location = Location(latitude: 50, longitude: 10)
    }

    override func tearDown() {
        location = nil
        notifier = nil
        signaller = nil
        fetcher = nil
        scheduler = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Gating

    func testDisabledWhileThePeriodIsOff() {
        let monitor = makeMonitor()

        XCTAssertFalse(monitor.isEnabled)

        monitor.run()

        XCTAssertEqual(fetcher.fetchCount, 0, "a disabled monitor must not fetch")
        XCTAssertTrue(notifier.notifications.isEmpty)
    }

    func testDisabledWhileAlertsAreOff() {
        settings.setChoice(600, for: .backgroundQueryPeriod)
        settings.set(false, for: .alertEnabled)

        let monitor = makeMonitor()

        XCTAssertFalse(monitor.isEnabled)

        monitor.run()

        XCTAssertEqual(fetcher.fetchCount, 0)
    }

    func testEnabledWithAlertsAndAPeriod() {
        settings.setChoice(600, for: .backgroundQueryPeriod)

        XCTAssertTrue(makeMonitor().isEnabled)
    }

    // MARK: - Scheduling

    func testStartSubmitsWithTheConfiguredPeriod() {
        settings.setChoice(600, for: .backgroundQueryPeriod)
        let monitor = makeMonitor()

        monitor.start()

        XCTAssertEqual(scheduler.registerCount, 1, "the handler is installed on construction")
        XCTAssertEqual(scheduler.submittedIntervals.last, 600)
    }

    func testEnterBackgroundSchedulesAndForegroundCancels() {
        settings.setChoice(120, for: .backgroundQueryPeriod)
        let monitor = makeMonitor()

        monitor.enterBackground()
        XCTAssertEqual(scheduler.submittedIntervals.last, 120)

        monitor.enterForeground()
        XCTAssertEqual(scheduler.cancelCount, 1)
    }

    func testADisabledMonitorCancelsAtLaunch() {
        let monitor = makeMonitor()

        monitor.start()

        XCTAssertTrue(scheduler.submittedIntervals.isEmpty, "off must not schedule")
        XCTAssertEqual(scheduler.cancelCount, 1, "a stale request is cancelled")
    }

    func testAWakeUpFetchesEvaluatesAndResubmits() {
        settings.setChoice(300, for: .backgroundQueryPeriod)
        fetcher.result = realtimeResult(strike: referenceTimestamp - 60)
        let monitor = makeMonitor()
        monitor.start()
        let submissionsBefore = scheduler.submittedIntervals.count

        scheduler.fire()

        XCTAssertEqual(fetcher.fetchCount, 1)
        XCTAssertEqual(notifier.notifications.count, 1, "a strike inside the limit notifies")
        XCTAssertGreaterThan(scheduler.submittedIntervals.count, submissionsBefore,
                             "the wake-up re-arms the next one")
    }

    func testAWakeUpDoesNothingWhenDisabled() {
        let monitor = makeMonitor()

        scheduler.fire()

        XCTAssertEqual(fetcher.fetchCount, 0)
    }

    // MARK: - Dedup across processes

    func testASecondMonitorDoesNotRenotifyTheSameStrike() {
        settings.setChoice(600, for: .backgroundQueryPeriod)
        fetcher.result = realtimeResult(strike: referenceTimestamp - 60)

        makeMonitor().run()
        XCTAssertEqual(notifier.notifications.count, 1)

        let secondNotifier = StubAlertNotifier()
        makeMonitor(notifier: secondNotifier).run()

        XCTAssertTrue(secondNotifier.notifications.isEmpty,
                      "the persisted watermark suppresses a repeat after relaunch")
    }

    func testANewerStrikeNotifiesAgain() {
        settings.setChoice(600, for: .backgroundQueryPeriod)
        fetcher.result = realtimeResult(strike: referenceTimestamp - 60)
        makeMonitor().run()

        let secondNotifier = StubAlertNotifier()
        fetcher.result = realtimeResult(strike: referenceTimestamp + 60,
                                        referenceTimestamp: referenceTimestamp + 60)
        makeMonitor(notifier: secondNotifier).run()

        XCTAssertEqual(secondNotifier.notifications.count, 1, "a newer qualifying strike notifies")
    }

    // MARK: - Notification readiness

    func testEnablingMonitoringAsksForAuthorizationOnce() {        settings.setChoice(600, for: .backgroundQueryPeriod)
        let monitor = makeMonitor()

        monitor.start()
        XCTAssertEqual(notifier.authorizationRequests, 1)

        monitor.start()
        XCTAssertEqual(notifier.authorizationRequests, 1, "asked once")
    }

    func testDisabledMonitoringAsksForNoAuthorization() {
        let monitor = makeMonitor()

        monitor.start()

        XCTAssertEqual(notifier.authorizationRequests, 0)
    }

    // MARK: - Declared background modes

    func testThePlistDeclaresTheBackgroundTaskIdentifier() {
        let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String]

        XCTAssertEqual(identifiers, [BackgroundMonitoring.taskIdentifier])
    }

    func testThePlistDeclaresTheLocationAndFetchBackgroundModes() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]

        XCTAssertEqual(Set(modes ?? []), ["fetch", "location"])
    }

    // MARK: - Helpers

    private func makeMonitor(notifier: StubAlertNotifier? = nil) -> BackgroundMonitor {
        let notifier = notifier ?? self.notifier!
        let alertMonitor = ProximityAlertMonitor(settings: settings, signaller: signaller, notifier: notifier)
        return BackgroundMonitor(settings: settings,
                                 scheduler: scheduler,
                                 fetcher: fetcher,
                                 alertMonitor: alertMonitor,
                                 notifier: notifier,
                                 location: { [weak self] in self?.location })
    }

    /// A realtime result with one point strike just north of the location.
    private func realtimeResult(strike: Int, referenceTimestamp: Int? = nil) -> Result {
        let strike = Strike(timestamp: strike,
                            andMultiplicity: 1,
                            andX: 10.0,
                            andY: 50.01,
                            andWidth: 0,
                            andHeight: 0)
        return Result(parameters: Parameters(region: Parameters.globalRegion, intervalOffset: 0),
                      referenceTimestamp: referenceTimestamp ?? self.referenceTimestamp,
                      strikes: [strike],
                      rasterParameters: nil)
    }
}
