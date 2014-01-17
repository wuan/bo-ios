
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class BOStrokeOverlay;

@interface BOStrokeOverlayRenderer : MKOverlayRenderer {

}
- (id)initWithOverlay:(BOStrokeOverlay *)overlay;
@end