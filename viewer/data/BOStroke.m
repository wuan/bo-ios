//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "BOStroke.h"

@interface BOStroke ()
@end

@implementation BOStroke {
}

@synthesize timestamp = _timestamp, multiplicity = _multiplicity;

- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate {
    return [self initWithTimestamp:timestamp andMultiplicity:multiplicity andX:xCoordinate andY:yCoordinate andWidth:0.0 andHeight:0.0];
}

- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate andWidth:(double)width andHeight:(double)height {
    _timestamp = timestamp;
    _multiplicity = multiplicity;
    envelope.center.longitude = xCoordinate;
    envelope.center.latitude = yCoordinate;
    envelope.span.longitudeDelta = width;
    envelope.span.latitudeDelta = height;
    return self;
}

- (const CLLocationCoordinate2D *)getLocation {
    return &envelope.center;
}

- (const MKCoordinateRegion *)getEnvelope {
    return &envelope;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Stroke: %ld (%.4f, %.4f) %d", _timestamp, envelope.center.longitude, envelope.center.latitude, _multiplicity];
}


@end