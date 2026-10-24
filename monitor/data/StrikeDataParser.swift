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

/// Errors raised while turning a provider response into a ``Result``.
public enum StrikeDataParserError: Error {
    case missingResult
    case missingReferenceTime
    case invalidReferenceTime(String)
}

/// Parses provider responses into the shared domain ``Result``.
///
/// The parser is transport-agnostic: it takes the decoded JSON object from any
/// provider so all data sources produce the same domain model.
public struct StrikeDataParser {

    /// Provider timestamps are UTC in the form `yyyyMMdd'T'HH:mm:ss`.
    public static let referenceTimeFormat = "yyyyMMdd'T'HH:mm:ss"

    public init() {}

    /// Parses a full JSON-RPC style response dictionary.
    public func parse(response: [String: AnyObject], parameters: Parameters) throws -> Result {
        guard let result = response["result"] as? [String: AnyObject] else {
            throw StrikeDataParserError.missingResult
        }
        return try parse(result: result, parameters: parameters)
    }

    /// Parses the `result` payload of a response.
    public func parse(result: [String: AnyObject], parameters: Parameters) throws -> Result {
        guard let referenceTimeString = result["t"] as? String else {
            throw StrikeDataParserError.missingReferenceTime
        }
        guard let referenceTimestamp = Self.referenceTimestamp(from: referenceTimeString) else {
            throw StrikeDataParserError.invalidReferenceTime(referenceTimeString)
        }

        let rasterParameters = GridParameters(fromDict: result)

        var strikes: [Strike] = []
        if let rasterParameters = rasterParameters, let dataArray = result["r"] as? [[Int]] {
            strikes = dataArray.map { rasterData in
                RasterElement(rasterParameters: rasterParameters,
                              withReferenceTimestamp: referenceTimestamp,
                              fromArray: rasterData)
            }
        }

        return Result(parameters: parameters,
                      referenceTimestamp: referenceTimestamp,
                      strikes: strikes,
                      rasterParameters: rasterParameters,
                      histogram: Self.histogram(from: result))
    }

    /// The strike-rate histogram a grid response reports, or `nil` when it
    /// carries none.
    ///
    /// The histogram arrives with the grid result, so the histogram overlay
    /// needs no request of its own; a response without the key is not an error.
    public static func histogram(from result: [String: AnyObject]) -> [Int]? {
        guard let values = result["h"] as? [Any] else { return nil }
        return values.compactMap { ($0 as? NSNumber)?.intValue }
    }

    /// Converts a provider reference-time string into a Unix timestamp, or `nil`
    /// when it cannot be parsed.
    public static func referenceTimestamp(from string: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = referenceTimeFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let date = formatter.date(from: string) else {
            return nil
        }
        return Int(date.timeIntervalSince1970)
    }
}
