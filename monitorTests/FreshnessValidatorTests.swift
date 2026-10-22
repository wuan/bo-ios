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

    private let realtime = Parameters(intervalOffset: 0)
    private let history = Parameters(intervalOffset: -30)

    func testFirstResultIsAccepted() {
        XCTAssertTrue(FreshnessValidator().accept(referenceTimestamp: 100, for: realtime))
    }

    func testNewerResultIsAcceptedForTheSameSelection() {
        let validator = FreshnessValidator()

        XCTAssertTrue(validator.accept(referenceTimestamp: 100, for: realtime))
        XCTAssertTrue(validator.accept(referenceTimestamp: 200, for: realtime))

        XCTAssertEqual(validator.lastAccepted(for: realtime), 200)
    }

    func testOlderResultIsRejectedForTheSameSelection() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200, for: realtime))

        XCTAssertFalse(validator.accept(referenceTimestamp: 100, for: realtime))
        XCTAssertEqual(validator.lastAccepted(for: realtime), 200)
    }

    func testEqualResultIsRejectedForTheSameSelection() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200, for: realtime))

        XCTAssertFalse(validator.accept(referenceTimestamp: 200, for: realtime))
    }

    func testOlderResultForADifferentSelectionIsAccepted() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200, for: realtime))

        XCTAssertTrue(validator.accept(referenceTimestamp: 100, for: history))
        XCTAssertEqual(validator.lastAccepted(for: history), 100)
        XCTAssertEqual(validator.lastAccepted(for: realtime), 200)
    }

    func testResetAllowsAnOlderResult() {
        let validator = FreshnessValidator()
        XCTAssertTrue(validator.accept(referenceTimestamp: 200, for: realtime))

        validator.reset()

        XCTAssertNil(validator.lastAccepted(for: realtime))
        XCTAssertTrue(validator.accept(referenceTimestamp: 100, for: realtime))
    }
}
