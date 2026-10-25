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

/// What the information screen shows.
///
/// The content is built from the installed version and the update outcome, so
/// the screen's text can be asserted without presenting it.
public struct InformationContent: Equatable {

    /// The project's home on the web.
    public static let projectURL = "https://github.com/wuan/bo-ios"

    /// The app's name.
    public let name: String
    /// The installed version, including the build.
    public let version: String
    /// The project home.
    public let project: String
    /// The copyright line.
    public let copyright: String
    /// The update outcome, or `nil` when it is unknown and nothing is shown.
    public let update: String?

    public init(name: String, version: String, project: String, copyright: String, update: String?) {
        self.name = name
        self.version = version
        self.project = project
        self.copyright = copyright
        self.update = update
    }

    /// Builds the content for an installed version and an update outcome.
    public static func make(version: AppVersion, outcome: UpdateOutcome) -> InformationContent {
        return InformationContent(name: NSLocalizedString("appinfo.name",
                                                          comment: "The app's name on the information screen"),
                                  version: version.displayText,
                                  project: projectURL,
                                  copyright: NSLocalizedString("appinfo.copyright",
                                                               comment: "The copyright line on the information screen"),
                                  update: updateText(for: outcome))
    }

    /// The line describing an update outcome, or `nil` for an unknown one.
    public static func updateText(for outcome: UpdateOutcome) -> String? {
        switch outcome {
        case .updateAvailable(let available):
            return String(format: NSLocalizedString("appinfo.update.available",
                                                    comment: "Update available, e.g. Update available: 1.1"),
                          available)
        case .upToDate:
            return NSLocalizedString("appinfo.update.uptodate",
                                     comment: "The installed version is the newest")
        case .unknown:
            return nil
        }
    }
}
