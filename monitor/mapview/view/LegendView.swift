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

/// Draws the legend and reports taps, which open quick settings.
///
/// The view owns no policy: it draws one ``LegendContent`` value and nothing
/// else, so the legend's numbers are decided and tested in the builder.
final class LegendView: UIControl {

    static let accessibilityIdentifier = "legend.view"

    /// Padding around and between the drawn items, in points.
    static let padding: CGFloat = 6
    /// The font size of the drawn text, in points.
    static let fontSize: CGFloat = 11

    private(set) var content: LegendContent?

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
        accessibilityIdentifier = LegendView.accessibilityIdentifier
        accessibilityLabel = NSLocalizedString("legend.title", comment: "Legend accessibility label")
    }

    /// Draws the given content, or nothing when there is none.
    func configure(content: LegendContent?) {
        self.content = content
        isHidden = content == nil
        accessibilityValue = content.map { value in
            [value.regionName, value.localRegionSize, value.gridBaseline]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }

    override var intrinsicContentSize: CGSize {
        guard let content = content else { return .zero }
        let textWidth = content.entries.reduce(CGFloat(0)) { width, entry in
            max(width, LegendView.fontSize + 2 * LegendView.padding + LegendView.textWidth(entry.ageText))
        }
        let headerWidth = max(LegendView.textWidth(content.regionName),
                              content.gridBaseline.map { LegendView.textWidth("Grid: \($0)") } ?? 0)
        let width = max(textWidth, headerWidth) + 2 * LegendView.padding
        let height = CGFloat(content.entries.count) * (LegendView.fontSize + LegendView.padding)
            + 2 * LegendView.padding
            + LegendView.fontSize
            + (content.gridBaseline == nil ? 0 : LegendView.fontSize)
        return CGSize(width: ceil(width), height: ceil(height))
    }

    override func draw(_ rect: CGRect) {
        guard let content = content else { return }

        UIColor(white: 0, alpha: 0.55).setFill()
        UIBezierPath(roundedRect: bounds, cornerRadius: 4).fill()

        let attributes = LegendView.textAttributes
        var y = LegendView.padding

        for entry in content.entries {
            UIColor(packed: entry.color).setFill()
            UIBezierPath(rect: CGRect(x: LegendView.padding,
                                      y: y,
                                      width: LegendView.fontSize,
                                      height: LegendView.fontSize)).fill()
            (entry.ageText as NSString).draw(at: CGPoint(x: 2 * LegendView.padding + LegendView.fontSize, y: y),
                                             withAttributes: attributes)
            y += LegendView.fontSize + LegendView.padding
        }

        y = drawCentered(content.regionName, y: y, attributes: attributes)
        if let gridBaseline = content.gridBaseline {
            _ = drawCentered("Grid: \(gridBaseline)", y: y, attributes: attributes)
        }
    }

    private func drawCentered(_ text: String,
                              y: CGFloat,
                              attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let width = LegendView.textWidth(text)
        (text as NSString).draw(at: CGPoint(x: max(LegendView.padding, (bounds.width - width) / 2), y: y),
                                withAttributes: attributes)
        return y + LegendView.fontSize
    }

    private static var textAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
        ]
    }

    private static func textWidth(_ text: String) -> CGFloat {
        return (text as NSString).size(withAttributes: textAttributes).width
    }
}
