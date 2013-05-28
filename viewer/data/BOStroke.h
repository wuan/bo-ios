//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <MapKit/MKGeometry.h>

@interface BOStroke : NSObject

@property long timestamp;
@property MKMapPoint location;
@property int multiplicity;

- (void)setLongitude:(double) x;
- (void)setLatitude:(double) y;
- (MKMapPoint const *)getLocation;
- (NSString *)description;
@end