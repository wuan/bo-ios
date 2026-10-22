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

final class DataCacheTests: XCTestCase {

    private func makeResult(timestamp: Int = 100) -> Result {
        return Result(parameters: Parameters(), referenceTimestamp: timestamp, strikes: [], rasterParameters: nil)
    }

    func testDefaultTimeToLiveIsFiveMinutes() {
        XCTAssertEqual(DataCache.defaultTimeToLive, 300)
    }

    func testCacheHitWithinTimeToLive() {
        let cache = DataCache(timeToLive: 300, now: { Date(timeIntervalSince1970: 0) })
        let result = makeResult()
        cache.store(result, for: Parameters())

        XCTAssertNotNil(cache.result(for: Parameters()))
    }

    func testExpiryTriggersAMissAndDiscardsTheEntry() {
        var clock = Date(timeIntervalSince1970: 0)
        let cache = DataCache(timeToLive: 300, now: { clock })
        cache.store(makeResult(), for: Parameters())

        clock = Date(timeIntervalSince1970: 301)

        XCTAssertNil(cache.result(for: Parameters()))
        XCTAssertEqual(cache.count, 0)
    }

    func testDifferingParametersMiss() {
        let cache = DataCache(now: { Date(timeIntervalSince1970: 0) })
        cache.store(makeResult(), for: Parameters(region: 1))

        XCTAssertNil(cache.result(for: Parameters(region: 0)))
        XCTAssertNotNil(cache.result(for: Parameters(region: 1)))
    }

    func testNewStoreReplacesTheEntry() {
        let cache = DataCache(now: { Date(timeIntervalSince1970: 0) })
        cache.store(makeResult(timestamp: 100), for: Parameters())
        cache.store(makeResult(timestamp: 200), for: Parameters())

        XCTAssertEqual(cache.result(for: Parameters())?.referenceTimestamp, 200)
        XCTAssertEqual(cache.count, 1)
    }

    func testClearRemovesEntries() {
        let cache = DataCache(now: { Date(timeIntervalSince1970: 0) })
        cache.store(makeResult(), for: Parameters())

        cache.clear()

        XCTAssertNil(cache.result(for: Parameters()))
        XCTAssertEqual(cache.count, 0)
    }
}
