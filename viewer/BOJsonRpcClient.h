//
//  BOJsonRpcClient.h
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BOJsonRpcClient : NSObject

- (id)initWithServiceEndpoint:(NSString *)serviceEndpoint;

- (void)call:(NSString *)methodName;

- (void)call:(NSString *)methodName withArgument:(id)argument, ... NS_REQUIRES_NIL_TERMINATION;

- (id)delegate;

- (void)setDelegate:(id)delegate;

@end
