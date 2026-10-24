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

import MapKit
import UIKit

/// The annotation marking the user's own location.
///
/// Drawn by the app rather than by MapKit's user-location dot, so a manually
/// set position shows without any location permission being granted.
final class OwnLocationAnnotation: NSObject, MKAnnotation {

    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }

    convenience init(marker: OwnLocationMarker) {
        self.init(coordinate: CLLocationCoordinate2D(latitude: marker.location.latitude,
                                                     longitude: marker.location.longitude))
    }
}

/// Draws the own-location marker as a filled dot with a light ring.
final class OwnLocationAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "own.location"
    /// The accessibility identifier the marker is queried by.
    static let accessibilityIdentifier = "own.location"

    private var diameter: CGFloat = OwnLocationMarker.defaultDiameter

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        isAccessibilityElement = true
        accessibilityIdentifier = OwnLocationAnnotationView.accessibilityIdentifier
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Sets the drawn size and refreshes the accessibility value.
    func configure(marker: OwnLocationMarker) {
        diameter = marker.diameter
        bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        centerOffset = .zero
        accessibilityLabel = NSLocalizedString("location.own",
                                              comment: "Accessibility label for the own-location marker")
        accessibilityValue = String(format: "%.5f,%.5f",
                                    marker.location.latitude,
                                    marker.location.longitude)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let ringWidth = max(1, diameter / 7)
        let dot = bounds.insetBy(dx: ringWidth, dy: ringWidth)

        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: bounds)
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fillEllipse(in: dot)
    }
}
