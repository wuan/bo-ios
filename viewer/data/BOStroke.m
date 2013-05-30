//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <MapKit/MapKit.h>
#import "BOStroke.h"

@interface BOStroke()
@end

@implementation BOStroke
{
}

@synthesize timestamp = _timestamp, multiplicity = _multiplicity;

- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate {
    return [self initWithTimestamp:timestamp andMultiplicity:multiplicity andX:xCoordinate andY:yCoordinate andWidth:0.0 andHeight:0.0];
}

- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate andWidth:(double)width andHeight:(double)height {
    _timestamp = timestamp;
    _multiplicity = multiplicity;
    envelope.origin.x = xCoordinate;
    envelope.origin.y = yCoordinate;
    envelope.size.width = width;
    envelope.size.height = height;
    return self;
}

- (const MKMapPoint *)getLocation {
    return &envelope.origin;
}

- (const MKMapRect*)getEnvelope {
    return &envelope;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Stroke: %ld (%.4f, %.4f) %d", _timestamp, envelope.origin.x, envelope.origin.y, _multiplicity];
}


@end