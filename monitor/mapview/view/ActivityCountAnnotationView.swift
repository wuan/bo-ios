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

/// The strike count shown inside a grid cell.
///
/// It is an annotation for the same reason the details popup is: MapKit keeps
/// it anchored to the cell while the map moves, and annotation views are drawn
/// above the map's overlays, so the count stays legible over the base-map dim.
final class ActivityCountAnnotation: NSObject, MKAnnotation {

    let coordinate: CLLocationCoordinate2D
    let text: String
    let textSize: CGFloat
    let textColor: UIColor

    var title: String? {
        return text
    }

    init(coordinate: CLLocationCoordinate2D,
         text: String,
         textSize: CGFloat,
         textColor: UIColor) {
        self.coordinate = coordinate
        self.text = text
        self.textSize = textSize
        self.textColor = textColor
        super.init()
    }
}

/// A plain label centred on its cell, matching the reference client's count.
final class ActivityCountAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "activity.count"

    private let label = UILabel()
    private var fittedSize: CGSize = .zero

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        canShowCallout = false
        // Touches must reach the map, so a tap on a labelled cell still selects it.
        isUserInteractionEnabled = false
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    /// Sets the count and sizes the view to fit it.
    func configure(text: String, textSize: CGFloat, textColor: UIColor) {
        label.text = text
        label.font = .boldSystemFont(ofSize: textSize)
        label.textColor = textColor
        label.sizeToFit()
        fittedSize = label.bounds.size
        frame.size = fittedSize
        label.frame = CGRect(origin: .zero, size: fittedSize)
        centerOffset = .zero
    }

    override var intrinsicContentSize: CGSize {
        return fittedSize
    }
}
