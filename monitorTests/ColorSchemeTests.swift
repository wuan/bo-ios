/*

Copyright 2026 Andreas Würl

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

import XCTest
@testable import monitor

/// Pins the palettes and their per-map-type variants to the reference values.
final class ColorSchemeTests: XCTestCase {

    func testBlitzortungPalette() {
        XCTAssertEqual(ColorScheme.blitzortung.strikeColors,
                       [0xffffffff, 0xffffffb0, 0xffffe079, 0xffffb060, 0xfff08060, 0xffe05050])
    }

    func testRainbowPalette() {
        XCTAssertEqual(ColorScheme.rainbow.strikeColors,
                       [0xffff0000, 0xffff9900, 0xffffff00, 0xff99ff22, 0xff00ffff, 0xff6699ff])
    }

    func testTemperaturePalette() {
        XCTAssertEqual(ColorScheme.temperature.strikeColors,
                       [0xffff5030, 0xffe78060, 0xffe0b0c0, 0xffc0c0f0, 0xff5080f0, 0xff4060ff])
    }

    func testSchemeRawValuesMatchTheReferenceNames() {
        XCTAssertEqual(ColorScheme.allCases.map { $0.rawValue },
                       ["BLITZORTUNG", "RAINBOW", "TEMPERATURE"])
    }

    func testEverySchemeHasSixColors() {
        for scheme in ColorScheme.allCases {
            XCTAssertEqual(scheme.strikeColors.count, 6, "\(scheme.rawValue) palette size")
        }
    }

    func testSatelliteVariantUsesThePaletteUnchanged() {
        for scheme in ColorScheme.allCases {
            XCTAssertEqual(scheme.colors(for: .satellite), scheme.strikeColors)
        }
    }

    func testStreetMapVariantUsesTheDarkenedPalette() {
        XCTAssertEqual(ColorScheme.blitzortung.colors(for: .streetMap),
                       [0xffcccccc, 0xffcccc8d, 0xffccb361, 0xffcc8d4d, 0xffc0664d, 0xffb34040])
        XCTAssertEqual(ColorScheme.rainbow.colors(for: .streetMap),
                       [0xffcc0000, 0xffcc7a00, 0xffcccc00, 0xff7acc1b, 0xff00cccc, 0xff527acc])
        XCTAssertEqual(ColorScheme.temperature.colors(for: .streetMap),
                       [0xffcc4026, 0xffb9664d, 0xffb38d9a, 0xff9a9ac0, 0xff4066c0, 0xff334dcc])
    }

    func testStreetMapVariantScalesEveryChannelDown() {
        func channels(_ color: UInt32) -> [UInt32] {
            return [(color & 0xff0000) >> 16, (color & 0x00ff00) >> 8, color & 0x0000ff]
        }

        for scheme in ColorScheme.allCases {
            let satellite = scheme.colors(for: .satellite)
            let streetMap = scheme.colors(for: .streetMap)
            for (bright, dark) in zip(satellite, streetMap) {
                XCTAssertNotEqual(bright, dark, "\(scheme.rawValue) variant did not change")
                for (brightChannel, darkChannel) in zip(channels(bright), channels(dark)) {
                    XCTAssertLessThan(darkChannel, brightChannel + 1,
                                      "\(scheme.rawValue) variant brightened a channel")
                }
            }
        }
    }

    func testStreetMapVariantKeepsColorsOpaque() {
        for scheme in ColorScheme.allCases {
            for color in scheme.colors(for: .streetMap) {
                XCTAssertEqual(color >> 24, 0xff, "\(scheme.rawValue) produced a translucent colour")
            }
        }
    }

    func testTextColorContrastsWithTheBaseMap() {
        XCTAssertEqual(ColorScheme.blitzortung.textColor(for: .satellite), 0xff000000)
        XCTAssertEqual(ColorScheme.blitzortung.textColor(for: .streetMap), 0xffffffff)
    }

    func testBrightenedWhiteAndRed() {
        XCTAssertEqual(ColorScheme.brightened(0xffffffff, factor: 0.8), 0xffcccccc)
        XCTAssertEqual(ColorScheme.brightened(0xffff0000, factor: 0.8), 0xffcc0000)
    }

    func testBrightnessRoundTripsUnchangedForFactorOne() {
        func channels(_ color: UInt32) -> [Int] {
            return [Int((color & 0xff0000) >> 16), Int((color & 0x00ff00) >> 8), Int(color & 0x0000ff)]
        }

        for scheme in ColorScheme.allCases {
            for color in scheme.strikeColors {
                let roundTripped = ColorScheme.brightened(color, factor: 1.0)
                XCTAssertEqual(roundTripped >> 24, 0xff)
                for (original, actual) in zip(channels(color), channels(roundTripped)) {
                    XCTAssertLessThanOrEqual(abs(original - actual), 1,
                                             "\(scheme.rawValue) drifted on \(color)")
                }
            }
        }
    }
}

/// Pins the age-to-section mapping to the reference rules.
final class ColorHandlerTests: XCTestCase {

    private let handler = ColorHandler(scheme: .blitzortung, baseType: .satellite)
    private let referenceTime = 1_700_000_000

    func testExposesThePaletteAndTextColorForTheActiveBaseMap() {
        XCTAssertEqual(handler.colors, ColorScheme.blitzortung.strikeColors)
        XCTAssertEqual(handler.numberOfColors, 6)
        XCTAssertEqual(handler.textColor, 0xff000000)
        XCTAssertEqual(ColorHandler(baseType: .streetMap).textColor, 0xffffffff)
    }

    func testBaseMapDimColorFollowsTheBaseMap() {
        XCTAssertEqual(ColorHandler(baseType: .satellite).baseMapDimColor, 0xff000000)
        XCTAssertEqual(ColorHandler(baseType: .streetMap).baseMapDimColor, 0xffffffff)
    }

    func testCurrentActivityUsesTheNewestSection() {
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime,
                                            intervalDuration: 60), 0)
        XCTAssertEqual(handler.color(section: 0), ColorScheme.blitzortung.strikeColors[0])
    }

    func testOlderActivityUsesAnOlderSection() {
        // A 60 minute interval over six colours is ten minutes per section.
        let fourtyFiveMinutesAgo = referenceTime - 45 * 60
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: fourtyFiveMinutesAgo,
                                            intervalDuration: 60), 4)
    }

    func testActivityOlderThanTheScaleUsesTheOldestColor() {
        let longAgo = referenceTime - 600 * 60
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: longAgo,
                                            intervalDuration: 60), 5)
        XCTAssertEqual(handler.color(referenceTime: referenceTime,
                                     eventTime: longAgo,
                                     intervalDuration: 60),
                       ColorScheme.blitzortung.strikeColors[5])
    }

    func testAnIntervalThatDoesNotDivideEvenlyStillMaps() {
        // 50 minutes over six colours is eight minutes per section.
        let handler = ColorHandler()
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime - 8 * 60,
                                            intervalDuration: 50), 1)
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime - 500 * 60,
                                            intervalDuration: 50), 5)
    }

    func testActivityInTheFutureUsesTheNewestSection() {
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime + 300,
                                            intervalDuration: 60), 0)
    }

    func testATooShortIntervalHasNoSections() {
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime,
                                            intervalDuration: 5), 0)
        XCTAssertEqual(handler.colorSection(referenceTime: referenceTime,
                                            eventTime: referenceTime - 3600,
                                            intervalDuration: 0), 0)
    }

    func testSectionLookupIsClampedAtBothEnds() {
        XCTAssertEqual(handler.color(section: -3), ColorScheme.blitzortung.strikeColors[0])
        XCTAssertEqual(handler.color(section: 99), ColorScheme.blitzortung.strikeColors[5])
    }
}
