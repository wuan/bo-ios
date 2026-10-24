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

public extension SettingsStore {

    /// The background query period in seconds; zero is off.
    ///
    /// A stored value outside the offered set falls back to off, so a period
    /// written from outside the app cannot start background work.
    var backgroundQueryPeriod: Int {
        let stored = int(for: .backgroundQueryPeriod)
        guard SelectableSettings.backgroundQueryPeriods.contains(where: { $0.value == stored }) else {
            return SelectableSettings.defaultBackgroundQueryPeriod
        }
        return stored
    }

    /// Whether background monitoring should run.
    ///
    /// Alerts alone do not start background work: the user opts into the
    /// cadence by setting a non-off period, matching the reference client.
    var backgroundMonitoringEnabled: Bool {
        return alertsEnabled && backgroundQueryPeriod > 0
    }
}
