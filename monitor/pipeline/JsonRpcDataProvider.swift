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
        let request = JsonRpcDataProvider.gridRequest(for: parameters)
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
        methodName: request.method,
        arguments: request.arguments)
    }

    /// The JSON-RPC method and positional arguments a request must use.
    ///
    /// The backend exposes a global and a local grid method. Sending a global or
    /// local region to the generic named-region method is not equivalent: that
    /// method clamps its region into the named range, so a global request would
    /// be served as a named region (Europe) rather than the whole globe. This
    /// source never names a region, so a global request drops the region
    /// argument, a local request carries its data area instead, and any other
    /// region falls back to the global method.
    static func gridRequest(for parameters: Parameters) -> (method: String, arguments: [Int]) {
        switch parameters.region {
        case Parameters.localRegion:
            guard let dataArea = parameters.dataArea else {
                // A local request without a data area cannot be bounded, so fall
                // back to the global method rather than send a region-less call.
                return (Self.globalMethod, Self.globalArguments(parameters))
            }
            return ("get_local_strikes_grid",
                    [dataArea.x,
                     dataArea.y,
                     parameters.rasterBaselength,
                     parameters.intervalDuration,
                     parameters.intervalOffset,
                     JsonRpcDataProvider.countThresholdArgument,
                     dataArea.scale])

        case Parameters.globalRegion:
            return (Self.globalMethod, Self.globalArguments(parameters))

        default:
            // Any other region falls back to the global method, mirroring the
            // local-without-a-data-area rule; the app never sends a named region
            // on this source.
            return (Self.globalMethod, Self.globalArguments(parameters))
        }
    }

    private static let globalMethod = "get_global_strikes_grid"

    private static func globalArguments(_ parameters: Parameters) -> [Int] {
        return [parameters.intervalDuration,
                parameters.rasterBaselength,
                parameters.intervalOffset,
                JsonRpcDataProvider.countThresholdArgument]
    }
}
