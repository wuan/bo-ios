//
//  BOJsonRpcClient.m
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

import Foundation

public class JsonRpcClient: NSObject {

    let serviceEndpoint: NSURL!

    init(withServiceEndpoint serviceEndpoint: String) {
        self.serviceEndpoint = NSURL(string: serviceEndpoint)
    }

    func call(callback: @escaping (_ response: [String:AnyObject]?, _ errorInServiceCall: Error?) -> Void,
              methodName: String, withArguments arguments: Int...) {

        var callArguments: [String:AnyObject] = ["id": 1 as AnyObject, "method": methodName as AnyObject]

        if (arguments.count > 0) {
            callArguments["params"] = arguments as AnyObject
        }

        var postData: NSData
        do {
            postData = try JSONSerialization.data(withJSONObject: callArguments, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData
        } catch let error {
            callback(nil, error)
            return
        }

        let request = NSMutableURLRequest(url: self.serviceEndpoint as URL);
        request.setValue("text/json", forHTTPHeaderField: "Content-Type")
        request.setValue("bo-ios", forHTTPHeaderField: "User-Agent")
        request.setValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"
        request.httpBody = postData as Data
        //NSLog(@"%@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);

        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler: {
            (response: URLResponse?, data: Data?, connectionError: Error?) -> Void in

            if let data = data {

                if data.count > 0 && connectionError == nil {
                    //NSString *jsonStringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                    //NSError *jsonError = [[NSError alloc] init];
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String:AnyObject]
                        //NSLog("\(jsonResponse)");
                        callback(jsonResponse, nil)
                    } catch let error {
                        callback(nil, error)
                    }
                }
            } else if (connectionError == nil) {
                NSLog("Nothing was downloaded.")
            } else if (connectionError != nil) {
                NSLog("Error = \(String(describing: connectionError))");
            }
        })
    }
}
