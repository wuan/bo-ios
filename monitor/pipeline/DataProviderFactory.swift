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

/// A selectable data source.
public enum DataProviderType: String, CaseIterable {
    case rpc
    case http
}

/// Built-in endpoints used when no override is configured.
public enum DataProviderDefaults {

    public static let rpcEndpoint = "http://bo-test.tryb.de"
    public static let httpEndpoint = "http://data.blitzortung.org/Data/Protected"

    /// The built-in endpoint for a source.
    public static func endpoint(for type: DataProviderType) -> String {
        switch type {
        case .rpc:
            return rpcEndpoint
        case .http:
            return httpEndpoint
        }
    }
}

/// Creates the provider for a selected source and endpoint.
public final class DataProviderFactory {

    private let userAgent: UserAgent
    private let credentialStore: CredentialStore
    private let transport: HttpTransport

    public init(userAgent: UserAgent = UserAgent(),
                credentialStore: CredentialStore = KeychainCredentialStore(),
                transport: HttpTransport = URLSessionHttpTransport()) {
        self.userAgent = userAgent
        self.credentialStore = credentialStore
        self.transport = transport
    }

    /// The endpoint to use: the override when it is a usable URL, otherwise the
    /// source's default.
    ///
    /// A user-editable override can contain anything, so an unusable value falls
    /// back to the default rather than reaching a provider.
    public static func resolvedEndpoint(for type: DataProviderType, override: String) -> String {
        let trimmed = override.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUsableEndpoint(trimmed) else {
            return DataProviderDefaults.endpoint(for: type)
        }
        return trimmed
    }

    /// Whether a value can be used as a service endpoint: an absolute URL with a
    /// scheme and a host.
    public static func isUsableEndpoint(_ value: String) -> Bool {
        guard !value.isEmpty,
              let url = URL(string: value),
              let scheme = url.scheme, !scheme.isEmpty,
              let host = url.host, !host.isEmpty else {
            return false
        }
        return true
    }

    /// The endpoint to use for `type` given the current override value.
    public func endpoint(for type: DataProviderType, override: String) -> String {
        return Self.resolvedEndpoint(for: type, override: override)
    }

    /// Builds the provider for a source and endpoint override.
    public func makeProvider(type: DataProviderType, endpointOverride: String) -> DataProvider {
        let endpoint = endpoint(for: type, override: endpointOverride)
        switch type {
        case .rpc:
            return JsonRpcDataProvider(serviceEndpoint: endpoint, userAgent: userAgent)
        case .http:
            return BlitzortungHttpDataProvider(endpoint: endpoint,
                                               transport: transport,
                                               credentialStore: credentialStore,
                                               userAgent: userAgent)
        }
    }
}
