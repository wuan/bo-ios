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

/// What the own-location marker draws.
///
/// Deliberately free of MapKit, so the marker's content can be tested without a
/// view hierarchy; the annotation view materialises it on the map.
public struct OwnLocationMarker: Equatable {

    /// The diameter the marker is drawn at, in points.
    public static let defaultDiameter: CGFloat = 14

    /// The position the marker sits at.
    public let location: Location
    /// The marker's diameter in points.
    public let diameter: CGFloat

    public init(location: Location, diameter: CGFloat = OwnLocationMarker.defaultDiameter) {
        self.location = location
        self.diameter = diameter
    }

    /// The marker for a location, or `nil` when no location is known.
    public static func make(location: Location?,
                            diameter: CGFloat = OwnLocationMarker.defaultDiameter) -> OwnLocationMarker? {
        guard let location = location else { return nil }
        return OwnLocationMarker(location: location, diameter: diameter)
    }
}
