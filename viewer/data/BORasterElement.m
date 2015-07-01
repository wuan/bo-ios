//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import "BORasterElement.h"
#import "BORasterParameters.h"


@interface BORasterElement ()
@property(nonatomic) BORasterParameters *rasterParameters;
@end

@implementation BORasterElement {

}

- (id)initWithRasterParameters:(BORasterParameters *)rasterParameters andReferenceTimestamp:(long)referenceTimestamp fromArray:(NSArray *)dataArray {
    long timestamp = referenceTimestamp + 1000 * [dataArray[3] integerValue];
    NSInteger multiplicity = [dataArray[2] integerValue];
    float xCoordinate = [rasterParameters getCenterLongitude:[dataArray[0] integerValue]];
    float yCoordinate = [rasterParameters getCenterLatitude:[dataArray[1] integerValue]];
    float width = [rasterParameters getLongitudeDelta];
    float height = [rasterParameters getLatitudeDelta];

    return [self initWithTimestamp:timestamp andMultiplicity:multiplicity andX:xCoordinate andY:yCoordinate andWidth:width andHeight:height];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Raster%@", [super description]];
}

@end