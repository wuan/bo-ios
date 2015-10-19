
import Foundation
import MapKit

public class StrokeOverlay : NSObject, MKOverlay {
    
    let stroke:Stroke
    public let boundingMapRect:MKMapRect
    public let coordinate:CLLocationCoordinate2D
    
    init(withWStroke stroke: Stroke) {
        self.stroke = stroke
        
        let strokeRegion = stroke.envelope
        
        let topLeftCoordinate = CLLocationCoordinate2DMake(strokeRegion.center.latitude + (strokeRegion.span.latitudeDelta / 2.0),
            strokeRegion.center.longitude + (strokeRegion.span.longitudeDelta / 2.0))
        
        let topLeftMapPoint = MKMapPointForCoordinate(topLeftCoordinate)
        
        let bottomRightCoordinate = CLLocationCoordinate2DMake(strokeRegion.center.latitude - (strokeRegion.span.latitudeDelta / 2.0),
            strokeRegion.center.longitude - (strokeRegion.span.longitudeDelta / 2.0))
        
        let bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoordinate)
        
        boundingMapRect = MKMapRectMake(topLeftMapPoint.x, topLeftMapPoint.y,
            fabs(bottomRightMapPoint.x - topLeftMapPoint.x),
            fabs(bottomRightMapPoint.y - topLeftMapPoint.y))
        
        coordinate = strokeRegion.center
    }
    
    override public var description :String {
        return "Overlay(\(self.stroke.description))"
    }
    
}