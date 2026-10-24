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

/// Builds the location source the active mode needs.
///
/// Manual mode keeps the persisted coordinates and needs no permission; a
/// device mode gets its own manager, so exactly one source is asking the device
/// for positions at a time.
public struct LocationSourceFactory {

    private let managerFactory: () -> LocationManaging

    public init(managerFactory: @escaping () -> LocationManaging = { CoreLocationManager() }) {
        self.managerFactory = managerFactory
    }

    /// The source serving `mode`.
    public func makeSource(for mode: LocationMode, settings: SettingsStore = SettingsStore()) -> LocationSource {
        guard mode.isDeviceBacked else {
            return ManualLocationSource(settings: settings)
        }
        return DeviceLocationSource(mode: mode, manager: managerFactory())
    }
}
