
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class BOMapViewDelegate;

@interface BOViewController : UIViewController
{
    NSTimer* pollingTimer;
    NSDate* lastUpdate;
    BOMapViewDelegate* mapViewDelegate;
    int timerPeriod;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *statusText;

@end
