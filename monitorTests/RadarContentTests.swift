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

final class RadarContentTests: XCTestCase {

    private let colorHandler = ColorHandler(scheme: .blitzortung, baseType: .satellite)
    private let location = Location(latitude: 0, longitude: 0)
    private let referenceTime = 1_500_000_000
    private let geometry = AlertGeometry.standard

    private func strike(northKilometres: Double, age: Int) -> Strike {
        return Strike(timestamp: referenceTime - age,
                      andMultiplicity: 1,
                      andX: 0,
                      andY: northKilometres / 111.195)
    }

    private func aggregate(_ strikes: [Strike]?,
                           dataArea: GridParameters? = nil,
                           location: Location? = nil,
                           isRealtime: Bool = true) -> AlertAggregation {
        return AlertAggregator().aggregate(strikes: strikes,
                                           dataArea: dataArea,
                                           location: location ?? self.location,
                                           isRealtime: isRealtime,
                                           referenceTime: referenceTime)
    }

    private func aggregateWithoutLocation(_ strikes: [Strike]?) -> AlertAggregation {
        return AlertAggregator().aggregate(strikes: strikes,
                                           dataArea: nil,
                                           location: nil,
                                           isRealtime: true,
                                           referenceTime: referenceTime)
    }

    private func content(_ aggregation: AlertAggregation,
                         measurementUnit: MeasurementUnit = .metric,
                         intervalDuration: Int = 60) -> RadarContent {
        return RadarContentBuilder.make(aggregation: aggregation,
                                        colorHandler: colorHandler,
                                        intervalDuration: intervalDuration,
                                        measurementUnit: measurementUnit,
                                        referenceTime: referenceTime,
                                        geometry: geometry)
    }

    private func sector(_ content: RadarContent, _ label: String) throws -> RadarSector {
        return try XCTUnwrap(content.sectors.first { $0.direction.label == label })
    }

    // MARK: - Active radar

