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
    var lastUpdate: Date?
    var strikeStatus: String?
    var timerPeriod: Int = 0
    var parameters: Parameters = Parameters()
    private let dataSource: DataEventSource
    private let settings: SettingsStore
    private let credentialStore: CredentialStore
    private var eventTask: Task<Void, Never>?

    var mapView: MKMapView!
    var statusText: UILabel!
    var settingsButton: UIButton!

    init(dataSource: DataEventSource,
         settings: SettingsStore = SettingsStore(),
         credentialStore: CredentialStore = KeychainCredentialStore()) {
        self.dataSource = dataSource
        self.settings = settings
        self.credentialStore = credentialStore
        super.init(nibName: nil, bundle: nil)
    }

    /// Creates a controller fed by a single provider's handler.
    public convenience init(dataHandler: DataHandler) {
        self.init(dataSource: dataHandler)
    }

    /// Creates a controller fed by the source-aware coordinator.
    public convenience init(coordinator: DataProviderCoordinator) {
        self.init(dataSource: coordinator)
    }

    public required init?(coder: NSCoder) {
        self.dataSource = DataProviderCoordinator(settings: SettingsStore(),
                                                  factory: DataProviderFactory())
        self.settings = SettingsStore()
        self.credentialStore = KeychainCredentialStore()
        super.init(coder: coder)
    }

    deinit {
        eventTask?.cancel()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        statusText = UILabel(frame: .zero)
        statusText.translatesAutoresizingMaskIntoConstraints = false
        statusText.clearsContextBeforeDrawing = true
        statusText.accessibilityIdentifier = "status.text"
        view.addSubview(statusText);

        settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.accessibilityIdentifier = "settings.open"
        settingsButton.setTitle(NSLocalizedString("settings.open", comment: "Button opening the data source settings"),
                                for: .normal)
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        view.addSubview(settingsButton)

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

        startEventStream()
    }

    func constraintsInit() {
        NSLayoutConstraint.activate([
            statusText.leftAnchor.constraint(equalTo: view.leftAnchor),
            statusText.topAnchor.constraint(equalTo: view.topAnchor),

            settingsButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: statusText.centerYAnchor),
            statusText.rightAnchor.constraint(lessThanOrEqualTo: settingsButton.leftAnchor, constant: -8),

            mapView.leftAnchor.constraint(equalTo: statusText.leftAnchor),
            mapView.topAnchor.constraint(equalTo: statusText.bottomAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// Presents the minimal data source configuration screen.
    @objc func showSettings() {
        let controller = SettingsViewController(settings: settings, credentialStore: credentialStore)
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true)
    }

    /// Subscribes to pipeline events and renders them on the main actor.
    private func startEventStream() {
        let events = dataSource.events()
        eventTask = Task { [weak self] in
            for await event in events {
                guard let self = self else { return }
                self.handle(event: event)
            }
        }
    }

    private func handle(event: DataEvent) {
        switch event {
        case .dataReceived(let result):
            render(result: result)
        case .failed(let error):
            NSLog("error in service call: \(error)")
        case .requestStarted:
            break
        }
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
            lastUpdate = Date()
            dataSource.requestData(parameters: parameters)
        }

        let countdown = String(format: NSLocalizedString("status.refreshCountdown",
                                                         comment: "Status line refresh countdown, e.g. 12/60 s"),
                               timerPeriod - timeInterval,
                               timerPeriod)
        let status = strikeStatus ?? NSLocalizedString("status.unavailable",
                                                       comment: "Status line shown before the first data arrives")
        self.statusText.text = "\(status) \(countdown)"
    }

    private func render(result: Result) {
        let overlays = result.strikes.map({
            (strike) -> MKOverlay in
            StrikeOverlay(withStrike: strike, andReferenceTimestamp: result.referenceTimestamp, andParameters: result.parameters)
        })

        strikeStatus = String(format: NSLocalizedString("status.strikeCount",
                                                        comment: "Status line showing strike count and interval in minutes"),
                              countStrikes(strikes: result.strikes),
                              parameters.intervalDuration)

        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.addOverlays(overlays)

        if let rasterParameters = result.rasterParameters {
            self.addDataArea(rasterParameters: rasterParameters)
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
