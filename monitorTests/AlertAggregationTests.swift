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

final class AlertAggregationTests: XCTestCase {

    /// The reference's test geometry: two half-circle sectors and two rings,
    /// the second ending at 5 km.
    private let geometry = AlertGeometry(rangeSteps: [2.5, 5], directionLabels: ["S", "N"])
    private let location = Location(latitude: 0, longitude: 0)
    private let referenceTime = 1_500_000_000

    /// A latitude offset that puts a strike at roughly `kilometres` north of
    /// the location (or south, when negative).
    private func latitudeOffset(forKilometres kilometres: Double) -> Double {
        return kilometres / 111.195
    }

    private func strike(northKilometres: Double = 0,
                        eastKilometres: Double = 0,
                        age: Int = 0,
                        multiplicity: Int = 1,
                        latitudeDelta: Double = 0,
                        longitudeDelta: Double = 0) -> Strike {
        return Strike(timestamp: referenceTime - age,
                      andMultiplicity: multiplicity,
                      andX: latitudeOffset(forKilometres: eastKilometres),
                      andY: latitudeOffset(forKilometres: northKilometres),
                      andWidth: longitudeDelta,
                      andHeight: latitudeDelta)
    }

    private func aggregate(_ strikes: [Strike]?,
                           dataArea: GridParameters? = nil,
                           location: Location? = nil,
                           isRealtime: Bool = true) -> AlertAggregation {
        return AlertAggregator(geometry: geometry).aggregate(strikes: strikes,
                                                             dataArea: dataArea,
                                                             location: location ?? self.location,
                                                             isRealtime: isRealtime,
                                                             referenceTime: referenceTime)
    }

    private func sector(_ activity: AlertActivity, _ label: String) throws -> AlertSectorActivity {
        return try XCTUnwrap(activity.sectors.first { $0.direction.label == label })
    }

    // MARK: - Bucketing (4.2)

