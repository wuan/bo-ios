//
//  StrokeOverlayRenderer.swift
//  viewer
//
//  Created by Andreas Würl on 26.09.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import Foundation
import MapKit

public class StrokeOverlayRenderer : MKOverlayRenderer {
    
    public let strokeOverlay:StrokeOverlay
    
    public override init(overlay:MKOverlay) {
        self.strokeOverlay = overlay as! StrokeOverlay
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
        NSLog("\(NSStringFromCGRect(rasterRect))  - \(rasterElement.origin.x), \(rasterElement.origin.y) - \(rasterElement.size.height), \(rasterElement.size.height)")
    }
}