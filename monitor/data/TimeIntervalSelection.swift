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

/// A time selection expressed as an interval with a duration and an offset.
///
/// Named `TimeIntervalSelection` rather than `TimeInterval` to avoid clashing
/// with Foundation's `TimeInterval`.
///
/// The stepping operations mirror the Android `TimeInterval`: an offset is
/// always clamped to the history lower limit and aligned to the history
/// increment, so repeated steps never drift away from the slider positions.
public struct TimeIntervalSelection: Equatable {

    /// Length of the displayed interval in minutes.
    public let duration: Int
    /// Offset of the interval in minutes; zero means realtime.
    public let offset: Int

    public init(duration: Int = 60, offset: Int = 0) {
        self.duration = duration
        self.offset = offset
    }

    /// A selection with a zero offset shows the most recent data.
    public var isRealtime: Bool {
        return offset == 0
    }

    // MARK: - Time stepping

    /// Returns a selection at `offset`, or the receiver unchanged when the
    /// offset falls outside the history range.
    public func withOffset(_ offset: Int, history: History) -> TimeIntervalSelection {
        guard offset >= history.lowerLimit(of: self), offset <= 0 else {
            return self
        }
        return TimeIntervalSelection(duration: duration, offset: offset)
    }

    /// Steps one increment further into the past.
    public func rewind(history: History) -> TimeIntervalSelection {
        return stepping(history, by: -1)
    }

    /// Steps one increment towards the present.
    public func fastForward(history: History) -> TimeIntervalSelection {
        return stepping(history, by: 1)
    }

    /// Advances the animation: from realtime it jumps to the oldest interval,
    /// otherwise it steps towards the present, looping back to the oldest.
    public func animationStep(history: History) -> TimeIntervalSelection {
        if offset == 0 {
            return TimeIntervalSelection(duration: duration, offset: history.lowerLimit(of: self))
        }
        return stepping(history, by: 1)
    }

    /// Returns a selection with a new duration.
    ///
    /// The offset is kept where `history` allows it and aligned to the history
    /// increment, so changing the duration never leaves the slider off-grid.
    public func withDuration(_ duration: Int, history: History) -> TimeIntervalSelection {
        let candidate = TimeIntervalSelection(duration: duration, offset: offset)
        let clamped = min(max(offset, history.lowerLimit(of: candidate)), 0)
        return TimeIntervalSelection(duration: duration,
                                     offset: Self.align(clamped, to: history.timeIncrement))
    }

    /// Returns to realtime without changing the duration.
    public func goRealtime() -> TimeIntervalSelection {
        return TimeIntervalSelection(duration: duration, offset: 0)
    }

    // MARK: - Slider positions

    /// The slider position for the current offset, where the rightmost position
    /// is realtime.
    public func position(history: History) -> Int {
        return Self.position(for: history.lowerLimit(of: self) - offset, history: history)
    }

    /// The rightmost slider position, which maps to a zero offset.
    public func maxPosition(history: History) -> Int {
        return Self.position(for: history.lowerLimit(of: self), history: history)
    }

    /// Converts a slider position back into a selection. The rightmost position
    /// yields a zero offset (realtime).
    public func withPosition(_ position: Int, history: History) -> TimeIntervalSelection {
        let offset = (-maxPosition(history: history) + position) * history.timeIncrement
        return withOffset(offset, history: history)
    }

    // MARK: - Helpers

    private func stepping(_ history: History, by increment: Int) -> TimeIntervalSelection {
        let stepped = offset + increment * history.timeIncrement
        let clamped = min(max(stepped, history.lowerLimit(of: self)), 0)
        return TimeIntervalSelection(duration: duration, offset: Self.align(clamped, to: history.timeIncrement))
    }

    private static func position(for value: Int, history: History) -> Int {
        guard history.timeIncrement != 0 else { return 0 }
        return -value / history.timeIncrement
    }

    private static func align(_ value: Int, to increment: Int) -> Int {
        guard increment != 0 else { return value }
        return (value / increment) * increment
    }
}
