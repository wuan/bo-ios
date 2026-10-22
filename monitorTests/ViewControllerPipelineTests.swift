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

/// Provider that returns a fixed result.
private final class FixedProvider: DataProvider {
    var result: Result?
    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        completion(result, nil)
    }
}

@MainActor
final class ViewControllerPipelineTests: XCTestCase {

    func testRendersStrikesDeliveredByPipeline() async {
        let grid = GridParameters(longitudeStart: -10.0,
                                  longitudeDelta: 1.0,
                                  longitudeCount: 20,
                                  latitudeStart: 55.0,
                                  latitudeDelta: 1.0,
                                  latitudeCount: 20)
        let strike = Strike(timestamp: 100,
                            andMultiplicity: 2,
                            andX: 0.0,
                            andY: 50.0,
                            andWidth: 1.0,
                            andHeight: 1.0)
        let result = Result(parameters: Parameters(),
                            referenceTimestamp: 100,
                            strikes: [strike],
                            rasterParameters: grid)

        let provider = FixedProvider()
        provider.result = result
        let handler = DataHandler(provider: provider)

        let controller = ViewController(dataHandler: handler)
        controller.loadViewIfNeeded()

        handler.requestData(parameters: Parameters())
        await waitUntil { controller.mapView.overlays.count > 0 }

        XCTAssertGreaterThanOrEqual(controller.mapView.overlays.count, 1)
    }

    func testIgnoresAResultForASupersededSelection() async {
        let strike = Strike(timestamp: 100, andMultiplicity: 1, andX: 0.0, andY: 50.0)
        let result = Result(parameters: Parameters(intervalOffset: -60),
                            referenceTimestamp: 100,
                            strikes: [strike],
                            rasterParameters: nil)

        let provider = FixedProvider()
        provider.result = result
        let handler = DataHandler(provider: provider)

        let controller = ViewController(dataHandler: handler)
        controller.loadViewIfNeeded()
        XCTAssertEqual(controller.timeModel.interval.offset, 0)

        handler.requestData(parameters: Parameters(intervalOffset: -60))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(controller.mapView.overlays.count, 0)
    }

    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
