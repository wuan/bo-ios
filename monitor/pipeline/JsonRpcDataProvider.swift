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

/// ``DataProvider`` backed by the blitzortung JSON-RPC service.
///
/// Wraps the existing ``JsonRpcClient`` and parses the response through
/// ``StrikeDataParser`` so the rest of the app sees domain results.
public final class JsonRpcDataProvider: DataProvider {

    /// The JSON-RPC backend serves both grid-aggregated data and clusters.
    public let capabilities = DataProviderCapabilities(supportsGrid: true, supportsClusters: true)

    /// The grid method's positional count-threshold argument.
    ///
    /// The method signature is positional and expects a threshold in its last
    /// position, but the app has no threshold control and always requests with
    /// it inactive, so the argument is sent as this constant.
    public static let countThresholdArgument = 0

    private let client: JsonRpcClient
    private let parser: StrikeDataParser

    public init(serviceEndpoint: String,
                userAgent: UserAgent = UserAgent(),
                parser: StrikeDataParser = StrikeDataParser(),
                session: URLSession = .shared) {
        self.client = JsonRpcClient(withServiceEndpoint: serviceEndpoint, userAgent: userAgent, session: session)
        self.parser = parser
    }

    public func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        let parser = self.parser
        client.call(callback: { response, errorInServiceCall in
            if let errorInServiceCall = errorInServiceCall {
                completion(nil, errorInServiceCall)
                return
            }
            guard let response = response else {
                completion(nil, StrikeDataParserError.missingResult)
                return
            }
            do {
                completion(try parser.parse(response: response, parameters: parameters), nil)
            } catch {
                completion(nil, error)
            }
        },
        methodName: "get_strikes_grid",
        withArguments: parameters.intervalDuration,
        parameters.rasterBaselength,
        parameters.intervalOffset,
        parameters.region,
        JsonRpcDataProvider.countThresholdArgument)
    }
}
