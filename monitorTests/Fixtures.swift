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

/// Saved sample provider responses used by the parser and pipeline tests.
enum Fixtures {

    /// A well-formed response with a 20x20 grid and three raster elements.
    static let completeResponseJSON = """
    {"id":1,"result":{"x0":-10.0,"xd":1.0,"xc":20,"y1":55.0,"yd":1.0,"yc":20,"t":"20160101T12:00:00","r":[[0,0,1,0],[5,5,3,-120],[19,19,2,-3000]]}}
    """

    /// A response that omits grid parameters entirely.
    static let responseWithoutGridJSON = """
    {"id":1,"result":{"t":"20160101T12:00:00","r":[]}}
    """

    /// A response whose reference time cannot be parsed.
    static let responseWithInvalidTimeJSON = """
    {"id":1,"result":{"x0":-10.0,"xd":1.0,"xc":20,"y1":55.0,"yd":1.0,"yc":20,"t":"not-a-time","r":[]}}
    """

    /// Reference timestamp for `20160101T12:00:00` interpreted as UTC.
    static let referenceTimestamp = 1_451_649_600

    static func decode(_ json: String) -> [String: AnyObject] {
        let data = json.data(using: .utf8)!
        return try! JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
    }

    // MARK: - Blitzortung HTTP strike logs

    /// A valid strike log line. Defaults to 2019-02-13T06:15:00Z.
    static func strikeLogLine(date: String = "2019-02-13",
                              time: String = "06:15:00.000000000",
                              latitude: Double = 37.714012,
                              longitude: Double = 26.801138,
                              altitude: Int = 0) -> String {
        return "\(date) \(time) pos;\(latitude);\(longitude);\(altitude) str;0 dev;7013 sta;18;85;1903,2326,2325"
    }

    /// A log file body built from the given lines.
    static func strikeLog(_ lines: [String]) -> String {
        return lines.joined(separator: "\n") + "\n"
    }

    /// A log line whose position values cannot be parsed.
    static let malformedStrikeLogLine = "2019-02-13 06:15:00.000000000 pos;bogus;value"

    /// A log line without any position field.
    static let positionlessStrikeLogLine = "2019-02-13 06:15:00.000000000 str;0 dev;7013"

    /// Epoch seconds for `2019-02-13T05:25:00Z`.
    static let strikeLogTimestamp0525 = 1_550_035_500
    /// Epoch seconds for `2019-02-13T06:15:00Z`.
    static let strikeLogTimestamp0615 = 1_550_038_500
    /// Epoch seconds for `2019-02-13T06:20:00Z`.
    static let strikeLogTimestamp0620 = 1_550_038_800
    /// Epoch seconds for `2019-02-13T06:25:00Z`.
    static let strikeLogTimestamp0625 = 1_550_039_100
    /// Epoch seconds for `2019-02-13T06:30:00Z`.
    static let strikeLogTimestamp0630 = 1_550_039_400
    /// Epoch seconds for `2019-02-13T07:30:00Z`.
    static let strikeLogTimestamp0730 = 1_550_043_000
}
