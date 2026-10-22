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

import UIKit

/// Draws the strike-rate histogram and reports taps, which zoom the map out to
/// the data area.
final class HistogramView: UIControl {

    static let accessibilityIdentifier = "histogram.view"

    /// The drawn size, in points.
    static let size = CGSize(width: 150, height: 70)

    private let padding: CGFloat = 6
    private(set) var content: HistogramContent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = HistogramView.accessibilityIdentifier
        accessibilityLabel = NSLocalizedString("histogram.title", comment: "Histogram accessibility label")
    }

    /// Draws the given content; an empty histogram hides the view.
    func configure(content: HistogramContent?) {
        self.content = content
        isHidden = content?.isEmpty ?? true
        accessibilityValue = content.flatMap { $0.rateText }
        setNeedsDisplay()
    }

    override var intrinsicContentSize: CGSize {
        return HistogramView.size
    }

    override func draw(_ rect: CGRect) {
        guard let content = content, !content.isEmpty else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }

        UIColor(white: 0, alpha: 0.35).setFill()
        UIBezierPath(roundedRect: bounds, cornerRadius: 4).fill()

        var top = padding
        if let rateText = content.rateText {
            let attributes = HistogramView.textAttributes
            let width = (rateText as NSString).size(withAttributes: attributes).width
            (rateText as NSString).draw(at: CGPoint(x: bounds.width - padding - width, y: top),
                                        withAttributes: attributes)
            top += HistogramView.fontSize
        }

        let bars = content.bars
        let plotWidth = bounds.width - 2 * padding
        let plotHeight = bounds.height - top - padding
        guard bars.count > 0, plotWidth > 0, plotHeight > 0 else { return }

        let plot = CGRect(x: padding, y: top, width: plotWidth, height: plotHeight)
        context.setLineWidth(3)
        context.setLineCap(.round)

        // The bars' tops are joined into one polyline, so each segment runs from
        // one bar's height to the next bar's rather than from the baseline.
        for segment in HistogramPlot.segments(for: bars, in: plot) {
            UIColor(packed: segment.color).setStroke()
            context.move(to: segment.from)
            context.addLine(to: segment.to)
            context.strokePath()
        }

        UIColor(white: 1, alpha: 0.8).setStroke()
        context.setLineWidth(1)
        context.move(to: CGPoint(x: padding, y: bounds.height - padding))
        context.addLine(to: CGPoint(x: bounds.width - padding, y: bounds.height - padding))
        context.strokePath()
    }

    private static let fontSize: CGFloat = 10

    private static var textAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
        ]
    }
}
