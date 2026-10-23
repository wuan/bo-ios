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

/// Identifies a persisted application setting.
///
/// Every case must have an entry in ``SettingsKey/defaultValues``; a unit test
/// enforces this so later phases cannot add a setting without a default.
public enum SettingsKey: String, CaseIterable {
    case mapMode
    case dataSource
    case serviceEndpoint
    case measurementUnit
    case alertEnabled
    case mapScale
    case mapFade
    case colorScheme
    case region
    case intervalDuration
    case historicTimestep
    case locationMode
    case manualLatitude
    case manualLongitude
    case manualLocationSet
    case showOwnLocation
    case ownLocationSize
    case keepZoomOnCenter
    case backgroundLocationDisclosureShown

    /// Values used when a setting has never been changed by the user.
    public static var defaultValues: [String: Any] {
        return [
            SettingsKey.mapMode.rawValue: "hybrid",
            SettingsKey.dataSource.rawValue: "rpc",
            SettingsKey.serviceEndpoint.rawValue: "",
            SettingsKey.measurementUnit.rawValue: "metric",
            SettingsKey.alertEnabled.rawValue: true,
            SettingsKey.mapScale.rawValue: 75,
            SettingsKey.mapFade.rawValue: 55,
            SettingsKey.colorScheme.rawValue: ColorScheme.blitzortung.rawValue,
            SettingsKey.region.rawValue: SelectableSettings.defaultRegion,
            SettingsKey.intervalDuration.rawValue: SelectableSettings.defaultIntervalDuration,
            SettingsKey.historicTimestep.rawValue: SelectableSettings.defaultHistoricTimestep,
            SettingsKey.locationMode.rawValue: LocationMode.manual.rawValue,
            SettingsKey.manualLatitude.rawValue: 0.0,
            SettingsKey.manualLongitude.rawValue: 0.0,
            // A fresh install has no location until the user sets one.
            SettingsKey.manualLocationSet.rawValue: false,
            // The marker is the only confirmation that a long press worked, so
            // it starts on, and 100 percent is the diameter it has always had.
            SettingsKey.showOwnLocation.rawValue: true,
            SettingsKey.ownLocationSize.rawValue: OwnLocationMarker.defaultSizePercent,
            // Centring zooms to the radar's range unless the user keeps the zoom.
            SettingsKey.keepZoomOnCenter.rawValue: false,
            // The background-location explanation has not been shown yet.
            SettingsKey.backgroundLocationDisclosureShown.rawValue: false,
        ]
    }
}
