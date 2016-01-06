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

public class RasterParameters {
    let longitudeStart: Double
    let longitudeDelta: Double
    let longitudeCount: Int
    let latitudeStart: Double
    let latitudeDelta: Double
    let latitudeCount: Int

    public init(longitudeStart: Double, longitudeDelta: Double, longitudeCount: Int, latitudeStart: Double, latitudeDelta: Double, latitudeCount: Int) {
        self.longitudeStart = longitudeStart
        self.longitudeDelta = longitudeDelta
        self.longitudeCount = longitudeCount
        self.latitudeStart = latitudeStart
        self.latitudeDelta = latitudeDelta
        self.latitudeCount = latitudeCount
    }

    public convenience init(fromDict dict: [String:AnyObject]) {
        self.init(longitudeStart: dict["x0"] as! Double, longitudeDelta: dict["xd"] as! Double, longitudeCount: dict["xc"] as! Int, latitudeStart: dict["y1"] as! Double, latitudeDelta: dict["yd"] as! Double, latitudeCount: dict["yc"] as! Int)
    }

    public var rectCenterLongitude: Double {
        return longitudeStart + longitudeDelta * Double(longitudeCount) / 2.0
    }

    public var rectCenterLatitude: Double {
        return latitudeStart - latitudeDelta * Double(latitudeCount) / 2.0
    }

    public func getCenterLongitude(offset: Int) -> Double {
        return longitudeStart + longitudeDelta * (Double(offset) - 0.5)
    }

    public func getCenterLatitude(offset: Int) -> Double {
        return latitudeStart - latitudeDelta * (Double(offset) + 0.5)
    }

    public var longitudeEnd: Double {
        return longitudeStart + longitudeDelta * Double(longitudeCount)
    }

    public var latitudeEnd: Double {
        return latitudeStart - latitudeDelta * Double(latitudeCount)
    }

}
