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

/// The base map a scheme is drawn over.
///
/// The reference client treats a light base map ("street") differently from a
/// dark one ("satellite"), so the same scheme needs two variants.
public enum MapBaseType: String, CaseIterable {
    case satellite
    case streetMap

    /// Whether the base map is light, so activity colours must be darkened.
    public var isLight: Bool {
        return self == .streetMap
    }
}

/// A named set of strike colours, from newest to oldest activity.
///
/// The palettes and their names match the reference client so the same scheme
/// values can be shared with it.
public enum ColorScheme: String, CaseIterable {
    case blitzortung = "BLITZORTUNG"
    case rainbow = "RAINBOW"
    case temperature = "TEMPERATURE"

    /// The colours for the newest through the oldest activity section.
    public var strikeColors: [UInt32] {
        switch self {
        case .blitzortung:
            return [0xffffffff, 0xffffffb0, 0xffffe079, 0xffffb060, 0xfff08060, 0xffe05050]
        case .rainbow:
            return [0xffff0000, 0xffff9900, 0xffffff00, 0xff99ff22, 0xff00ffff, 0xff6699ff]
        case .temperature:
            return [0xffff5030, 0xffe78060, 0xffe0b0c0, 0xffc0c0f0, 0xff5080f0, 0xff4060ff]
        }
    }

    /// Brightness factor applied on a light base map.
    public static let streetMapBrightness = 0.8

    /// The colours to draw on the given base map.
    public func colors(for baseType: MapBaseType) -> [UInt32] {
        switch baseType {
        case .satellite:
            return strikeColors
        case .streetMap:
            return strikeColors.map {
                ColorScheme.brightened($0, factor: ColorScheme.streetMapBrightness)
            }
        }
    }

    /// The colour used for a count drawn on top of this scheme on the given base map.
    public func textColor(for baseType: MapBaseType) -> UInt32 {
        switch baseType {
        case .satellite:
            return 0xff000000
        case .streetMap:
            return 0xffffffff
        }
    }

    // MARK: - Colour arithmetic

    /// The colour with its brightness scaled, keeping it opaque.
    public static func brightened(_ color: UInt32, factor: Double) -> UInt32 {
        let (hue, saturation, brightness) = hsv(from: color)
        return rgb(hue: hue,
                   saturation: saturation,
                   brightness: min(1.0, max(0.0, brightness * factor)))
    }

    /// Converts an opaque RGB colour into hue (degrees), saturation, and brightness.
    static func hsv(from color: UInt32) -> (hue: Double, saturation: Double, brightness: Double) {
        let red = Double((color & 0xff0000) >> 16) / 255.0
        let green = Double((color & 0x00ff00) >> 8) / 255.0
        let blue = Double(color & 0x0000ff) / 255.0

        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum

        var hue = 0.0
        if delta > 0 {
            if maximum == red {
                hue = 60 * (((green - blue) / delta).truncatingRemainder(dividingBy: 6))
            } else if maximum == green {
                hue = 60 * ((blue - red) / delta + 2)
            } else {
                hue = 60 * ((red - green) / delta + 4)
            }
        }
        if hue < 0 {
            hue += 360
        }

        let saturation = maximum == 0 ? 0.0 : delta / maximum
        return (hue, saturation, maximum)
    }

    /// Converts hue (degrees), saturation, and brightness into an opaque RGB colour.
    static func rgb(hue: Double, saturation: Double, brightness: Double) -> UInt32 {
        let chroma = brightness * saturation
        let section = (hue.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360) / 60
        let second = chroma * (1 - abs(section.truncatingRemainder(dividingBy: 2) - 1))
        let offset = brightness - chroma

        let components: (Double, Double, Double)
        switch section {
        case ..<1: components = (chroma, second, 0)
        case ..<2: components = (second, chroma, 0)
        case ..<3: components = (0, chroma, second)
        case ..<4: components = (0, second, chroma)
        case ..<5: components = (second, 0, chroma)
        default: components = (chroma, 0, second)
        }

        let red = UInt32((components.0 + offset) * 255 + 0.5)
        let green = UInt32((components.1 + offset) * 255 + 0.5)
        let blue = UInt32((components.2 + offset) * 255 + 0.5)
        return 0xff000000 | (red << 16) | (green << 8) | blue
    }
}
