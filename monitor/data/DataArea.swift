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

/// A quantized geographic area used to request local lightning data.
///
/// The area is identified by a grid index (`x`, `y`) and a `scale` in degrees,
/// matching the coarse rounding used by the Android app so that no precise
/// user location is sent to the backend.
public struct DataArea: Equatable {

    public let x: Int
    public let y: Int
    public let scale: Int

    public init(x: Int, y: Int, scale: Int) {
        self.x = x
        self.y = y
        self.scale = scale
    }

    public var x1: Int { return x * scale }
    public var x2: Int { return (x + 1) * scale }
    public var y1: Int { return y * scale }
    public var y2: Int { return (y + 1) * scale }
}
