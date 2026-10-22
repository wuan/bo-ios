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

/// Resolves the colours used to draw activity for one scheme and base map.
///
/// The age of an event is quantised into a section of the active palette, so
/// the newest activity takes the first colour and anything older than the last
/// section keeps the oldest colour.
public struct ColorHandler: Equatable {

    /// The active colour scheme.
    public let scheme: ColorScheme
    /// The base map the colours must stay legible on.
    public let baseType: MapBaseType

    public init(scheme: ColorScheme = .blitzortung, baseType: MapBaseType = .satellite) {
        self.scheme = scheme
        self.baseType = baseType
    }

    /// The palette for the active scheme and base map, newest first.
    public var colors: [UInt32] {
        return scheme.colors(for: baseType)
    }

    /// The number of colours in the active palette.
    public var numberOfColors: Int {
        return colors.count
    }

    /// The colour used for a count drawn on top of the palette.
    public var textColor: UInt32 {
        return scheme.textColor(for: baseType)
    }

    /// The colour of the base-map dim layer for the active base map.
    ///
    /// A dark base map is dimmed towards black and a light one towards white,
    /// so the wash reads as contrast in both cases.
    public var baseMapDimColor: UInt32 {
        switch baseType {
        case .satellite:
            return 0xff000000
        case .streetMap:
            return 0xffffffff
        }
    }

    /// The palette section of an event, from its age relative to the reference time.
    ///
    /// - Parameters:
    ///   - referenceTime: the time the displayed result is referenced to, in
    ///     seconds since the epoch.
    ///   - eventTime: when the event happened, in seconds since the epoch.
    ///   - intervalDuration: the interval the palette spans, in minutes.
    /// - Returns: a section index within the palette, clamped at both ends.
    public func colorSection(referenceTime: Int, eventTime: Int, intervalDuration: Int) -> Int {
        guard numberOfColors > 0 else { return 0 }

        let minutesPerColor = intervalDuration / numberOfColors
        guard minutesPerColor > 0 else { return 0 }

        let ageInMinutes = (referenceTime - eventTime) / 60
        return limitToValidRange(ageInMinutes / minutesPerColor)
    }

    /// The colour of an event, from its age relative to the reference time.
    public func color(referenceTime: Int, eventTime: Int, intervalDuration: Int) -> UInt32 {
        return color(section: colorSection(referenceTime: referenceTime,
                                           eventTime: eventTime,
                                           intervalDuration: intervalDuration))
    }

    /// The palette section of an event, from its age in seconds.
    public func section(ageSeconds: Int, intervalDuration: Int) -> Int {
        return colorSection(referenceTime: ageSeconds, eventTime: 0, intervalDuration: intervalDuration)
    }

    /// The colour of an event, from its age in seconds.
    public func color(ageSeconds: Int, intervalDuration: Int) -> UInt32 {
        return color(section: section(ageSeconds: ageSeconds, intervalDuration: intervalDuration))
    }

    /// The colour of a palette section, clamped to the palette's range.
    public func color(section: Int) -> UInt32 {
        guard numberOfColors > 0 else { return 0xffffffff }
        return colors[limitToValidRange(section)]
    }

    private func limitToValidRange(_ section: Int) -> Int {
        return max(min(section, numberOfColors - 1), 0)
    }
}
