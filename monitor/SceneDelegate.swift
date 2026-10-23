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
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Runs the alert decision while the app is not in the foreground.
    private var backgroundMonitor: BackgroundMonitor?
    /// The store the background-location request reads its mode and gate from.
    private var settings: SettingsStore?
    /// The manager the background location request goes through; the same one
    /// the device location source uses.
    private var backgroundLocationManager: CoreLocationManager?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let settings = SettingsStore()
            let credentialStore = KeychainCredentialStore()
            let factory = DataProviderFactory(credentialStore: credentialStore)
            let coordinator = DataProviderCoordinator(settings: settings, factory: factory)

            // One device manager serves both the location source and the
            // background-location request, so only one asks the device.
            let locationManager = CoreLocationManager()
            let locationFactory = LocationSourceFactory(managerFactory: { locationManager })

            let notifier = LocalAlertNotifier(measurementUnit: { settings.measurementUnit })
            let alertMonitor = ProximityAlertMonitor(settings: settings,
                                                     signaller: SystemAlertSignaller(),
                                                     notifier: notifier)
            let scheduler = (UIApplication.shared.delegate as? AppDelegate)?.backgroundScheduling
                ?? BGTaskSchedulerScheduling()
            let backgroundLocation: () -> Location? = {
                settings.locationMode.isDeviceBacked ? locationManager.location : settings.manualLocation
            }
            let fetcher = CoordinatorBackgroundFetcher(source: coordinator,
                                                       settings: settings,
                                                       location: backgroundLocation)
            let monitor = BackgroundMonitor(
                settings: settings,
                scheduler: scheduler,
                fetcher: fetcher,
                alertMonitor: alertMonitor,
                notifier: notifier,
                location: backgroundLocation)

            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = ViewController(dataSource: coordinator,
                                                       settings: settings,
                                                       credentialStore: credentialStore,
                                                       locationSourceFactory: locationFactory)
            self.window = window
            self.settings = settings
            self.backgroundMonitor = monitor
            self.backgroundLocationManager = locationManager
            window.makeKeyAndVisible()

            monitor.start()
            requestBackgroundLocationIfNeeded()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // The foreground refresh takes over, so the scheduled background fetch
        // is stopped.
        backgroundMonitor?.enterForeground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Schedule the next background fetch while monitoring is enabled, and
        // request the background location it needs.
        backgroundMonitor?.enterBackground()
        requestBackgroundLocationIfNeeded()
    }

    /// Requests background location for monitoring, behind the disclosure.
    ///
    /// Only a device-backed mode asks, and only once the explanation has been
    /// acknowledged; a manual location needs nothing.
    private func requestBackgroundLocationIfNeeded() {
        guard let settings = settings,
              let manager = backgroundLocationManager,
              settings.backgroundMonitoringEnabled,
              settings.locationMode.isDeviceBacked else {
            return
        }

        let permission = BackgroundLocationPermission(settings: settings)
        permission.request(for: settings.locationMode,
                           manager: manager,
                           disclosing: { [weak self] in self?.presentBackgroundLocationDisclosure() })
    }

    /// Presents the background-location explanation, then requests the
    /// permission once the user has acknowledged it.
    private func presentBackgroundLocationDisclosure() {
        let alert = UIAlertController(
            title: NSLocalizedString("background.disclosure.title",
                                     comment: "Title of the background-location explanation"),
            message: NSLocalizedString("background.disclosure.message",
                                       comment: "Explains why background location is used"),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("background.disclosure.confirm",
                                     comment: "Acknowledges the background-location explanation"),
            style: .default) { [weak self] _ in
                guard let self = self, let settings = self.settings else { return }
                BackgroundLocationPermission(settings: settings).acknowledge()
                self.requestBackgroundLocationIfNeeded()
            })
        window?.rootViewController?.present(alert, animated: true)
    }
}

