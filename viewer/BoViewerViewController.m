//
//  BoViewerViewController.m
//  viewer
//
//  Created by Andreas Würl on 21.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import "BoViewerViewController.h"
#import "BoViewerJsonRpcClient.h"

@interface BoViewerViewController ()

@end

@implementation BoViewerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    timerPeriod = 20;
    
    pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(timerTick)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)timerTick
{
    boolean_t update = false;

    int timeInterval;
    
    if (lastUpdate == nil) {
        update = true;
    } else {
        timeInterval = -[lastUpdate timeIntervalSinceNow];
    
        if (timeInterval >= timerPeriod)
        {
            update = true;
        }
    }
    
    if (update) {
        lastUpdate = [NSDate date];
        BoViewerJsonRpcClient* jsonRpcClient = [[BoViewerJsonRpcClient alloc] initWithServiceEndpoint:@"http://bo1.tryb.de:7080"];
        [jsonRpcClient call:@"check"];
    }
    
    [_statusText setText:[NSString stringWithFormat:@"%d/%d", timeInterval, timerPeriod ]];
}



@end
