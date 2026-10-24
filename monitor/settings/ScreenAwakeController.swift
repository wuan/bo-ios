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

import Foundation
import UIKit

/// The display's idle timer, behind ``ScreenAwakeController``.
///
/// `UIApplication` is the only thing that can hold the display awake, so the
/// seam exists purely to keep the controller testable.
public protocol IdleTimerControlling: AnyObject {
    var isIdleTimerDisabled: Bool { get set }
}

extension UIApplication: IdleTimerControlling {}

/// Keeps the display awake while the setting says so.
///
/// iOS releases the assertion when the app leaves the foreground, so the
/// controller only has to follow the setting: it applies it at launch and again
/// whenever it changes.
public final class ScreenAwakeController {

    private let settings: SettingsStore
    private let application: IdleTimerControlling
    private var observer: NSObjectProtocol?

    public init(settings: SettingsStore = SettingsStore(),
                application: IdleTimerControlling = UIApplication.shared) {
        self.settings = settings
        self.application = application
    }

    deinit {
        if let observer = observer {
            settings.removeObserver(observer)
        }
    }

    /// Applies the stored setting and follows it from here on.
    public func start() {
        apply()
        observer = settings.observe(.keepScreenAwake) { [weak self] in
            self?.apply()
        }
    }

    /// Reflects the stored setting in the idle timer.
    public func apply() {
        application.isIdleTimerDisabled = settings.bool(for: .keepScreenAwake)
    }
}
