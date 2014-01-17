//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <MapKit/MapKit.h>
#import "BOStrokeOverlayRenderer.h"
#import "BOStrokeOverlay.h"


@interface BOStrokeOverlayRenderer ()
@property(nonatomic, strong) BOStrokeOverlay *strokeOverlay;
@end

@implementation BOStrokeOverlayRenderer {

}

- (id)initWithOverlay:(id <MKOverlay>)overlay {
    self = [super initWithOverlay:overlay];
    if (self) {
        self.strokeOverlay = (BOStrokeOverlay *)overlay;
    }

    return self;
}

- (BOOL)canDrawMapRect:(MKMapRect)mapRect
             zoomScale:(MKZoomScale)zoomScale {
    return YES;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];

    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);

    MKMapRect rasterElement = [self.strokeOverlay boundingMapRect];

    CGRect rasterRect = [self rectForMapRect:rasterElement];
    MKMapRect rect = [self mapRectForRect:rasterRect];
    CGContextFillRect(context, rasterRect);
    NSLog(@"%@  - %f, %f - %f, %f", NSStringFromCGRect(rasterRect), rasterElement.origin.x, rasterElement.origin.y, rasterElement.size.width, rasterElement.size.height);
}

@end