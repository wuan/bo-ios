//
//  BoViewerJsonRpcClient.m
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import "BoViewerJsonRpcClient.h"

@interface BoViewerJsonRpcClient()
@property(nonatomic, strong) NSURL *_serviceEndpoint;
@end

@implementation BoViewerJsonRpcClient

- (id) initWithServiceEndpoint:(NSString*) serviceEndpoint {
    self._serviceEndpoint = [NSURL URLWithString:serviceEndpoint];
    return self;
}

- (void) call:(NSString*) methodName {
    [self call:methodName withArgument:nil];
}

- (void) call:(NSString*) methodName withArgument:(NSString*)firstArgument, ... {
    NSArray* arguments = [[NSArray alloc] init];
    NSString* eachArgument;
    va_list argumentList;
    if (firstArgument)
    {
        arguments = [arguments arrayByAddingObject:firstArgument];
        va_start(argumentList, firstArgument);
        while ((eachArgument = va_arg(argumentList, NSString*)))
            arguments = [arguments arrayByAddingObject:eachArgument];
        va_end(argumentList);
    }
    
    NSArray* argumentKeys = [NSArray arrayWithObjects:@"id", @"method", nil];
    NSArray* argumentValues = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], methodName, nil];
    
    if ([arguments count] > 0) {
        argumentKeys = [argumentKeys arrayByAddingObject:@"params"];
        argumentValues = [argumentValues arrayByAddingObject:arguments];
    }
    
    NSDictionary* argumentDict = [NSDictionary dictionaryWithObjects: argumentValues forKeys:argumentKeys];
    
    NSError* error;
    NSData* postData = [NSJSONSerialization dataWithJSONObject:argumentDict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self._serviceEndpoint];
    [request setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"bo-ios" forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%i", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    
}


@end
