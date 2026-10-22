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

/// A value a selectable setting accepts, together with the name shown for it.
public struct SelectableValue: Equatable {
    public let value: Int
    public let name: String

    public init(value: Int, name: String) {
        self.value = value
        self.name = name
    }
}

/// The fixed value sets behind the region, interval duration, and historic
/// timestep settings.
///
/// The values and their order reproduce the reference client's lists, and the
/// defaults are the ones a fresh install uses.
public enum SelectableSettings {

    /// The region a fresh install requests, Europe.
    public static let defaultRegion = 1
    /// The interval duration in minutes a fresh install displays.
    public static let defaultIntervalDuration = 60
    /// The history step in minutes a fresh install steps by.
    public static let defaultHistoricTimestep = History.defaultOffsetIncrement

    /// The selectable data regions, from the visible extent and the globe to
    /// the named regions.
    public static let regions: [SelectableValue] = [
        SelectableValue(value: Parameters.localRegion,
                        name: NSLocalizedString("region.local", comment: "Region name: the visible extent")),
        SelectableValue(value: Parameters.globalRegion,
                        name: NSLocalizedString("region.global", comment: "Region name: the whole globe")),
        SelectableValue(value: 1, name: NSLocalizedString("region.europe", comment: "Region name")),
        SelectableValue(value: 3, name: NSLocalizedString("region.northAmerica", comment: "Region name")),
        SelectableValue(value: 7, name: NSLocalizedString("region.centralAmerica", comment: "Region name")),
        SelectableValue(value: 5, name: NSLocalizedString("region.southAmerica", comment: "Region name")),
        SelectableValue(value: 2, name: NSLocalizedString("region.oceania", comment: "Region name")),
        SelectableValue(value: 4, name: NSLocalizedString("region.asia", comment: "Region name")),
        SelectableValue(value: 6, name: NSLocalizedString("region.africa", comment: "Region name")),
    ]

    /// The selectable interval durations in minutes.
    public static let intervalDurations: [SelectableValue] =
        [30, 60, 90, 120, 240].map { SelectableValue(value: $0, name: minutesName($0)) }

    /// The selectable historic timesteps in minutes.
    public static let historicTimesteps: [SelectableValue] =
        [15, 30, 60].map { SelectableValue(value: $0, name: minutesName($0)) }

    /// The value set behind a setting, or `nil` when the setting is not
    /// restricted to a fixed set of values.
    public static func values(for key: SettingsKey) -> [SelectableValue]? {
        switch key {
        case .region:
            return regions
        case .intervalDuration:
            return intervalDurations
        case .historicTimestep:
            return historicTimesteps
        default:
            return nil
        }
    }

    /// Whether a setting accepts `value`.
    public static func allows(_ value: Int, for key: SettingsKey) -> Bool {
        guard let values = values(for: key) else { return true }
        return values.contains { $0.value == value }
    }

    /// The name shown for one value of a setting, if the value is known.
    public static func name(for key: SettingsKey, value: Int) -> String? {
        return values(for: key)?.first { $0.value == value }?.name
    }

    /// The name for a duration in minutes, e.g. `60 min`.
    private static func minutesName(_ minutes: Int) -> String {
        return String(format: NSLocalizedString("settings.minutes",
                                                comment: "Duration in minutes, e.g. 60 min"),
                      minutes)
    }
}
