/*

 Copyright 2025 Andreas Würl

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

@MainActor
final class DataAreaOverviewViewTests: XCTestCase {

    private func content(aspectRatio: Double) -> DataAreaOverviewContent {
        return DataAreaOverviewContent(longitudeText: "-1.0..1.0",
                                       latitudeText: "49.0..51.0",
                                       cellSizeText: "1.0 1.0",
                                       viewport: OverviewViewport(x: 0, y: 0, width: 1, height: 1),
                                       zoomText: "Zoom 7.0",
                                       aspectRatio: aspectRatio)
    }

    private func view(aspectRatio: Double) -> DataAreaOverviewView {
        let view = DataAreaOverviewView()
        view.configure(content: content(aspectRatio: aspectRatio))
        return view
    }

    func testTheBoxWidthIsFixed() {
        XCTAssertEqual(view(aspectRatio: 1).intrinsicContentSize.width, DataAreaOverviewView.width)
    }

    /// The height is the width scaled by the extent's ratio, so a wide extent
    /// draws a flatter box than a tall one.
    func testTheBoxHeightFollowsTheRatio() {
        let wide = view(aspectRatio: 0.75).intrinsicContentSize.height
        let tall = view(aspectRatio: 1.5).intrinsicContentSize.height

        XCTAssertEqual(wide, DataAreaOverviewView.width * 0.75, accuracy: 0.001)
        XCTAssertEqual(tall, DataAreaOverviewView.width * 1.5, accuracy: 0.001)
        XCTAssertLessThan(wide, tall, "a wide extent must draw a flatter box")
    }

    func testTheBoxHeightIsClamped() {
        XCTAssertEqual(view(aspectRatio: 0.01).intrinsicContentSize.height,
                       DataAreaOverviewView.minimumHeight,
                       accuracy: 0.001)
        XCTAssertEqual(view(aspectRatio: 100).intrinsicContentSize.height,
                       DataAreaOverviewView.maximumHeight,
                       accuracy: 0.001)
    }

    func testNoContentHidesTheViewAndKeepsTheFallbackSize() {
        let view = DataAreaOverviewView()
        view.configure(content: nil)

        XCTAssertTrue(view.isHidden)
        XCTAssertEqual(view.intrinsicContentSize, DataAreaOverviewView.size)
    }

    func testContentShowsTheView() {
        let view = view(aspectRatio: 1)

        XCTAssertFalse(view.isHidden)
        XCTAssertEqual(view.intrinsicContentSize.height, DataAreaOverviewView.width, accuracy: 0.001)
    }
}
