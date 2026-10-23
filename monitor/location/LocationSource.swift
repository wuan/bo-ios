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

import CoreGraphics
import Foundation

/// How the current location is determined.
///
/// Manual takes the position from coordinates the user sets; the device-backed
/// modes take it from the device, in the mode's own way.
public enum LocationMode: String, CaseIterable {
    /// The position comes from coordinates the user sets.
    case manual
    /// The position comes from the device's network-based location.
    case network
    /// The position comes from the device's GPS.
    case gps
    /// The position comes from updates the device produces for others.
    case passive

    /// Whether the mode needs the device rather than stored coordinates.
    public var isDeviceBacked: Bool {
        return self != .manual
    }
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
    /// A stored value that names no known mode falls back to manual, which needs
    /// no permission and is what a fresh install starts in.
    var locationMode: LocationMode {
        return LocationMode(rawValue: string(for: .locationMode)) ?? .manual
    }

    /// Whether the own-location marker is drawn while a location is known.
    var showOwnLocation: Bool {
        return bool(for: .showOwnLocation)
    }

    /// The own-location marker's diameter in points, from the stored percentage.
    ///
    /// The percentage is clamped to the settable range, so a value written from
    /// outside the app cannot draw an invisible or absurd marker.
    var ownLocationDiameter: CGFloat {
        return OwnLocationMarker.diameter(percent: int(for: .ownLocationSize))
    }

    /// Whether centring on the location keeps the map's current zoom level.
    var keepZoomOnCenter: Bool {
        return bool(for: .keepZoomOnCenter)
    }
}
