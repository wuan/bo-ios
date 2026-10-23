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

import UIKit
import XCTest
@testable import monitor

/// The app follows the device appearance: its own interface adapts, it never
/// forces an appearance, and it configures a launch screen that does too.
@MainActor
final class AppearanceTests: XCTestCase {

    private func makeController() -> ViewController {
        let controller = ViewController(dataHandler: DataHandler(provider: RecordingProvider()))
        controller.loadViewIfNeeded()
        return controller
    }

    /// The map screen's root background is the app's own surface behind the map,
    /// so it must resolve with the appearance rather than stay a fixed white.
    func testTheMapScreenBackgroundFollowsTheAppearance() {
        let controller = makeController()
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let light = UITraitCollection(userInterfaceStyle: .light)

        XCTAssertEqual(controller.view.backgroundColor?.resolvedColor(with: dark),
                       UIColor.systemBackground.resolvedColor(with: dark),
                       "the map screen must use an adaptive background, not a fixed colour")
        XCTAssertEqual(controller.view.backgroundColor?.resolvedColor(with: light),
                       UIColor.systemBackground.resolvedColor(with: light))
    }

    /// Following the system appearance means not pinning one: neither a trait
    /// override on the screen nor a `UIUserInterfaceStyle` in the Info.plist.
    func testTheAppDoesNotForceAnAppearance() {
        let controller = makeController()

        XCTAssertEqual(controller.overrideUserInterfaceStyle, .unspecified,
                       "the map screen must not pin an appearance")
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "UIUserInterfaceStyle"),
                     "the app must not pin an appearance in its Info.plist")
    }

    /// An unconfigured launch screen does not follow the appearance - it shows a
    /// light background in dark mode - so a launch screen has to be declared.
    func testTheLaunchScreenIsConfigured() {
        let screen = Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen")
        let storyboard = Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName")

        XCTAssertTrue(screen != nil || storyboard != nil,
                      "the app must configure a launch screen")
    }
}
