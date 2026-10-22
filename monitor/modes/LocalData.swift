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

/// Maps a region setting and the visible extent to concrete request parameters.
///
/// The rules reproduce the Android client: an explicit local region without a
/// derivable data area falls back to global; a global region with a grid size
/// finer than the local threshold and a known data area is upgraded to local;
/// any other region is used as-is. The data area itself is derived by
/// quantizing the extent, and the grid size is chosen to suit the extent.
public struct LocalData {

    /// Region value selecting a data area derived from the visible extent.
    public static let localRegion = Parameters.localRegion
    /// Region value selecting global data with no data area.
    public static let globalRegion = Parameters.globalRegion
    /// Below this grid size a global request is switched to the local data area.
    public static let localRegionGridSizeThreshold = 25000

    /// Finest supported data-area quantization in degrees.
    public static let minDataScale = 5
    /// Coarsest supported data-area quantization in degrees.
    public static let maxDataScale = 20
    /// Quantization used for an explicitly selected local data area.
    public static let localDataScale = minDataScale
    /// Fraction of the larger extent span a data area should cover.
    public static let dataAreaSizeFactor = 0.5

    /// Supported grid sizes in metres, from finest to coarsest.
    public static let supportedGridSizes = [5000, 10000, 25000, 50000, 100000]

    /// The current quantized local data area, if one could be derived.
    public private(set) var dataArea: DataArea?
    /// The geometry of the last received grid result, used to detect when the
    /// visible extent leaves it.
    public private(set) var gridParameters: GridParameters?

    public init(dataArea: DataArea? = nil, gridParameters: GridParameters? = nil) {
        self.dataArea = dataArea
        self.gridParameters = gridParameters
    }

    // MARK: - Extent tracking

    /// Recomputes the data area from the extent.
    ///
    /// - Returns: whether the data area changed, so a caller can refresh only
    ///   when the visible area has moved outside the current one.
    @discardableResult
    public mutating func update(extent: ViewExtent, force: Bool = false) -> Bool {
        let area = Self.dataArea(for: extent)
        let isOutside = gridParameters.map { Self.isOutside(extent, $0) } ?? false
        let isChanged = area != dataArea
        let outsideAndChanged = gridParameters != nil && isOutside && isChanged
        let globalOrUnsetAndChanged = (gridParameters == nil || gridParameters!.isGlobal) && isChanged

        if outsideAndChanged || globalOrUnsetAndChanged || force {
            dataArea = area
            return true
        }
        return false
    }

    /// Remembers the grid geometry of a received result.
    public mutating func store(gridParameters: GridParameters?) {
        self.gridParameters = gridParameters
    }

    // MARK: - Parameter selection

    /// Resolves the request parameters for the stored region setting.
    public func updateParameters(_ parameters: Parameters) -> Parameters {
        switch parameters.region {
        case Self.localRegion:
            guard let dataArea = dataArea else {
                return Self.globalParameters(parameters)
            }
            return parameters.withRegion(Self.localRegion).withDataArea(dataArea)

        case Self.globalRegion:
            if let dataArea = dataArea, parameters.rasterBaselength < Self.localRegionGridSizeThreshold {
                return parameters.withRegion(Self.localRegion).withDataArea(dataArea)
            }
            return Self.globalParameters(parameters)

        default:
            return parameters
        }
    }

    private static func globalParameters(_ parameters: Parameters) -> Parameters {
        return parameters
            .withRegion(Self.globalRegion)
            .withDataArea(nil)
            .withRasterBaselength(max(parameters.rasterBaselength, Self.localRegionGridSizeThreshold))
    }

    // MARK: - Derivation

    /// The quantized data area for an extent, or `nil` when the extent is too
    /// large for a local area.
    public static func dataArea(for extent: ViewExtent) -> DataArea? {
        guard let scale = dataAreaScale(for: extent) else { return nil }
        let x = localCoordinate(extent.center.longitude, scale: scale)
        let y = localCoordinate(extent.center.latitude, scale: scale)
        return DataArea(x: x, y: y, scale: scale)
    }

    /// The data-area quantization in degrees for an extent, or `nil` when the
    /// extent is too large for a local area.
    public static func dataAreaScale(for extent: ViewExtent) -> Int? {
        let target = dataAreaSizeFactor * extent.maximumSpan
        let scale = Int(ceil(target / Double(minDataScale)) * Double(minDataScale))
        guard scale > 0, scale <= maxDataScale else { return nil }
        return scale
    }

    /// Quantizes a coordinate to the grid cell that contains it, rounding
    /// towards negative infinity so negative coordinates stay consistent.
    public static func localCoordinate(_ coordinate: Double, scale: Int = LocalData.localDataScale) -> Int {
        guard scale != 0 else { return 0 }
        return Int(coordinate / Double(scale)) - (coordinate < 0 ? 1 : 0)
    }

    /// The grid size in metres suited to an extent.
    ///
    /// The thresholds mirror the Android auto-grid buckets, expressed in the
    /// extent's larger span in degrees rather than the map zoom level, and the
    /// result is clamped to the supported range.
    public static func gridSize(for extent: ViewExtent) -> Int {
        let span = extent.maximumSpan
        let size: Int
        switch span {
        case ..<3:
            size = 5000
        case ..<16:
            size = 10000
        case ..<45:
            size = 25000
        case ..<90:
            size = 50000
        default:
            size = 100000
        }
        return min(max(size, supportedGridSizes.first ?? size),
                   supportedGridSizes.last ?? size)
    }

    private static func isOutside(_ extent: ViewExtent, _ gridParameters: GridParameters) -> Bool {
        if gridParameters.isGlobal {
            return false
        }
        let longitudeWest = extent.center.longitude - extent.longitudeSpan / 2
        let longitudeEast = extent.center.longitude + extent.longitudeSpan / 2
        let latitudeNorth = extent.center.latitude + extent.latitudeSpan / 2
        let latitudeSouth = extent.center.latitude - extent.latitudeSpan / 2

        return longitudeWest < gridParameters.longitudeStart ||
            longitudeEast > gridParameters.longitudeEnd ||
            latitudeNorth > gridParameters.latitudeStart ||
            latitudeSouth < gridParameters.latitudeEnd
    }
}
