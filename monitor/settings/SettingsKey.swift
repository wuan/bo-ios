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

/// Identifies a persisted application setting.
///
/// Every case must have an entry in ``SettingsKey/defaultValues``; a unit test
/// enforces this so later phases cannot add a setting without a default.
public enum SettingsKey: String, CaseIterable {
    case mapMode
    case dataSource
    case serviceEndpoint
    case measurementUnit
    case alertEnabled
    case mapScale
    case mapFade

    /// Values used when a setting has never been changed by the user.
    public static var defaultValues: [String: Any] {
        return [
            SettingsKey.mapMode.rawValue: "hybrid",
            SettingsKey.dataSource.rawValue: "rpc",
            SettingsKey.serviceEndpoint.rawValue: "",
            SettingsKey.measurementUnit.rawValue: "metric",
            SettingsKey.alertEnabled.rawValue: true,
            SettingsKey.mapScale.rawValue: 75,
            SettingsKey.mapFade.rawValue: 55,
        ]
    }
}
