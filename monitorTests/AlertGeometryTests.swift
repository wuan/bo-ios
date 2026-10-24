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

final class AlertGeometryTests: XCTestCase {

    private let geometry = AlertGeometry.standard

    // MARK: - Rings

    func testRingBoundariesMatchTheReference() {
        XCTAssertEqual(geometry.ranges.map { $0.maximum }, [10, 25, 50, 100, 250, 500])
        XCTAssertEqual(geometry.ranges.map { $0.minimum }, [0, 10, 25, 50, 100, 250])
    }

    func testRingIndexFollowsTheBoundaries() {
        XCTAssertEqual(geometry.ringIndex(forDistance: 0), 0)
        XCTAssertEqual(geometry.ringIndex(forDistance: 10), 0)
        XCTAssertEqual(geometry.ringIndex(forDistance: 10.001), 1)
        XCTAssertEqual(geometry.ringIndex(forDistance: 25), 1)
        XCTAssertEqual(geometry.ringIndex(forDistance: 499.999), 5)
        XCTAssertEqual(geometry.ringIndex(forDistance: 500), 5)
        XCTAssertNil(geometry.ringIndex(forDistance: 500.001))
    }

    // MARK: - Sectors

    func testSectorLabelsMatchTheReference() {
        XCTAssertEqual(geometry.directions.map { $0.label }, ["S", "SW", "W", "NW", "N", "NE", "E", "SE"])
    }

    func testSectorsAreEquallyWideAndCoverTheFullCircle() {
        XCTAssertEqual(geometry.directions.count, 8)

        let widths = geometry.directions.map { direction in
            direction.maximumBearing - direction.minimumBearing + 360 * (direction.maximumBearing < direction.minimumBearing ? 1 : 0)
        }
        for width in widths {
            XCTAssertEqual(width, 45, accuracy: 1e-9)
        }

        let centers = geometry.directions.map { $0.centerBearing }
        XCTAssertEqual(centers, [-180, -135, -90, -45, 0, 45, 90, 135])
    }

    func testEveryBearingFallsInExactlyOneSector() {
        var bearing = -180.0
        while bearing < 180 {
            let matches = geometry.directions.filter { $0.contains(bearing: bearing) }
            XCTAssertEqual(matches.count, 1, "bearing \(bearing) matched \(matches.count) sectors")
            bearing += 0.25
        }
    }

    func testSectorIndexPlacesCardinalBearings() {
        XCTAssertEqual(geometry.sectorIndex(forBearing: 180), 0)
        XCTAssertEqual(geometry.sectorIndex(forBearing: -180), 0)
        XCTAssertEqual(geometry.sectorIndex(forBearing: -170), 0)
        XCTAssertEqual(geometry.sectorIndex(forBearing: -135), 1)
        XCTAssertEqual(geometry.sectorIndex(forBearing: -90), 2)
        XCTAssertEqual(geometry.sectorIndex(forBearing: -45), 3)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 0), 4)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 45), 5)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 90), 6)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 135), 7)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 157.4), 7)
        // The southern sector straddles the end of the circle.
        XCTAssertEqual(geometry.sectorIndex(forBearing: 157.5), 0)
        XCTAssertEqual(geometry.sectorIndex(forBearing: 170), 0)
    }

    // MARK: - Geometry helpers

    func testDistanceBetweenLocations() {
        let distance = AlertGeometry.distance(from: Location(latitude: 0, longitude: 0),
                                              to: Location(latitude: 0, longitude: 1))

        XCTAssertEqual(distance, 111.195, accuracy: 0.01)
    }

    func testBearingToCardinalDirections() {
        let origin = Location(latitude: 0, longitude: 0)

        XCTAssertEqual(AlertGeometry.bearing(from: origin, to: Location(latitude: 1, longitude: 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(AlertGeometry.bearing(from: origin, to: Location(latitude: 0, longitude: 1)), 90, accuracy: 1e-9)
        XCTAssertEqual(AlertGeometry.bearing(from: origin, to: Location(latitude: -1, longitude: 0)), 180, accuracy: 1e-9)
        XCTAssertEqual(AlertGeometry.bearing(from: origin, to: Location(latitude: 0, longitude: -1)), -90, accuracy: 1e-9)
    }
}
