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

/// The state the alarm radar presents.
public enum RadarState: Equatable {
    /// No location is known, so there is nothing to measure from.
    case noLocation
    /// The location lies outside the available lightning data area.
    case outsideDataArea
    /// No realtime activity is available.
    case noData
    /// Activity data is available, but nothing lies within the radar's range.
    case inactive
    /// Activity is present within range.
    case active
}

/// One direction sector of the radar face.
public struct RadarSector: Equatable {

    /// The direction the sector covers.
    public let direction: AlertDirection
    /// The sector's fill colour, from its closest strike's age; `nil` when the
    /// sector holds no strike within the alert interval, so it is left empty.
    public let color: UInt32?
    /// The age of the sector's closest strike in minutes, when it has one.
    public let ageMinutes: Int?
    /// One fill per ring, innermost first: the colour of the activity that ring
    /// holds, or `nil` when it holds none.
    ///
    /// The radar draws these rather than one wedge per sector, so a strike far
    /// out does not paint the rings inside it.
    public let ringFills: [UInt32?]

    public init(direction: AlertDirection,
                color: UInt32?,
                ageMinutes: Int?,
                ringFills: [UInt32?] = []) {
        self.direction = direction
        self.color = color
        self.ageMinutes = ageMinutes
        self.ringFills = ringFills
    }

    /// Whether the sector is filled.
    public var isFilled: Bool {
        return color != nil
    }
}

/// One ring label of the radar face.
public struct RadarRingLabel: Equatable {

    /// The ring's outer edge in kilometres.
    public let kilometres: Double
    /// The distance as shown, in the active unit.
    public let text: String
    /// Whether this is the outermost ring, which carries the unit name.
    public let isOuter: Bool

    public init(kilometres: Double, text: String, isOuter: Bool) {
        self.kilometres = kilometres
        self.text = text
        self.isOuter = isOuter
    }
}

/// What the alarm radar displays.
public struct RadarContent: Equatable {

    /// The state to present.
    public let state: RadarState
    /// One entry per direction sector, in the radar's order.
    public let sectors: [RadarSector]
    /// One entry per ring, innermost first.
    public let ringLabels: [RadarRingLabel]
    /// The unit the ring labels are in.
    public let distanceUnit: String
    /// The closest strike as shown, e.g. `SW 12.3 km`; `nil` when no sector
    /// holds a strike.
    public let closestStrikeText: String?
    /// Whether an alert is active, so a warning can be told apart from activity
    /// that is merely in range.
    public let alert: Bool

    public init(state: RadarState,
                sectors: [RadarSector],
                ringLabels: [RadarRingLabel],
                distanceUnit: String,
                closestStrikeText: String?,
                alert: Bool = false) {
        self.state = state
        self.sectors = sectors
        self.ringLabels = ringLabels
        self.distanceUnit = distanceUnit
        self.closestStrikeText = closestStrikeText
        self.alert = alert
    }
}

/// Builds the radar's content from the aggregation.
public enum RadarContentBuilder {

    /// Builds the radar content.
    ///
    /// - Parameters:
    ///   - aggregation: the aggregation of the realtime activity around the
    ///     current location.
    ///   - colorHandler: the colours of the active scheme and base map.
    ///   - intervalDuration: the displayed interval in minutes, which the
    ///     colour sections divide.
    ///   - measurementUnit: the unit ring labels are shown in.
    ///   - referenceTime: the moment the aggregation's ages are measured from,
    ///     in seconds since the epoch, which the ring fills are coloured by.
    ///   - geometry: the radar's geometry.
    ///   - alert: whether an alert is active, which the radar marks.
    public static func make(aggregation: AlertAggregation,
                            colorHandler: ColorHandler,
                            intervalDuration: Int,
                            measurementUnit: MeasurementUnit,
                            referenceTime: Int,
                            geometry: AlertGeometry = .standard,
                            alert: Bool = false) -> RadarContent {
        let ringLabels = geometry.ranges.enumerated().map { index, range in
            RadarRingLabel(kilometres: range.maximum,
                           text: measurementUnit.wholeValue(kilometres: range.maximum),
                           isOuter: index == geometry.ranges.count - 1)
        }

        guard let activity = aggregation.activity else {
            return RadarContent(state: state(for: aggregation),
                                sectors: emptySectors(geometry),
                                ringLabels: ringLabels,
                                distanceUnit: measurementUnit.unitName,
                                closestStrikeText: nil,
                                alert: alert)
        }

        let sectors = activity.sectors.map { sector -> RadarSector in
            let ringFills = sector.cells.map { cell -> UInt32? in
                guard cell.strikeCount > 0, cell.latestStrikeTimestamp > 0 else { return nil }
                let age = max(0, referenceTime - cell.latestStrikeTimestamp)
                return colorHandler.color(ageSeconds: age, intervalDuration: intervalDuration)
            }

            guard let closest = sector.closestStrike else {
                return RadarSector(direction: sector.direction,
                                   color: nil,
                                   ageMinutes: nil,
                                   ringFills: ringFills)
            }
            let minutes = closest.age / 60
            return RadarSector(direction: sector.direction,
                               color: colorHandler.color(ageSeconds: closest.age,
                                                         intervalDuration: intervalDuration),
                               ageMinutes: minutes,
                               ringFills: ringFills)
        }

        let hasStrike = activity.sectors.contains { $0.closestStrike != nil }
        let closestStrikeText = activity.closest.map { closest in
            String(format: NSLocalizedString("radar.closestStrike",
                                             comment: "Closest strike, e.g. SW 12.3 km"),
                   closest.direction,
                   measurementUnit.distance(fromKilometres: closest.distance),
                   measurementUnit.unitName)
        }

        return RadarContent(state: hasStrike ? .active : .inactive,
                            sectors: sectors,
                            ringLabels: ringLabels,
                            distanceUnit: measurementUnit.unitName,
                            closestStrikeText: closestStrikeText,
                            alert: alert)
    }

    private static func state(for aggregation: AlertAggregation) -> RadarState {
        switch aggregation {
        case .noLocation:
            return .noLocation
        case .outsideDataArea:
            return .outsideDataArea
        case .noData:
            return .noData
        case .activity:
            return .inactive
        }
    }

    private static func emptySectors(_ geometry: AlertGeometry) -> [RadarSector] {
        return geometry.directions.map {
            RadarSector(direction: $0,
                        color: nil,
                        ageMinutes: nil,
                        ringFills: Array(repeating: nil, count: geometry.ranges.count))
        }
    }
}
