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

import AudioToolbox
import Foundation
import UIKit
import UserNotifications

/// The device's sound and vibration, behind ``AlertSignalling``.
///
/// The stored strength maps to a haptic intensity, because iOS has intensity
/// where the reference client had a vibration duration; zero means no vibration
/// at all. A stored sound is played as a system sound, and an empty one plays
/// nothing, because the notification carries the system's own sound.
public final class SystemAlertSignaller: AlertSignalling {

    public init() {}

    public func signal(sound: String, vibrationStrength: Int) {
        if vibrationStrength > 0 {
            let intensity = CGFloat(min(max(Double(vibrationStrength) / 30.0, 0.1), 1.0))
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        }

        if let identifier = UInt32(sound), identifier != 0 {
            AudioServicesPlaySystemSound(SystemSoundID(identifier))
        }
    }
}

/// The notification centre, behind ``AlertNotifying``.
///
/// Also the centre's delegate, so a notification raised while the app is open is
/// presented rather than swallowed: the app only evaluates the alert in the
/// foreground, so without this the notification limit would never be visible.
public final class LocalAlertNotifier: NSObject, AlertNotifying, UNUserNotificationCenterDelegate {

    private let center: UNUserNotificationCenter
    private let measurementUnit: () -> MeasurementUnit

    public init(center: UNUserNotificationCenter = .current(),
                measurementUnit: @escaping () -> MeasurementUnit = { .metric }) {
        self.center = center
        self.measurementUnit = measurementUnit
        super.init()
        center.delegate = self
    }

    /// Asks for the authorisation a notification needs.
    ///
    /// Called when alerts are switched on; a refusal leaves the notification
    /// path a no-op while the signals and the reported state keep working.
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func notify(closest: AlertClosestStrike) {
        let unit = measurementUnit()
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("alert.notification.title",
                                          comment: "Title of the proximity alert notification")
        content.body = String(format: NSLocalizedString("alert.notification.body",
                                                        comment: "Closest strike, e.g. SW 12.3 km"),
                              closest.direction,
                              unit.distance(fromKilometres: closest.distance),
                              unit.unitName)
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                           content: content,
                                           trigger: nil)
        center.add(request)
    }

    /// Presents an alert's notification while the app is open.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
