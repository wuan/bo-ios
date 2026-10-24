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

import BackgroundTasks
import Foundation

/// Identifiers the background monitoring uses.
public enum BackgroundMonitoring {

    /// The background refresh task identifier.
    ///
    /// Must also appear in the app's `BGTaskSchedulerPermittedIdentifiers`.
    public static let taskIdentifier = "net.wuerl.blitzortung.monitor.refresh"

    /// The grid size a background request asks for, in metres.
    ///
    /// The background request is always local, bounded by the position, so it
    /// asks for the finest supported grid. A global query has no such bound and
    /// is not allowed a grid below the backend's 25 km minimum, which is why the
    /// background monitor never issues one.
    public static let localGridSize = 5000

    /// The shortest interval a request may be scheduled with, in seconds.
    ///
    /// The platform will not honour an aggressive cadence; nothing is asked for
    /// sooner than this even if a shorter period is stored.
    public static let minimumInterval: TimeInterval = 60
}

/// Schedules the periodic background fetch.
///
/// Behind a port so the monitor's gating and submission can be tested without
/// `BGTaskScheduler`, the same shape the location and alert ports use.
public protocol BackgroundMonitoringScheduling: AnyObject {

    /// Installs the handler the system runs on a wake-up.
    ///
    /// The handler calls its completion when the work has finished, so the task
    /// can report completion.
    func register(handler: @escaping (@escaping () -> Void) -> Void)

    /// Asks the system to run the handler after `interval` seconds.
    func submit(after interval: TimeInterval)

    /// Cancels any pending request.
    func cancel()
}

/// ``BackgroundMonitoringScheduling`` backed by `BGTaskScheduler`.
///
/// Registration must happen before the app finishes launching, so
/// ``registerTask()`` is callable on its own - before a handler exists - and
/// ``register(handler:)`` installs the handler later, when the monitor is built.
public final class BGTaskSchedulerScheduling: BackgroundMonitoringScheduling {

    private let identifier: String
    private var handler: ((@escaping () -> Void) -> Void)?
    private var interval: TimeInterval = 0
    private var isRegistered = false

    public init(identifier: String = BackgroundMonitoring.taskIdentifier) {
        self.identifier = identifier
    }

    /// Registers with the system, once, before the app finishes launching.
    ///
    /// Safe to call before a handler is installed: a wake-up that arrives with
    /// no handler completes the task immediately rather than leaving it hanging.
    public func registerTask() {
        guard !isRegistered else { return }
        isRegistered = true

        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { [weak self] task in
            guard let self = self, let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            // Re-arm for the next wake-up before doing the work, so a slow or
            // failed fetch still leaves the next one scheduled.
            self.schedule()
            refresh.expirationHandler = { refresh.setTaskCompleted(success: false) }
            if let handler = self.handler {
                handler { refresh.setTaskCompleted(success: true) }
            } else {
                refresh.setTaskCompleted(success: true)
            }
        }
    }

    public func register(handler: @escaping (@escaping () -> Void) -> Void) {
        self.handler = handler
        registerTask()
    }

    public func submit(after interval: TimeInterval) {
        self.interval = interval
        schedule()
    }

    public func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }

    private func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(interval, BackgroundMonitoring.minimumInterval))
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            NSLog("background refresh scheduling failed: \(error)")
        }
    }
}
