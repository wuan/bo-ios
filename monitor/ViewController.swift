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
import UIKit
import MapKit

enum MapViewError: Error {
    case UnhandledType(AnyClass)
}

public class ViewController: UIViewController, MKMapViewDelegate {

    var pollingTimer: Timer?
    var lastUpdate: NSDate?
    var strikeStatus: String?
    var timerPeriod: Int = 0
    var parameters: Parameters = Parameters()
    let serviceClient = DefaultClient()

    var mapView: MKMapView!
    var statusText: UILabel!

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        statusText = UILabel(frame: .zero)
        statusText.translatesAutoresizingMaskIntoConstraints = false
        statusText.clearsContextBeforeDrawing = true
        view.addSubview(statusText);

        mapView = MKMapView()
        mapView.mapType = MKMapType.hybrid
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        view.addSubview(mapView)

        constraintsInit();

        timerPeriod = 60;

        pollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.timerTick), userInfo: nil, repeats: true)
    }

    func constraintsInit() {
        NSLayoutConstraint.activate([
            statusText.leftAnchor.constraint(equalTo: view.leftAnchor),
            statusText.topAnchor.constraint(equalTo: view.topAnchor),

            mapView.leftAnchor.constraint(equalTo: statusText.leftAnchor),
            mapView.topAnchor.constraint(equalTo: statusText.bottomAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is StrikeOverlay {
            return StrikeOverlayRenderer(overlay: overlay as! StrikeOverlay)
        }

        let renderer = MKPolygonRenderer.init(polygon: overlay as! MKPolygon)
        renderer.strokeColor = UIColor.white
        renderer.lineWidth = 1
        return renderer
    }

    @objc func timerTick() {
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
            serviceClient.fetchData(parameters: parameters, callback: handleResult)
        }

        self.statusText.text = (strikeStatus ?? "n/a ") + "\(timerPeriod - timeInterval)/\(timerPeriod) s"
    }

    func handleResult(result: Result) {
        let overlays = result.strikes.map({
            (strike) -> MKOverlay in
            StrikeOverlay(withStrike: strike, andReferenceTimestamp: result.referenceTimestamp, andParameters: result.parameters)
        })

        strikeStatus = "\(countStrikes(strikes: result.strikes)) strikes/\(parameters.intervalDuration) minutes "

        DispatchQueue.main.async {
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlays(overlays)

            if let rasterParameters = result.rasterParameters {
                self.addDataArea(rasterParameters: rasterParameters)
            }
        }
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

    public override var prefersStatusBarHidden: Bool { return true }

}
