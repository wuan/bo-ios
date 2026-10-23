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

import CoreLocation

/// How a device-backed mode asks the device for a position.
public struct DeviceLocationConfiguration: Equatable {

    /// The accuracy the manager is asked for.
    public let accuracy: CLLocationAccuracy
    /// Whether the mode adopts updates the device produces for others, rather
    /// than asking for a stream of its own.
    public let usesSignificantChanges: Bool

    public init(accuracy: CLLocationAccuracy, usesSignificantChanges: Bool) {
        self.accuracy = accuracy
        self.usesSignificantChanges = usesSignificantChanges
    }

    /// The configuration a mode needs, or `nil` for the manual mode, which asks
    /// the device for nothing.
    public static func forMode(_ mode: LocationMode) -> DeviceLocationConfiguration? {
        switch mode {
        case .manual:
            return nil
        case .network:
            return DeviceLocationConfiguration(accuracy: kCLLocationAccuracyKilometer,
                                               usesSignificantChanges: false)
        case .gps:
            return DeviceLocationConfiguration(accuracy: kCLLocationAccuracyBest,
                                               usesSignificantChanges: false)
        case .passive:
            return DeviceLocationConfiguration(accuracy: kCLLocationAccuracyThreeKilometers,
                                               usesSignificantChanges: true)
        }
    }
}

/// Device-backed location: the position comes from the device in the active
/// network, GPS, or passive mode and needs no user-set coordinates.
///
/// Deliberately not a ``SettableLocationSource``: the map's long press has
/// nothing to set here, and the manual coordinates stay as they are, so
/// returning to manual mode restores the position the user picked.
public final class DeviceLocationSource: LocationSource, LocationManagerDelegate {

    /// The mode this source serves.
    public let mode: LocationMode

    private let manager: LocationManaging
    /// The last position the device reported, or `nil` until it reports one.
    public private(set) var location: Location?

    public init(mode: LocationMode, manager: LocationManaging = CoreLocationManager()) {
        self.mode = mode
        self.manager = manager
        manager.delegate = self
        start()
    }

    deinit {
        stop()
    }

    /// Asks for the permission the mode needs and starts the updates it uses.
    ///
    /// A refusal or a restriction leaves the source without a position rather
    /// than failing, so the app carries on with whatever the user set by hand.
    public func start() {
        guard let configuration = DeviceLocationConfiguration.forMode(mode) else { return }
        manager.desiredAccuracy = configuration.accuracy
        startUpdatesIfAuthorized(configuration)
    }

    /// Stops asking the device for positions.
    public func stop() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.delegate = nil
    }

    private func startUpdatesIfAuthorized(_ configuration: DeviceLocationConfiguration) {
        switch manager.authorizationStatus {
        case .notDetermined:
            // The permission has to be asked for before anything can be
            // requested; the updates then start from the authorisation change.
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if configuration.usesSignificantChanges {
                manager.startMonitoringSignificantLocationChanges()
            } else {
                manager.startUpdatingLocation()
            }
        default:
            // Refused or restricted: no device position, no permission request.
            break
        }
    }

    // MARK: - LocationManagerDelegate

    public func managerDidChangeAuthorization(_ manager: LocationManaging) {
        guard let configuration = DeviceLocationConfiguration.forMode(mode) else { return }
        startUpdatesIfAuthorized(configuration)
    }

    /// Adopts a reported position as the current location.
    ///
    /// Observers are notified once, and only when the position actually
    /// changed.
    public func manager(_ manager: LocationManaging, didUpdate location: Location) {
        guard location != self.location else { return }
        self.location = location
        publishLocationChange()
    }
}
