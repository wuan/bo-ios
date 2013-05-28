//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "BOStroke.h"

@class BORasterParameters;

@interface BORasterElement : BOStroke

-(id) initWithRasterParameters:(const BORasterParameters*)rasterParameters andTimestamp:(long)referenceTimestamp fromArray:(NSArray*)dataArray;

- (NSString *)description;
@end