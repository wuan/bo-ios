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

final class GridGatingTests: XCTestCase {

    private final class CapturingProvider: DataProvider {
        let capabilities: DataProviderCapabilities
        private(set) var received: [Parameters] = []

        init(capabilities: DataProviderCapabilities) {
            self.capabilities = capabilities
        }

        func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
            received.append(parameters)
            completion(nil, nil)
        }
    }

    private let gridCapable = DataProviderCapabilities(supportsGrid: true, supportsClusters: true)
    private let nonGrid = DataProviderCapabilities(supportsGrid: false, supportsClusters: false)

    func testNonGridSourceCarriesNoGridSizeOrThreshold() {
        let parameters = Parameters(rasterBaselength: 5000, countThreshold: 4)

        let gated = parameters.gatingGrid(on: nonGrid)

        XCTAssertEqual(gated.rasterBaselength, 0)
        XCTAssertFalse(gated.isRaster())
        XCTAssertEqual(gated.countThreshold, 0)
    }

    func testGridSourceKeepsTheGridSize() {
        let parameters = Parameters(rasterBaselength: 5000, countThreshold: 4)

        XCTAssertEqual(parameters.gatingGrid(on: gridCapable), parameters)
    }

    func testNonGridSourceIssuesNoGridRequest() {
        let provider = CapturingProvider(capabilities: nonGrid)
        let parameters = Parameters(rasterBaselength: 5000).gatingGrid(on: provider.capabilities)

        provider.fetchData(parameters: parameters) { _, _ in }

        XCTAssertEqual(provider.received.map { $0.rasterBaselength }, [0])
    }

    func testGridCapableSourceIssuesTheGridSize() {
        let provider = CapturingProvider(capabilities: gridCapable)
        let parameters = Parameters(rasterBaselength: 5000).gatingGrid(on: provider.capabilities)

        provider.fetchData(parameters: parameters) { _, _ in }

        XCTAssertEqual(provider.received.map { $0.rasterBaselength }, [5000])
    }
}
