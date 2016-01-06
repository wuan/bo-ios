//
// Created by Andreas Würl on 06.01.16.
// Copyright (c) 2016 Andreas Würl. All rights reserved.
//

import Foundation

public class Result {
    let parameters: Parameters
    let referenceTimestamp: Int
    let strikes: [Strike]
    let rasterParameters: RasterParameters?

    init(parameters: Parameters, referenceTimestamp: Int, strikes: [Strike], rasterParameters: RasterParameters? = nil) {
        self.parameters = parameters
        self.referenceTimestamp = referenceTimestamp
        self.strikes = strikes
        self.rasterParameters = rasterParameters
    }
}
