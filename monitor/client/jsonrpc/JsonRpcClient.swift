//
//  BOJsonRpcClient.m
//  viewer
//
//  Created by Andreas Würl on 24.10.12.
//  Copyright (c) 2012 Andreas Würl. All rights reserved.
//

import Foundation

/// Errors raised before a JSON-RPC request can be sent.
public enum JsonRpcClientError: Error {
    /// The configured service endpoint is not a usable URL.
    case invalidEndpoint(String)
}

public class JsonRpcClient: NSObject {

    let serviceEndpoint: URL?
    private let userAgent: UserAgent
    private let session: URLSession

    init(withServiceEndpoint serviceEndpoint: String,
         userAgent: UserAgent = UserAgent(),
         session: URLSession = .shared) {
        self.serviceEndpoint = URL(string: serviceEndpoint)
        self.userAgent = userAgent
        self.session = session
    }

    func call(callback: @escaping (_ response: [String:AnyObject]?, _ errorInServiceCall: Error?) -> Void,
              methodName: String, withArguments arguments: Int...) {

        guard let serviceEndpoint = serviceEndpoint else {
            callback(nil, JsonRpcClientError.invalidEndpoint(methodName))
            return
        }

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

        var request = URLRequest(url: serviceEndpoint);
        request.setValue("text/json", forHTTPHeaderField: "Content-Type")
        userAgent.apply(to: &request)
        request.setValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"
        request.httpBody = postData as Data
        //NSLog(@"%@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);

        let task = session.dataTask(with: request) {
            (data: Data?, response: URLResponse?, connectionError: Error?) -> Void in

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
        }
        task.resume()
    }
}
