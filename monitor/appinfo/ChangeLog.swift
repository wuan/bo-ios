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

import Foundation

/// One released version and the changes it carried.
public struct ChangeLogEntry: Equatable {
    /// The version heading, exactly as the change log writes it.
    public let version: String
    /// The change bullets for the version, in file order.
    public let changes: [String]

    public init(version: String, changes: [String]) {
        self.version = version
        self.changes = changes
    }
}

/// The app's change log, parsed from the bundled `CHANGELOG.md`.
///
/// The file lists releases newest first: one `## <version>` heading per release
/// followed by `- ` bullets. Prose outside a heading and headings without a
/// bullet contribute nothing, so a missing or entryless file yields no entries
/// rather than failing.
public enum ChangeLog {

    /// The bundled resource's name and extension.
    public static let resourceName = "CHANGELOG"
    public static let resourceExtension = "md"

    /// Parses change-log text into its entries, in file order (newest first).
    public static func parse(_ text: String) -> [ChangeLogEntry] {
        var entries: [ChangeLogEntry] = []
        var version: String?
        var changes: [String] = []

        func record() {
            if let version = version, !changes.isEmpty {
                entries.append(ChangeLogEntry(version: version, changes: changes))
            }
            version = nil
            changes = []
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                // A heading starts the next release; the previous one is complete.
                record()
                version = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if version != nil, line.hasPrefix("- ") || line.hasPrefix("* ") {
                changes.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
            }
        }
        record()

        return entries
    }

    /// Loads and parses the bundled change log, or returns no entries when the
    /// resource is missing or unreadable.
    public static func load(bundle: Bundle = .main) -> [ChangeLogEntry] {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parse(text)
    }
}