    func testActiveRadarFillsTheSectorByClosestStrikeAge() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)]))

        XCTAssertEqual(content.state, .active)
        let north = try sector(content, "N")
        XCTAssertTrue(north.isFilled)
        XCTAssertEqual(north.color, colorHandler.color(ageSeconds: 0, intervalDuration: 60))
        XCTAssertEqual(north.ageMinutes, 0)
    }

    /// A strike in the outermost ring must colour only that ring: filling the
    /// whole sector would show activity in every ring inside it.
    func testActivityFarOutFillsOnlyTheOutermostRing() throws {
        let content = self.content(aggregate([strike(northKilometres: 400, age: 0)]))

        let north = try sector(content, "N")
        XCTAssertEqual(north.ringFills.count, geometry.ranges.count, "one fill per ring")
        XCTAssertEqual(north.ringFills[geometry.ranges.count - 1],
                       colorHandler.color(ageSeconds: 0, intervalDuration: 60),
                       "400 km falls in the 250...500 km ring")
        XCTAssertTrue(north.ringFills.dropLast().allSatisfy { $0 == nil },
                      "the inner rings must stay clear")
    }

    /// Activity in an inner ring leaves the rings outside it clear.
    func testActivityNearByLeavesTheOuterRingsClear() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)]))

        let north = try sector(content, "N")
        XCTAssertEqual(north.ringFills.first,
                       colorHandler.color(ageSeconds: 0, intervalDuration: 60),
                       "5 km falls in the innermost ring")
        XCTAssertTrue(north.ringFills.dropFirst().allSatisfy { $0 == nil })
    }

    func testEachRingTakesTheColourOfItsOwnNewestStrike() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0),
                                              strike(northKilometres: 200, age: 5 * 60)]))

        let north = try sector(content, "N")
        XCTAssertEqual(north.ringFills.first,
                       colorHandler.color(ageSeconds: 0, intervalDuration: 60))
        // 200 km falls in the 100...250 km ring, the fifth of six.
        XCTAssertEqual(north.ringFills[4],
                       colorHandler.color(ageSeconds: 5 * 60, intervalDuration: 60))
        XCTAssertNil(north.ringFills[geometry.ranges.count - 1],
                     "the outermost ring holds nothing")
    }

    func testOlderActivityTakesAnOlderColour() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 4 * 60)]))

        XCTAssertEqual(try sector(content, "N").color,
                       colorHandler.color(ageSeconds: 4 * 60, intervalDuration: 60))
    }

    func testSectorsWithoutAStrikeAreNotFilled() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)]))

        XCTAssertFalse(try sector(content, "S").isFilled)
        XCTAssertNil(try sector(content, "S").color)
    }

    func testClosestStrikeSummaryIsShown() throws {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0),
                                              strike(northKilometres: -30, age: 0)]))

        XCTAssertEqual(content.closestStrikeText, "N 5.0 km")
    }

    // MARK: - Empty states

    func testNoLocationState() {
        XCTAssertEqual(self.content(aggregateWithoutLocation([strike(northKilometres: 5, age: 0)])).state,
                       .noLocation)
    }

    func testNoDataState() {
        XCTAssertEqual(self.content(aggregate(nil)).state, .noData)
        XCTAssertEqual(self.content(aggregate([strike(northKilometres: 5, age: 0)],
                                              isRealtime: false)).state,
                       .noData)
    }

    func testOutsideDataAreaState() throws {
        let area = GridParameters(longitudeStart: 10,
                                  longitudeDelta: 0.2,
                                  longitudeCount: 10,
                                  latitudeStart: 50,
                                  latitudeDelta: 0.2,
                                  latitudeCount: 10)
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)],
                                             dataArea: area,
                                             location: Location(latitude: 49.9, longitude: 10.5)))

        XCTAssertEqual(content.state, .outsideDataArea)
        XCTAssertTrue(content.sectors.allSatisfy { !$0.isFilled })
    }

    func testInactiveStateWhenNothingIsInRange() {
        let content = self.content(aggregate([strike(northKilometres: 600, age: 0)]))

        XCTAssertEqual(content.state, .inactive)
        XCTAssertNil(content.closestStrikeText)
        XCTAssertEqual(content.sectors.count, geometry.directions.count)
    }

    func testEmptyStatesStillCarryTheWholeFace() {
        for content in [self.content(aggregate(nil)),
                        self.content(aggregateWithoutLocation([strike(northKilometres: 5, age: 0)]))] {
            XCTAssertEqual(content.sectors.count, 8)
            XCTAssertEqual(content.ringLabels.count, 6)
        }
    }

    // MARK: - Labels

    func testRingLabelsEndAtTheReferenceRings() {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)]))

        XCTAssertEqual(content.ringLabels.map { $0.kilometres }, [10, 25, 50, 100, 250, 500])
        XCTAssertEqual(content.ringLabels.map { $0.text }, ["10", "25", "50", "100", "250", "500"])
        XCTAssertEqual(content.ringLabels.map { $0.isOuter }, [false, false, false, false, false, true])
    }

    func testRingLabelsUseMetricByDefault() {
        let content = self.content(aggregate(nil), measurementUnit: .metric)

        XCTAssertEqual(content.distanceUnit, "km")
    }

    func testRingLabelsUseTheImperialUnit() {
        let content = self.content(aggregate(nil), measurementUnit: .imperial)

        XCTAssertEqual(content.distanceUnit, "mi")
        // 10 km is 6.2 miles, shown as a whole number on the ring.
        XCTAssertEqual(content.ringLabels.first?.text, "6")
        XCTAssertEqual(content.ringLabels.last?.text, "311")
    }

    func testSummaryIsFormattedInTheActiveUnit() {
        let content = self.content(aggregate([strike(northKilometres: 5, age: 0)]),
                                   measurementUnit: .imperial)

        XCTAssertEqual(content.closestStrikeText, "N 3.1 mi")
    }
}
