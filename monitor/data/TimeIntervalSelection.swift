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
}
