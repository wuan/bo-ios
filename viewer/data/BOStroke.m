//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BOStroke.h"


@implementation BOStroke
{
    long timestamp;
    MKMapPoint location;
    int multiplicity;
}

@synthesize timestamp, multiplicity;

- (void)setLongitude:(double)x {
    location.x = x;
}

- (void)setLatitude:(double)y {
    location.y = y;
}

- (const MKMapPoint *)getLocation {
    return &location;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Stroke: %d (%.4f, %.4f) %d", timestamp, longitude, latitude, multiplicity];
}
@end