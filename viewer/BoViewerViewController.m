//
//  BoViewerViewController.m
//  viewer
//
//  Created by Andreas Würl on 21.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import "BoViewerViewController.h"
#import "BoViewerJsonRpcClient.h"
#import "BORasterParameters.h"
#import "BORasterElement.h"

@interface BoViewerViewController ()

@end

@implementation BoViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    timerPeriod = 20;

    pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(timerTick)
                                                  userInfo:nil
                                                   repeats:YES];
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
        BoViewerJsonRpcClient *jsonRpcClient = [[BoViewerJsonRpcClient alloc] initWithServiceEndpoint:@"http://bo1.tryb.de:7080"];
        [jsonRpcClient setDelegate:self];
        [jsonRpcClient call:@"get_strokes_raster" withArgument:@60, @10000, @0, @1, nil ];
    }

    [_statusText setText:[NSString stringWithFormat:@"%d/%d", timerPeriod - timeInterval, timerPeriod]];
}


- (void)receivedResponse:(NSDictionary *)response {
    id rasterParameters = [[BORasterParameters alloc] initFromJson:response];

    NSString *referenceTimeString = [response objectForKey:@"t"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *referenceTime = [dateFormatter dateFromString:referenceTimeString];

    long referenceTimestamp = (long)[referenceTime timeIntervalSince1970];

    NSArray *dataArray = [response objectForKey:@"r"];

    NSMutableArray *rasterElements = [[NSMutableArray alloc] initWithCapacity:dataArray.count];

    for (NSArray *rasterData in dataArray) {
        BORasterElement *rasterElement = [[BORasterElement alloc] initWithRasterParameters:rasterParameters andTimestamp:referenceTimestamp fromArray:rasterData];
        [rasterElements addObject:rasterElement];
    }
    NSLog(@"%@", rasterElements);
    NSLog(@"%d", rasterElements.count);
}

@end
