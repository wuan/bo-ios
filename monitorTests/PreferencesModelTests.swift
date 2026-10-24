/*

 Copyright 2026 Andreas Würl

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

final class PreferencesModelTests: XCTestCase {

    func testTheScreenHasTheSevenCategoriesInOrder() {
        XCTAssertEqual(PreferencesModel.categories.map { $0.id },
                       ["map", "animation", "data-source", "location", "alarm", "generic", "backup"])
    }

    func testEveryCategoryHasATitleAndSettings() {
        for category in PreferencesModel.categories {
            XCTAssertFalse(category.title.isEmpty, "\(category.id) has no title")
            XCTAssertFalse(category.items.isEmpty, "\(category.id) has no settings")
        }
    }

    /// Every user-facing setting appears in exactly one category, and the app's
    /// own bookkeeping appears in none.
    func testEveryUserFacingSettingAppearsExactlyOnce() {
        let keys = PreferencesModel.keys
        XCTAssertEqual(Set(keys), Set(SettingsKey.userFacing),
                       "the screen must offer every user-facing setting")

        for key in keys {
            XCTAssertEqual(keys.filter { $0 == key }.count, 1,
                           "\(key.rawValue) appears in more than one category")
        }

        for key in SettingsKey.internalKeys {
            XCTAssertFalse(keys.contains(key), "\(key.rawValue) is bookkeeping, not a setting")
        }
    }

    func testCategoriesCarryTheSettingsTheyShould() {
        let byCategory = Dictionary(uniqueKeysWithValues: PreferencesModel.categories.map {
            ($0.id, $0.items.compactMap { $0.key })
        })

        XCTAssertEqual(byCategory["map"], [.mapMode, .mapFade, .colorScheme,
                                           .showOwnLocation, .ownLocationSize, .keepZoomOnCenter])
        XCTAssertEqual(byCategory["animation"], [.animationStepDuration, .animationCyclePause])
        XCTAssertEqual(byCategory["data-source"], [.dataSource, .serviceEndpoint, .region,
                                                   .intervalDuration, .historicTimestep])
        XCTAssertEqual(byCategory["location"], [.locationMode, .manualLatitude, .manualLongitude])
        XCTAssertEqual(byCategory["alarm"], [.alertEnabled, .backgroundQueryPeriod,
                                             .notificationDistanceLimit, .signalingDistanceLimit,
                                             .alertSoundSignal, .alertVibrationSignal,
                                             .signalingSuppressionTime])
        XCTAssertEqual(byCategory["generic"], [.measurementUnit, .keepScreenAwake, .diagnosticsEnabled])
        XCTAssertEqual(byCategory["backup"], [])
    }

    func testTheCredentialFieldsAreOfferedForTheDataSource() {
        let credentials = PreferencesModel.dataSource.items.compactMap { $0.credential }
        XCTAssertEqual(credentials, [.username, .password])
    }

    func testTheBackupCategoryOffersExportImportAndReset() {
        let actions = PreferencesModel.backup.items.compactMap { $0.action }
        XCTAssertEqual(actions, [.export, .importSettings, .reset])
    }

    /// A choice offers the values its store accepts, and nothing else does.
    func testChoicesOfferTheStoredValueSets() {
        for item in PreferencesModel.categories.flatMap({ $0.items }) {
            guard let key = item.key else { continue }
            switch item.kind {
            case .intChoice:
                XCTAssertEqual(item.choiceValues,
                               SelectableSettings.values(for: key)?.map { String($0.value) } ?? [],
                               "\(key.rawValue) offers the wrong values")
            case .stringChoice:
                XCTAssertFalse(item.choiceValues.isEmpty, "\(key.rawValue) offers no values")
            case .decimalChoice:
                XCTAssertFalse(item.choiceValues.isEmpty, "\(key.rawValue) offers no values")
            default:
                XCTAssertTrue(item.choiceValues.isEmpty, "\(key.rawValue) should not offer a value set")
            }
        }
    }

    func testChoiceNamesAndValuesAreBothPresent() {
        for item in PreferencesModel.categories.flatMap({ $0.items }) where !item.choiceValues.isEmpty {
            XCTAssertEqual(item.choiceNames.count, item.choiceValues.count,
                           "\(item.title) has a value without a name")
            for name in item.choiceNames {
                XCTAssertFalse(name.isEmpty, "\(item.title) has an unnamed value")
            }
        }
    }

    func testDocumentedDefaultsComeFromTheStoredValues() {
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .mapMode), "hybrid")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .measurementUnit), "metric")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .mapFade), "55")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .animationStepDuration), "1")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .notificationDistanceLimit), "50")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .showOwnLocation), "true")
        XCTAssertEqual(PreferencesModel.documentedDefault(for: .keepScreenAwake), "false")
    }
}
