/*

 Copyright 2026 Andreas Würl

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

/// One value a string-valued choice offers, with the name shown for it.
public struct StringChoiceValue: Equatable {
    /// The stored form of the value.
    public let value: String
    /// The name shown for the value.
    public let name: String

    public init(value: String, name: String) {
        self.value = value
        self.name = name
    }
}

/// What a preferences row changes.
public enum PreferenceSubject: Equatable {
    /// A persisted setting.
    case setting(SettingsKey)
    /// A stored credential - the username or the password.
    case credential(CredentialField)
    /// An action the screen performs rather than a value it stores.
    case action(PreferenceAction)
}

/// The credentials the app keeps in the Keychain.
public enum CredentialField: String, Equatable, CaseIterable {
    case username
    case password
}

/// The actions the settings screen offers.
public enum PreferenceAction: String, Equatable, CaseIterable {
    case export
    case importSettings
    case reset
}

/// How a preferences row presents and validates its value.
public enum PreferenceKind: Equatable {
    /// A choice among a fixed set of integer values.
    case intChoice([SelectableValue])
    /// A choice among a fixed set of decimal values.
    case decimalChoice([Double])
    /// A choice among a fixed set of string values.
    case stringChoice([StringChoiceValue])
    /// An on/off switch.
    case toggle
    /// An integer within a range, shown as a slider.
    case intSlider(minimum: Int, maximum: Int)
    /// Free text.
    case text
    /// A secret, shown masked.
    case password
    /// A decimal number.
    case decimal
    /// A row that performs an action.
    case button
}

/// One row of the settings screen.
public struct PreferenceItem: Equatable {
    /// The row's label.
    public let title: String
    /// What the row changes.
    public let subject: PreferenceSubject
    /// How the row presents and validates its value.
    public let kind: PreferenceKind

    public init(title: String, subject: PreferenceSubject, kind: PreferenceKind) {
        self.title = title
        self.subject = subject
        self.kind = kind
    }

    /// The setting the row binds, when it binds one.
    public var key: SettingsKey? {
        guard case .setting(let key) = subject else { return nil }
        return key
    }

    /// The credential the row binds, when it binds one.
    public var credential: CredentialField? {
        guard case .credential(let field) = subject else { return nil }
        return field
    }

    /// The action the row performs, when it performs one.
    public var action: PreferenceAction? {
        guard case .action(let action) = subject else { return nil }
        return action
    }

    /// The names of the values a choice offers, empty for any other kind.
    public var choiceNames: [String] {
        switch kind {
        case .intChoice(let values):
            return values.map { $0.name }
        case .stringChoice(let values):
            return values.map { $0.name }
        case .decimalChoice(let values):
            return values.map { PreferencesModel.distanceName(kilometres: $0) }
        default:
            return []
        }
    }

    /// The stored forms of the values a choice offers, empty for any other kind.
    public var choiceValues: [String] {
        switch kind {
        case .intChoice(let values):
            return values.map { String($0.value) }
        case .stringChoice(let values):
            return values.map { $0.value }
        case .decimalChoice(let values):
            return values.map { SettingsValueFormatter.string(kilometres: $0) }
        default:
            return []
        }
    }
}

/// One section of the settings screen.
public struct PreferenceCategory: Equatable {
    /// A stable identifier for the category, used by the settings reference.
    public let id: String
    /// The section header shown to the user.
    public let title: String
    /// The rows the section contains, in display order.
    public let items: [PreferenceItem]

    public init(id: String, title: String, items: [PreferenceItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

/// The declarative description of the settings screen.
///
/// The screen renders this description, the settings reference is checked
/// against it, and the settings export validates against it, so the three cannot
/// disagree about which settings exist or what they accept.
public enum PreferencesModel {

    /// The sections the settings screen shows, in display order.
    public static var categories: [PreferenceCategory] {
        return [map, animation, dataSource, location, alarm, generic, backup]
    }

    /// Every setting the screen offers, in display order.
    public static var keys: [SettingsKey] {
        return categories.flatMap { $0.items.compactMap { $0.key } }
    }

    // MARK: - Categories

    static var map: PreferenceCategory {
        return PreferenceCategory(id: "map",
                                  title: categoryTitle("map", "Map settings section"),
                                  items: [
            item(.mapMode),
            item(.mapFade),
            item(.colorScheme),
            item(.showOwnLocation),
            item(.ownLocationSize),
            item(.keepZoomOnCenter),
        ])
    }

    static var animation: PreferenceCategory {
        return PreferenceCategory(id: "animation",
                                  title: categoryTitle("animation", "Animation settings section"),
                                  items: [
            item(.animationStepDuration),
            item(.animationCyclePause),
        ])
    }

    static var dataSource: PreferenceCategory {
        return PreferenceCategory(id: "data-source",
                                  title: categoryTitle("datasource", "Data source settings section"),
                                  items: [
            item(.dataSource),
            item(.serviceEndpoint),
            item(.region),
            item(.intervalDuration),
            item(.historicTimestep),
            item(.username),
            item(.password),
        ])
    }

    static var location: PreferenceCategory {
        return PreferenceCategory(id: "location",
                                  title: categoryTitle("location", "Location settings section"),
                                  items: [
            item(.locationMode),
            item(.manualLatitude),
            item(.manualLongitude),
        ])
    }

    static var alarm: PreferenceCategory {
        return PreferenceCategory(id: "alarm",
                                  title: categoryTitle("alarm", "Alarm settings section"),
                                  items: [
            item(.alertEnabled),
            item(.backgroundQueryPeriod),
            item(.notificationDistanceLimit),
            item(.signalingDistanceLimit),
            item(.alertSoundSignal),
            item(.alertVibrationSignal),
            item(.signalingSuppressionTime),
        ])
    }

    static var generic: PreferenceCategory {
        return PreferenceCategory(id: "generic",
                                  title: categoryTitle("generic", "Generic settings section"),
                                  items: [
            item(.measurementUnit),
            item(.keepScreenAwake),
            item(.diagnosticsEnabled),
        ])
    }

    static var backup: PreferenceCategory {
        return PreferenceCategory(id: "backup",
                                  title: categoryTitle("backup", "Backup settings section"),
                                  items: [
            PreferenceItem(title: NSLocalizedString("settings.backup.export",
                                                    comment: "Export settings action"),
                           subject: .action(.export),
                           kind: .button),
            PreferenceItem(title: NSLocalizedString("settings.backup.import",
                                                    comment: "Import settings action"),
                           subject: .action(.importSettings),
                           kind: .button),
            PreferenceItem(title: NSLocalizedString("settings.backup.reset",
                                                    comment: "Reset settings action"),
                           subject: .action(.reset),
                           kind: .button),
        ])
    }

    // MARK: - Items

    /// The row for a setting, with the kind and value set the key carries.
    static func item(_ key: SettingsKey) -> PreferenceItem {
        return PreferenceItem(title: itemTitle(key), subject: .setting(key), kind: kind(for: key))
    }

    static func item(_ credential: CredentialField) -> PreferenceItem {
        switch credential {
        case .username:
            return PreferenceItem(title: NSLocalizedString("settings.username",
                                                           comment: "Label for the username field"),
                                  subject: .credential(.username),
                                  kind: .text)
        case .password:
            return PreferenceItem(title: NSLocalizedString("settings.password",
                                                           comment: "Label for the password field"),
                                  subject: .credential(.password),
                                  kind: .password)
        }
    }

    /// The kind a setting's value is edited with.
    public static func kind(for key: SettingsKey) -> PreferenceKind {
        switch key {
        case .mapMode:
            return .stringChoice(mapModeChoices)
        case .mapFade:
            return .intSlider(minimum: 0, maximum: 100)
        case .colorScheme:
            return .stringChoice(colorSchemeChoices)
        case .showOwnLocation, .keepZoomOnCenter, .alertEnabled, .keepScreenAwake,
             .diagnosticsEnabled:
            return .toggle
        case .ownLocationSize:
            return .intSlider(minimum: OwnLocationMarker.minimumSizePercent,
                              maximum: OwnLocationMarker.maximumSizePercent)
        case .animationStepDuration:
            return .intChoice(SelectableSettings.animationStepDurations)
        case .animationCyclePause:
            return .intChoice(SelectableSettings.animationCyclePauses)
        case .dataSource:
            return .stringChoice(dataSourceChoices)
        case .serviceEndpoint, .alertSoundSignal:
            return .text
        case .region, .intervalDuration, .historicTimestep, .backgroundQueryPeriod:
            return .intChoice(SelectableSettings.values(for: key) ?? [])
        case .locationMode:
            return .stringChoice(locationModeChoices)
        case .measurementUnit:
            return .stringChoice(measurementUnitChoices)
        case .manualLatitude, .manualLongitude:
            return .decimal
        case .notificationDistanceLimit, .signalingDistanceLimit:
            return .decimalChoice(AlertSettingsValues.distanceLimits)
        case .signalingSuppressionTime:
            return .decimalChoice(AlertSettingsValues.suppressionTimes)
        case .alertVibrationSignal:
            return .intSlider(minimum: 0, maximum: AlertSettingsValues.maximumVibrationStrength)
        case .manualLocationSet, .backgroundLocationDisclosureShown,
             .lastNotifiedStrikeTimestamp, .lastSignalledStrikeTimestamp:
            // Internal bookkeeping has no row; the screen never asks for its kind.
            return .text
        }
    }

    /// The sections' names keyed by the stable category identifier.
    static func categoryTitle(_ suffix: String, _ comment: String) -> String {
        return NSLocalizedString("settings.category.\(suffix)", comment: comment)
    }

    static func itemTitle(_ key: SettingsKey) -> String {
        return NSLocalizedString("settings.item.\(key.rawValue)", comment: "Label for a setting")
    }

    static var mapModeChoices: [StringChoiceValue] {
        return ["hybrid", "satellite", "standard"].map {
            StringChoiceValue(value: $0,
                              name: NSLocalizedString("settings.mapmode.\($0)", comment: "Map type name"))
        }
    }

    static var colorSchemeChoices: [StringChoiceValue] {
        return ColorScheme.allCases.map {
            StringChoiceValue(value: $0.rawValue,
                              name: NSLocalizedString("settings.scheme.\($0.rawValue.lowercased())",
                                                      comment: "Colour scheme name"))
        }
    }

    static var dataSourceChoices: [StringChoiceValue] {
        return DataProviderType.allCases.map {
            StringChoiceValue(value: $0.rawValue,
                              name: NSLocalizedString("settings.source.\($0.rawValue)",
                                                      comment: "Data source name"))
        }
    }

    static var locationModeChoices: [StringChoiceValue] {
        return LocationMode.allCases.map {
            StringChoiceValue(value: $0.rawValue,
                              name: NSLocalizedString("settings.locationmode.\($0.rawValue)",
                                                      comment: "Location mode name"))
        }
    }

    static var measurementUnitChoices: [StringChoiceValue] {
        return MeasurementUnit.allCases.map {
            StringChoiceValue(value: $0.rawValue,
                              name: NSLocalizedString("settings.unit.\($0.rawValue)",
                                                      comment: "Measurement unit name"))
        }
    }

    /// The name a distance limit is shown under.
    static func distanceName(kilometres: Double) -> String {
        guard kilometres > 0 else {
            return NSLocalizedString("settings.distance.off", comment: "Distance limit: off")
        }
        return String(format: NSLocalizedString("settings.distance.km",
                                                comment: "Distance limit in kilometres, e.g. 50 km"),
                      Int(kilometres))
    }

    /// The default a setting is documented and shown with, as text.
    public static func documentedDefault(for key: SettingsKey) -> String {
        return SettingsValueFormatter.string(value: SettingsKey.defaultValues[key.rawValue])
    }

    /// Whether the kind offers a fixed set of values to choose from.
    public static func isChoice(_ kind: PreferenceKind) -> Bool {
        switch kind {
        case .intChoice, .decimalChoice, .stringChoice:
            return true
        default:
            return false
        }
    }

    /// The stored forms a choice accepts, empty for a kind without a set.
    public static func allowedValues(for kind: PreferenceKind) -> [String] {
        switch kind {
        case .intChoice(let values):
            return values.map { String($0.value) }
        case .stringChoice(let values):
            return values.map { $0.value }
        case .decimalChoice(let values):
            return values.map { SettingsValueFormatter.string(kilometres: $0) }
        default:
            return []
        }
    }
}

/// Renders a setting's value, or a distance, as the text the reference and the
/// export both use.
public enum SettingsValueFormatter {

    /// A stored value - string, integer, decimal, or boolean - as text.
    public static func string(value: Any?) -> String {
        switch value {
        case let value as String:
            return value
        case let value as Bool:
            return value ? "true" : "false"
        case let value as Int:
            return String(value)
        case let value as Double:
            return string(kilometres: value)
        default:
            return ""
        }
    }

    /// A decimal distance in kilometres, without a trailing `.0` for a whole
    /// number, so `50.0` reads `50` and `0.5` keeps its fraction.
    public static func string(kilometres: Double) -> String {
        if kilometres == kilometres.rounded() {
            return String(Int(kilometres))
        }
        return String(kilometres)
    }
}
