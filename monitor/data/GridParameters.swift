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

/// Geometry of the raster grid on which lightning activity is aggregated.
///
/// Replaces the previous `RasterParameters` class; that name is kept as a
/// type alias for source compatibility.
public struct GridParameters: Equatable {

    public let longitudeStart: Double
    public let longitudeDelta: Double
    public let longitudeCount: Int
    public let latitudeStart: Double
    public let latitudeDelta: Double
    public let latitudeCount: Int

    public init(longitudeStart: Double,
                longitudeDelta: Double,
                longitudeCount: Int,
                latitudeStart: Double,
                latitudeDelta: Double,
                latitudeCount: Int) {
        self.longitudeStart = longitudeStart
        self.longitudeDelta = longitudeDelta
        self.longitudeCount = longitudeCount
        self.latitudeStart = latitudeStart
        self.latitudeDelta = latitudeDelta
        self.latitudeCount = latitudeCount
    }

    /// Parses grid parameters from a provider result dictionary.
    ///
    /// - Returns: `nil` when the required keys are absent or not of the expected
    ///   numeric type, so callers can handle a response without grid data.
    public init?(fromDict dict: [String: AnyObject]) {
        guard let longitudeStart = dict["x0"] as? Double,
              let longitudeDelta = dict["xd"] as? Double,
              let longitudeCount = dict["xc"] as? Int,
              let latitudeStart = dict["y1"] as? Double,
              let latitudeDelta = dict["yd"] as? Double,
              let latitudeCount = dict["yc"] as? Int else {
            return nil
        }
        self.init(longitudeStart: longitudeStart,
                  longitudeDelta: longitudeDelta,
                  longitudeCount: longitudeCount,
                  latitudeStart: latitudeStart,
                  latitudeDelta: latitudeDelta,
                  latitudeCount: latitudeCount)
    }

    public var rectCenterLongitude: Double {
        return longitudeStart + longitudeDelta * Double(longitudeCount) / 2.0
    }

    public var rectCenterLatitude: Double {
        return latitudeStart - latitudeDelta * Double(latitudeCount) / 2.0
    }

    /// The longitude a cell offset is measured from.
    ///
    /// A bounded grid numbers its columns from its western edge. A
    /// world-spanning grid numbers them from the prime meridian instead, even
    /// though `longitudeStart` still reports the geographic western edge.
    private var offsetOriginLongitude: Double {
        return isGlobal ? 0 : longitudeStart
    }

    /// The latitude a cell offset is measured from.
    ///
    /// A bounded grid numbers its rows southwards from `latitudeStart`. A
    /// world-spanning grid numbers them southwards from the equator, writing a
    /// negated index, even though `latitudeStart` still reports the geographic
    /// northern edge.
    private var offsetOriginLatitude: Double {
        return isGlobal ? 0 : latitudeStart
    }

    /// The longitude at the centre of the cell `offset` cells east of the grid's
    /// anchor.
    ///
    /// The offsets are zero-based, so the first cell's centre lies half a cell
    /// inside the anchor; the reference client uses the same `+ 0.5` on both
    /// axes. The anchor itself depends on the grid: see `offsetOriginLongitude`.
    public func getCenterLongitude(offset: Int) -> Double {
        return offsetOriginLongitude + longitudeDelta * (Double(offset) + 0.5)
    }

    /// The latitude at the centre of the row `offset` rows south of the grid's
    /// anchor. See `offsetOriginLatitude` for the anchor.
    public func getCenterLatitude(offset: Int) -> Double {
        return offsetOriginLatitude - latitudeDelta * (Double(offset) + 0.5)
    }

    public var longitudeEnd: Double {
        return longitudeStart + longitudeDelta * Double(longitudeCount)
    }

    public var latitudeEnd: Double {
        return latitudeStart - latitudeDelta * Double(latitudeCount)
    }

    /// Whether the grid spans nearly the whole globe, so no visible extent can
    /// fall outside it.
    public var isGlobal: Bool {
        return longitudeDelta * Double(longitudeCount) > 350 &&
            latitudeDelta * Double(latitudeCount) > 170
    }

    /// Whether a location lies inside the grid.
    ///
    /// - Parameter inset: how far inside every edge the location must lie, in
    ///   degrees, so a location on or near the border can count as outside.
    public func contains(_ location: Location, inset: Double = 0) -> Bool {
        let inLongitude = location.longitude >= longitudeStart + inset &&
            location.longitude <= longitudeEnd - inset
        let inLatitude = location.latitude >= latitudeEnd + inset &&
            location.latitude <= latitudeStart - inset
        return inLongitude && inLatitude
    }
}
