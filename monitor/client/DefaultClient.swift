/*

Copyright 2015-2016 Andreas Würl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

import Foundation

public class DefaultClient {

    public func fetchData(parameters: Parameters, callback: (Result) -> Void) {
        let jsonRpcClient = JsonRpcClient(withServiceEndpoint: "http://bo-test.tryb.de")

        let responseHandler = {
            (response: [String:AnyObject]?, errorInServiceCall: ErrorType?) -> Void in
            self.receivedResponse(callback, parameters: parameters, response: response, errorInServiceCall: errorInServiceCall)
        }

        jsonRpcClient.call(responseHandler,
                methodName: "get_strikes_grid",
                withArguments: parameters.intervalDuration,
                parameters.rasterBaselength,
                parameters.intervalOffset,
                parameters.region,
                parameters.countThreshold);

    }

    func receivedResponse(callback: (Result) -> Void, parameters: Parameters, response: [String:AnyObject]?, errorInServiceCall: ErrorType?) {
        if let response = response {
            if let result = response["result"] as? [String:AnyObject] {

                let rasterParameters = RasterParameters(fromDict: result)

                let referenceTimeString = result["t"] as! String
                let dateFormatter = NSDateFormatter()

                dateFormatter.dateFormat = "yyyyMMdd'T'HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone.localTimeZone()
                let referenceTime = dateFormatter.dateFromString(referenceTimeString)

                let referenceTimestamp = Int((referenceTime?.timeIntervalSince1970)!)

                let dataArray = result["r"] as! [[Int]];

                let strikes = dataArray.map({
                    (rasterData: [Int]) -> Strike in
                    return RasterElement(rasterParameters: rasterParameters, withReferenceTimestamp: referenceTimestamp, fromArray: rasterData)
                })

                let result = Result(parameters: parameters, referenceTimestamp: referenceTimestamp, strikes: strikes, rasterParameters: rasterParameters)
                callback(result)

                //NSLog("\(overlays)");
                NSLog("# strikes: \(strikes.count)");
            }
        } else {
            if let error = errorInServiceCall {
                NSLog("error in service call: \(error)")
            }
        }
    }
}
