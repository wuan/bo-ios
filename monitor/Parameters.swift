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

/// The parameters of a single data request.
///
/// This is a value type so it can be compared and used as a cache key; two
/// parameter sets built from equal values are equal.
public struct Parameters: Equatable, Hashable, TimeIntervalWithOffset {

    /// Region value selecting a data area derived from the visible extent.
    public static let localRegion = -1
    /// Region value selecting global data with no data area.
    public static let globalRegion = 0

    public let region: Int
    public let rasterBaselength: Int
    public let intervalDuration: Int
    public let intervalOffset: Int
    public let countThreshold: Int
    /// The quantized area a local request is limited to, if any.
    public let dataArea: DataArea?

    public init(region: Int = 1,
                rasterBaselength: Int = 10000,
                intervalDuration: Int = 60,
                intervalOffset: Int = 0,
                countThreshold: Int = 0,
                dataArea: DataArea? = nil) {
        self.region = region
        self.rasterBaselength = rasterBaselength
        self.intervalDuration = intervalDuration
        self.intervalOffset = intervalOffset
        self.countThreshold = countThreshold
        self.dataArea = dataArea
    }

    /// The interval selection these parameters describe.
    public var timeInterval: TimeIntervalSelection {
        return TimeIntervalSelection(duration: intervalDuration, offset: intervalOffset)
    }

    /// Whether the request covers global data.
    public var isGlobal: Bool {
        return region == Parameters.globalRegion
    }

    /// Whether the request is limited to a local data area.
    public var isLocal: Bool {
        return region == Parameters.localRegion
    }

    public func isRealtime() -> Bool {
        return intervalOffset == 0
    }

    public func isRaster() -> Bool {
        return rasterBaselength != 0
    }

    // MARK: - Copy helpers

    public func withRegion(_ region: Int) -> Parameters {
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: intervalDuration,
                          intervalOffset: intervalOffset,
                          countThreshold: countThreshold,
                          dataArea: dataArea)
    }

    public func withRasterBaselength(_ rasterBaselength: Int) -> Parameters {
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: intervalDuration,
                          intervalOffset: intervalOffset,
                          countThreshold: countThreshold,
                          dataArea: dataArea)
    }

    public func withDataArea(_ dataArea: DataArea?) -> Parameters {
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: intervalDuration,
                          intervalOffset: intervalOffset,
                          countThreshold: countThreshold,
                          dataArea: dataArea)
    }

    public func withInterval(_ interval: TimeIntervalSelection) -> Parameters {
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: interval.duration,
                          intervalOffset: interval.offset,
                          countThreshold: countThreshold,
                          dataArea: dataArea)
    }

    public func withIntervalDuration(_ intervalDuration: Int) -> Parameters {
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: intervalDuration,
                          intervalOffset: intervalOffset,
                          countThreshold: countThreshold,
                          dataArea: dataArea)
    }

    /// Carries `threshold` as the count threshold. A zero or negative value
    /// means the threshold is inactive, and leaving it unset is a no-op.
    public func withCountThreshold(_ threshold: Int) -> Parameters {
        let active = max(0, threshold)
        guard active != countThreshold else { return self }
        return Parameters(region: region,
                          rasterBaselength: rasterBaselength,
                          intervalDuration: intervalDuration,
                          intervalOffset: intervalOffset,
                          countThreshold: active,
                          dataArea: dataArea)
    }

    /// Advances the interval one animation step, looping across the history.
    public func animationStep(history: History) -> Parameters {
        return withInterval(timeInterval.animationStep(history: history))
    }

    /// Returns the interval to realtime.
    public func goRealtime() -> Parameters {
        return withInterval(timeInterval.goRealtime())
    }

    // MARK: - Source capability

    /// Disables grid-only request fields when the active source cannot serve
    /// grid data, so a non-grid source never receives a grid size or threshold.
    public func gatingGrid(on capabilities: DataProviderCapabilities) -> Parameters {
        guard !capabilities.supportsGrid else { return self }
        return withRasterBaselength(0).withCountThreshold(0)
    }
}
