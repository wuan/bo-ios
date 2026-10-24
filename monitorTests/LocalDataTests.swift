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

final class LocalDataTests: XCTestCase {

    /// Center (50, 10), spans 6 x 8: quantizes to a 5-degree area at (2, 10).
    private let extent = ViewExtent(center: Location(latitude: 50, longitude: 10),
                                    latitudeSpan: 6,
                                    longitudeSpan: 8)

    func testLocalCoordinateRoundsTowardsNegativeInfinity() {
        XCTAssertEqual(LocalData.localCoordinate(10, scale: 5), 2)
        XCTAssertEqual(LocalData.localCoordinate(0, scale: 5), 0)
        XCTAssertEqual(LocalData.localCoordinate(-1, scale: 5), -1)
    }

    func testDataAreaScaleQuantizesToTheFinestStep() {
        XCTAssertEqual(LocalData.dataAreaScale(for: extent), 5)

        let medium = ViewExtent(center: Location(latitude: 50, longitude: 10),
                                latitudeSpan: 20,
                                longitudeSpan: 30)
        XCTAssertEqual(LocalData.dataAreaScale(for: medium), 15)
    }

    func testDataAreaIsNilWhenTheExtentIsTooLarge() {
        let large = ViewExtent(center: Location(latitude: 50, longitude: 10),
                               latitudeSpan: 80,
                               longitudeSpan: 100)
        XCTAssertNil(LocalData.dataAreaScale(for: large))
        XCTAssertNil(LocalData.dataArea(for: large))
    }

    func testDataAreaIsDerivedFromTheExtent() {
        XCTAssertEqual(LocalData.dataArea(for: extent), DataArea(x: 2, y: 10, scale: 5))
    }

    func testGridSizeIsChosenFromTheExtent() {
        XCTAssertEqual(LocalData.gridSize(for: span(2)), 5000)
        XCTAssertEqual(LocalData.gridSize(for: span(10)), 10000)
        XCTAssertEqual(LocalData.gridSize(for: span(30)), 25000)
        XCTAssertEqual(LocalData.gridSize(for: span(60)), 50000)
    }

    func testGridSizeIsCoarsestForAnExtentTooLargeForALocalArea() {
        let large = span(100)
        XCTAssertNil(LocalData.dataArea(for: large))
        XCTAssertEqual(LocalData.gridSize(for: large), 100000)
    }

    func testLocalRegionUsesTheDerivedArea() {
        var localData = LocalData()
        localData.update(extent: extent)

        let parameters = localData.updateParameters(Parameters(region: Parameters.localRegion))

        XCTAssertTrue(parameters.isLocal)
        XCTAssertEqual(parameters.dataArea, DataArea(x: 2, y: 10, scale: 5))
    }

    func testLocalRegionWithoutAnAreaFallsBackToGlobal() {
        let localData = LocalData()

        let parameters = localData.updateParameters(Parameters(region: Parameters.localRegion))

        XCTAssertTrue(parameters.isGlobal)
        XCTAssertNil(parameters.dataArea)
        XCTAssertEqual(parameters.rasterBaselength, LocalData.localRegionGridSizeThreshold)
    }

    func testGlobalRegionWithAFineGridSwitchesToLocal() {
        var localData = LocalData()
        localData.update(extent: extent)

        let parameters = localData.updateParameters(Parameters(region: Parameters.globalRegion,
                                                               rasterBaselength: 5000))

        XCTAssertTrue(parameters.isLocal)
        XCTAssertEqual(parameters.dataArea, DataArea(x: 2, y: 10, scale: 5))
    }

    func testGlobalRegionWithACoarseGridStaysGlobal() {
        var localData = LocalData()
        localData.update(extent: extent)

        let parameters = localData.updateParameters(Parameters(region: Parameters.globalRegion,
                                                               rasterBaselength: 50000))

        XCTAssertTrue(parameters.isGlobal)
        XCTAssertNil(parameters.dataArea)
        XCTAssertEqual(parameters.rasterBaselength, 50000)
    }

    func testGlobalRegionRaisesAFineGridToTheThreshold() {
        let localData = LocalData()

        let parameters = localData.updateParameters(Parameters(region: Parameters.globalRegion,
                                                               rasterBaselength: 5000))

        XCTAssertTrue(parameters.isGlobal)
        XCTAssertEqual(parameters.rasterBaselength, LocalData.localRegionGridSizeThreshold)
    }

    func testOtherRegionsPassThroughUnchanged() {
        let localData = LocalData()
        let input = Parameters(region: 1, rasterBaselength: 10000)

        XCTAssertEqual(localData.updateParameters(input), input)
    }

    func testUpdateReportsWhenTheAreaChanges() {
        var localData = LocalData()

        XCTAssertTrue(localData.update(extent: extent))
        XCTAssertFalse(localData.update(extent: extent))

        let moved = ViewExtent(center: Location(latitude: 50, longitude: 60),
                               latitudeSpan: 6,
                               longitudeSpan: 8)
        XCTAssertTrue(localData.update(extent: moved))
    }

    func testUpdateCanBeForced() {
        var localData = LocalData()
        localData.update(extent: extent)

        XCTAssertTrue(localData.update(extent: extent, force: true))
    }

    func testUpdateLeavesAStoredNonGlobalGridWhenTheAreaIsUnchanged() {
        var localData = LocalData()
        localData.update(extent: extent)
        localData.store(gridParameters: GridParameters(longitudeStart: 0,
                                                       longitudeDelta: 0.1,
                                                       longitudeCount: 10,
                                                       latitudeStart: 60,
                                                       latitudeDelta: 0.1,
                                                       latitudeCount: 10))

        XCTAssertFalse(localData.update(extent: extent))
    }

    private func span(_ degrees: Double) -> ViewExtent {
        return ViewExtent(center: Location(latitude: 0, longitude: 0),
                          latitudeSpan: degrees,
                          longitudeSpan: degrees)
    }
}
