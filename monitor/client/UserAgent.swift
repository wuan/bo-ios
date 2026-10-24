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

/// Identifies the app to a data source.
///
/// The value is composed from the app's build number so every provider sends
/// the same identifier and no code change is needed when the build number
/// changes. This mirrors the Android client, which sends
/// `bo-android-<version code>`.
public struct UserAgent: Equatable {

    /// The client prefix shared by all providers.
    public static let prefix = "bo-ios"
    /// The HTTP header field the identifier is sent in.
    public static let headerField = "User-Agent"

    /// The header value, e.g. `bo-ios-42`.
    public let value: String

    /// Creates a user agent from an explicit build number.
    ///
    /// When the build number is missing or empty the plain prefix is used.
    public init(buildNumber: String?) {
        if let buildNumber = buildNumber, !buildNumber.isEmpty {
            value = "\(Self.prefix)-\(buildNumber)"
        } else {
            value = Self.prefix
        }
    }

    /// Creates a user agent from a bundle's build number (`CFBundleVersion`).
    public init(bundle: Bundle = .main) {
        self.init(buildNumber: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
    }

    /// Applies the identifier to a request.
    public func apply(to request: inout URLRequest) {
        request.setValue(value, forHTTPHeaderField: Self.headerField)
    }
}
