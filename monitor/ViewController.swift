//
//  ViewController.swift
//  viewer
//
//  Created by Andreas Würl on 26.09.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import Foundation
import UIKit
import MapKit

enum MapViewError: ErrorType {
    case UnhandledType(AnyClass)
}

public class ViewController: UIViewController, MKMapViewDelegate {

    var pollingTimer: NSTimer?
    var lastUpdate: NSDate?
    var strikeStatus: String?
    var timerPeriod: Int = 0
    var parameters: Parameters = Parameters()
    let serviceClient = DefaultClient()

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusText: UILabel!

    public override func viewDidLoad() {
        super.viewDidLoad()

        timerPeriod = 20;

        pollingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerTick", userInfo: nil, repeats: true)
    }

    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay.isKindOfClass(StrikeOverlay)) {
            return StrikeOverlayRenderer(overlay: overlay as! StrikeOverlay)
        }

        let renderer = MKPolygonRenderer.init(polygon: overlay as! MKPolygon)
        renderer.strokeColor = UIColor.whiteColor()
        renderer.lineWidth = 1
        return renderer;
    }

    func timerTick() {
        var update = false;

        var timeInterval: Int;

        if (self.lastUpdate == nil) {
            update = true;
            timeInterval = 0;
        } else {
            timeInterval = -Int((lastUpdate?.timeIntervalSinceNow)!);

            if (timeInterval >= timerPeriod) {
                update = true;
            }
        }

        if (update) {
            lastUpdate = NSDate()
            serviceClient.fetchData(parameters, callback: handleResult)
        }

        self.statusText.text = (strikeStatus ?? "") + "\(timerPeriod - timeInterval)/\(timerPeriod)"
    }

    func handleResult(result: Result) {
        let overlays = result.strikes.map({
            (let strike) -> MKOverlay in
            return StrikeOverlay(withStrike: strike, andReferenceTimestamp: result.referenceTimestamp, andParameters: result.parameters)
        })

        strikeStatus = "\(countStrikes(result.strikes)) strikes/\(parameters.intervalDuration) minutes "

        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlays(overlays)

            if let rasterParameters = result.rasterParameters {
                self.addDataArea(rasterParameters)
            }
        })
    }

    private func countStrikes(strikes: [Strike]) -> Int {
        var count = 0
        for strike in strikes {
            count += strike.multiplicity
        }
        return count
    }

    func addDataArea(rasterParameters: RasterParameters) {
        let x1 = rasterParameters.longitudeStart
        let x2 = rasterParameters.longitudeEnd

        let y1 = rasterParameters.latitudeStart
        let y2 = rasterParameters.latitudeEnd

        var worldCoords = [
                CLLocationCoordinate2D(latitude: y1, longitude: x1),
                CLLocationCoordinate2D(latitude: y1, longitude: x2),
                CLLocationCoordinate2D(latitude: y2, longitude: x2),
                CLLocationCoordinate2D(latitude: y2, longitude: x1)]

        let worldOverlay = MKPolygon(coordinates: &worldCoords, count: 4);

        self.mapView.addOverlay(worldOverlay)
    }


}