//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <MapKit/MKGeometry.h>
#import <MapKit/MKOverlay.h>

@interface BOStroke : NSObject {
    MKCoordinateRegion envelope;
}

@property (readonly) long timestamp;
@property (readonly) int multiplicity;

- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate;
- (id)initWithTimestamp:(long)timestamp andMultiplicity:(int)multiplicity andX:(double)xCoordinate andY:(double)yCoordinate andWidth:(double)width andHeight:(double)height;

- (CLLocationCoordinate2D const *)getLocation;

- (MKCoordinateRegion const *)getEnvelope;

- (NSString *)description;

@end