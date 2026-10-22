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
import MapKit
@testable import monitor

final class ViewExtentTests: XCTestCase {

    func testMaximumSpanIsTheLargerSpan() {
        let extent = ViewExtent(center: Location(latitude: 50, longitude: 10),
                                latitudeSpan: 4,
                                longitudeSpan: 9)
        XCTAssertEqual(extent.maximumSpan, 9)
    }

    func testBuildsFromFixedCenterAndSpanValues() {
        let extent = ViewExtent(center: Location(latitude: 48.5, longitude: 9.5),
                                latitudeSpan: 3,
                                longitudeSpan: 6)
        XCTAssertEqual(extent.center, Location(latitude: 48.5, longitude: 9.5))
        XCTAssertEqual(extent.latitudeSpan, 3)
        XCTAssertEqual(extent.longitudeSpan, 6)
    }

    func testBuildsFromAMapViewRegion() {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.5, longitude: 9.5),
                                        span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 6))
        let extent = ViewExtent(region: region)

        XCTAssertEqual(extent.center, Location(latitude: 48.5, longitude: 9.5))
        XCTAssertEqual(extent.latitudeSpan, 3)
        XCTAssertEqual(extent.longitudeSpan, 6)
    }
}
