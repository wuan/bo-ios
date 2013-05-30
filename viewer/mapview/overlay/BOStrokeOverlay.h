//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class BOStroke;

@interface BOStrokeOverlay : NSObject <MKOverlay> {
    const MKMapRect *boundingMapRect;
    const BOStroke *stroke;
}

- (id)initWithStroke:(BOStroke*)inputStroke;
- (const BOStroke *)getStroke;
- (NSString *)description;

@end