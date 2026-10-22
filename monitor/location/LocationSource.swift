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

/// How the current location is determined.
///
/// Only the manual path ships with the map chrome; the device-backed modes
/// (network, GPS, passive) arrive with the location phase behind the same seam
/// and the same setting.
public enum LocationMode: String, CaseIterable {
    /// The position comes from coordinates the user sets.
    case manual
}

/// A location source whose position the user can set directly.
///
/// The map's long press is the manual mode's mechanism; a device-backed source
/// added later is not settable and simply does not adopt it.
public protocol SettableLocationSource: LocationSource {
    /// Sets the current location, replacing any previous position.
    func setLocation(_ location: Location)
}

/// The notifications a ``LocationSource`` posts.
public enum LocationSourceNotification {
    /// Posted whenever the current location changes, with the source as object.
    public static let didChange = Notification.Name("LocationSource.didChange")
}

/// Supplies the current location and publishes changes to it.
///
/// Consumers - the alarm radar, the own-location marker, and centring - depend
/// on this seam rather than on how the position was obtained, so the location
/// phase can add device-backed implementations without reworking them.
public protocol LocationSource: AnyObject {

    /// The current location, or `nil` when no location is known.
    var location: Location? { get }

    /// Registers `block` to run whenever the location changes and returns a
    /// token that can be passed to ``removeObserver(_:)``.
    @discardableResult
    func observe(_ block: @escaping () -> Void) -> NSObjectProtocol

    /// Stops delivering updates for a token returned by ``observe(_:)``.
    func removeObserver(_ token: NSObjectProtocol)
}

public extension LocationSource {

    @discardableResult
    func observe(_ block: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: LocationSourceNotification.didChange,
                                                      object: self,
                                                      queue: nil) { _ in
            block()
        }
    }

    func removeObserver(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }

    /// Announces a location change to observers of this source.
    func publishLocationChange() {
        NotificationCenter.default.post(name: LocationSourceNotification.didChange, object: self)
    }
}

public extension SettingsStore {
    /// The stored location mode.
    ///
    /// A stored value that names no known mode falls back to manual, which is
    /// the only mode this phase ships.
    var locationMode: LocationMode {
        return LocationMode(rawValue: string(for: .locationMode)) ?? .manual
    }
}
