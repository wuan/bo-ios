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
import os

/// One recorded diagnostic message.
public struct AppLogEntry: Equatable {
    /// When the message was recorded.
    public let date: Date
    /// What was recorded.
    public let message: String

    public init(date: Date, message: String) {
        self.date = date
        self.message = message
    }
}

/// The app's diagnostic log.
///
/// A bounded, append-only ring of recent messages, gated by the diagnostics
/// setting: nothing is kept while diagnostics are off, so the switch has an
/// observable effect rather than only being stored. Every message also goes to
/// the system log, so it is visible with the platform's own tooling whatever the
/// setting says. A later phase's log view and send-for-support action read the
/// same ring.
public final class AppLog {

    /// The log the app records through.
    public static let shared = AppLog(settings: SettingsStore())

    /// How many messages the ring keeps at most.
    public let capacity: Int

    private let settings: SettingsStore
    private let clock: () -> Date
    private let systemSink: (String) -> Void
    private let lock = NSLock()
    private var storage: [AppLogEntry] = []

    public init(settings: SettingsStore,
                capacity: Int = 500,
                clock: @escaping () -> Date = Date.init,
                systemSink: ((String) -> Void)? = nil) {
        self.settings = settings
        self.capacity = capacity
        self.clock = clock
        self.systemSink = systemSink ?? AppLog.systemLogSink
    }

    /// Whether diagnostics are switched on.
    public var isEnabled: Bool {
        return settings.bool(for: .diagnosticsEnabled)
    }

    /// The recorded messages, oldest first.
    public var entries: [AppLogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    /// Records a message.
    ///
    /// The message always reaches the system log; it is kept in the ring only
    /// while diagnostics are enabled, and the ring drops its oldest messages
    /// once it is full.
    public func record(_ message: String) {
        systemSink(message)

        guard isEnabled else { return }

        lock.lock()
        defer { lock.unlock() }
        storage.append(AppLogEntry(date: clock(), message: message))
        if storage.count > capacity {
            storage.removeFirst(storage.count - capacity)
        }
    }

    /// Drops every message the ring holds.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    /// Writes a message to the system log.
    static func systemLogSink(_ message: String) {
        logger.log("\(message, privacy: .public)")
    }

    private static let logger = Logger(subsystem: "org.blitzortung.monitor", category: "app")
}
