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

import CoreGraphics
import Foundation

/// One bar of the strike-rate histogram.
public struct HistogramBar: Equatable {

    /// The bar's position in the period, oldest first.
    public let index: Int
    /// The strike count the bar stands for.
    public let count: Int
    /// The bar's height as a fraction of the tallest bar, in `0...1`.
    public let height: Double
    /// The colour of the bar, from its age within the period.
    public let color: UInt32

    public init(index: Int, count: Int, height: Double, color: UInt32) {
        self.index = index
        self.count = count
        self.height = height
        self.color = color
    }
}

/// What the strike-rate histogram displays.
public struct HistogramContent: Equatable {

    /// The length of one bin in minutes.
    public static let minutesPerBin = 5

    /// One bar per bin of the displayed period, oldest first.
    public let bars: [HistogramBar]
    /// The displayed period in minutes.
    public let periodMinutes: Int
    /// The strike rate shown above the bars, e.g. `3.0/min`; `nil` when the
    /// period holds nothing.
    public let rateText: String?

    public init(bars: [HistogramBar], periodMinutes: Int, rateText: String?) {
        self.bars = bars
        self.periodMinutes = periodMinutes
        self.rateText = rateText
    }

    /// Whether the histogram has anything to draw.
    public var isEmpty: Bool {
        return bars.isEmpty
    }
}

/// Builds the histogram's content from a grid result's histogram values.
///
/// The grid response already carries the strike rate for each part of the
/// displayed period, so the histogram needs no request of its own. A period
/// whose length is not a whole number of bins keeps its partial last bin.
public enum HistogramContentBuilder {

    /// Builds the histogram content.
    ///
    /// - Parameters:
    ///   - values: the strike counts the result reports per bin, oldest first,
    ///     or `nil` when the result carries none.
    ///   - intervalDuration: the displayed period in minutes.
    ///   - colorHandler: the colours of the active scheme and base map.
    public static func make(values: [Int]?,
                            intervalDuration: Int,
                            colorHandler: ColorHandler) -> HistogramContent {
        guard let values = values, !values.isEmpty, intervalDuration > 0 else {
            return HistogramContent(bars: [], periodMinutes: max(0, intervalDuration), rateText: nil)
        }

        let binCount = binCount(for: intervalDuration)
        let maximum = values.max() ?? 0
        let scale = Double(max(1, maximum))

        let bars = (0 ..< binCount).map { index -> HistogramBar in
            let count = index < values.count ? values[index] : 0
            // Index 0 is the oldest bin, so its age is the period's length.
            let ageMinutes = (binCount - 1 - index) * HistogramContent.minutesPerBin
            return HistogramBar(index: index,
                                count: count,
                                height: Double(count) / scale,
                                color: colorHandler.color(ageSeconds: ageMinutes * 60,
                                                          intervalDuration: intervalDuration))
        }

        let rate = Double(maximum) / Double(HistogramContent.minutesPerBin)
        let rateText = String(format: NSLocalizedString("histogram.rate",
                                                       comment: "Strike rate shown above the histogram, e.g. 3.0/min"),
                              rate)

        return HistogramContent(bars: bars, periodMinutes: intervalDuration, rateText: rateText)
    }

    /// The number of bins a period divides into, rounding a partial last bin up.
    public static func binCount(for intervalDuration: Int) -> Int {
        guard intervalDuration > 0 else { return 0 }
        return (intervalDuration + HistogramContent.minutesPerBin - 1) / HistogramContent.minutesPerBin
    }
}

/// One line of the histogram's plot: a bar's top joined to the next bar's top.
public struct HistogramSegment: Equatable {

    /// Where the segment starts, the older bar's top.
    public let from: CGPoint
    /// Where the segment ends, the newer bar's top.
    public let to: CGPoint
    /// The colour the segment is drawn in, the older bar's colour.
    public let color: UInt32

    public init(from: CGPoint, to: CGPoint, color: UInt32) {
        self.from = from
        self.to = to
        self.color = color
    }
}

/// The plot geometry of the histogram.
///
/// The bars' tops are joined into one polyline, as the reference draws it: a
/// segment runs from one bar's height to the next bar's height, never from the
/// baseline, so the plot reads as a strike-rate curve. Everything is expressed
/// in the plot rectangle the view passes in, so the geometry can be checked
/// without a view hierarchy.
public enum HistogramPlot {

    /// The segments joining the bars' tops, oldest bar first.
    ///
    /// A histogram with fewer than two bars has nothing to join and yields no
    /// segments.
    public static func segments(for bars: [HistogramBar], in plot: CGRect) -> [HistogramSegment] {
        guard bars.count > 1, plot.width > 0, plot.height > 0 else { return [] }

        let step = plot.width / CGFloat(bars.count - 1)
        return (0 ..< bars.count - 1).map { index in
            let bar = bars[index]
            let next = bars[index + 1]
            return HistogramSegment(from: CGPoint(x: plot.minX + CGFloat(index) * step,
                                                  y: top(of: bar, in: plot)),
                                    to: CGPoint(x: plot.minX + CGFloat(index + 1) * step,
                                                y: top(of: next, in: plot)),
                                    color: bar.color)
        }
    }

    /// The y coordinate of a bar's top in the plot.
    private static func top(of bar: HistogramBar, in plot: CGRect) -> CGFloat {
        return plot.maxY - CGFloat(bar.height) * plot.height
    }
}
