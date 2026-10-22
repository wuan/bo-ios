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

final class LegendContentTests: XCTestCase {

    private func content(scheme: ColorScheme = .blitzortung,
                         baseType: MapBaseType = .satellite,
                         intervalDuration: Int = 60,
                         regionName: String = "Europe",
                         region: Int = 1,
                         dataArea: DataArea? = nil,
                         gridBaselineMetres: Int = 10000) -> LegendContent {
        return LegendContentBuilder.make(colorHandler: ColorHandler(scheme: scheme, baseType: baseType),
                                         intervalDuration: intervalDuration,
                                         regionName: regionName,
                                         region: region,
                                         dataArea: dataArea,
                                         gridBaselineMetres: gridBaselineMetres)
    }

    func testOneEntryPerColourSection() {
        for scheme in ColorScheme.allCases {
            let content = self.content(scheme: scheme)
            XCTAssertEqual(content.entries.count, scheme.strikeColors.count)
            XCTAssertEqual(content.entries.map { $0.color }, scheme.colors(for: .satellite))
        }
    }

    func testEntriesSpanTheDisplayedInterval() {
        let content = self.content(intervalDuration: 60)

        // Six sections over 60 minutes are 10 minutes each.
        XCTAssertEqual(content.entries.map { $0.minimumAge }, [0, 10, 20, 30, 40, 50])
        XCTAssertEqual(content.entries.map { $0.maximumAge }, [10, 20, 30, 40, 50, nil])
        XCTAssertEqual(content.entries.first?.ageText, "< 10 min")
        XCTAssertEqual(content.entries.last?.ageText, "> 50 min")
    }

    func testEntriesFollowTheLongestInterval() {
        let content = self.content(intervalDuration: 240)

        XCTAssertEqual(content.entries.map { $0.minimumAge }, [0, 40, 80, 120, 160, 200])
        XCTAssertEqual(content.entries.last?.ageText, "> 200 min")
    }

    func testRegionNameIsShown() {
        XCTAssertEqual(self.content(regionName: "N. America", region: 3).regionName, "N. America")
    }

    func testGridBaselineIsShownForSeveralSizes() {
        XCTAssertEqual(self.content(gridBaselineMetres: 5000).gridBaseline, "5 km")
        XCTAssertEqual(self.content(gridBaselineMetres: 10000).gridBaseline, "10 km")
        XCTAssertEqual(self.content(gridBaselineMetres: 100000).gridBaseline, "100 km")
        XCTAssertNil(self.content(gridBaselineMetres: 0).gridBaseline,
                     "a source without a grid has no baseline to show")
    }

    func testLocalRegionSizeIsShownOnlyForALocalRegion() {
        let area = DataArea(x: 3, y: 4, scale: 5)

        XCTAssertEqual(self.content(region: Parameters.localRegion, dataArea: area).localRegionSize, "5°")
        XCTAssertNil(self.content(region: Parameters.localRegion).localRegionSize,
                     "a local region without a derived area has no size")
        XCTAssertNil(self.content(region: 1, dataArea: area).localRegionSize,
                     "a named region has no local size")
    }
}
