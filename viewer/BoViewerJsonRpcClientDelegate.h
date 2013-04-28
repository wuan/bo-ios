//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
//


#import <Foundation/Foundation.h>

@protocol BoViewerJsonRpcClientDelegate <NSObject>

-(void)receivedResponse:(NSDictionary*)response;
-(void)errorInServiceCall:(NSError*)error;

@end