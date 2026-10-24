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

import XCTest
@testable import monitor

final class CredentialStoreTests: XCTestCase {

    func testDefaultCredentialsAreEmpty() {
        XCTAssertTrue(InMemoryCredentialStore().load().isEmpty)
    }

    func testSaveAndLoadRoundTrip() {
        let store = InMemoryCredentialStore()
        let credentials = Credentials(username: "alice", password: "s3cret")

        store.save(credentials)

        XCTAssertEqual(store.load(), credentials)
    }

    func testClearRemovesCredentials() {
        let store = InMemoryCredentialStore()
        store.save(Credentials(username: "alice", password: "s3cret"))

        store.clear()

        XCTAssertEqual(store.load(), Credentials())
        XCTAssertTrue(store.load().isEmpty)
    }

    func testCredentialsAreNotStoredInUserDefaults() {
        let suiteName = "CredentialStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = InMemoryCredentialStore()
        store.save(Credentials(username: "alice", password: "s3cret"))

        let dumped = defaults.dictionaryRepresentation().values
            .map { "\($0)" }
            .joined(separator: "|")

        XCTAssertFalse(dumped.contains("alice"))
        XCTAssertFalse(dumped.contains("s3cret"))
    }
}
