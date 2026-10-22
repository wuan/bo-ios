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
import Security

/// Credentials for a data source that requires authentication.
public struct Credentials: Equatable {
    public let username: String
    public let password: String

    public init(username: String = "", password: String = "") {
        self.username = username
        self.password = password
    }

    /// Whether no credentials have been configured.
    public var isEmpty: Bool {
        return username.isEmpty && password.isEmpty
    }
}

/// Stores the credentials used by authenticated data sources.
///
/// Secrets are deliberately kept out of the settings store (`UserDefaults`),
/// matching the security intent of the parity roadmap rather than Android's
/// plain-preferences storage.
public protocol CredentialStore {
    /// Returns the stored credentials, or empty credentials when none are set.
    func load() -> Credentials
    /// Persists the given credentials.
    func save(_ credentials: Credentials)
    /// Removes any stored credentials.
    func clear()
}

/// Keychain-backed credential store used by the app.
public final class KeychainCredentialStore: CredentialStore {

    private let service: String
    private let account: String

    public init(service: String = "net.wuerl.blitzortung.monitor", account: String = "data-providers") {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    public func load() -> Credentials {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let stored = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            return Credentials()
        }
        return Credentials(username: stored.username, password: stored.password)
    }

    public func save(_ credentials: Credentials) {
        guard let data = try? JSONEncoder().encode(StoredCredentials(username: credentials.username,
                                                                      password: credentials.password)) else {
            return
        }

        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var insertQuery = baseQuery
            insertQuery[kSecValueData as String] = data
            insertQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insertQuery as CFDictionary, nil)
        }
    }

    public func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}

/// In-memory credential store used by tests.
public final class InMemoryCredentialStore: CredentialStore {

    private var credentials: Credentials

    public init(credentials: Credentials = Credentials()) {
        self.credentials = credentials
    }

    public func load() -> Credentials {
        return credentials
    }

    public func save(_ credentials: Credentials) {
        self.credentials = credentials
    }

    public func clear() {
        credentials = Credentials()
    }
}

private struct StoredCredentials: Codable {
    let username: String
    let password: String
}
