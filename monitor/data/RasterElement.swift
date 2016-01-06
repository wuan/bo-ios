//
// Created by Andreas Würl on 01.09.15.
// Copyright (c) 2015 Andreas Würl. All rights reserved.
//

import Foundation

@objc
public class RasterElement: Strike {

    init(rasterParameters: RasterParameters,
         withReferenceTimestamp referenceTimestamp: Int,
         fromArray dataArray: [Int]) {
        let timestamp = referenceTimestamp + 1000 * dataArray[3]
        let multiplicity = dataArray[2];
        let xCoordinate = rasterParameters.getCenterLongitude(dataArray[0])
        let yCoordinate = rasterParameters.getCenterLatitude(dataArray[1])
        let width = rasterParameters.longitudeDelta
        let height = rasterParameters.latitudeDelta

        super.init(timestamp: timestamp, andMultiplicity: multiplicity, andX: xCoordinate, andY: yCoordinate, andWidth: width, andHeight: height);
    }

    override public var description: String {
        return "Raster\(super.description)";
    }
}
