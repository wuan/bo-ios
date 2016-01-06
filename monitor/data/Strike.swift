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
import MapKit

@objc
public class Strike: NSObject {

    let timestamp: Int
    let multiplicity: Int
    public let envelope: MKCoordinateRegion
    var location: CLLocationCoordinate2D {
        get {
            return self.envelope.center
        }
    }

    init(timestamp: Int,
         andMultiplicity multiplicity: Int,
         andX xCoordinate: Double,
         andY yCoordinate: Double,
         andWidth width: Double = 0.0,
         andHeight height: Double = 0.0) {
        self.timestamp = timestamp
        self.multiplicity = multiplicity

        let location = CLLocationCoordinate2D(latitude: yCoordinate, longitude: xCoordinate)
        let span = MKCoordinateSpanMake(height, width)
        envelope = MKCoordinateRegion(center: location, span: span)
    }

    override public var description: String {
        return "Stroke: \(timestamp) (\(envelope.center.longitude), \(envelope.center.latitude)) \(multiplicity)";
    }

}
