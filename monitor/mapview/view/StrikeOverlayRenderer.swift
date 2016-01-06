//
//  StrokeOverlayRenderer.swift
//  viewer
//
//  Created by Andreas Würl on 26.09.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import Foundation
import MapKit

public class StrikeOverlayRenderer: MKOverlayRenderer {

    public let strokeOverlay: StrikeOverlay

    private let colorScheme: ColorScheme

    public override init(overlay: MKOverlay) {
        strokeOverlay = overlay as! StrikeOverlay
        colorScheme = ColorScheme()
        super.init(overlay: overlay)
    }

    public override func canDrawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return true
    }

    public override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        super.drawMapRect(mapRect, zoomScale: zoomScale, inContext: context)

        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0)

        let rasterElement = self.strokeOverlay.boundingMapRect

        let rasterRect = self.rectForMapRect(rasterElement);

        CGContextFillRect(context, rasterRect);
    }
}