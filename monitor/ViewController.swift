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

public class ViewController: UIViewController, JsonRpcClientDelegate, MKMapViewDelegate {

    var pollingTimer: NSTimer?
    var lastUpdate: NSDate?
    var timerPeriod: Int = 0

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusText: UILabel!

    public override func viewDidLoad() {
        super.viewDidLoad()

        timerPeriod = 20;

        pollingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerTick", userInfo: nil, repeats: true)
    }

    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay.isKindOfClass(StrokeOverlay)) {
            return StrokeOverlayRenderer(overlay: overlay as! StrokeOverlay)
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
            let jsonRpcClient = JsonRpcClient(withServiceEndpoint: "http://bo-test.tryb.de")
            jsonRpcClient.setDelegate(self)
            jsonRpcClient.call("get_strikes_grid", withArguments: 60, 10000, 0, 1, 0);
        }

        self.statusText.text = "\(timerPeriod - timeInterval)/\(timerPeriod)"
    }

    func receivedResponse(response: [String:AnyObject]?, errorInServiceCall: ErrorType?) {
        if let response = response {
            if let result = response["result"] as? [String:AnyObject] {

                let rasterParameters = RasterParameters(fromDict: result)

                let referenceTimeString = result["t"] as! String
                let dateFormatter = NSDateFormatter()

                dateFormatter.dateFormat = "yyyyMMdd'T'HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone.localTimeZone()
                let referenceTime = dateFormatter.dateFromString(referenceTimeString)

                let referenceTimestamp = Int((referenceTime?.timeIntervalSince1970)!)

                let dataArray = result["r"] as! [[Int]];

                let overlays = dataArray.map({
                    (rasterData: [Int]) -> MKOverlay in
                    let rasterElement = RasterElement(rasterParameters: rasterParameters, withReferenceTimestamp: referenceTimestamp, fromArray: rasterData)
                    return StrokeOverlay(withStroke: rasterElement)
                })

                dispatch_async(dispatch_get_main_queue(), {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    self.mapView.addOverlays(overlays)

                    self.addDataArea(rasterParameters)
                })

                //NSLog("\(overlays)");
                NSLog("# overlays: \(overlays.count)");
            }
        } else {
            if let error = errorInServiceCall {
                NSLog("error in service call: \(errorInServiceCall)")
            }
        }
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