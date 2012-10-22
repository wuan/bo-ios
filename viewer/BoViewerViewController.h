//
//  BoViewerViewController.h
//  viewer
//
//  Created by Andreas Würl on 21.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface BoViewerViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet NSTimer *timer;

@end
