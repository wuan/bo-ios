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

    /// The diameter the marker is drawn at when the size is at 100 percent.
    public static let defaultDiameter: CGFloat = 14

    /// The percentage the size setting starts at.
    public static let defaultSizePercent = 100

    /// The smallest size the marker is drawn at, in percent.
    public static let minimumSizePercent = 50

    /// The largest size the marker is drawn at, in percent.
    public static let maximumSizePercent = 400

    /// The position the marker sits at.
    public let location: Location
    /// The marker's diameter in points.
    public let diameter: CGFloat

    public init(location: Location, diameter: CGFloat = OwnLocationMarker.defaultDiameter) {
        self.location = location
        self.diameter = diameter
    }

    /// The diameter a size percentage draws.
    ///
    /// A percentage outside the settable range is clamped, so a stale or
    /// externally written value cannot draw an invisible or absurd marker.
    /// 100 percent reproduces ``defaultDiameter``.
    public static func diameter(percent: Int) -> CGFloat {
        let clamped = min(max(percent, minimumSizePercent), maximumSizePercent)
        return defaultDiameter * CGFloat(clamped) / 100
    }

    /// The marker for a location, or `nil` when there is nothing to draw -
    /// because no location is known, or because own-location display is off.
    public static func make(location: Location?,
                            visible: Bool = true,
                            diameter: CGFloat = OwnLocationMarker.defaultDiameter) -> OwnLocationMarker? {
        guard visible, let location = location else { return nil }
        return OwnLocationMarker(location: location, diameter: diameter)
    }
}
