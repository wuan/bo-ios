//
//  BoViewerJsonRpcClient.h
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BoViewerJsonRpcClient : NSObject

- (id) initWithServiceEndpoint:(NSString*) serviceEndpoint;
- (void) call:(NSString*) methodName;
- (void) call:(NSString*) methodName withArgument:(NSString*)argument, ...;
@end
