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

/// One entry of the legend: a colour and the age range it stands for.
public struct LegendEntry: Equatable {

    /// The colour drawn as the entry's swatch.
    public let color: UInt32
    /// The youngest age the section covers, in minutes.
    public let minimumAge: Int
    /// The oldest age the section covers, in minutes; `nil` for the oldest
    /// section, which is open-ended.
    public let maximumAge: Int?
    /// The age range as shown, e.g. `< 20 min` or `> 100 min`.
    public let ageText: String

    public init(color: UInt32, minimumAge: Int, maximumAge: Int?, ageText: String) {
        self.color = color
        self.minimumAge = minimumAge
        self.maximumAge = maximumAge
        self.ageText = ageText
    }
}

/// What the legend displays.
public struct LegendContent: Equatable {

    /// One entry per colour section, newest first.
    public let entries: [LegendEntry]
    /// The active region's name.
    public let regionName: String
    /// The grid baseline as shown, e.g. `10 km`; `nil` when the source serves
    /// no grid.
    public let gridBaseline: String?
    /// The local region's size as shown, e.g. `5°`; `nil` unless a local region
    /// with a known data area is active.
    public let localRegionSize: String?

    public init(entries: [LegendEntry],
                regionName: String,
                gridBaseline: String?,
                localRegionSize: String?) {
        self.entries = entries
        self.regionName = regionName
        self.gridBaseline = gridBaseline
        self.localRegionSize = localRegionSize
    }
}

/// Builds the legend's content from the active scheme, region, and grid.
///
/// Pure: the same inputs always produce the same entries, so the legend's
/// numbers can be checked without a view hierarchy.
public enum LegendContentBuilder {

    /// The number of minutes one colour section spans.
    public static func minutesPerColor(numberOfColors: Int, intervalDuration: Int) -> Int {
        guard numberOfColors > 0 else { return 0 }
        return intervalDuration / numberOfColors
    }

    /// Builds the legend content.
    ///
    /// - Parameters:
    ///   - colorHandler: the colours of the active scheme and base map.
    ///   - intervalDuration: the displayed interval in minutes, which the
    ///     colour sections divide.
    ///   - regionName: the name of the active region.
    ///   - region: the active region value.
    ///   - dataArea: the active local data area, when there is one.
    ///   - gridBaselineMetres: the requested grid baseline in metres; zero when
    ///     the active source serves no grid.
    public static func make(colorHandler: ColorHandler,
                            intervalDuration: Int,
                            regionName: String,
                            region: Int,
                            dataArea: DataArea?,
                            gridBaselineMetres: Int) -> LegendContent {
        let colors = colorHandler.colors
        let minutes = minutesPerColor(numberOfColors: colors.count, intervalDuration: intervalDuration)

        let entries = colors.enumerated().map { index, color -> LegendEntry in
            let isOldest = index == colors.count - 1
            let minimumAge = index * minutes
            let maximumAge = isOldest ? nil : (index + 1) * minutes
            let text = isOldest
                ? String(format: NSLocalizedString("legend.over", comment: "Oldest legend entry, e.g. > 60 min"),
                         minimumAge)
                : String(format: NSLocalizedString("legend.under", comment: "Legend entry, e.g. < 20 min"),
                         maximumAge ?? 0)
            return LegendEntry(color: color,
                               minimumAge: minimumAge,
                               maximumAge: maximumAge,
                               ageText: text)
        }

        let localRegionSize: String?
        if region == Parameters.localRegion, let dataArea = dataArea {
            localRegionSize = String(format: NSLocalizedString("legend.regionSize",
                                                              comment: "Local region size in degrees, e.g. 5°"),
                                     dataArea.scale)
        } else {
            localRegionSize = nil
        }

        let gridBaseline: String?
        if gridBaselineMetres > 0 {
            gridBaseline = String(format: NSLocalizedString("unit.kilometres.value",
                                                            comment: "Distance in kilometres, e.g. 10 km"),
                                  Double(gridBaselineMetres) / 1000)
        } else {
            gridBaseline = nil
        }

        return LegendContent(entries: entries,
                             regionName: regionName,
                             gridBaseline: gridBaseline,
                             localRegionSize: localRegionSize)
    }
}
