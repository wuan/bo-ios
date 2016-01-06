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