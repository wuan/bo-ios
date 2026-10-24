/*

Copyright 2026 Andreas Würl

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

import Foundation
import MapKit
import UIKit

/// The details popup shown for a selected tile or strike.
///
/// It is an annotation so the map keeps it anchored to the selected activity
/// while the map is panned or zoomed.
final class ActivitySelectionAnnotation: NSObject, MKAnnotation {

    let coordinate: CLLocationCoordinate2D
    let text: String

    var title: String? {
        return text
    }

    init(coordinate: CLLocationCoordinate2D, text: String) {
        self.coordinate = coordinate
        self.text = text
        super.init()
    }
}

/// A small label above the selected activity, matching the reference popup.
final class ActivitySelectionAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "activity.selection"

    private static let padding = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    private static let cornerRadius: CGFloat = 4

    private let label = UILabel()
    private var fittedSize: CGSize = .zero

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        canShowCallout = false
        backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        clipsToBounds = true
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .white
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    /// Sets the popup text and sizes the view to fit it.
    ///
    /// MapKit positions an annotation view by its frame, so the view is sized
    /// here rather than by constraints.
    func configure(text: String) {
        label.text = text
        label.sizeToFit()

        let padding = ActivitySelectionAnnotationView.padding
        let labelSize = label.bounds.size
        fittedSize = CGSize(width: labelSize.width + padding.left + padding.right,
                            height: labelSize.height + padding.top + padding.bottom)
        frame.size = fittedSize
        label.frame = CGRect(x: padding.left,
                             y: padding.top,
                             width: labelSize.width,
                             height: labelSize.height)
        layer.cornerRadius = ActivitySelectionAnnotationView.cornerRadius

        // Anchor the popup above the selected activity.
        centerOffset = CGPoint(x: 0, y: -(fittedSize.height / 2))
    }

    override var intrinsicContentSize: CGSize {
        return fittedSize
    }
}
