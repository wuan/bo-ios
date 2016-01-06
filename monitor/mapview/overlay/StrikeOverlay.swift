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

public class StrikeOverlay: NSObject, MKOverlay {
    
    let strike: Strike
    let referenceTimestamp: Int
    let parameters: Parameters
    public let boundingMapRect: MKMapRect
    public let coordinate: CLLocationCoordinate2D
    
    init(withStrike strike: Strike, andReferenceTimestamp referenceTimestamp: Int, andParameters parameters: Parameters) {
        self.strike = strike
        self.referenceTimestamp = referenceTimestamp
        self.parameters = parameters
        
        let strokeRegion = strike.envelope
        
        let topLeftCoordinate = CLLocationCoordinate2DMake(
            strokeRegion.center.latitude + (strokeRegion.span.latitudeDelta / 2.0),
            strokeRegion.center.longitude + (strokeRegion.span.longitudeDelta / 2.0))
        
        let topLeftMapPoint = MKMapPointForCoordinate(topLeftCoordinate)
        
        let bottomRightCoordinate = CLLocationCoordinate2DMake(
            strokeRegion.center.latitude - (strokeRegion.span.latitudeDelta / 2.0),
            strokeRegion.center.longitude - (strokeRegion.span.longitudeDelta / 2.0))
        
        let bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoordinate)
        
        boundingMapRect = MKMapRectMake(topLeftMapPoint.x, topLeftMapPoint.y,
            fabs(bottomRightMapPoint.x - topLeftMapPoint.x) + 1,
            fabs(bottomRightMapPoint.y - topLeftMapPoint.y) + 1)
        
        coordinate = strokeRegion.center
    }
    
    override public var description: String {
        return "Overlay(\(self.strike.description))"
    }
    
}