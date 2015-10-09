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

public class ViewController : UIViewController, JsonRpcClientDelegate, MKMapViewDelegate {
    
    var pollingTimer:NSTimer?
    var lastUpdate:NSDate?
    var timerPeriod:Int = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusText: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        timerPeriod = 20;
        
        pollingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector:"timerTick", userInfo: nil, repeats: true)
        
        //For Location 1
        let location1 = CLLocationCoordinate2D(
            latitude: 49.0,
            longitude: 11.0
        )
        
        let annotation1 = MKPointAnnotation()
        annotation1.coordinate = location1;
        annotation1.title = "Chelsea"
        annotation1.subtitle = "Chelsea"
        
        let span = MKCoordinateSpanMake(5, 5)
        
        let region1 = MKCoordinateRegion(center: location1, span: span)
        mapView.setRegion(region1, animated: true)
        mapView.addAnnotation(annotation1)
        
        //CLLocationCoordinate2D worldCoords[4] = { {90,-180}, {90,180}, {-90,180}, {-90,-180} };
        var worldCoords = [
            CLLocationCoordinate2D(latitude: 43, longitude: 11),
            CLLocationCoordinate2D(latitude: 43, longitude: 15),
            CLLocationCoordinate2D(latitude: 25, longitude: 15),
            CLLocationCoordinate2D(latitude: 25, longitude: 11)]
        
        let worldOverlay = MKPolygon(coordinates: &worldCoords, count:4);
        mapView.addOverlay(worldOverlay)
        
        let locations = [CLLocation(latitude: 48.5, longitude: 10.5), CLLocation(latitude: 49.5,longitude: 11.5)]
        
        //This line shows error
        var coordinates = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        
        let polyline = MKPolyline(coordinates: &coordinates, count: locations.count)
        
        mapView.addOverlay(polyline)
        
        mapView.ad

    }
    
    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) throws -> MKOverlayRenderer {
        if (overlay.isKindOfClass(MKPolygon)) {
            let renderer = MKPolygonRenderer.init(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.4)
            return renderer;
        } else if (overlay.isKindOfClass(StrokeOverlay)) {
            return StrokeOverlayRenderer(overlay: overlay as! StrokeOverlay)
        }
        throw MapViewError.UnhandledType(overlay as! AnyClass)
    }
    
    public func mapView(mapView: MKMapView, didAddOverlayRenderers renderers: [MKOverlayRenderer]) {
        print("hallo")
    }
    
    public func mapViewWillStartLoadingMap(mapView: MKMapView) {
        print("will start loading")
    }
    
    public func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        print("did finish loading")
    }
    
    public func mapViewWillStartRenderingMap(mapView: MKMapView) {
        print("will start rendering")
    }
    
    public func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        print("did finish rendering \(fullyRendered)")
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
            let jsonRpcClient = JsonRpcClient(withServiceEndpoint:"http://bo-test.tryb.de")
            jsonRpcClient.setDelegate(self)
            jsonRpcClient.call("get_strikes_grid", withArguments: 60, 10000, 0, 1, 0);
        }
        
        self.statusText?.text = "\(timerPeriod - timeInterval)/\(timerPeriod)"
    }
    
    func receivedResponse(response:[String:AnyObject]?, errorInServiceCall:ErrorType?) {
        if let result = response!["result"] as? [String:AnyObject] {
            
            let rasterParameters = RasterParameters(fromDict:result)
            
            let referenceTimeString = result["t"] as! String
            let dateFormatter = NSDateFormatter()
            
            dateFormatter.dateFormat = "yyyyMMdd'T'HH:mm:ss"
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            let referenceTime = dateFormatter.dateFromString(referenceTimeString)
            
            let referenceTimestamp = Int((referenceTime?.timeIntervalSince1970)!)
            
            let dataArray = result["r"] as! [[Int]];
            
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
    
    
}