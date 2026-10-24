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

/// A settings value as it travels in an export document.
///
/// JSON has four scalar types, and the setting's ``SettingsStorage`` says which
/// one a value must be, so an import can reject a document that carries a
/// string where a number belongs.
public enum SettingsValue: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

extension SettingsValue: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "unsupported settings value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }

    /// The stored form of the value, as the settings reference writes it.
    public var text: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return SettingsValueFormatter.string(kilometres: value)
        case .bool(let value):
            return value ? "true" : "false"
        }
    }
}

/// The portable representation of the app's settings.
public struct PreferencesDocument: Codable, Equatable {

    /// The document layout the app writes and accepts.
    public static let currentVersion = 1

    /// The document layout's version.
    public var version: Int
    /// The user-facing settings, keyed by ``SettingsKey/rawValue``.
    public var settings: [String: SettingsValue]
    /// The credentials, present only when the user opted to include them.
    public var credentials: ExportedCredentials?

    /// Credentials carried by an export.
    public struct ExportedCredentials: Codable, Equatable {
        public var username: String
        public var password: String

        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }

    public init(version: Int = PreferencesDocument.currentVersion,
                settings: [String: SettingsValue],
                credentials: ExportedCredentials? = nil) {
        self.version = version
        self.settings = settings
        self.credentials = credentials
    }
}

/// Why an import was refused.
public enum PreferencesBackupError: Error, Equatable {
    /// The document names a setting the app does not have.
    case unknownSetting(String)
    /// The document's value is not the type the setting stores.
    case wrongType(String)
    /// The document's value is outside the setting's accepted set.
    case valueNotAllowed(String)
    /// The document was written by a different layout.
    case unsupportedVersion(Int)
    /// The document could not be read at all.
    case unreadable
}

/// Exports, imports, and resets the app's settings.
///
/// An export carries the user-facing settings only: the app's own bookkeeping
/// stays behind, and credentials are included only when the caller asks, so a
/// document cannot quietly move secrets to another install. An import validates
/// the whole document before it applies anything, so a document with one bad
/// value changes nothing.
public enum PreferencesBackup {

    // MARK: - Export

    /// The document describing the settings currently in effect.
    public static func export(settings: SettingsStore,
                              credentials: Credentials? = nil,
                              includeCredentials: Bool = false) -> PreferencesDocument {
        var values: [String: SettingsValue] = [:]
        for key in SettingsKey.userFacing {
            values[key.rawValue] = value(for: key, in: settings)
        }

        var exported: PreferencesDocument.ExportedCredentials?
        if includeCredentials, let credentials = credentials {
            exported = .init(username: credentials.username, password: credentials.password)
        }

        return PreferencesDocument(version: PreferencesDocument.currentVersion,
                                   settings: values,
                                   credentials: exported)
    }

    /// Encodes a document as the JSON an export writes.
    public static func encode(_ document: PreferencesDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    /// Reads a document from JSON.
    ///
    /// - Throws: ``PreferencesBackupError/unreadable`` when the data is not a
    ///   document this app can read.
    public static func decode(_ data: Data) throws -> PreferencesDocument {
        do {
            return try JSONDecoder().decode(PreferencesDocument.self, from: data)
        } catch {
            throw PreferencesBackupError.unreadable
        }
    }

    // MARK: - Import

    /// Validates a document and applies it.
    ///
    /// Every value is checked before any is applied, so a document that names an
    /// unknown setting, carries the wrong type, offers a value outside the
    /// setting's set, or was written by a different layout changes nothing.
    public static func apply(_ document: PreferencesDocument,
                             to settings: SettingsStore,
                             credentialStore: CredentialStore) throws {
        guard document.version == PreferencesDocument.currentVersion else {
            throw PreferencesBackupError.unsupportedVersion(document.version)
        }

        for (rawKey, value) in document.settings {
            guard let key = SettingsKey(rawValue: rawKey), key.isUserFacing else {
                throw PreferencesBackupError.unknownSetting(rawKey)
            }
            try validate(value, for: key)
        }

        for (rawKey, value) in document.settings {
            guard let key = SettingsKey(rawValue: rawKey) else { continue }
            try apply(value, for: key, to: settings)
        }

        if let credentials = document.credentials {
            credentialStore.save(Credentials(username: credentials.username,
                                             password: credentials.password))
        }
    }

    // MARK: - Reset

    /// Restores the user-facing settings to their defaults.
    ///
    /// Credentials live in the Keychain rather than in the settings, so they are
    /// left alone; the diagnostics ring is cleared with the settings it belongs
    /// to. The manual location is forgotten first, so resetting with alerts on
    /// cannot look like a location appearing and ask for notification
    /// authorisation.
    public static func reset(settings: SettingsStore, log: AppLog? = nil) {
        settings.set(false, for: .manualLocationSet)
        settings.reset()
        log?.clear()
    }

    // MARK: - Values

    /// The value the store currently holds for a setting.
    static func value(for key: SettingsKey, in settings: SettingsStore) -> SettingsValue {
        switch key.storage {
        case .string:
            return .string(settings.string(for: key))
        case .int:
            return .int(settings.choice(for: key))
        case .double:
            return .double(settings.double(for: key))
        case .bool:
            return .bool(settings.bool(for: key))
        }
    }

    static func validate(_ value: SettingsValue, for key: SettingsKey) throws {
        switch (key.storage, value) {
        case (.string, .string(let text)):
            try validateChoice(text, for: key)

        case (.int, .int(let number)):
            switch PreferencesModel.kind(for: key) {
            case .intChoice(let values):
                guard values.contains(where: { $0.value == number }) else {
                    throw PreferencesBackupError.valueNotAllowed(key.rawValue)
                }
            case .intSlider(let minimum, let maximum):
                guard (minimum...maximum).contains(number) else {
                    throw PreferencesBackupError.valueNotAllowed(key.rawValue)
                }
            default:
                break
            }

        case (.double, .int(let number)):
            try validateDecimal(Double(number), for: key)

        case (.double, .double(let number)):
            try validateDecimal(number, for: key)

        case (.bool, .bool):
            break

        default:
            throw PreferencesBackupError.wrongType(key.rawValue)
        }
    }

    /// A string-valued setting is checked against its choice, when it has one.
    static func validateChoice(_ text: String, for key: SettingsKey) throws {
        guard case .stringChoice(let values) = PreferencesModel.kind(for: key) else { return }
        guard values.contains(where: { $0.value == text }) else {
            throw PreferencesBackupError.valueNotAllowed(key.rawValue)
        }
    }

    /// A decimal-valued setting is checked against its set, when it has one.
    static func validateDecimal(_ number: Double, for key: SettingsKey) throws {
        guard case .decimalChoice(let values) = PreferencesModel.kind(for: key) else { return }
        guard values.contains(number) else {
            throw PreferencesBackupError.valueNotAllowed(key.rawValue)
        }
    }

    static func apply(_ value: SettingsValue, for key: SettingsKey, to settings: SettingsStore) throws {
        switch value {
        case .string(let text):
            settings.set(text, for: key)
        case .int(let number):
            if SelectableSettings.values(for: key) != nil {
                settings.setChoice(number, for: key)
            } else {
                settings.set(number, for: key)
            }
        case .double(let number):
            settings.set(number, for: key)
        case .bool(let flag):
            settings.set(flag, for: key)
        }
    }
}
