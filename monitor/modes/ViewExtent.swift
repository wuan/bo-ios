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

import Foundation

/// A plain description of the visible map extent.
///
/// Deliberately free of MapKit: the map view produces a `ViewExtent` and the
/// region, data-area, and grid-size rules consume it, so those rules are
/// testable with fixed values and Phase 4 can add a location input without
/// reshaping the algorithm.
public struct ViewExtent: Equatable {

    /// Center of the visible area.
    public let center: Location
    /// North-south span in degrees.
    public let latitudeSpan: Double
    /// East-west span in degrees.
    public let longitudeSpan: Double

    public init(center: Location, latitudeSpan: Double, longitudeSpan: Double) {
        self.center = center
        self.latitudeSpan = latitudeSpan
        self.longitudeSpan = longitudeSpan
    }

    /// The larger of the two spans, in degrees. Drives grid and data-area sizing.
    public var maximumSpan: Double {
        return max(latitudeSpan, longitudeSpan)
    }
}
