//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <pthread.h>
#import "BOStrokesOverlay.h"
#import "BORasterElement.h"
#import "BOStroke.h"


@implementation BOStrokesOverlay {

}

@synthesize strokes, strokeCount;

- (id)init
{
    self = [super init];
    if (self)
    {
        // initialize read-write lock for drawing and updates
        pthread_rwlock_init(&rwLock, NULL);
    }
    return self;
}

@end