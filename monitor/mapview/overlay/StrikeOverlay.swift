import Foundation
import MapKit

public class StrikeOverlay: NSObject, MKOverlay {

    let stroke: Strike
    public let boundingMapRect: MKMapRect
    public let coordinate: CLLocationCoordinate2D

    init(withStroke stroke: Strike) {
        self.stroke = stroke

        let strokeRegion = stroke.envelope

        let topLeftCoordinate = CLLocationCoordinate2DMake(strokeRegion.center.latitude + (strokeRegion.span.latitudeDelta / 2.0),
                strokeRegion.center.longitude + (strokeRegion.span.longitudeDelta / 2.0))

        let topLeftMapPoint = MKMapPointForCoordinate(topLeftCoordinate)

        let bottomRightCoordinate = CLLocationCoordinate2DMake(strokeRegion.center.latitude - (strokeRegion.span.latitudeDelta / 2.0),
                strokeRegion.center.longitude - (strokeRegion.span.longitudeDelta / 2.0))

        let bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoordinate)

        boundingMapRect = MKMapRectMake(topLeftMapPoint.x, topLeftMapPoint.y,
                fabs(bottomRightMapPoint.x - topLeftMapPoint.x) + 1,
                fabs(bottomRightMapPoint.y - topLeftMapPoint.y) + 1)

        coordinate = strokeRegion.center
    }

    override public var description: String {
        return "Overlay(\(self.stroke.description))"
    }

}