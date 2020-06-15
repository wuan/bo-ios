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

@objc
public class RasterElement: Strike {

    init(rasterParameters: RasterParameters,
         withReferenceTimestamp referenceTimestamp: Int,
         fromArray dataArray: [Int]) {
        let timestamp = referenceTimestamp + 1000 * dataArray[3]
        let multiplicity = dataArray[2];
        let xCoordinate = rasterParameters.getCenterLongitude(offset: dataArray[0])
        let yCoordinate = rasterParameters.getCenterLatitude(offset: dataArray[1])
        let width = rasterParameters.longitudeDelta
        let height = rasterParameters.latitudeDelta

        super.init(timestamp: timestamp, andMultiplicity: multiplicity, andX: xCoordinate, andY: yCoordinate, andWidth: width, andHeight: height);
    }

    override public var description: String {
        return "Raster\(super.description)";
    }
}
