//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import <MapKit/MapKit.h>
#import "BOStrokeOverlay.h"
#import "BORasterElement.h"

@implementation BOStrokeOverlay {
    CLLocationCoordinate2D coordinate;
}

- (id)initWithStroke:(BOStroke *)inputStroke {
    stroke = inputStroke;
    boundingMapRect = [stroke getEnvelope];
    coordinate = CLLocationCoordinate2DMake(boundingMapRect->origin.x, boundingMapRect->origin.y);
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Overlay(%@)", [stroke description]];
}

- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (MKMapRect)boundingMapRect {
    return *boundingMapRect;
}

- (const BOStroke *)getStroke {
    return stroke;
}

@end