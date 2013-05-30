//
// Created by Andreas Würl on 30.05.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface BOMapViewDelegate : NSObject <MKMapViewDelegate>
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id < MKOverlay >)overlay;
@end