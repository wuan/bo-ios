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
}
