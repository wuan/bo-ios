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

/// Where an alert's sound and vibration go.
///
/// Behind a port so the decision that produced them can be tested without a
/// speaker or a haptic engine.
public protocol AlertSignalling: AnyObject {

    /// Emits the alert signal.
    ///
    /// - Parameters:
    ///   - sound: the configured sound, or an empty string for none.
    ///   - vibrationStrength: the configured strength; zero means no vibration.
    func signal(sound: String, vibrationStrength: Int)
}

/// Where an alert's notification goes.
public protocol AlertNotifying: AnyObject {

    /// Asks for the authorisation a notification needs.
    ///
    /// A refusal leaves this port a no-op, so the alert state and the signals
    /// keep working without it.
    func requestAuthorization()

    /// Raises a notification for the closest strike.
    func notify(closest: AlertClosestStrike)
}

/// What the monitor reports about the current alert.
public enum ProximityAlertState: Equatable {
    /// Nothing qualifies: no location, no realtime data, nothing inside the
    /// notification limit, or alerts switched off.
    case cancelled
    /// A strike lies inside the notification limit.
    case active(AlertClosestStrike)

    /// Whether an alert is active.
    public var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    /// The closest strike the alert reports, when one is active.
    public var closestStrike: AlertClosestStrike? {
        guard case .active(let closest) = self else { return nil }
        return closest
    }
}

/// The values the alert settings accept, taken from the reference client.
public enum AlertSettingsValues {

    /// The distances a limit may take, in kilometres; zero is off.
    ///
    /// The non-zero values are the radar's own ring edges, so a limit always
    /// covers whole rings.
    public static let distanceLimits: [Double] = [0, 10, 25, 50, 100, 250, 500]

    /// The times a suppression window may take, in minutes; zero is off.
    public static let suppressionTimes: [Double] = [0, 5, 15, 30]

    /// The notification limit applied when nothing valid is stored, in km.
    public static let defaultNotificationDistanceLimit: Double = 50
    /// The signalling limit applied when nothing valid is stored, in km.
    public static let defaultSignalingDistanceLimit: Double = 25
    /// The suppression time applied when nothing valid is stored, in minutes.
    public static let defaultSuppressionTime: Double = 0
    /// The vibration strength applied when nothing valid is stored.
    public static let defaultVibrationStrength = 3
    /// The strongest vibration the setting allows.
    public static let maximumVibrationStrength = 30
}

public extension SettingsStore {

    /// Whether proximity alerts are switched on.
    var alertsEnabled: Bool {
        return bool(for: .alertEnabled)
    }

    /// The notification limit in kilometres; zero switches it off.
    ///
    /// A stored value outside the settable set falls back to the default, so a
    /// limit the radar has no ring for cannot take effect.
    var notificationDistanceLimit: Double {
        return AlertSettingsValues.distanceLimits.contains(double(for: .notificationDistanceLimit))
            ? double(for: .notificationDistanceLimit)
            : AlertSettingsValues.defaultNotificationDistanceLimit
    }

    /// The signalling limit in kilometres; zero switches it off.
    var signalingDistanceLimit: Double {
        return AlertSettingsValues.distanceLimits.contains(double(for: .signalingDistanceLimit))
            ? double(for: .signalingDistanceLimit)
            : AlertSettingsValues.defaultSignalingDistanceLimit
    }

    /// The suppression window in seconds.
    var suppressionTime: Double {
        let minutes = AlertSettingsValues.suppressionTimes.contains(double(for: .signalingSuppressionTime))
            ? double(for: .signalingSuppressionTime)
            : AlertSettingsValues.defaultSuppressionTime
        return minutes * 60
    }

    /// The vibration strength, clamped to what the setting allows.
    var alertVibrationStrength: Int {
        return min(max(int(for: .alertVibrationSignal), 0), AlertSettingsValues.maximumVibrationStrength)
    }

    /// The sound the signal plays, or an empty string for none.
    var alertSoundSignal: String {
        return string(for: .alertSoundSignal)
    }
}

/// Turns the aggregation around the current location into the alert decision:
/// whether to notify, whether to signal, and what state to report.
///
/// The limits and the enable switch come from the settings; the notification and
/// the signal go through the ports. Suppression and the notification's
/// once-only rule are keyed on the strikes that caused them rather than on the
/// clock, so how often the app happens to evaluate the data cannot change the
/// outcome.
public final class ProximityAlertMonitor {

    private let settings: SettingsStore
    private let signaller: AlertSignalling
    private let notifier: AlertNotifying

    /// The strike that last caused a signal, in seconds since the epoch.
    private var lastSignalledTimestamp = 0
    /// The strike last covered by a notification, in seconds since the epoch.
    private var lastNotifiedTimestamp = 0

    public init(settings: SettingsStore,
                signaller: AlertSignalling,
                notifier: AlertNotifying) {
        self.settings = settings
        self.signaller = signaller
        self.notifier = notifier
    }

    /// Evaluates the aggregation, signals and notifies what qualifies, and
    /// reports the alert state.
    @discardableResult
    public func evaluate(_ aggregation: AlertAggregation) -> ProximityAlertState {
        guard settings.alertsEnabled else { return .cancelled }
        guard let activity = aggregation.activity, let closest = activity.closest else { return .cancelled }

        let signallingLimit = settings.signalingDistanceLimit
        if signallingLimit > 0,
           closest.distance <= signallingLimit,
           let latest = latestStrike(within: signallingLimit, in: activity),
           Double(latest) > Double(lastSignalledTimestamp) + settings.suppressionTime {
            signaller.signal(sound: settings.alertSoundSignal,
                             vibrationStrength: settings.alertVibrationStrength)
            lastSignalledTimestamp = latest
        }

        let notificationLimit = settings.notificationDistanceLimit
        if notificationLimit > 0,
           closest.distance <= notificationLimit,
           let latest = latestStrike(within: notificationLimit, in: activity),
           latest > lastNotifiedTimestamp {
            notifier.notify(closest: closest)
            lastNotifiedTimestamp = latest
        }

        guard notificationLimit > 0, closest.distance <= notificationLimit else { return .cancelled }
        return .active(closest)
    }

    /// The newest strike inside `kilometres`, from the rings that limit covers.
    ///
    /// The aggregation records the newest strike of every cell, so a limit that
    /// sits on a ring edge covers the rings inside it and no partial ring.
    func latestStrike(within kilometres: Double, in activity: AlertActivity) -> Int? {
        return activity.sectors
            .flatMap { $0.cells }
            .filter { $0.range.maximum <= kilometres && $0.latestStrikeTimestamp > 0 }
            .map { $0.latestStrikeTimestamp }
            .max()
    }
}
