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

/// A timestamped lightning event.
///
/// Provider-agnostic: both raster grid elements and individual strikes can
/// conform, so alert and rendering code can work against the protocol.
public protocol Event {
    /// Event time as a Unix timestamp in seconds.
    var timestamp: Int { get }
    /// Number of strokes grouped into this event.
    var multiplicity: Int { get }
}
