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

/// The application log, rendered for display and for sharing.
///
/// The screen lists ``lines`` and the send action shares ``text``; keeping the
/// rendering pure lets the ordering, the timestamp format, and the empty state
/// be asserted without a view.
public struct ApplicationLogContent: Equatable {

    /// One display line per recorded entry, oldest first.
    public let lines: [String]
    /// Whether nothing has been recorded.
    public var isEmpty: Bool {
        return lines.isEmpty
    }
    /// The whole log as one text, for the send-for-support action.
    public var text: String {
        return lines.joined(separator: "\n")
    }

    public init(lines: [String]) {
        self.lines = lines
    }

    /// Builds the content from recorded entries, oldest first.
    public static func make(entries: [AppLogEntry],
                            formatter: DateFormatter = ApplicationLogContent.timestampFormatter) -> ApplicationLogContent {
        let lines = entries.map { "\(formatter.string(from: $0.date))  \($0.message)" }
        return ApplicationLogContent(lines: lines)
    }

    /// The timestamp every line starts with, e.g. `2026-10-24 19:50:55`.
    public static var timestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
}
