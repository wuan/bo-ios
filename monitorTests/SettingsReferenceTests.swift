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

/// Checks the settings reference against the code.
///
/// The document is the one users read, so it is parsed as written rather than
/// rebuilt from the model: a setting the code adds, a default the code changes,
/// or a value set that drifts fails here instead of silently disagreeing.
final class SettingsReferenceTests: XCTestCase {

    private struct Row {
        let category: String
        let name: String
        let kind: String
        let values: String
        let documentedDefault: String
    }

    private static let referenceURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("docs/preferences.md")

    private func referenceRows() throws -> [Row] {
        let text = try String(contentsOf: Self.referenceURL, encoding: .utf8)
        return text.split(separator: "\n", omittingEmptySubsequences: false).compactMap { line in
            guard line.hasPrefix("|") else { return nil }
            let cells = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count == 7 else { return nil }
            let columns = Array(cells[1..<6])

            // The header and the dashed separator are not settings.
            if columns[1] == "Setting" || columns[1].allSatisfy({ $0 == "-" }) {
                return nil
            }

            return Row(category: columns[0],
                       name: columns[1],
                       kind: columns[2],
                       values: columns[3],
                       documentedDefault: columns[4] == "(empty)" ? "" : columns[4])
        }
    }

    private func category(of key: SettingsKey) -> String? {
        return PreferencesModel.categories.first { category in
            category.items.contains { $0.key == key }
        }?.id
    }

    func testTheReferenceListsEveryUserFacingSettingExactlyOnce() throws {
        let rows = try referenceRows()
        let documented = rows.map { $0.name }
        let expected = SettingsKey.userFacing.map { $0.rawValue }

        XCTAssertEqual(Set(documented).count, documented.count,
                       "a setting is documented more than once")
        for key in expected {
            XCTAssertTrue(documented.contains(key), "\(key) is missing from docs/preferences.md")
        }
        for name in documented where !expected.contains(name) {
            XCTAssertTrue(PreferenceAction(rawValue: name) != nil || CredentialField(rawValue: name) != nil,
                          "docs/preferences.md documents \(name), which is not a setting")
        }
    }

    func testEveryDocumentedSettingSitsInItsModelCategory() throws {
        for row in try referenceRows() {
            guard let key = SettingsKey(rawValue: row.name) else { continue }
            XCTAssertEqual(row.category, category(of: key),
                           "\(row.name) is documented under the wrong category")
        }
    }

    func testDocumentedDefaultsMatchTheCode() throws {
        for row in try referenceRows() {
            guard let key = SettingsKey(rawValue: row.name) else { continue }
            XCTAssertEqual(row.documentedDefault, PreferencesModel.documentedDefault(for: key),
                           "the documented default for \(row.name) has drifted from the code")
        }
    }

    func testDocumentedValueSetsMatchTheCode() throws {
        for row in try referenceRows() {
            guard let key = SettingsKey(rawValue: row.name) else { continue }
            let kind = PreferencesModel.kind(for: key)
            let expected = PreferencesModel.allowedValues(for: kind).joined(separator: ", ")
            if PreferencesModel.isChoice(kind) {
                XCTAssertEqual(row.values, expected,
                               "the documented values for \(row.name) have drifted from the code")
            } else {
                XCTAssertEqual(row.values, "-",
                               "\(row.name) is not a choice, so it documents no value set")
            }
        }
    }

    func testEveryCategoryAndActionIsDocumented() throws {
        let rows = try referenceRows()
        for category in PreferencesModel.categories {
            XCTAssertTrue(rows.contains { $0.category == category.id },
                          "\(category.id) is missing from docs/preferences.md")
        }
        for action in PreferenceAction.allCases {
            XCTAssertTrue(rows.contains { $0.name == action.rawValue },
                          "\(action.rawValue) is missing from docs/preferences.md")
        }
    }

    func testTheReferenceRecordsTheRemovedSetting() throws {
        let text = try String(contentsOf: Self.referenceURL, encoding: .utf8)
        XCTAssertTrue(text.contains("mapScale"), "the removed mapScale setting is not recorded")
    }
}
