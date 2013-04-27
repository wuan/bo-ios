//
//  BoViewerJsonRpcClient.h
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BoViewerJsonRpcClient : NSObject

@property(nonatomic, strong) NSMutableData *_receivedData;

- (id) initWithServiceEndpoint:(NSString*) serviceEndpoint;

- (void) call:(NSString*) methodName;

- (void) call:(NSString*) methodName withArgument:(id)argument, ... NS_REQUIRES_NIL_TERMINATION;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end
