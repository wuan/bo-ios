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

/// How a setting's value is stored.
///
/// The storage kind is what the settings export writes and what an import checks
/// a document's value against, so a value cannot be read back in the wrong type.
public enum SettingsStorage {
    case string
    case int
    case double
    case bool
}

/// Identifies a persisted application setting.
///
/// Every case must have an entry in ``SettingsKey/defaultValues``; a unit test
/// enforces this so later phases cannot add a setting without a default. The
/// settings are split into the ones the user can change (``userFacing``) and the
/// app's own bookkeeping (``internalKeys``): the preferences screen, the settings
/// reference, and the settings export cover the user-facing set only.
public enum SettingsKey: String, CaseIterable {

    // MARK: - User-facing settings

    case mapMode
    case mapFade
    case colorScheme
    case showOwnLocation
    case ownLocationSize
    case keepZoomOnCenter
    case animationStepDuration
    case animationCyclePause
    case dataSource
    case serviceEndpoint
    case region
    case intervalDuration
    case historicTimestep
    case locationMode
    case manualLatitude
    case manualLongitude
    case alertEnabled
    case backgroundQueryPeriod
    case notificationDistanceLimit
    case signalingDistanceLimit
    case signalingSuppressionTime
    case alertVibrationSignal
    case alertSoundSignal
    case measurementUnit
    case keepScreenAwake
    case diagnosticsEnabled

    // MARK: - Internal bookkeeping

    case manualLocationSet
    case backgroundLocationDisclosureShown
    case lastNotifiedStrikeTimestamp
    case lastSignalledStrikeTimestamp

    /// The settings the user can change, in the order the reference client lists
    /// them; the preferences screen and the settings export cover exactly these.
    public static var userFacing: [SettingsKey] {
        return allCases.filter { !internalKeys.contains($0) }
    }

    /// The settings the app keeps for itself.
    ///
    /// Persisted like any other setting, but not a preference: the screen does
    /// not offer them, an export must not carry them to another install, and
    /// reset clears them.
    public static let internalKeys: Set<SettingsKey> = [
        .manualLocationSet,
        .backgroundLocationDisclosureShown,
        .lastNotifiedStrikeTimestamp,
        .lastSignalledStrikeTimestamp,
    ]

    /// Whether the user can see and change this setting.
    public var isUserFacing: Bool {
        return !SettingsKey.internalKeys.contains(self)
    }

    /// How this setting's value is stored.
    public var storage: SettingsStorage {
        switch self {
        case .mapMode, .colorScheme, .dataSource, .serviceEndpoint,
             .locationMode, .measurementUnit, .alertSoundSignal:
            return .string
        case .manualLatitude, .manualLongitude, .notificationDistanceLimit,
             .signalingDistanceLimit, .signalingSuppressionTime:
            return .double
        case .showOwnLocation, .keepZoomOnCenter, .alertEnabled, .keepScreenAwake,
             .diagnosticsEnabled, .manualLocationSet, .backgroundLocationDisclosureShown:
            return .bool
        case .mapFade, .ownLocationSize, .animationStepDuration, .animationCyclePause,
             .region, .intervalDuration, .historicTimestep, .backgroundQueryPeriod,
             .alertVibrationSignal, .lastNotifiedStrikeTimestamp, .lastSignalledStrikeTimestamp:
            return .int
        }
    }

    /// Values used when a setting has never been changed by the user.
    public static var defaultValues: [String: Any] {
        return [
            SettingsKey.mapMode.rawValue: "hybrid",
            SettingsKey.mapFade.rawValue: 55,
            SettingsKey.colorScheme.rawValue: ColorScheme.blitzortung.rawValue,
            // The marker is the only confirmation that a long press worked, so
            // it starts on, and 100 percent is the diameter it has always had.
            SettingsKey.showOwnLocation.rawValue: true,
            SettingsKey.ownLocationSize.rawValue: OwnLocationMarker.defaultSizePercent,
            // Centring zooms to the radar's range unless the user keeps the zoom.
            SettingsKey.keepZoomOnCenter.rawValue: false,
            // One step a second and no pause reproduce the fixed playback the app
            // had before the settings existed.
            SettingsKey.animationStepDuration.rawValue: 1,
            SettingsKey.animationCyclePause.rawValue: 0,
            SettingsKey.dataSource.rawValue: "rpc",
            SettingsKey.serviceEndpoint.rawValue: "",
            SettingsKey.region.rawValue: SelectableSettings.defaultRegion,
            SettingsKey.intervalDuration.rawValue: SelectableSettings.defaultIntervalDuration,
            SettingsKey.historicTimestep.rawValue: SelectableSettings.defaultHistoricTimestep,
            SettingsKey.locationMode.rawValue: LocationMode.manual.rawValue,
            SettingsKey.manualLatitude.rawValue: 0.0,
            SettingsKey.manualLongitude.rawValue: 0.0,
            SettingsKey.alertEnabled.rawValue: true,
            // Background monitoring is off until the user picks a period.
            SettingsKey.backgroundQueryPeriod.rawValue: SelectableSettings.defaultBackgroundQueryPeriod,
            // The alert limits and signals, at the reference client's defaults.
            SettingsKey.notificationDistanceLimit.rawValue: AlertSettingsValues.defaultNotificationDistanceLimit,
            SettingsKey.signalingDistanceLimit.rawValue: AlertSettingsValues.defaultSignalingDistanceLimit,
            SettingsKey.signalingSuppressionTime.rawValue: AlertSettingsValues.defaultSuppressionTime,
            SettingsKey.alertVibrationSignal.rawValue: AlertSettingsValues.defaultVibrationStrength,
            SettingsKey.alertSoundSignal.rawValue: "",
            SettingsKey.measurementUnit.rawValue: "metric",
            // Keeping the screen awake and diagnostics are both opt-in.
            SettingsKey.keepScreenAwake.rawValue: false,
            SettingsKey.diagnosticsEnabled.rawValue: false,
            // A fresh install has no location until the user sets one.
            SettingsKey.manualLocationSet.rawValue: false,
            // The background-location explanation has not been shown yet.
            SettingsKey.backgroundLocationDisclosureShown.rawValue: false,
            // Dedup watermarks: no strike has been notified or signalled yet.
            SettingsKey.lastNotifiedStrikeTimestamp.rawValue: 0,
            SettingsKey.lastSignalledStrikeTimestamp.rawValue: 0,
        ]
    }
}
