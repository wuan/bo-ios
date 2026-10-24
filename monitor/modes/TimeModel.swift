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

/// Holds the realtime, history, and animation state and the selected interval.
///
/// The model is a plain value type: it owns no view, no timer, and no data
/// source, so every transition is unit-testable. It clamps and aligns the
/// interval through ``TimeIntervalSelection``.
public struct TimeModel {

    /// The current mode.
    public private(set) var mode: DataMode
    /// The selected interval.
    public private(set) var interval: TimeIntervalSelection
    /// The bounds and stepping used for historical selection.
    public private(set) var history: History

    public init(mode: DataMode = .realtime,
                interval: TimeIntervalSelection = TimeIntervalSelection(),
                history: History = History()) {
        self.mode = mode
        self.interval = interval
        self.history = history
    }

    /// Whether the selection shows the most recent interval.
    public var isRealtime: Bool {
        return interval.isRealtime
    }

    /// The slider position for the current interval.
    public var position: Int {
        return interval.position(history: history)
    }

    /// The rightmost slider position, which selects realtime.
    public var maxPosition: Int {
        return interval.maxPosition(history: history)
    }

    /// Returns to realtime mode.
    public mutating func goRealtime() {
        interval = interval.goRealtime()
        mode = .realtime
    }

    /// Steps one increment into the past and leaves realtime.
    public mutating func rewind() {
        interval = interval.rewind(history: history)
        updateModeForInterval()
    }

    /// Steps one increment towards the present, entering realtime at offset zero.
    public mutating func fastForward() {
        interval = interval.fastForward(history: history)
        updateModeForInterval()
    }

    /// Selects the interval at a slider position. The rightmost position
    /// activates realtime; any other position selects that historical interval.
    public mutating func setPosition(_ position: Int) {
        interval = interval.withPosition(position, history: history)
        updateModeForInterval()
    }

    /// Starts animation playback.
    public mutating func startAnimation() {
        mode = .animation
    }

    /// Stops animation, holding the interval it stopped on. The user can then
    /// resume manual time selection; realtime is only re-entered on request.
    public mutating func stopAnimation() {
        updateModeForInterval()
    }

    /// Adopts a new interval duration and history step.
    ///
    /// The current selection is kept where the new bounds allow it, and the
    /// mode is only re-derived for a manual selection so a running animation
    /// is not interrupted by a settings change.
    public mutating func configure(intervalDuration: Int, historicTimestep: Int) {
        history = History(timeIncrement: historicTimestep)
        interval = interval.withDuration(intervalDuration, history: history)
        if mode != .animation {
            updateModeForInterval()
        }
    }

    /// Advances one animation step.
    ///
    /// - Returns: whether the step cycled back to the beginning, which happens
    ///   when the playback was at the present and jumped to the oldest interval.
    @discardableResult
    public mutating func advanceAnimation() -> Bool {
        let wrapped = interval.offset == 0
        interval = interval.animationStep(history: history)
        return wrapped
    }

    /// The moment the selected interval starts, derived from the reference time:
    /// the interval ends `offset` minutes before `now` and lasts `duration`.
    public func intervalStart(now: Date) -> Date {
        return now.addingTimeInterval(TimeInterval((interval.offset - interval.duration) * 60))
    }

    private mutating func updateModeForInterval() {
        mode = interval.isRealtime ? .realtime : .history
    }
}
