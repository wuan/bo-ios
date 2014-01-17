//
// Created by Andreas Würl on 29.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import <MapKit/MapKit.h>
#import "BOStrokeOverlay.h"
#import "BORasterElement.h"

@implementation BOStrokeOverlay {
    CLLocationCoordinate2D coordinate;
}

- (id)initWithStroke:(BOStroke *)inputStroke {
    stroke = inputStroke;
    const MKCoordinateRegion *strokeRegion = stroke.getEnvelope;

    CLLocationCoordinate2D topLeftCoordinate =
            CLLocationCoordinate2DMake(strokeRegion->center.latitude
                    + (strokeRegion->span.latitudeDelta / 2.0),
                    strokeRegion->center.longitude
                            - (strokeRegion->span.longitudeDelta / 2.0));

    MKMapPoint topLeftMapPoint = MKMapPointForCoordinate(topLeftCoordinate);

    CLLocationCoordinate2D bottomRightCoordinate =
            CLLocationCoordinate2DMake(strokeRegion->center.latitude
                    - (strokeRegion->span.latitudeDelta / 2.0),
                    strokeRegion->center.longitude
                            + (strokeRegion->span.longitudeDelta / 2.0));

    MKMapPoint bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoordinate);

    boundingMapRect = MKMapRectMake(topLeftMapPoint.x,
            topLeftMapPoint.y,
            fabs(bottomRightMapPoint.x - topLeftMapPoint.x),
            fabs(bottomRightMapPoint.y - topLeftMapPoint.y));

    coordinate = strokeRegion->center;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Overlay(%@)", [stroke description]];
}

- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (MKMapRect)boundingMapRect {
    return boundingMapRect;
}

- (const BOStroke *)getStroke {
    return stroke;
}

@end