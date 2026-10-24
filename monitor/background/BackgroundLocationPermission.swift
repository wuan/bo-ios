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
import Foundation

/// Requests the background location authorisation monitoring needs.
///
/// Only a device-backed mode asks, and only once the background-location
/// explanation has been acknowledged - the same gate the foreground uses, so
/// the permission is never requested before the user has been told what it is
/// for. A manual location needs no permission, so monitoring still runs on a
/// fresh install with a hand-set position.
public struct BackgroundLocationPermission {

    private let disclosure: BackgroundLocationDisclosure

    public init(settings: SettingsStore = SettingsStore()) {
        self.disclosure = BackgroundLocationDisclosure(settings: settings)
    }

    /// Whether the background-location explanation still has to be presented.
    public var isDue: Bool {
        return disclosure.isDue
    }

    /// Records that the user has seen and acknowledged the explanation.
    public func acknowledge() {
        disclosure.acknowledge()
    }

    /// Requests background authorisation when the mode needs it and it is not
    /// already held.
    ///
    /// - Parameters:
    ///   - mode: the active location mode; a manual mode asks for nothing.
    ///   - manager: the device location manager to request through.
    ///   - disclosing: presents the explanation while it is still due.
    /// - Returns: whether the request ran, i.e. the explanation had been
    ///   acknowledged (or was never due).
    @discardableResult
    public func request(for mode: LocationMode,
                        manager: LocationManaging,
                        disclosing: () -> Void) -> Bool {
        guard mode.isDeviceBacked else { return false }
        guard manager.authorizationStatus != .authorizedAlways else { return true }
        return disclosure.request(disclosing: disclosing) {
            manager.requestAlwaysAuthorization()
        }
    }
}
