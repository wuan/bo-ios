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

    public let strikeOverlay: StrikeOverlay

    private let colorScheme: ColorScheme

    public override init(overlay: MKOverlay) {
        strikeOverlay = overlay as! StrikeOverlay
        colorScheme = ColorScheme()
        super.init(overlay: overlay)
    }

    public override func canDrawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return true
    }

    public override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        super.drawMapRect(mapRect, zoomScale: zoomScale, inContext: context)

        let color = colorScheme.getColor(strikeOverlay.referenceTimestamp,
                eventTime: strikeOverlay.strike.timestamp,
                intervalDuration: strikeOverlay.parameters.intervalDuration)
        
        let red = CGFloat((color & 0xff0000) >> 16) / 255.0
        let green = CGFloat((color & 0x00ff00) >> 8) / 255.0
        let blue = CGFloat(color & 0x0000ff) / 255.0
        
        CGContextSetRGBFillColor(context, red , green, blue, 1.0)

        let rasterElement = strikeOverlay.boundingMapRect

        let rasterRect = rectForMapRect(rasterElement);

        CGContextFillRect(context, rasterRect);
    }
}