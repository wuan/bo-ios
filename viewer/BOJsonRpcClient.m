//
//  BOJsonRpcClient.m
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import "BOJsonRpcClient.h"
#import "BOJsonRpcClientDelegate.h"

@interface BOJsonRpcClient ()
@property(nonatomic, strong) NSURL *serviceEndpoint;
@property(retain, nonatomic) id <BOJsonRpcClientDelegate> delegate;
@end

@implementation BOJsonRpcClient

@synthesize delegate = _delegate;

- (id)initWithServiceEndpoint:(NSString *)serviceEndpoint {
    _serviceEndpoint = [NSURL URLWithString:serviceEndpoint];

    return self;
}

- (void)call:(NSString *)methodName {
    [self call:methodName withArgument:nil];
}

- (void)call:(NSString *)methodName withArgument:(id)firstArgument, ... {
    NSArray *arguments = [[NSArray alloc] init];
    id eachArgument;
    va_list argumentList;
    if (firstArgument) {
        arguments = [arguments arrayByAddingObject:firstArgument];
        va_start(argumentList, firstArgument);
        while ((eachArgument = va_arg(argumentList, NSString*))) {
            arguments = [arguments arrayByAddingObject:eachArgument];
        }
        va_end(argumentList);
    }

    NSArray *argumentKeys = [NSArray arrayWithObjects:@"id", @"method", nil];
    NSArray *argumentValues = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], methodName, nil];

    if ([arguments count] > 0) {
        argumentKeys = [argumentKeys arrayByAddingObject:@"params"];
        argumentValues = [argumentValues arrayByAddingObject:arguments];
    }

    NSDictionary *argumentDict = [NSDictionary dictionaryWithObjects:argumentValues forKeys:argumentKeys];

    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:argumentDict
                                                       options:NSJSONWritingPrettyPrinted error:&error];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_serviceEndpoint];
    [request setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"bo-ios" forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%i", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    //NSLog(@"%@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);

    [NSURLConnection
            sendAsynchronousRequest:request
                              queue:[[NSOperationQueue alloc] init]
                  completionHandler:^(NSURLResponse *response,
                          NSData *data,
                          NSError *connectionError) {
                      if ([data length] > 0 && connectionError == nil) {
                          //NSString *jsonStringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                          NSError *jsonError = [[NSError alloc] init];
                          NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                          NSLog(@"%@", jsonResponse);
                          [[self delegate] receivedResponse:[jsonResponse objectForKey:@"result"]];
                      }
                      else if ([data length] == 0 && connectionError == nil) {
                          NSLog(@"Nothing was downloaded.");
                      }
                      else if (connectionError != nil) {
                          NSLog(@"Error = %@", connectionError);
                      }

                  }];
}

- (id)delegate {
    return _delegate;
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}
@end
