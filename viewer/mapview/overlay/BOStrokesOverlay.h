//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class BOStroke;

@interface BOStrokesOverlay : NSObject <MKOverlay> {
    MKMapRect boundingMapRect;

    BOStroke *strokes;
    NSUInteger strokeCount;

    pthread_rwlock_t rwLock;
}

@property (readonly) BOStroke *strokes;
@property (readonly) NSUInteger strokeCount;

- (id)init:(CLLocationCoordinate2D)coord;

- (MKMapRect)replaceStrokes:(CLLocationCoordinate2D)coord;

- (void)lockForReading;

- (void)unlockForReading;
@end