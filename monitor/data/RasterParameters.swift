//
// Created by Andreas Würl on 01.09.15.
// Copyright (c) 2015 Andreas Würl. All rights reserved.
//

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
        self.init(longitudeStart: dict["x0"] as! Double, longitudeDelta: dict["xd"] as! Double,longitudeCount: dict["xc"] as! Int,latitudeStart: dict["y1"] as! Double,latitudeDelta: dict["yd"] as! Double,latitudeCount: dict["yc"] as! Int)
    }

    public var rectCenterLongitude: Double {
        return longitudeStart + longitudeDelta * Double(longitudeCount) / 2.0;
    }

    public var rectCenterLatitude: Double {
        return latitudeStart - latitudeDelta * Double(latitudeCount) / 2.0;
    }

    public func getCenterLongitude(offset: Int) -> Double {
        return longitudeStart + longitudeDelta * (Double(offset) + 0.5);
    }

    public func getCenterLatitude(offset: Int) -> Double {
        return latitudeStart - latitudeDelta * (Double(offset) + 0.5);
    }

}
