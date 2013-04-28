//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface BOAbstractStroke : NSObject

@property long timestamp;
@property float longitude;
@property float latitude;
@property int multiplicity;

- (NSString *)description;
@end