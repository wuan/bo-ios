//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BORasterParameters.h"


@implementation BORasterParameters {
}

- (id)initFromJson:(NSDictionary *)json {
    lon_start = [json[@"x0"] floatValue];
    lat_start = [json[@"y1"] floatValue];
    lon_delta = [json[@"xd"] floatValue];
    lat_delta = [json[@"yd"] floatValue];
    lon_count = [json[@"xc"] integerValue];
    lat_count = [json[@"yc"] integerValue];

    return self;
}

-(float) getRectCenterLongitude {
    return lon_start + lon_delta * lon_count / 2.0f;
}

-(float) getRectCenterLatitude {
    return lat_start - lat_delta * lat_count / 2.0f;
}

-(float) getCenterLongitude:(int)offset {
    return lon_start + lon_delta * (offset + 0.5f);
}

-(float) getCenterLatitude:(int) offset {
    return lat_start - lat_delta * (offset + 0.5f);
}

-(float) getLongitudeDelta {
    return lon_delta;
}

-(float) getLatitudeDelta {
    return lat_delta;
}

@end