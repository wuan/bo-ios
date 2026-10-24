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

/// Describes what data a provider can serve.
///
/// Sources are not interchangeable: the Blitzortung HTTP source serves strike
/// lists only, while the JSON-RPC source can serve grid-aggregated data and
/// clusters. Consumers ask the active provider instead of assuming.
public struct DataProviderCapabilities: Equatable {
    /// Whether the source can serve grid-aggregated data.
    public let supportsGrid: Bool
    /// Whether the source can serve cluster data.
    public let supportsClusters: Bool

    public init(supportsGrid: Bool, supportsClusters: Bool) {
        self.supportsGrid = supportsGrid
        self.supportsClusters = supportsClusters
    }
}

/// Supplies lightning data for a set of request parameters.
///
/// Defined independently of any transport so providers can be replaced without
/// changing consumers.
public protocol DataProvider {
    /// Fetches data, invoking `completion` with a result or an error.
    func fetchData(parameters: Parameters, completion: @escaping (_ result: Result?, _ error: Error?) -> Void)
    /// What this provider can serve.
    var capabilities: DataProviderCapabilities { get }
}

public extension DataProvider {
    /// Providers that do not declare capabilities are assumed unable to serve
    /// grid data or clusters, so consumers never request what was not promised.
    var capabilities: DataProviderCapabilities {
        return DataProviderCapabilities(supportsGrid: false, supportsClusters: false)
    }
}
