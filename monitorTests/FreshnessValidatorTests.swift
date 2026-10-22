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

final class FreshnessValidatorTests: XCTestCase {

    func testFirstResultIsAccepted() {
        XCTAssertTrue(FreshnessValidator().accept(referenceTimestamp: 100))
    }

    func testNewerResultIsAccepted() {
        let validator = FreshnessValidator()

        XCTAssertTrue(validator.accept(referenceTimestamp: 100))
        XCTAssertTrue(validator.accept(referenceTimestamp: 200))

        XCTAssertEqual(validator.lastAccepted, 200)
    }

    func testOlderResultIsRejected() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200))

        XCTAssertFalse(validator.accept(referenceTimestamp: 100))
        XCTAssertEqual(validator.lastAccepted, 200)
    }

    func testEqualResultIsRejected() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200))

        XCTAssertFalse(validator.accept(referenceTimestamp: 200))
    }

    func testResetAllowsAnOlderResult() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200))

        validator.reset()

        XCTAssertNil(validator.lastAccepted)
        XCTAssertTrue(validator.accept(referenceTimestamp: 100))
    }
}
