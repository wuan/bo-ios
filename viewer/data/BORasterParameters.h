//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface BORasterParameters : NSObject {
    float lon_start;
    float lat_start;
    float lon_delta;
    float lat_delta;
    int lon_count;
    int lat_count;
}

- initFromJson:(NSDictionary *)json;

- (float)getRectCenterLongitude;

- (float)getRectCenterLatitude;

- (float)getCenterLongitude:(int)offset;

- (float)getCenterLatitude:(int)offset;

- (float)getLongitudeDelta;

- (float)getLatitudeDelta;
@end