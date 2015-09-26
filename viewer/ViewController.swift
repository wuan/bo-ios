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

public class ViewController : UIViewController, JsonRpcClientDelegate {
    
    var pollingTimer:NSTimer
    var lastUpdate:NSDate?
    var mapViewDelegate:MapViewDelegate
    var timerPeriod:Int = 0
    
    @IBOutlet weak var mapView:MKMapView?
    @IBOutlet weak var statusText:UILabel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        timerPeriod = 20;
        
        pollingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector:"timerTick", userInfo: nil, repeats: true)
        
        mapViewDelegate = MapViewDelegate()
        
        mapView?.delegate = mapViewDelegate;
        
        //CLLocationCoordinate2D worldCoords[4] = { {90,-180}, {90,180}, {-90,180}, {-90,-180} };
        var worldCoords = [
            CLLocationCoordinate2D(latitude: 43, longitude: -100),
            CLLocationCoordinate2D(latitude: 43, longitude: -80),
            CLLocationCoordinate2D(latitude: 25, longitude: -80),
            CLLocationCoordinate2D(latitude: 25, longitude: -100)]
        
        let worldOverlay = MKPolygon(coordinates: &worldCoords, count:4);
        mapView?.addOverlay(worldOverlay)
    }
    
    func timerTick() {
        var update = false;
        
        var timeInterval:Int;
        
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
            let jsonRpcClient = JsonRpcClient(withServiceEndpoint:"http://bo1.tryb.de")
            jsonRpcClient.setDelegate(self)
            jsonRpcClient.call("get_strikes_grid", withArguments: 60, 10000, 0, 1, 0);
        }
        
        self.statusText?.text = "\(timerPeriod - timeInterval)/\(timerPeriod)"
    }
    
    func receivedResponse(response:[String:AnyObject]) {
        let rasterParameters = RasterParameters(fromDict:response)
        
        let referenceTimeString = response["t"] as! String
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "yyyyMMdd'T'HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        let referenceTime = dateFormatter.dateFromString(referenceTimeString)
        
        let referenceTimestamp = Int((referenceTime?.timeIntervalSince1970)!)
        
        let dataArray = response["r"] as! [[Int]];
        
        let overlays = dataArray.map({(rasterData:[Int]) -> MKOverlay in
            let rasterElement = RasterElement(rasterParameters: rasterParameters, withReferenceTimestamp: referenceTimestamp, fromArray: rasterData)
            let overlay = StrokeOverlay(withWStroke: rasterElement)
            self.mapView?.addOverlay(overlay)
            return overlay
        })
        
        NSLog("\(overlays)");
        NSLog("# overlays: \(overlays.count)");
    }
}