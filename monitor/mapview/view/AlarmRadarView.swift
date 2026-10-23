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

/// Draws the alarm radar: its rings, sector fills, and state.
///
/// The view is drawn from one ``RadarContent`` value, so the geometry and the
/// colours are decided and tested in the builder.
final class AlarmRadarView: UIControl {

    static let accessibilityIdentifier = "radar.view"

    private let padding: CGFloat = 4
    private(set) var content: RadarContent?

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
        accessibilityIdentifier = AlarmRadarView.accessibilityIdentifier
        accessibilityLabel = NSLocalizedString("radar.title", comment: "Alarm radar accessibility label")
    }

    /// Draws the given content, or a placeholder when there is none.
    func configure(content: RadarContent?) {
        self.content = content
        accessibilityValue = content.map { content in
            guard content.alert else { return AlarmRadarView.name(for: content.state) }
            return "\(AlarmRadarView.name(for: content.state)), "
                + NSLocalizedString("radar.alert", comment: "Radar accessibility value while an alert is active")
        }
        setNeedsDisplay()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 110, height: 110)
    }

    override func draw(_ rect: CGRect) {
        let side = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = side / 2 - padding

        UIColor(white: 0, alpha: 0.35).setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - radius - padding,
                                    y: center.y - radius - padding,
                                    width: 2 * (radius + padding),
                                    height: 2 * (radius + padding))).fill()

        guard let content = content, !content.ringLabels.isEmpty else { return }

        // One fill per sector, coloured by its closest strike's age.
        for sector in content.sectors {
            guard let color = sector.color else { continue }
            UIColor(packed: color, alpha: 0.85).setFill()
            let wedge = UIBezierPath()
            wedge.move(to: center)
            wedge.addArc(withCenter: center,
                         radius: radius,
                         startAngle: AlarmRadarView.radians(sector.direction.centerBearing - 22.5 - 90),
                         endAngle: AlarmRadarView.radians(sector.direction.centerBearing + 22.5 - 90),
                         clockwise: true)
            wedge.close()
            wedge.fill()
        }

        let rings = content.ringLabels.count
        let increment = radius / CGFloat(rings)
        UIColor(white: 1, alpha: 0.8).setStroke()
        for ring in 1 ... rings {
            let path = UIBezierPath(arcCenter: center,
                                    radius: CGFloat(ring) * increment,
                                    startAngle: 0,
                                    endAngle: 2 * .pi,
                                    clockwise: true)
            path.lineWidth = ring == rings ? 2 : 1
            path.stroke()
        }
        for sector in content.sectors {
            let bearing = sector.direction.centerBearing - 22.5
            let path = UIBezierPath()
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + radius * sin(AlarmRadarView.radians(bearing)),
                                     y: center.y - radius * cos(AlarmRadarView.radians(bearing))))
            path.lineWidth = 1
            path.stroke()
        }

        // An active alert marks the face, so a warning is not mistaken for
        // activity that is merely in range.
        if content.alert {
            UIColor.systemRed.setStroke()
            let mark = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: 0,
                                    endAngle: 2 * .pi,
                                    clockwise: true)
            mark.lineWidth = 4
            mark.stroke()
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.white,
        ]
        if let label = content.ringLabels.last {
            let text = label.isOuter ? "\(label.text) \(content.distanceUnit)" : label.text
            (text as NSString).draw(at: CGPoint(x: center.x + radius * 0.6, y: center.y + 2),
                                    withAttributes: attributes)
        }

        if content.state != .active {
            drawState(AlarmRadarView.name(for: content.state), center: center)
        }
    }

    /// Draws the state name across the face when the radar has nothing to show.
    private func drawState(_ text: String, center: CGPoint) {
        guard !text.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: center.x - size.width / 2,
                                            y: center.y - size.height / 2),
                                withAttributes: attributes)
    }

    /// The name shown for a radar state.
    static func name(for state: RadarState) -> String {
        switch state {
        case .noLocation:
            return NSLocalizedString("radar.state.noLocation", comment: "Radar state: no location known")
        case .outsideDataArea:
            return NSLocalizedString("radar.state.outsideDataArea", comment: "Radar state: outside the data area")
        case .noData:
            return NSLocalizedString("radar.state.noData", comment: "Radar state: no data")
        case .inactive:
            return NSLocalizedString("radar.state.inactive", comment: "Radar state: no activity in range")
        case .active:
            return NSLocalizedString("radar.state.active", comment: "Radar state: activity in range")
        }
    }

    private static func radians(_ degrees: Double) -> CGFloat {
        return CGFloat(degrees * .pi / 180)
    }
}
