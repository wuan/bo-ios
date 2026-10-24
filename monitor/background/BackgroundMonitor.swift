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

import Foundation

/// Runs the alert decision while the app is not in the foreground.
///
/// The monitor is pure composition: it gates on the stored alerts switch and
/// background query period, fetches the current realtime interval through the
/// shared pipeline, and evaluates the shared ``ProximityAlertMonitor`` - the
/// decision, the ports, and the aggregation are unchanged. Scheduling sits
/// behind ``BackgroundMonitoringScheduling`` and fetching behind
/// ``BackgroundDataFetching``, so the logic is tested without `BGTaskScheduler`.
public final class BackgroundMonitor {

    private let settings: SettingsStore
    private let scheduler: BackgroundMonitoringScheduling
    private let fetcher: BackgroundDataFetching
    private let alertMonitor: ProximityAlertMonitor
    private let notifier: AlertNotifying
    private let aggregator: AlertAggregator
    private let location: () -> Location?

    private var hasRequestedAuthorization = false

    public init(settings: SettingsStore,
                scheduler: BackgroundMonitoringScheduling,
                fetcher: BackgroundDataFetching,
                alertMonitor: ProximityAlertMonitor,
                notifier: AlertNotifying,
                aggregator: AlertAggregator = AlertAggregator(),
                location: @escaping () -> Location?) {
        self.settings = settings
        self.scheduler = scheduler
        self.fetcher = fetcher
        self.alertMonitor = alertMonitor
        self.notifier = notifier
        self.aggregator = aggregator
        self.location = location

        scheduler.register { [weak self] completion in
            self?.handleRefresh(completion: completion) ?? completion()
        }
    }

    /// Whether background monitoring should run for the stored settings.
    public var isEnabled: Bool {
        return settings.backgroundMonitoringEnabled
    }

    /// Re-establishes monitoring at launch: asks for notification readiness and
    /// schedules the next wake-up when enabled, and cancels any stale request
    /// when not.
    public func start() {
        guard isEnabled else {
            scheduler.cancel()
            return
        }
        requestAuthorizationIfNeeded()
        scheduler.submit(after: TimeInterval(settings.backgroundQueryPeriod))
    }

    /// Schedules monitoring because the app left the foreground.
    public func enterBackground() {
        start()
    }

    /// Stops scheduling monitoring because the app returned to the foreground,
    /// where the foreground refresh takes over.
    public func enterForeground() {
        scheduler.cancel()
    }

    /// Fetches the current interval and evaluates the alert decision on it.
    ///
    /// Does nothing when monitoring is disabled, so a stray wake-up cannot do
    /// background work after the user turned it off.
    public func run(completion: @escaping () -> Void = {}) {
        guard isEnabled else {
            completion()
            return
        }

        fetcher.fetchRealtime { [weak self] result in
            guard let self = self else {
                completion()
                return
            }
            if let result = result {
                let aggregation = self.aggregator.aggregate(strikes: result.strikes,
                                                            dataArea: result.rasterParameters,
                                                            location: self.location(),
                                                            isRealtime: result.parameters.isRealtime(),
                                                            referenceTime: result.referenceTimestamp)
                self.alertMonitor.evaluate(aggregation)
            }
            completion()
        }
    }

    /// Asks for the notification authorisation background alerts need, once.
    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        notifier.requestAuthorization()
    }

    /// Runs a wake-up and re-arms the next one while monitoring remains enabled.
    private func handleRefresh(completion: @escaping () -> Void) {
        guard isEnabled else {
            scheduler.cancel()
            completion()
            return
        }
        run { [weak self] in
            self?.scheduler.submit(after: TimeInterval(self?.settings.backgroundQueryPeriod ?? 0))
            completion()
        }
    }
}
