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

import XCTest
@testable import monitor

final class LocalizationTests: XCTestCase {

    func testBaseCatalogResolvesStatusKeys() {
        let unavailable = NSLocalizedString("status.unavailable", bundle: .main, comment: "")
        XCTAssertEqual(unavailable, "n/a")

        let strikeCount = NSLocalizedString("status.strikeCount", bundle: .main, comment: "")
        XCTAssertNotEqual(strikeCount, "status.strikeCount", "status.strikeCount did not resolve")
        XCTAssertTrue(strikeCount.contains("strikes"))

        let countdown = NSLocalizedString("status.refreshCountdown", bundle: .main, comment: "")
        XCTAssertNotEqual(countdown, "status.refreshCountdown", "status.refreshCountdown did not resolve")
    }

    func testUnknownKeyFallsBackToKey() {
        let value = NSLocalizedString("status.doesNotExist", bundle: .main, comment: "")
        XCTAssertEqual(value, "status.doesNotExist")
    }

    func testBaseCatalogResolvesSettingsKeys() {
        for key in ["settings.title", "settings.source", "settings.endpoint",
                    "settings.username", "settings.password", "settings.save",
                    "settings.close"] {
            let value = NSLocalizedString(key, bundle: .main, comment: "")
            XCTAssertNotEqual(value, key, "\(key) did not resolve")
        }
    }

    /// Every string the application menu and the information surfaces show
    /// resolves from the catalog, so no literal key is left in the interface.
    func testBaseCatalogResolvesAppInformationKeys() {
        var keys = ["menu.open", "menu.cancel", "realtime.goto",
                    "appinfo.close", "appinfo.name", "appinfo.copyright",
                    "appinfo.update.available", "appinfo.update.uptodate",
                    "appinfo.log.title", "appinfo.log.empty", "appinfo.log.send",
                    "appinfo.changelog.title", "appinfo.changelog.empty"]
        // A menu entry's identifier is also the key its title resolves from.
        keys += AppMenuEntry.allCases.map { $0.accessibilityIdentifier }

        for key in keys {
            let value = NSLocalizedString(key, bundle: .main, comment: "")
            XCTAssertNotEqual(value, key, "\(key) did not resolve")
        }

        for entry in AppMenuEntry.allCases {
            XCTAssertFalse(entry.title.hasPrefix("menu."),
                           "\(entry.rawValue) shows its unresolved key")
        }
    }

    /// Every label the settings screen shows resolves from the catalog, so no
    /// literal key is left in the interface.
    func testTheSettingsScreenLabelsResolve() {
        for category in PreferencesModel.categories {
            XCTAssertFalse(category.title.hasPrefix("settings."),
                           "\(category.id) shows the unresolved key '\(category.title)'")
            for item in category.items {
                XCTAssertFalse(item.title.hasPrefix("settings."),
                               "a row shows the unresolved key '\(item.title)'")
            }
        }
    }

    /// iOS ignores a location request whose usage description is missing, so a
    /// device mode would silently never prompt. Both keys have to be there.
    func testLocationUsageDescriptionsAreDeclared() {
        for key in ["NSLocationWhenInUseUsageDescription",
                    "NSLocationAlwaysAndWhenInUseUsageDescription"] {
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
            XCTAssertNotNil(value, "\(key) is missing from the app's Info.plist")
            XCTAssertFalse(value?.isEmpty ?? true, "\(key) is empty")
        }
    }
}
