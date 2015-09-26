//
//  MapViewDelegate.swift
//  viewer
//
//  Created by Andreas Würl on 26.09.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import Foundation
import MapKit

enum MapViewDelegateError: ErrorType {
        case UnhandledType(AnyClass)
}

public class MapViewDelegate : NSObject, MKMapViewDelegate {
    
    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) throws -> MKOverlayRenderer {
        if (overlay.isKindOfClass(MKPolygon)) {
            let renderer = MKPolygonRenderer.init(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.4)
            return renderer;
        } else if (overlay.isKindOfClass(StrokeOverlay)) {
            return StrokeOverlayRenderer(overlay: overlay as! StrokeOverlay)
        }
        throw MapViewDelegateError.UnhandledType(overlay as! AnyClass)
    }
}
