
#import "BOViewController.h"
#import "BOJsonRpcClient.h"
#import "BORasterParameters.h"
#import "BORasterElement.h"
#import "BOMapViewDelegate.h"
#import "BOStrokeOverlay.h"

@interface BOViewController ()

@end

@implementation BOViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    timerPeriod = 20;

    pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(timerTick)
                                                  userInfo:nil
                                                   repeats:YES];

    mapViewDelegate = [[BOMapViewDelegate alloc] init];

    [_mapView setDelegate:mapViewDelegate];

    //CLLocationCoordinate2D worldCoords[4] = { {90,-180}, {90,180}, {-90,180}, {-90,-180} };
    CLLocationCoordinate2D worldCoords[4] = { {43,-100}, {43,-80}, {25,-80}, {25,-100} };
    MKPolygon *worldOverlay = [MKPolygon polygonWithCoordinates:worldCoords
                                                          count:4];
    [_mapView addOverlay:worldOverlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)timerTick {
    boolean_t update = false;

    int timeInterval;

    if (lastUpdate == nil) {
        update = true;
        timeInterval = 0;
    } else {
        timeInterval = (int) -[lastUpdate timeIntervalSinceNow];

        if (timeInterval >= timerPeriod) {
            update = true;
        }
    }

    if (update) {
        lastUpdate = [NSDate date];
        BOJsonRpcClient *jsonRpcClient = [[BOJsonRpcClient alloc] initWithServiceEndpoint:@"http://bo1.tryb.de:7080"];
        [jsonRpcClient setDelegate:self];
        [jsonRpcClient call:@"get_strokes_raster" withArgument:@60, @10000, @0, @1, nil ];
    }

    [_statusText setText:[NSString stringWithFormat:@"%d/%d", timerPeriod - timeInterval, timerPeriod]];
}


- (void)receivedResponse:(NSDictionary *)response {
    id rasterParameters = [[BORasterParameters alloc] initFromJson:response];

    NSString *referenceTimeString = response[@"t"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *referenceTime = [dateFormatter dateFromString:referenceTimeString];

    long referenceTimestamp = (long)[referenceTime timeIntervalSince1970];

    NSArray *dataArray = response[@"r"];

    NSMutableArray *overlays = [[NSMutableArray alloc] initWithCapacity:dataArray.count];

    for (NSArray *rasterData in dataArray) {
        BORasterElement* rasterElement = [[BORasterElement alloc] initWithRasterParameters:rasterParameters andReferenceTimestamp:referenceTimestamp fromArray:rasterData];
        BOStrokeOverlay* overlay = [[BOStrokeOverlay alloc] initWithStroke:rasterElement];
        [_mapView addOverlay:overlay];
        [overlays addObject:overlay];
    }
    NSLog(@"%@", overlays);
    NSLog(@"%d", overlays.count);
}


@end
