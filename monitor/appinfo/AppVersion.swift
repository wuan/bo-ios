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

/// The version the app is installed as.
///
/// The marketing version (`CFBundleShortVersionString`) and the build number
/// (`CFBundleVersion`) are read from the bundle, so the information screen and
/// the update check report what the App Store would.
public struct AppVersion: Equatable {

    /// The marketing version, e.g. `1.0`.
    public let marketing: String
    /// The build number, e.g. `1`.
    public let build: String

    public init(marketing: String, build: String) {
        self.marketing = marketing
        self.build = build
    }

    /// Reads the version from the given bundle.
    public static func read(bundle: Bundle = .main) -> AppVersion {
        return AppVersion(marketing: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                          build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")
    }

    /// The version shown to the user, including the build when one is known.
    public var displayText: String {
        return build.isEmpty ? marketing : "\(marketing) (\(build))"
    }
}

/// What an update check concluded.
public enum UpdateOutcome: Equatable {
    /// A newer version is available; the associated value is the store's version.
    case updateAvailable(String)
    /// The installed version is the newest available.
    case upToDate
    /// The available version could not be determined.
    case unknown
}

/// Compares the installed version with the version available from the store.
///
/// The comparison is numeric per version component, so `1.10` is newer than
/// `1.9`. Anything that is not a dotted number - a missing or malformed
/// available version - is `unknown`, never a false "update".
public enum UpdateCheck {

    public static func evaluate(installed: String, available: String?) -> UpdateOutcome {
        guard let available = available?.trimmingCharacters(in: .whitespaces),
              !available.isEmpty,
              let candidate = VersionNumber(available),
              let current = VersionNumber(installed) else {
            return .unknown
        }

        switch candidate.compare(to: current) {
        case .orderedDescending:
            return .updateAvailable(available)
        default:
            return .upToDate
        }
    }
}

/// A dotted numeric version, compared component by component.
struct VersionNumber: Equatable {

    let components: [Int]

    /// Parses a dotted version. Returns `nil` unless every component is a
    /// non-negative integer, so a non-numeric string never parses.
    init?(_ text: String) {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }

        var values: [Int] = []
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard let value = Int(trimmed), value >= 0 else { return nil }
            values.append(value)
        }
        self.components = values
    }

    /// Orders two versions, treating a missing component as zero so `1.0`
    /// equals `1.0.0`.
    func compare(to other: VersionNumber) -> ComparisonResult {
        let count = max(components.count, other.components.count)
        for index in 0..<count {
            let lhs = index < components.count ? components[index] : 0
            let rhs = index < other.components.count ? other.components[index] : 0
            if lhs != rhs {
                return lhs < rhs ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }
}
