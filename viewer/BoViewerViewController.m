//
//  BoViewerViewController.m
//  viewer
//
//  Created by Andreas Würl on 21.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import "BoViewerViewController.h"

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
    }
    
    [_statusText setText:[NSString stringWithFormat:@"%d/%d", timeInterval, timerPeriod ]];
}

@end
