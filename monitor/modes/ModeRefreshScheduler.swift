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

/// Decides when a refresh is due, as a function of the active mode.
///
/// Realtime refreshes on the query period, history refreshes only when the
/// selection changes, and animation advances one step per animation tick. An
/// animation that cycles back to the beginning is not due again until the cycle
/// pause has passed. The decision is a pure function of the supplied time, so it
/// is unit-testable without a run loop.
public final class ModeRefreshScheduler {

    /// What the caller should do on a tick.
    public enum Action: Equatable {
        /// Nothing is due.
        case none
        /// Fetch the currently selected interval.
        case refresh
        /// Advance the animation one step, then fetch.
        case advanceAndRefresh
    }

    /// Interval between automatic refreshes in realtime mode, in seconds.
    public let realtimePeriod: TimeInterval
    /// Interval between animation steps, in seconds.
    public private(set) var animationPeriod: TimeInterval
    /// The pause before an animation that reached the present cycles back to the
    /// beginning, in seconds; zero means it repeats at once.
    public private(set) var animationCyclePause: TimeInterval

    private var lastRefresh: Date?

    public init(realtimePeriod: TimeInterval = 60,
                animationPeriod: TimeInterval = 1,
                animationCyclePause: TimeInterval = 0) {
        self.realtimePeriod = realtimePeriod
        self.animationPeriod = animationPeriod
        self.animationCyclePause = animationCyclePause
    }

    /// Whether a first refresh has happened.
    public var hasRefreshed: Bool {
        return lastRefresh != nil
    }

    /// Adopts a new animation step duration and cycle pause.
    ///
    /// A running animation keeps its place; only the pacing changes, so the next
    /// step is due a period after the last one rather than immediately.
    public func configure(animationStepDuration: TimeInterval, animationCyclePause: TimeInterval) {
        self.animationPeriod = animationStepDuration
        self.animationCyclePause = animationCyclePause
    }

    /// The action due at `now` for the given mode.
    ///
    /// The first tick always acts: an immediate fetch in realtime and history,
    /// an immediate step in animation.
    public func tick(mode: DataMode, now: Date) -> Action {
        guard let last = lastRefresh else {
            lastRefresh = now
            return mode == .animation ? .advanceAndRefresh : .refresh
        }

        switch mode {
        case .history:
            return .none
        case .realtime:
            guard now.timeIntervalSince(last) >= realtimePeriod else { return .none }
            lastRefresh = now
            return .refresh
        case .animation:
            guard now.timeIntervalSince(last) >= animationPeriod else { return .none }
            lastRefresh = now
            return .advanceAndRefresh
        }
    }

    /// Records the outcome of an animation step.
    ///
    /// A step that cycled back to the beginning defers the next one by the cycle
    /// pause, so the playback holds on the first interval before repeating.
    public func animationStepCompleted(wrapped: Bool, now: Date) {
        guard wrapped, animationCyclePause > 0 else { return }
        lastRefresh = now.addingTimeInterval(animationCyclePause)
    }

    /// Records that the selection changed, which refreshes at once in history
    /// mode and restarts the period in the other modes.
    @discardableResult
    public func selectionChanged(now: Date) -> Action {
        lastRefresh = now
        return .refresh
    }
}
