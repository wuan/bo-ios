

#import "BOMapViewDelegate.h"
#import "BOStrokeOverlay.h"
#import "BOStrokeOverlayRenderer.h"


@implementation BOMapViewDelegate {

}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygon *polygon = (MKPolygon *) overlay;
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
        renderer.fillColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.4];
        return renderer;
    } else if ([overlay isKindOfClass:[BOStrokeOverlay class]]) {
        BOStrokeOverlay *strokeOverlay = (BOStrokeOverlay *) overlay;
        BOStrokeOverlayRenderer *renderer = [[BOStrokeOverlayRenderer alloc] initWithOverlay:strokeOverlay];
        return renderer;
    }
    return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    return nil;
}


@end