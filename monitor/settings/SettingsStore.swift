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

/// Reads and writes typed application settings backed by `UserDefaults`.
///
/// Every setting has a registered default, so reading an unset setting returns
/// its default rather than a zero value. Changes are announced through
/// ``SettingsStore/didChangeNotification``; use ``observe(_:using:)`` to react to
/// a single setting and ``removeObserver(_:)`` to stop.
public final class SettingsStore {

    /// Posted whenever a setting changes. The changed key is stored under
    /// ``SettingsStore/changedKeyUserInfoKey`` in the notification's user info.
    public static let didChangeNotification = Notification.Name("SettingsStore.didChange")
    public static let changedKeyUserInfoKey = "key"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: SettingsKey.defaultValues)
    }

    // MARK: - Typed access

    public func string(for key: SettingsKey) -> String {
        return defaults.string(forKey: key.rawValue) ?? (SettingsKey.defaultValues[key.rawValue] as? String ?? "")
    }

    public func int(for key: SettingsKey) -> Int {
        return defaults.integer(forKey: key.rawValue)
    }

    public func double(for key: SettingsKey) -> Double {
        return defaults.double(forKey: key.rawValue)
    }

    public func bool(for key: SettingsKey) -> Bool {
        return defaults.bool(forKey: key.rawValue)
    }

    /// Stores a value and notifies observers of the change.
    public func set(_ value: Any, for key: SettingsKey) {
        defaults.set(value, forKey: key.rawValue)
        postChange(for: key)
    }

    // MARK: - Selectable settings

    /// The value of a setting restricted to a fixed set of values.
    ///
    /// A stored value outside the setting's set is treated as unset and the
    /// registered default is returned, so a stale or externally written value
    /// cannot take effect.
    public func choice(for key: SettingsKey) -> Int {
        let stored = defaults.integer(forKey: key.rawValue)
        guard SelectableSettings.values(for: key) != nil,
              !SelectableSettings.allows(stored, for: key) else {
            return stored
        }
        return SettingsKey.defaultValues[key.rawValue] as? Int ?? stored
    }

    /// Stores `value` for a setting restricted to a fixed set of values and
    /// notifies observers of the change.
    ///
    /// - Returns: whether the value was accepted. A value outside the setting's
    ///   set is rejected and nothing changes.
    @discardableResult
    public func setChoice(_ value: Int, for key: SettingsKey) -> Bool {
        guard SelectableSettings.allows(value, for: key) else { return false }
        defaults.set(value, forKey: key.rawValue)
        postChange(for: key)
        return true
    }

    /// Restores every setting to its registered default.
    public func reset() {
        for key in SettingsKey.allCases {
            defaults.removeObject(forKey: key.rawValue)
            postChange(for: key)
        }
    }

    // MARK: - Observation

    /// Registers `block` to run whenever `key` changes and returns a token that
    /// can be passed to ``removeObserver(_:)``.
    @discardableResult
    public func observe(_ key: SettingsKey, using block: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: Self.didChangeNotification,
            object: self,
            queue: nil) { note in
                guard let changed = note.userInfo?[Self.changedKeyUserInfoKey] as? String else { return }
                if changed == key.rawValue {
                    block()
                }
            }
    }

    public func removeObserver(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }

    private func postChange(for key: SettingsKey) {
        NotificationCenter.default.post(
            name: Self.didChangeNotification,
            object: self,
            userInfo: [Self.changedKeyUserInfoKey: key.rawValue])
    }
}
