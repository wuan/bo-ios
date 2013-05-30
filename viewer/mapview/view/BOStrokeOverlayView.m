//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BOStrokeOverlayView.h"


@implementation BOStrokeOverlayView {

}

- (id)initWithOverlay:(id <MKOverlay>)overlay {
    self = [super initWithOverlay:overlay];
    if (self) {

    }

    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
}

@end