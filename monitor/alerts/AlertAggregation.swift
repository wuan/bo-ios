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

/// The activity recorded in one ring of one direction sector.
public struct AlertCellActivity: Equatable {

    /// The ring this cell belongs to.
    public let range: AlertRange
    /// The number of events recorded in the cell.
    public let strikeCount: Int
    /// When the cell's most recent event happened, in seconds since the epoch;
    /// zero when the cell is empty.
    public let latestStrikeTimestamp: Int

    public init(range: AlertRange, strikeCount: Int, latestStrikeTimestamp: Int) {
        self.range = range
        self.strikeCount = strikeCount
        self.latestStrikeTimestamp = latestStrikeTimestamp
    }
}

/// A sector's closest strike within the alert window.
public struct AlertClosestStrike: Equatable {

    /// The direction the strike lies in.
    public let direction: String
    /// The distance to the strike in kilometres.
    public let distance: Double
    /// The strike's age in seconds at the reference time.
    public let age: Int

    public init(direction: String, distance: Double, age: Int) {
        self.direction = direction
        self.distance = distance
        self.age = age
    }
}

/// The activity one direction sector reports.
public struct AlertSectorActivity: Equatable {

    /// The sector this activity belongs to.
    public let direction: AlertDirection
    /// One entry per ring, in the radar's order, including the empty ones.
    public let cells: [AlertCellActivity]
    /// The nearest strike in the sector within the alert window, or `nil` when
    /// the sector contains none.
    public let closestStrike: AlertClosestStrike?

    public init(direction: AlertDirection,
                cells: [AlertCellActivity],
                closestStrike: AlertClosestStrike?) {
        self.direction = direction
        self.cells = cells
        self.closestStrike = closestStrike
    }

    /// Whether any activity was recorded in the sector.
    public var hasActivity: Bool {
        return cells.contains { $0.strikeCount > 0 }
    }
}

/// The aggregated activity around the current location.
public struct AlertActivity: Equatable {

    /// The rings the radar draws, from the location outwards.
    public let ranges: [AlertRange]
    /// One entry per direction sector, in the radar's order.
    public let sectors: [AlertSectorActivity]
    /// The sector whose closest strike is nearest, or `nil` when no sector
    /// contains a strike.
    public let closest: AlertClosestStrike?

    public init(ranges: [AlertRange],
                sectors: [AlertSectorActivity],
                closest: AlertClosestStrike?) {
        self.ranges = ranges
        self.sectors = sectors
        self.closest = closest
    }
}

/// The result of aggregating activity around the current location.
public enum AlertAggregation: Equatable {
    /// No location is known, so there is nothing to measure from.
    case noLocation
    /// The location lies outside the available lightning data area.
    case outsideDataArea
    /// No realtime activity is available to aggregate.
    case noData
    /// The aggregated rings and sectors around the location.
    case activity(AlertActivity)

    /// The activity, when the aggregation found any to report.
    public var activity: AlertActivity? {
        guard case .activity(let activity) = self else { return nil }
        return activity
    }
}

/// Aggregates realtime strikes into the radar's rings and sectors.
///
/// Pure logic: it takes the strikes, the data area, the location, and the
/// reference time and returns rings and sectors with the closest strike in
/// each. Distances are measured from the location to the strike, and the alert
/// interval is fixed rather than derived from the interval the map displays.
///
/// The aggregation is realtime-only: a history or animation result leaves it
/// reporting no data, matching the reference client.
public struct AlertAggregator {

    /// The alert interval in seconds.
    public static let alertInterval = 10 * 60

    /// How far inside the data area's edge the location must lie, in degrees.
    ///
    /// A location within the inset counts as outside, so the radar does not
    /// report activity from a grid whose edge it sits on.
    public static let outlyingInset = 0.2

    /// The geometry the rings and sectors are built from.
    public let geometry: AlertGeometry

    public init(geometry: AlertGeometry = .standard) {
        self.geometry = geometry
    }

