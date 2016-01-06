//
// Created by Andreas Würl on 06.01.16.
// Copyright (c) 2016 Andreas Würl. All rights reserved.
//

import Foundation

public class Parameters: TimeIntervalWithOffset {
    let region: Int
    let rasterBaselength: Int
    let intervalDuration: Int
    let intervalOffset: Int
    let countThreshold: Int

    init(region: Int = 1, rasterBaselength: Int = 10000, intervalDuration: Int = 60, intervalOffset: Int = 0, countThreshold: Int = 0) {
        self.region = region
        self.rasterBaselength = rasterBaselength
        self.intervalDuration = intervalDuration
        self.intervalOffset = intervalOffset
        self.countThreshold = countThreshold
    }

    func isRealtime() -> Bool {
        return intervalOffset == 0
    }

    func isRaster() -> Bool {
        return rasterBaselength != 0
    }
}
