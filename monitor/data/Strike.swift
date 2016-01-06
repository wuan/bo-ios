//
// Created by Andreas Würl on 01.09.15.
// Copyright (c) 2015 Andreas Würl. All rights reserved.
//

import Foundation
import MapKit

@objc
public class Strike: NSObject {

    let timestamp: Int
    let multiplicity: Int
    public let envelope: MKCoordinateRegion
    var location: CLLocationCoordinate2D {
        get {
            return self.envelope.center
        }
    }

    init(timestamp: Int,
         andMultiplicity multiplicity: Int,
         andX xCoordinate: Double,
         andY yCoordinate: Double,
         andWidth width: Double = 0.0,
         andHeight height: Double = 0.0) {
        self.timestamp = timestamp
        self.multiplicity = multiplicity

        let location = CLLocationCoordinate2D(latitude: yCoordinate, longitude: xCoordinate)
        let span = MKCoordinateSpanMake(height, width)
        envelope = MKCoordinateRegion(center: location, span: span)
    }

    override public var description: String {
        return "Stroke: \(timestamp) (\(envelope.center.longitude), \(envelope.center.latitude)) \(multiplicity)";
    }

}
