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

/// Where the version available from the store comes from.
///
/// The seam keeps the update check testable: the information screen asks a
/// provider, and tests inject one that answers with stubbed version data and no
/// network.
public protocol AvailableVersionProviding {
    /// Asks for the version the store offers, calling back with `nil` when it
    /// cannot be determined.
    func availableVersion(completion: @escaping (String?) -> Void)
}

/// Looks the available version up through the App Store lookup API.
public struct AppStoreVersionLookup: AvailableVersionProviding {

    /// The App Store lookup endpoint.
    public static let endpoint = "https://itunes.apple.com/lookup"

    private let bundleIdentifier: String
    private let session: URLSession

    public init(bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "",
                session: URLSession = .shared) {
        self.bundleIdentifier = bundleIdentifier
        self.session = session
    }

    /// Queries the lookup API by bundle id and decodes the offered version.
    ///
    /// The request is best-effort: any failure - an unreachable store, an
    /// unreadable answer, or no listing for the bundle id - yields `nil`, so the
    /// caller stays silent rather than guessing.
    public func availableVersion(completion: @escaping (String?) -> Void) {
        guard !bundleIdentifier.isEmpty,
              var components = URLComponents(string: AppStoreVersionLookup.endpoint) else {
            completion(nil)
            return
        }
        components.queryItems = [URLQueryItem(name: "bundleId", value: bundleIdentifier)]
        guard let url = components.url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { data, _, _ in
            let version = data.flatMap { AppStoreVersionLookup.decode(data: $0) }
            DispatchQueue.main.async {
                completion(version)
            }
        }.resume()
    }

    /// Decodes the offered version from a lookup response, if there is one.
    static func decode(data: Data) -> String? {
        struct Response: Decodable {
            let results: [Entry]

            struct Entry: Decodable {
                let version: String?
            }
        }

        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            return nil
        }
        return response.results.first?.version
    }
}