    /// Aggregates activity relative to a location.
    ///
    /// - Parameters:
    ///   - strikes: the strikes of the displayed result, or `nil` when none is
    ///     available.
    ///   - dataArea: the grid geometry the result covers, when it has one.
    ///   - location: the current location, or `nil` when none is known.
    ///   - isRealtime: whether the displayed result is the realtime one.
    ///   - referenceTime: the moment the alert interval ends at, in seconds
    ///     since the epoch.
    public func aggregate(strikes: [Strike]?,
                          dataArea: GridParameters?,
                          location: Location?,
                          isRealtime: Bool,
                          referenceTime: Int) -> AlertAggregation {
        guard let location = location else { return .noLocation }
        guard isRealtime, let strikes = strikes else { return .noData }

        if let dataArea = dataArea,
           !dataArea.isGlobal,
           !dataArea.contains(location, inset: AlertAggregator.outlyingInset) {
            return .outsideDataArea
        }

        return .activity(activity(strikes: strikes,
                                  location: location,
                                  referenceTime: referenceTime))
    }

    private func activity(strikes: [Strike],
                          location: Location,
                          referenceTime: Int) -> AlertActivity {
        let threshold = referenceTime - AlertAggregator.alertInterval
        let ringCount = geometry.ranges.count
        var counts = Array(repeating: Array(repeating: 0, count: ringCount),
                           count: geometry.directions.count)
        var latest = counts
        var closest = Array<AlertClosestStrike?>(repeating: nil, count: geometry.directions.count)

        for strike in strikes {
            let position = AlertAggregator.position(of: strike, relativeTo: location)
            let distance = AlertGeometry.distance(from: location, to: position)
            guard let ringIndex = geometry.ringIndex(forDistance: distance) else { continue }

            let bearing = AlertGeometry.bearing(from: location, to: position)
            guard let sectorIndex = geometry.sectorIndex(forBearing: bearing) else { continue }

            counts[sectorIndex][ringIndex] += strike.multiplicity
            latest[sectorIndex][ringIndex] = max(latest[sectorIndex][ringIndex], strike.timestamp)

            // Only strikes inside the alert interval count as a closest strike;
            // older ones still shape the cell counts and their recency.
            guard strike.timestamp >= threshold else { continue }
            if let recorded = closest[sectorIndex], recorded.distance <= distance {
                continue
            }
            closest[sectorIndex] = AlertClosestStrike(direction: geometry.directions[sectorIndex].label,
                                                      distance: distance,
                                                      age: max(0, referenceTime - strike.timestamp))
        }

        let sectors = geometry.directions.enumerated().map { sectorIndex, direction in
            AlertSectorActivity(direction: direction,
                                cells: geometry.ranges.enumerated().map { ringIndex, range in
                                    AlertCellActivity(range: range,
                                                      strikeCount: counts[sectorIndex][ringIndex],
                                                      latestStrikeTimestamp: latest[sectorIndex][ringIndex])
                                },
                                closestStrike: closest[sectorIndex])
        }

        return AlertActivity(ranges: geometry.ranges,
                             sectors: sectors,
                             closest: sectors.compactMap { $0.closestStrike }
                                 .min { $0.distance < $1.distance })
    }

    /// The position a strike contributes to the aggregation.
    ///
    /// A grid cell covers an area, so the point of it nearest the location is
    /// used, matching the reference; a single strike contributes its own
    /// position.
    static func position(of strike: Strike, relativeTo location: Location) -> Location {
        let span = strike.envelope.span
        guard span.latitudeDelta > 0 || span.longitudeDelta > 0 else {
            return Location(latitude: strike.envelope.center.latitude,
                            longitude: strike.envelope.center.longitude)
        }

        return Location(latitude: closestCoordinate(location.latitude,
                                                    to: strike.envelope.center.latitude,
                                                    size: span.latitudeDelta),
                        longitude: closestCoordinate(location.longitude,
                                                     to: strike.envelope.center.longitude,
                                                     size: span.longitudeDelta))
    }

    private static func closestCoordinate(_ value: Double, to target: Double, size: Double) -> Double {
        let half = size / 2
        if value >= target - half && value <= target + half {
            return value
        }
        return value < target ? target - half : target + half
    }
}
