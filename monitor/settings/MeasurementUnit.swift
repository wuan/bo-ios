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

/// The unit distances are displayed in.
///
/// The measurement-unit selection UI arrives with the preferences phase; the
/// stored setting and the conversion the chrome needs exist from here.
public enum MeasurementUnit: String, CaseIterable {

    case metric
    case imperial

    /// Kilometres in one unit of this system.
    public var kilometresPerUnit: Double {
        switch self {
        case .metric:
            return 1
        case .imperial:
            return 1.609344
        }
    }

    /// The name of the unit distances are shown in.
    public var unitName: String {
        switch self {
        case .metric:
            return NSLocalizedString("unit.km", comment: "Kilometre unit name")
        case .imperial:
            return NSLocalizedString("unit.miles", comment: "Miles unit name")
        }
    }

    /// A distance in kilometres expressed in this unit.
    public func distance(fromKilometres kilometres: Double) -> Double {
        return kilometres / kilometresPerUnit
    }

    /// A distance in this unit, rounded to a whole unit, as shown on a ring
    /// label.
    public func wholeValue(kilometres: Double) -> String {
        return String(format: "%.0f", distance(fromKilometres: kilometres))
    }

    /// A distance as shown with its unit, e.g. `12.3 km` or `7.6 mi`.
    public func formatted(kilometres: Double) -> String {
        return String(format: "%.1f", distance(fromKilometres: kilometres)) + " " + unitName
    }
}

public extension SettingsStore {

    /// The stored measurement unit.
    ///
    /// A stored value that names no known unit falls back to metric.
    var measurementUnit: MeasurementUnit {
        return MeasurementUnit(rawValue: string(for: .measurementUnit)) ?? .metric
    }
}
