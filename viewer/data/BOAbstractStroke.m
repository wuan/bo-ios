//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BOAbstractStroke.h"


@implementation BOAbstractStroke
{
    long timestamp;
    float longitude;
    float latitude;
    int multiplicity;
}

@synthesize timestamp, longitude, latitude, multiplicity;

- (NSString *)description {
    return [NSString stringWithFormat: @"Stroke: %d (%.4f, %.4f) %d", timestamp, longitude, latitude, multiplicity];
}
@end