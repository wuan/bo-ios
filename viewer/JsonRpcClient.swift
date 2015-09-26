//
//  BOJsonRpcClient.m
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

import Foundation

public class JsonRpcClient : NSObject {
    
    var delegate:JsonRpcClientDelegate
    let serviceEndpoint :NSURL!
    
    init(withServiceEndpoint serviceEndpoint: String) {
        self.serviceEndpoint = NSURL(string: serviceEndpoint)
    }
    
    func call(methodName :String, withArguments arguments: AnyObject...) {
        
        var callArguments :[String:AnyObject] = ["id": 1, "method": methodName]
        
        
        if (arguments.count > 0) {
            callArguments["params"] = arguments.map({(object:AnyObject) -> String in object.description})
        }
        
        var postData :NSData
        do {
            postData = try NSJSONSerialization.dataWithJSONObject(callArguments, options: NSJSONWritingOptions.PrettyPrinted)
        } catch let error {
            delegate.receivedResponse(nil, error)
            return
        }
        
        var request = NSMutableURLRequest(URL: self.serviceEndpoint);
        request.setValue("text/json", forHTTPHeaderField:"Content-Type")
        request.setValue("bo-ios", forHTTPHeaderField:"User-Agent")
        request.setValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
        //NSLog(@"%@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response:NSURLResponse?, data:NSData?, connectionError:NSError?) -> Void in
            if (data!.length > 0 && connectionError == nil) {
                //NSString *jsonStringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                //NSError *jsonError = [[NSError alloc] init];
                do {
                    let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0)) as! [String:AnyObject]
                    NSLog("\(jsonResponse)");
                    delegate.receivedResponse(jsonResponse)
                } catch let error {
                    delegate.receivedResponse(nil, error)
                }
            }
            else if (data!.length == 0 && connectionError == nil) {
                NSLog("Nothing was downloaded.")
            }
            else if (connectionError != nil) {
                NSLog("Error = \(connectionError)");
            }
        })
    }
    
    func setDelegate(delegate:JsonRpcClientDelegate) {
        self.delegate = delegate
    }
}