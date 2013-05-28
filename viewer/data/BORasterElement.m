//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BORasterElement.h"
#import "BORasterParameters.h"


@interface BORasterElement ()
@property(nonatomic) BORasterParameters *rasterParameters;
@end

@implementation BORasterElement {

}

- (id)initWithRasterParameters:(BORasterParameters *)rasterParameters andTimestamp:(long)referenceTimestamp fromArray:(NSArray *)dataArray {
    [self setLongitude:[rasterParameters getCenterLongitude:[[dataArray objectAtIndex:0] integerValue]]];
    [self setLatitude:[rasterParameters getCenterLatitude:[[dataArray objectAtIndex:1] integerValue]]];
    [self setMultiplicity:[[dataArray objectAtIndex:2] integerValue]];
    [self setTimestamp:referenceTimestamp + 1000 * [[dataArray objectAtIndex:3] integerValue]];
    [self setRasterParameters:rasterParameters];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Raster%@", [super description]];
}
@end