    func testActivityIsBucketedByDistanceAndDirection() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2)])

        let activity = try XCTUnwrap(aggregation.activity)
        let north = try sector(activity, "N")
        XCTAssertEqual(north.cells[0].strikeCount, 1)
        XCTAssertEqual(north.cells[1].strikeCount, 0)

        let south = try sector(activity, "S")
        XCTAssertEqual(south.cells[0].strikeCount, 0)
    }

    func testSouthernActivityGoesToTheSouthernSector() throws {
        let aggregation = aggregate([strike(northKilometres: -2.2)])

        let activity = try XCTUnwrap(aggregation.activity)
        let south = try sector(activity, "S")
        XCTAssertEqual(south.cells[0].strikeCount, 1)
        XCTAssertTrue(south.hasActivity)
        XCTAssertFalse(try sector(activity, "N").hasActivity)
    }

    func testMultiplicityIsCounted() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2, multiplicity: 3)])

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertEqual(try sector(activity, "N").cells[0].strikeCount, 3)
    }

    func testClosestStrikeIsKeptPerSector() throws {
        let aggregation = aggregate([strike(northKilometres: 4.4, age: 10),
                                     strike(northKilometres: 2.2, age: 20)])

        let activity = try XCTUnwrap(aggregation.activity)
        let closest = try XCTUnwrap(try sector(activity, "N").closestStrike)
        XCTAssertEqual(closest.distance, 2.2, accuracy: 0.05)
        XCTAssertEqual(closest.age, 20)
    }

    func testEmptySectorReportsNoStrike() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2)])

        let activity = try XCTUnwrap(aggregation.activity)
        let south = try sector(activity, "S")
        XCTAssertNil(south.closestStrike)
        XCTAssertEqual(south.cells[0].strikeCount, 0)
    }

    func testStrikeBeyondTheOutermostRingIsIgnored() throws {
        let aggregation = aggregate([strike(northKilometres: 6.7)])

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertNil(activity.closest)
        XCTAssertFalse(activity.sectors.contains { $0.hasActivity })
    }

    func testStrikeAgeIsMeasuredFromTheReferenceTime() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2, age: 120)])

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertEqual(try XCTUnwrap(try sector(activity, "N").closestStrike).age, 120)
    }

    func testGridCellDistanceUsesThePointNearestTheLocation() throws {
        // A cell centred 1 km north which reaches across the location.
        let cell = Strike(timestamp: referenceTime,
                          andMultiplicity: 1,
                          andX: 0,
                          andY: latitudeOffset(forKilometres: 1.0),
                          andWidth: 0,
                          andHeight: latitudeOffset(forKilometres: 3.0))

        let aggregation = aggregate([cell])

        let activity = try XCTUnwrap(aggregation.activity)
        let closest = try XCTUnwrap(try sector(activity, "N").closestStrike)
        XCTAssertEqual(closest.distance, 0, accuracy: 0.01, "the cell reaches the location")
        XCTAssertEqual(try sector(activity, "N").cells[0].strikeCount, 1)
    }

    func testGridCellAwayFromTheLocationUsesItsNearestEdge() throws {
        // A cell centred 4 km north, 3 km tall, so its nearest point is 2.5 km away.
        let cell = Strike(timestamp: referenceTime,
                          andMultiplicity: 1,
                          andX: 0,
                          andY: latitudeOffset(forKilometres: 4.0),
                          andWidth: 0,
                          andHeight: latitudeOffset(forKilometres: 3.0))

        let aggregation = aggregate([cell])

        let activity = try XCTUnwrap(aggregation.activity)
        let closest = try XCTUnwrap(try sector(activity, "N").closestStrike)
        XCTAssertEqual(closest.distance, 2.5, accuracy: 0.05)
        XCTAssertEqual(try sector(activity, "N").cells[1].strikeCount, 1)
    }

    // MARK: - Alert window (4.3)

    func testTheAlertIntervalIsTenMinutes() {
        XCTAssertEqual(AlertAggregator.alertInterval, 600)
    }

    func testActivityOlderThanTheAlertIntervalIsNotAClosestStrike() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2,
                                            age: AlertAggregator.alertInterval + 1)])

        let activity = try XCTUnwrap(aggregation.activity)
        let north = try sector(activity, "N")
        XCTAssertNil(north.closestStrike, "older activity must not become a closest strike")
        XCTAssertEqual(north.cells[0].strikeCount, 1, "the cell still records it")
        XCTAssertEqual(north.cells[0].latestStrikeTimestamp, referenceTime - AlertAggregator.alertInterval - 1)
    }

    func testActivityInsideTheAlertIntervalIsAClosestStrike() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2,
                                            age: AlertAggregator.alertInterval)])

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertEqual(try XCTUnwrap(try sector(activity, "N").closestStrike).age,
                       AlertAggregator.alertInterval)
    }

    /// The aggregator takes no displayed interval at all, so a longer display
    /// interval cannot widen the window.
    func testTheDisplayedIntervalDoesNotWidenTheWindow() throws {
        let aggregation = aggregate([strike(northKilometres: 2.2, age: 900)])

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertNil(try sector(activity, "N").closestStrike)
    }

    func testNonRealtimeDataYieldsNoActivity() {
        let aggregation = aggregate([strike(northKilometres: 2.2)], isRealtime: false)

        XCTAssertEqual(aggregation, .noData)
    }

    // MARK: - States (4.4)

    func testNoLocationState() {
        let aggregator = AlertAggregator(geometry: geometry)

        let aggregation = aggregator.aggregate(strikes: [strike(northKilometres: 2.2)],
                                               dataArea: nil,
                                               location: nil,
                                               isRealtime: true,
                                               referenceTime: referenceTime)

        XCTAssertEqual(aggregation, .noLocation)
    }

    func testNoDataStateWithoutStrikes() {
        XCTAssertEqual(aggregate(nil), .noData)
    }

    func testOutsideDataAreaState() throws {
        let area = GridParameters(longitudeStart: 10,
                                  longitudeDelta: 0.2,
                                  longitudeCount: 10,
                                  latitudeStart: 50,
                                  latitudeDelta: 0.2,
                                  latitudeCount: 10)

        // Just inside the northern edge, within the inset.
        let edge = Location(latitude: 49.9, longitude: 10.5)
        let outside = aggregate([strike()], dataArea: area, location: edge)
        XCTAssertEqual(outside, .outsideDataArea)

        // Deep inside the area.
        let inside = Location(latitude: 49, longitude: 10.5)
        XCTAssertNotNil(aggregate([strike()], dataArea: area, location: inside).activity)
    }

    func testGlobalDataAreaNeverCountsAsOutlying() {
        let global = GridParameters(longitudeStart: -180,
                                    longitudeDelta: 1,
                                    longitudeCount: 360,
                                    latitudeStart: 90,
                                    latitudeDelta: 1,
                                    latitudeCount: 180)

        let aggregation = aggregate([strike(northKilometres: 2.2)], dataArea: global)

        XCTAssertNotNil(aggregation.activity)
    }

    func testActivityState() {
        let aggregation = aggregate([strike(northKilometres: 2.2)])

        XCTAssertNotNil(aggregation.activity)
    }

    // MARK: - Summary (4.4)

    func testSummaryReportsTheNearestSectorsDirectionAndDistance() throws {
        let aggregation = aggregate([strike(northKilometres: 4.4),
                                     strike(northKilometres: -1.5)])

        let activity = try XCTUnwrap(aggregation.activity)
        let closest = try XCTUnwrap(activity.closest)
        XCTAssertEqual(closest.direction, "S")
        XCTAssertEqual(closest.distance, 1.5, accuracy: 0.05)
        XCTAssertEqual(closest.age, 0)
    }

    func testSummaryReportsNoDistanceWhenNoSectorHasAStrike() throws {
        let activity = try XCTUnwrap(aggregate([strike(northKilometres: 6.7)]).activity)

        XCTAssertNil(activity.closest)
    }

    // MARK: - Complete face (4.5)

    func testAggregationCoversTheWholeRadar() throws {
        let aggregator = AlertAggregator()
        let aggregation = aggregator.aggregate(strikes: [strike(northKilometres: 5)],
                                               dataArea: nil,
                                               location: location,
                                               isRealtime: true,
                                               referenceTime: referenceTime)

        let activity = try XCTUnwrap(aggregation.activity)
        XCTAssertEqual(activity.sectors.count, 8)
        XCTAssertEqual(activity.ranges.count, 6)
        for sector in activity.sectors {
            XCTAssertEqual(sector.cells.count, 6)
            XCTAssertEqual(sector.cells.map { $0.range }, activity.ranges)
        }
        XCTAssertEqual(activity.sectors.reduce(0) { $0 + $1.cells.count }, 48)
    }
}
