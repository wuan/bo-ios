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

/// What the app tells a device location manager to do.
///
/// The delegate reports positions in the app's own `Location` type and the
/// authorisation changes, so a device source can be exercised without a real
/// location manager and without the device permissions.
public protocol LocationManagerDelegate: AnyObject {

    /// The authorisation state changed, so updates may now be allowed.
    func managerDidChangeAuthorization(_ manager: LocationManaging)

    /// The manager produced a new position.
    func manager(_ manager: LocationManaging, didUpdate location: Location)
}

/// The slice of `CLLocationManager` the device source uses.
public protocol LocationManaging: AnyObject {

    /// The current authorisation state for this app.
    var authorizationStatus: CLAuthorizationStatus { get }

    /// The accuracy the manager is asked for.
    var desiredAccuracy: CLLocationAccuracy { get set }

    /// The last position the manager produced, or `nil` before one arrives.
    var location: Location? { get }

    /// The object told about authorisation changes and positions.
    var delegate: LocationManagerDelegate? { get set }

    /// Asks for permission to use the location while the app is in use.
    func requestWhenInUseAuthorization()

    /// Asks for permission to use the location in the background as well.
    func requestAlwaysAuthorization()

    /// Starts continuous position updates.
    func startUpdatingLocation()

    /// Stops continuous position updates.
    func stopUpdatingLocation()

    /// Starts position updates the device produces for other apps.
    func startMonitoringSignificantLocationChanges()

    /// Stops significant-change updates.
    func stopMonitoringSignificantLocationChanges()
}

/// The device location manager, behind ``LocationManaging``.
///
/// Translates CoreLocation's positions into the app's own type, so the device
/// source itself deals in `Location` alone.
public final class CoreLocationManager: NSObject, LocationManaging, CLLocationManagerDelegate {

    private let manager: CLLocationManager

    public init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.delegate = self
    }

    public var authorizationStatus: CLAuthorizationStatus {
        return manager.authorizationStatus
    }

    public var desiredAccuracy: CLLocationAccuracy {
        get { return manager.desiredAccuracy }
        set { manager.desiredAccuracy = newValue }
    }

    /// The last position the device reported.
    public private(set) var location: Location?

    public weak var delegate: LocationManagerDelegate?

    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    public func startMonitoringSignificantLocationChanges() {
        manager.startMonitoringSignificantLocationChanges()
    }

    public func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.managerDidChangeAuthorization(self)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.location = location
        delegate?.manager(self, didUpdate: location)
    }
}
