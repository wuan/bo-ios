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

/// A location source whose position the user sets and the app persists.
///
/// This is the manual path: the position comes from coordinates the user picks
/// on the map and needs no location permission, so the alarm radar, the
/// own-location marker, and centring all work on a fresh install once a
/// position has been set.
public final class ManualLocationSource: SettableLocationSource {

    private let settings: SettingsStore

    public init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }

    /// The stored location mode, which selects this source while manual mode is
    /// active.
    public var mode: LocationMode {
        return settings.locationMode
    }

    /// The persisted position, or `nil` until one has been set.
    public var location: Location? {
        guard settings.bool(for: .manualLocationSet) else { return nil }
        return Location(latitude: settings.double(for: .manualLatitude),
                        longitude: settings.double(for: .manualLongitude))
    }

    /// Sets the current location, replacing any previous position.
    ///
    /// Observers are notified once, and only when the position actually
    /// changed.
    public func setLocation(_ location: Location) {
        guard location != self.location else { return }
        settings.set(location.latitude, for: .manualLatitude)
        settings.set(location.longitude, for: .manualLongitude)
        settings.set(true, for: .manualLocationSet)
        publishLocationChange()
    }
}
