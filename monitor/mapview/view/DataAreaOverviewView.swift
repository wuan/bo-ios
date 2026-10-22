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

/// Draws the data-area overview: the area, the part of it the map shows, and
/// the zoom level.
final class DataAreaOverviewView: UIView {

    static let accessibilityIdentifier = "overview.view"

    /// The drawn size, in points.
    static let size = CGSize(width: 130, height: 90)

    private let padding: CGFloat = 6
    private(set) var content: DataAreaOverviewContent?

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
        accessibilityIdentifier = DataAreaOverviewView.accessibilityIdentifier
        accessibilityLabel = NSLocalizedString("overview.title", comment: "Data area overview accessibility label")
    }

    /// Draws the given content; a result without a data area hides the view.
    func configure(content: DataAreaOverviewContent?) {
        self.content = content
        isHidden = content == nil
        accessibilityValue = content.map { "\($0.longitudeText) \($0.latitudeText) \($0.zoomText)" }
        setNeedsDisplay()
    }

    override var intrinsicContentSize: CGSize {
        return DataAreaOverviewView.size
    }

    override func draw(_ rect: CGRect) {
        guard let content = content else { return }

        UIColor(white: 0, alpha: 0.35).setFill()
        UIBezierPath(roundedRect: bounds, cornerRadius: 4).fill()

        let attributes = DataAreaOverviewView.textAttributes
        let lineHeight = DataAreaOverviewView.fontSize * 1.2
        var top = padding

        for text in [content.longitudeText, content.latitudeText, content.cellSizeText] {
            draw(text, alignedRightAt: top, attributes: attributes)
            top += lineHeight
        }

        let box = CGRect(x: padding,
                         y: top,
                         width: bounds.width - 2 * padding,
                         height: bounds.height - top - lineHeight - padding)
        UIColor(white: 1, alpha: 0.9).setStroke()
        let path = UIBezierPath(rect: box)
        path.lineWidth = 1
        path.stroke()

        let viewport = content.viewport
        let viewportRect = CGRect(x: box.minX + CGFloat(viewport.x) * box.width,
                                  y: box.minY + CGFloat(viewport.y) * box.height,
                                  width: CGFloat(viewport.width) * box.width,
                                  height: CGFloat(viewport.height) * box.height)
        let clipped = viewportRect.intersection(box)
        if !clipped.isNull && clipped.width > 0 && clipped.height > 0 {
            UIColor(white: 1, alpha: 0.7).setFill()
            UIBezierPath(rect: clipped).fill()
        }

        draw(content.zoomText, alignedRightAt: bounds.height - padding - lineHeight, attributes: attributes)
    }

    private func draw(_ text: String,
                      alignedRightAt top: CGFloat,
                      attributes: [NSAttributedString.Key: Any]) {
        let width = (text as NSString).size(withAttributes: attributes).width
        (text as NSString).draw(at: CGPoint(x: bounds.width - padding - width, y: top),
                                withAttributes: attributes)
    }

    private static let fontSize: CGFloat = 9

    private static var textAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
        ]
    }
}
