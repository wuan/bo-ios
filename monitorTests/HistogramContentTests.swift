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

final class HistogramContentTests: XCTestCase {

    private let colorHandler = ColorHandler(scheme: .blitzortung, baseType: .satellite)

    private func content(_ values: [Int]?, intervalDuration: Int = 60) -> HistogramContent {
        return HistogramContentBuilder.make(values: values,
                                            intervalDuration: intervalDuration,
                                            colorHandler: colorHandler)
    }

    func testATypicalPeriodMapsValuesToBins() {
        let values = [0, 1, 3, 6, 2, 0, 1, 4, 8, 5, 2, 1]

        let content = self.content(values)

        XCTAssertEqual(content.periodMinutes, 60)
        XCTAssertEqual(content.bars.count, 12)
        XCTAssertEqual(content.bars.map { $0.count }, values)
        XCTAssertEqual(content.bars.map { $0.index }, Array(0 ..< 12))
    }

    func testBarHeightsAreRelativeToTheTallestBar() throws {
        let content = self.content([0, 4, 8, 2])

        XCTAssertEqual(try XCTUnwrap(content.bars.first { $0.count == 8 }).height, 1.0)
        XCTAssertEqual(try XCTUnwrap(content.bars.first { $0.count == 4 }).height, 0.5)
        XCTAssertEqual(try XCTUnwrap(content.bars.first).height, 0)
    }

    func testBarsAreColouredOldestToNewest() {
        let content = self.content([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        let colors = colorHandler.colors

        XCTAssertEqual(content.bars.first?.color, colors[colors.count - 1], "the oldest bin is the oldest colour")
        XCTAssertEqual(content.bars.last?.color, colors[0], "the newest bin is the first colour")
    }

    func testEmptyPeriodHasNoBarsOrRate() {
        let content = self.content(nil)

        XCTAssertTrue(content.isEmpty)
        XCTAssertTrue(content.bars.isEmpty)
        XCTAssertNil(content.rateText)
        XCTAssertEqual(content.periodMinutes, 60)
    }

    func testAllZeroValuesStillProduceBars() {
        let content = self.content([0, 0, 0, 0])

        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.bars.allSatisfy { $0.height == 0 })
        XCTAssertEqual(content.rateText, "0.0/min")
    }

    func testRateUsesTheTallestBinOverTheBinLength() {
        XCTAssertEqual(self.content([0, 5, 0, 0]).rateText, "1.0/min")
        XCTAssertEqual(self.content([0, 10, 0, 0]).rateText, "2.0/min")
    }

    func testAPeriodThatIsNotAWholeNumberOfBinsKeepsItsPartialBin() {
        // Twelve minutes at five minutes a bin leaves a two-minute last bin.
        let content = self.content([1, 2], intervalDuration: 12)

        XCTAssertEqual(HistogramContentBuilder.binCount(for: 12), 3)
        XCTAssertEqual(content.bars.count, 3)
        XCTAssertEqual(content.bars.map { $0.count }, [1, 2, 0])
    }

    func testAWholeNumberOfBinsIsNotRoundedUp() {
        XCTAssertEqual(HistogramContentBuilder.binCount(for: 60), 12)
        XCTAssertEqual(self.content(Array(repeating: 1, count: 12)).bars.count, 12)
    }

    func testMoreValuesThanBinsAreTruncatedToThePeriod() {
        let content = self.content(Array(repeating: 1, count: 20), intervalDuration: 60)

        XCTAssertEqual(content.bars.count, 12)
    }

    // MARK: - Plot geometry

    private let plot = CGRect(x: 6, y: 16, width: 138, height: 48)

    /// Renders a period whose tallest bin is 8 and whose second bin is 2.
    private func plottedContent() -> HistogramContent {
        return self.content([0, 8, 2, 0])
    }

    func testSegmentsJoinOneBarToTheNext() throws {
        let bars = plottedContent().bars
        let segments = HistogramPlot.segments(for: bars, in: plot)

        XCTAssertEqual(segments.count, bars.count - 1, "one segment per pair of neighbouring bars")

        // The second bar is the tallest, so both of its segments start or end at
        // the top of the plot, and the first segment reaches it from the first
        // bar's height rather than from the baseline.
        let tallestTop = plot.minY
        XCTAssertEqual(try XCTUnwrap(segments.first).from.y, plot.maxY, "the first bar is empty, so it sits on the baseline")
        XCTAssertEqual(try XCTUnwrap(segments.first).to.y, tallestTop)
        XCTAssertEqual(segments[1].from.y, tallestTop)
        XCTAssertEqual(segments[1].to.y, plot.maxY - 0.25 * plot.height, "the third bar is a quarter of the tallest")
    }

    func testSegmentsRunLeftToRightAcrossTheWholePlot() throws {
        let bars = plottedContent().bars
        let segments = HistogramPlot.segments(for: bars, in: plot)

        XCTAssertEqual(try XCTUnwrap(segments.first).from.x, plot.minX)
        XCTAssertEqual(try XCTUnwrap(segments.last).to.x, plot.maxX, accuracy: 1e-9)
        let step = plot.width / CGFloat(bars.count - 1)
        XCTAssertEqual(segments[1].from.x - segments[0].from.x, step, accuracy: 1e-9)
    }

    func testEverySegmentTakesTheOlderBarsColour() {
        let bars = plottedContent().bars
        let segments = HistogramPlot.segments(for: bars, in: plot)

        XCTAssertEqual(segments.map { $0.color }, bars.dropLast().map { $0.color })
    }

    func testASingleBarHasNothingToJoin() {
        // A five-minute period is one bin, so there is no neighbouring bar.
        let bars = self.content([4], intervalDuration: 5).bars

        XCTAssertEqual(bars.count, 1)
        XCTAssertTrue(HistogramPlot.segments(for: bars, in: plot).isEmpty)
    }

    func testAnEmptyOrCollapsedPlotHasNoSegments() {
        let bars = plottedContent().bars

        XCTAssertTrue(HistogramPlot.segments(for: bars,
                                             in: CGRect(x: 0, y: 0, width: 0, height: 48)).isEmpty)
        XCTAssertTrue(HistogramPlot.segments(for: bars,
                                             in: CGRect(x: 0, y: 0, width: 138, height: 0)).isEmpty)
        XCTAssertTrue(HistogramPlot.segments(for: [], in: plot).isEmpty)
    }
}
