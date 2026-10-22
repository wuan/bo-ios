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

/// Fetches raw bytes for a provider over HTTP.
///
/// Kept behind a protocol so providers can be tested without a network and so
/// credentials are attached in exactly one place.
public protocol HttpTransport {
    /// Performs a GET, invoking `completion` with the body or an error.
    ///
    /// - Parameters:
    ///   - url: The resource to fetch.
    ///   - credentials: Credentials to send, or `nil`/empty to send none.
    ///   - userAgent: The client identifier to send.
    func get(url: URL, credentials: Credentials?, userAgent: UserAgent, completion: @escaping (Data?, Error?) -> Void)
}

/// The default ``HttpTransport``, built on `URLSession`.
public final class URLSessionHttpTransport: HttpTransport {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(url: URL, credentials: Credentials?, userAgent: UserAgent, completion: @escaping (Data?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        userAgent.apply(to: &request)

        if let credentials = credentials, !credentials.isEmpty {
            let raw = "\(credentials.username):\(credentials.password)"
            let encoded = Data(raw.utf8).base64EncodedString()
            request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        }

        session.dataTask(with: request) { data, _, error in
            completion(data, error)
        }.resume()
    }
}
