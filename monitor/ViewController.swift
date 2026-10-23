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
    var parameters: Parameters = Parameters()
    private let dataSource: DataEventSource
    private let settings: SettingsStore
    private let credentialStore: CredentialStore
    /// Where the current location comes from; the stored mode selects it.
    private(set) var locationSource: LocationSource
    /// Builds the source a changed mode selects.
    private let locationSourceFactory: LocationSourceFactory
    /// The mode the current source serves, so an unchanged mode swaps nothing.
    private var activeLocationMode: LocationMode
    private var eventTask: Task<Void, Never>?

    /// The interval/mode state driving requests and the slider.
    var timeModel = TimeModel()
    /// Region and data-area selection for the visible extent.
    var localData = LocalData()
    /// Decides when a refresh is due for the active mode.
    let scheduler = ModeRefreshScheduler()

    /// Region used for requests, from the persisted region setting.
    var regionSetting: Int

    private var viewExtent: ViewExtent?
    private var lastGridSize: Int?

    /// The activity currently drawn, and the result it came from so a settings
    /// change can redraw the same data.
    private var activity: MapActivity?
    private var lastResult: Result?
    /// The area the drawn activity covers, used to avoid redrawing on every pan tick.
    private var lastPlanVisibleMapRect: MKMapRect?
    /// The base-map wash currently on the map, so an unchanged one is kept.
    private var drawnDim: ActivityRenderPlan.BaseMapDim?
    /// Tokens for the rendering settings this screen observes.
    private var settingsObservers: [NSObjectProtocol] = []
    /// Token for the location source this screen observes.
    private var locationObserver: NSObjectProtocol?
    /// The own-location marker currently drawn, if any.
    private(set) var ownLocationMarker: OwnLocationMarker?

    var mapView: MKMapView!
    var statusText: UILabel!
    var settingsButton: UIButton!
    var timeSlider: UISlider!
    var animationButton: UIButton!
    var modeLabel: UILabel!

    /// The chrome framing the map.
    var legendView: LegendView!
    var histogramView: HistogramView!
    var overviewView: DataAreaOverviewView!
    var radarView: AlarmRadarView!

    /// The content currently presented by the chrome.
    private(set) var legendContent: LegendContent?
    private(set) var histogramContent: HistogramContent?
    private(set) var radarContent: RadarContent?
    private(set) var overviewContent: DataAreaOverviewContent?

    /// Aggregates realtime activity for the radar.
    let alertAggregator = AlertAggregator()
    /// Turns the aggregation into the alert decision.
    private let alertMonitor: ProximityAlertMonitor
    /// Where an alert's notification goes.
    let alertNotifier: AlertNotifying
    /// Whether the notification authorisation has been asked for.
    private var hasRequestedNotificationAuthorization = false
    /// The alert state the monitor last reported.
    private(set) var alertState: ProximityAlertState = .cancelled

    init(dataSource: DataEventSource,
         settings: SettingsStore = SettingsStore(),
         credentialStore: CredentialStore = KeychainCredentialStore(),
         locationSource: LocationSource? = nil,
         locationSourceFactory: LocationSourceFactory = LocationSourceFactory(),
         alertSignaller: AlertSignalling? = nil,
         alertNotifier: AlertNotifying? = nil) {
        self.dataSource = dataSource
        self.settings = settings
        self.credentialStore = credentialStore
        self.locationSourceFactory = locationSourceFactory
        self.activeLocationMode = settings.locationMode
        self.locationSource = locationSource ?? locationSourceFactory.makeSource(for: settings.locationMode,
                                                                               settings: settings)
        self.alertNotifier = alertNotifier ?? LocalAlertNotifier(measurementUnit: { settings.measurementUnit })
        self.alertMonitor = ProximityAlertMonitor(settings: settings,
                                                  signaller: alertSignaller ?? SystemAlertSignaller(),
                                                  notifier: self.alertNotifier)
        self.regionSetting = settings.choice(for: .region)
        self.timeModel = ViewController.timeModel(for: settings)
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
        let settings = SettingsStore()
        self.dataSource = DataProviderCoordinator(settings: settings,
                                                  factory: DataProviderFactory())
        self.settings = settings
        self.credentialStore = KeychainCredentialStore()
        self.locationSourceFactory = LocationSourceFactory()
        self.activeLocationMode = settings.locationMode
        self.locationSource = LocationSourceFactory().makeSource(for: settings.locationMode,
                                                                settings: settings)
        self.alertNotifier = LocalAlertNotifier()
        self.alertMonitor = ProximityAlertMonitor(settings: settings,
                                                  signaller: SystemAlertSignaller(),
                                                  notifier: self.alertNotifier)
        self.regionSetting = settings.choice(for: .region)
        self.timeModel = ViewController.timeModel(for: settings)
        super.init(coder: coder)
    }

    /// The time model the stored interval duration and history step describe.
    static func timeModel(for settings: SettingsStore) -> TimeModel {
        return TimeModel(interval: TimeIntervalSelection(duration: settings.choice(for: .intervalDuration)),
                         history: History(timeIncrement: settings.choice(for: .historicTimestep)))
    }

    deinit {
        eventTask?.cancel()
        settingsObservers.forEach { settings.removeObserver($0) }
        if let locationObserver = locationObserver {
            locationSource.removeObserver(locationObserver)
        }
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
        mapView.mapType = ViewController.mapType(for: settings.string(for: .mapMode))
        mapView.isRotateEnabled = false
        // The own-location marker is drawn by the app, from the location source,
        // so MapKit's own user-location display stays off and no location
        // permission is needed for the manual path.
        mapView.showsUserLocation = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.accessibilityIdentifier = "map.view"
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTapped)))
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                 action: #selector(mapLongPressed)))
        view.addSubview(mapView)

        buildModeControls()
        buildChrome()
        constraintsInit()
        syncModeControls()
        observeRenderingSettings()
        observeSelectableSettings()
        observeLocation()
        observeLocationDisplay()
        observeAlertSettings()
        applyLocation()
        refreshChrome()

        pollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.timerTick), userInfo: nil, repeats: true)

        startEventStream()
    }

    /// Builds the time slider and animation control that drive the mode.
    private func buildModeControls() {
        modeLabel = UILabel()
        modeLabel.translatesAutoresizingMaskIntoConstraints = false
        modeLabel.accessibilityIdentifier = "mode.indicator"
        modeLabel.font = .preferredFont(forTextStyle: .subheadline)

        timeSlider = UISlider()
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.accessibilityIdentifier = "time.slider"
        timeSlider.minimumValue = 0
        timeSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        animationButton = UIButton(type: .system)
        animationButton.translatesAutoresizingMaskIntoConstraints = false
        animationButton.accessibilityIdentifier = "animation.toggle"
        animationButton.addTarget(self, action: #selector(animationToggled), for: .touchUpInside)

        let controls = UIStackView(arrangedSubviews: [modeLabel, timeSlider, animationButton])
        controls.axis = .vertical
        controls.spacing = 8
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.accessibilityIdentifier = "mode.controls"
        view.addSubview(controls)

        self.modeControls = controls
    }

    private var modeControls: UIStackView!

    /// Builds the on-map chrome: legend, radar, overview, and histogram.
    private func buildChrome() {
        legendView = LegendView()
        legendView.translatesAutoresizingMaskIntoConstraints = false
        legendView.addTarget(self, action: #selector(legendTapped), for: .touchUpInside)
        view.addSubview(legendView)

        radarView = AlarmRadarView()
        radarView.translatesAutoresizingMaskIntoConstraints = false
        let radarTap = UITapGestureRecognizer(target: self, action: #selector(radarTapped))
        let radarLongPress = UILongPressGestureRecognizer(target: self, action: #selector(radarLongPressed))
        radarTap.require(toFail: radarLongPress)
        radarView.addGestureRecognizer(radarTap)
        radarView.addGestureRecognizer(radarLongPress)
        view.addSubview(radarView)

        overviewView = DataAreaOverviewView()
        overviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overviewView)

        histogramView = HistogramView()
        histogramView.translatesAutoresizingMaskIntoConstraints = false
        histogramView.addTarget(self, action: #selector(histogramTapped), for: .touchUpInside)
        view.addSubview(histogramView)
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
            mapView.bottomAnchor.constraint(equalTo: modeControls.topAnchor, constant: -8),

            modeControls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            modeControls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            modeControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            // The reference's corners: legend top-left, radar bottom-left,
            // overview above the histogram bottom-right, histogram above the
            // time slider.
            legendView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            legendView.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 8),

            radarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            radarView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -8),

            histogramView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            histogramView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -8),

            overviewView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            overviewView.bottomAnchor.constraint(equalTo: histogramView.topAnchor, constant: -8),
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
            // Ignore a response for a selection the user has already moved past,
            // so an out-of-order reply cannot overwrite the current interval.
            guard result.parameters.intervalOffset == timeModel.interval.offset else { return }
            render(result: result)
        case .failed(let error):
            NSLog("error in service call: \(error)")
        case .requestStarted:
            break
        }
    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let tile as ActivityTilePolygon:
            let renderer = MKPolygonRenderer(polygon: tile)
            renderer.fillColor = tile.fillColor
            renderer.strokeColor = .clear
            return renderer
        case let strike as ActivityStrikePolygon:
            let renderer = MKPolygonRenderer(polygon: strike)
            renderer.fillColor = strike.fillColor
            renderer.strokeColor = .clear
            return renderer
        case let dim as ActivityDimPolygon:
            let renderer = MKMultiPolygonRenderer(multiPolygon: dim)
            renderer.fillColor = dim.fillColor
            renderer.strokeColor = .clear
            return renderer
        default:
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.strokeColor = UIColor.white
            renderer.lineWidth = 1
            return renderer
        }
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let count = annotation as? ActivityCountAnnotation {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: ActivityCountAnnotationView.reuseIdentifier)
                as? ActivityCountAnnotationView)
                ?? ActivityCountAnnotationView(annotation: count,
                                               reuseIdentifier: ActivityCountAnnotationView.reuseIdentifier)
            view.configure(text: count.text, textSize: count.textSize, textColor: count.textColor)
            return view
        }

        // The marker's drawn size comes from the display settings, so the view is
        // built from the content the controller last computed rather than from a
        // fresh default-sized marker.
        if annotation is OwnLocationAnnotation, let marker = ownLocationMarker {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: OwnLocationAnnotationView.reuseIdentifier)
                as? OwnLocationAnnotationView)
                ?? OwnLocationAnnotationView(annotation: annotation,
                                             reuseIdentifier: OwnLocationAnnotationView.reuseIdentifier)
            view.annotation = annotation
            view.configure(marker: marker)
            return view
        }

        guard let selection = annotation as? ActivitySelectionAnnotation else { return nil }

        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: ActivitySelectionAnnotationView.reuseIdentifier)
            as? ActivitySelectionAnnotationView)
            ?? ActivitySelectionAnnotationView(annotation: selection,
                                               reuseIdentifier: ActivitySelectionAnnotationView.reuseIdentifier)
        view.configure(text: selection.text)
        return view
    }

    /// Tracks the visible extent so region and grid selection follow the map,
    /// and keeps the drawn activity aligned with the visible area.
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        applyExtent(ViewExtent(region: mapView.region))
        redrawActivityIfVisibleAreaChanged()
        refreshOverview()
    }

    /// Redraws the activity once the map has moved far enough to matter.
    ///
    /// Culling and the base-map wash follow the visible rect, so panning needs a
    /// fresh plan; rebuilding on every region tick would draw far too often.
    private func redrawActivityIfVisibleAreaChanged() {
        guard activity != nil else { return }
        let visible = mapView.visibleMapRect
        if let last = lastPlanVisibleMapRect, last.contains(visible) { return }
        drawActivity()
    }

    private func applyExtent(_ extent: ViewExtent) {
        viewExtent = extent
        let areaChanged = localData.update(extent: extent)
        let gridSize = LocalData.gridSize(for: extent)
        let gridChanged = gridSize != lastGridSize
        lastGridSize = gridSize
        if areaChanged || gridChanged {
            requestCurrentParameters()
        }
    }

    @objc func timerTick() {
        let now = Date()

        switch scheduler.tick(mode: timeModel.mode, now: now) {
        case .none:
            break
        case .refresh:
            requestCurrentParameters()
        case .advanceAndRefresh:
            timeModel.advanceAnimation()
            syncModeControls()
            requestCurrentParameters()
        }

        updateStatus(now: now)
    }

    /// Advances the record from the time model and the visible extent.
    @discardableResult
    func requestCurrentParameters() -> Parameters {
        lastUpdate = Date()

        var parameters = baseParameters()
        parameters = localData.updateParameters(parameters)
        parameters = parameters.gatingGrid(on: dataSource.capabilities)
        self.parameters = parameters
        dataSource.requestData(parameters: parameters)
        return parameters
    }

    func baseParameters() -> Parameters {
        let gridSize = viewExtent.map { LocalData.gridSize(for: $0) } ?? parameters.rasterBaselength
        return Parameters(region: regionSetting,
                          rasterBaselength: gridSize,
                          intervalDuration: timeModel.interval.duration,
                          intervalOffset: timeModel.interval.offset,
                          dataArea: nil)
    }

    // MARK: - Mode controls

    @objc private func sliderChanged(_ sender: UISlider) {
        let position = Int(sender.value.rounded())
        timeModel.setPosition(position)
        sender.setValue(Float(position), animated: false)
        updateModeIndicator()
        scheduler.selectionChanged(now: Date())
        requestCurrentParameters()
    }

    @objc private func animationToggled() {
        if timeModel.mode == .animation {
            timeModel.stopAnimation()
        } else {
            timeModel.startAnimation()
        }
        syncModeControls()
        requestCurrentParameters()
    }

    /// Reflects the time model in the slider, the animation button, and the
    /// mode indicator.
    private func syncModeControls() {
        let maxPosition = max(1, timeModel.maxPosition)
        timeSlider.maximumValue = Float(maxPosition)
        timeSlider.value = Float(timeModel.position)
        timeSlider.isEnabled = timeModel.mode != .animation
        updateModeIndicator()
        updateAnimationButton()
    }

    private func updateModeIndicator() {
        let key: String
        switch timeModel.mode {
        case .realtime:
            key = "mode.realtime"
        case .history:
            key = "mode.history"
        case .animation:
            key = "mode.animation"
        }
        modeLabel.text = NSLocalizedString(key, comment: "Time mode indicator")
    }

    private func updateAnimationButton() {
        let titleKey = timeModel.mode == .animation ? "animation.stop" : "animation.start"
        animationButton.setTitle(NSLocalizedString(titleKey, comment: "Start or stop animation playback"),
                                 for: .normal)
    }

    private func updateStatus(now: Date) {
        let status = strikeStatus ?? NSLocalizedString("status.unavailable",
                                                       comment: "Status line shown before the first data arrives")
        self.statusText.text = "\(status) \(statusSuffix(now: now))"
    }

    /// The realtime countdown, or the start time of the selected historical
    /// interval, which has no countdown of its own.
    private func statusSuffix(now: Date) -> String {
        guard timeModel.mode == .realtime else {
            return String(format: NSLocalizedString("status.intervalStart",
                                                    comment: "Status line showing the start time of the selected interval"),
                          Self.intervalStartFormatter.string(from: timeModel.intervalStart(now: now)))
        }

        let period = Int(scheduler.realtimePeriod)
        let elapsed = lastUpdate.map { Int(now.timeIntervalSince($0)) } ?? 0
        return String(format: NSLocalizedString("status.refreshCountdown",
                                                comment: "Status line refresh countdown, e.g. 12/60 s"),
                      period - elapsed,
                      period)
    }

    /// Renders the selected interval's start as a wall-clock time, e.g. `14:30`.
    static let intervalStartFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Renders the displayed result, replacing any activity already drawn.
    func render(result: Result) {
        lastResult = result

        if let rasterParameters = result.rasterParameters {
            localData.store(gridParameters: rasterParameters)
        }

        activity = MapActivity(tiles: ViewController.tiles(for: result),
                               points: ViewController.points(for: result),
                               referenceTimestamp: result.referenceTimestamp,
                               intervalDuration: result.parameters.intervalDuration,
                               colorHandler: colorHandler,
                               fadeAlpha: baseMapDimAlpha)

        strikeStatus = String(format: NSLocalizedString("status.strikeCount",
                                                        comment: "Status line showing strike count and interval in minutes"),
                              countStrikes(strikes: result.strikes),
                              parameters.intervalDuration)

        dismissSelection()
        drawActivity()
        applyAlerts()
        refreshChrome()

        if let rasterParameters = result.rasterParameters {
            self.addDataArea(rasterParameters: rasterParameters)
        }
    }

    /// Draws the displayed activity with MapKit's own renderers.
    ///
    /// The plan decides colours, opacity, labels, and culling; MapKit builds the
    /// geometry, so only overlays and annotations are created here.
    func drawActivity() {
        mapView.removeOverlays(mapView.overlays.filter { $0 is ActivityTilePolygon
            || $0 is ActivityStrikePolygon })
        mapView.removeAnnotations(mapView.annotations.filter { $0 is ActivityCountAnnotation })

        guard let activity = activity else {
            drawBaseMapDim(nil)
            return
        }

        let zoomScale = currentZoomScale()
        let covered = ActivityRenderPlan.coveringRect(for: mapView.visibleMapRect)
        let plan = ActivityRenderPlan.make(activity: activity,
                                          zoomScale: zoomScale,
                                          visibleMapRect: covered)
        lastPlanVisibleMapRect = covered

        // The dim goes down first so the activity is drawn above it.
        drawBaseMapDim(plan.baseMapDim)
        mapView.addOverlays(plan.tileFills.map { ActivityOverlayBuilder.tilePolygon(for: $0) },
                            level: .aboveRoads)
        mapView.addOverlays(plan.strikeMarks.map {
            ActivityOverlayBuilder.strikePolygon(for: $0, zoomScale: zoomScale)
        }, level: .aboveRoads)
        mapView.addAnnotations(plan.countLabels.map { label in
            ActivityCountAnnotation(coordinate: label.coordinate,
                                    text: label.text,
                                    textSize: label.textSize,
                                    textColor: UIColor(packed: label.textColor,
                                                       alpha: CGFloat(label.alpha)))
        })
    }

    /// Draws the base-map wash, keeping the one already on the map when it did
    /// not change.
    ///
    /// The wash spans the whole map and depends only on the fade setting and the
    /// base map, so it survives camera changes. MapKit rebuilds an overlay's
    /// tiles when it is added, and doing that on every pan and pinch tick makes
    /// the wash appear as separate rectangles over the map.
    private func drawBaseMapDim(_ dim: ActivityRenderPlan.BaseMapDim?) {
        guard drawnDim != dim else { return }

        for overlay in mapView.overlays where overlay is ActivityDimPolygon {
            mapView.removeOverlay(overlay)
        }
        if let dim = dim {
            mapView.addOverlay(ActivityOverlayBuilder.dimPolygon(for: dim), level: .aboveRoads)
        }
        drawnDim = dim
    }

    /// The grid cells in a result: strikes that cover an area.
    static func tiles(for result: Result) -> [MapActivity.Tile] {
        return result.strikes.filter { isTile($0) }.map { strike in
            MapActivity.Tile(center: strike.envelope.center,
                             longitudeDelta: strike.envelope.span.longitudeDelta,
                             latitudeDelta: strike.envelope.span.latitudeDelta,
                             count: strike.multiplicity,
                             timestamp: strike.timestamp)
        }
    }

    /// The individual strikes in a result: those without a covered area.
    static func points(for result: Result) -> [MapActivity.Point] {
        return result.strikes.filter { !isTile($0) }.map { strike in
            MapActivity.Point(coordinate: strike.envelope.center,
                              count: strike.multiplicity,
                              timestamp: strike.timestamp)
        }
    }

    private static func isTile(_ strike: Strike) -> Bool {
        return strike.envelope.span.longitudeDelta > 0 || strike.envelope.span.latitudeDelta > 0
    }

    // MARK: - Chrome

    /// Rebuilds the chrome's content from the displayed result, the active
    /// settings, the current location, and the map's visible rect.
    func refreshChrome() {
        refreshLegend()
        refreshHistogram()
        refreshRadar()
        refreshOverview()
    }

    /// Refreshes the legend from the active scheme, region, and grid.
    func refreshLegend() {
        let content = LegendContentBuilder.make(colorHandler: colorHandler,
                                               intervalDuration: timeModel.interval.duration,
                                               regionName: activeRegionName,
                                               region: regionSetting,
                                               dataArea: localData.dataArea,
                                               gridBaselineMetres: parameters.rasterBaselength)
        legendContent = content
        legendView.configure(content: content)
    }

    /// Refreshes the histogram from the displayed result's histogram values.
    ///
    /// A result that carries no histogram leaves the view empty rather than
    /// failing, and no request of its own is made.
    func refreshHistogram() {
        let content = HistogramContentBuilder.make(values: lastResult?.histogram,
                                                  intervalDuration: timeModel.interval.duration,
                                                  colorHandler: colorHandler)
        histogramContent = content
        histogramView.configure(content: content)
    }

    /// Refreshes the radar from the aggregation of the displayed activity.
    func refreshRadar() {
        let content = RadarContentBuilder.make(aggregation: currentAggregation(),
                                               colorHandler: colorHandler,
                                               intervalDuration: timeModel.interval.duration,
                                               measurementUnit: settings.measurementUnit,
                                               referenceTime: lastResult?.referenceTimestamp ?? 0,
                                               alert: alertState.isActive)
        radarContent = content
        radarView.configure(content: content)
    }

    /// Evaluates the alert decision and reflects it on the radar.
    ///
    /// Called when the data changes and when the location changes - the two
    /// moments the answer can change - so a signal or a notification follows the
    /// activity rather than the chrome's refresh cadence.
    func applyAlerts() {
        if settings.alertsEnabled, location != nil {
            requestNotificationAuthorizationIfNeeded()
        }
        alertState = alertMonitor.evaluate(currentAggregation())
        refreshRadar()
    }

    /// Asks for the notification authorisation once, the first time alerts are
    /// on and a location is known - the moment the app could actually warn.
    ///
    /// Asking at launch would put a system prompt in front of a user the app
    /// cannot warn yet, and asking only when the switch is toggled would leave a
    /// default install's notifications unauthorised forever.
    func requestNotificationAuthorizationIfNeeded() {
        guard !hasRequestedNotificationAuthorization else { return }
        hasRequestedNotificationAuthorization = true
        alertNotifier.requestAuthorization()
    }

    /// Refreshes the data-area overview from the result and the visible rect.
    func refreshOverview() {
        let content = DataAreaOverviewContentBuilder.make(grid: lastResult?.rasterParameters,
                                                          viewport: viewExtent,
                                                          zoomLevel: currentZoomLevel)
        overviewContent = content
        overviewView.configure(content: content)
    }

    /// The aggregation of the displayed activity around the current location.
    func currentAggregation() -> AlertAggregation {
        return alertAggregator.aggregate(strikes: lastResult?.strikes,
                                         dataArea: lastResult?.rasterParameters,
                                         location: location,
                                         isRealtime: lastResult?.parameters.isRealtime() ?? false,
                                         referenceTime: lastResult?.referenceTimestamp ?? 0)
    }

    /// The map's current zoom level, as a fractional tile zoom.
    var currentZoomLevel: Double {
        let span = mapView.region.span.longitudeDelta
        guard span > 0 else { return 0 }
        return log2(360 / span)
    }

    // MARK: - Chrome interaction

    /// Opens the quick-settings dialog over the map.
    @objc func legendTapped() {
        let controller = QuickSettingsViewController(settings: settings)
        controller.modalPresentationStyle = .pageSheet
        present(controller, animated: true)
    }

    /// Zooms the map out to the active data area.
    @objc func histogramTapped() {
        guard let grid = lastResult?.rasterParameters else { return }
        let centre = CLLocationCoordinate2D(latitude: (grid.latitudeStart + grid.latitudeEnd) / 2,
                                            longitude: (grid.longitudeStart + grid.longitudeEnd) / 2)
        let span = MKCoordinateSpan(latitudeDelta: abs(grid.latitudeStart - grid.latitudeEnd),
                                    longitudeDelta: abs(grid.longitudeEnd - grid.longitudeStart))
        mapView.setRegion(MKCoordinateRegion(center: centre, span: span), animated: true)
    }

    /// Centres the map on the current location.
    ///
    /// The radar's own content is left as it is, so a radar that cannot centre -
    /// because no location is known - keeps presenting its state.
    @objc func radarTapped() {
        centerOnLocation()
    }

    /// Opens the enlarged radar without changing the small one's state.
    @objc func radarLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let controller = EnlargedRadarViewController()
        controller.configure(content: radarContent)
        controller.modalPresentationStyle = .pageSheet
        present(controller, animated: true)
    }

    // MARK: - Location

    /// The current location, if one is known.
    var location: Location? {
        return locationSource.location
    }

    /// The location under a point in the map view.
    func location(for point: CGPoint) -> Location {
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        return Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Sets the current location from a point in the map view.
    ///
    /// Only a source that accepts a set position - the manual one - takes it,
    /// and the new position replaces any previous one.
    func setLocation(at point: CGPoint) {
        guard let settable = locationSource as? SettableLocationSource else { return }
        settable.setLocation(location(for: point))
    }

    /// Sets the current location from a long press on the map.
    @objc func mapLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        setLocation(at: gesture.location(in: mapView))
    }

    /// Follows the location source and the stored mode that selects it.
    private func observeLocation() {
        observeLocationSource()
        settingsObservers.append(settings.observe(.locationMode) { [weak self] in
            self?.applyLocationMode()
        })
    }

    /// Registers observation of the current source.
    private func observeLocationSource() {
        locationObserver = locationSource.observe { [weak self] in
            self?.applyLocation()
            self?.applyAlerts()
        }
    }

    /// Stops observing the current source, so a replaced one goes quiet.
    private func stopObservingLocation() {
        guard let token = locationObserver else { return }
        locationSource.removeObserver(token)
        locationObserver = nil
    }

    /// Adopts a changed location mode by replacing the source that serves it.
    ///
    /// The previous source is stopped and no longer observed, so exactly one
    /// source can publish a position. A source that has not reported one yet
    /// leaves the marker unset, as a fresh manual source does.
    func applyLocationMode() {
        let mode = settings.locationMode
        guard mode != activeLocationMode else { return }
        activeLocationMode = mode
        stopObservingLocation()
        (locationSource as? DeviceLocationSource)?.stop()
        locationSource = locationSourceFactory.makeSource(for: mode, settings: settings)
        observeLocationSource()
        applyLocation()
        applyAlerts()
    }

    /// Re-evaluates the alert decision when an alert setting changes, so a new
    /// limit or a switched-on alert applies without a relaunch.
    private func observeAlertSettings() {
        settingsObservers.append(settings.observe(.alertEnabled) { [weak self] in
            // applyAlerts takes the authorisation request with it when alerts
            // are on and a location is known.
            self?.applyAlerts()
        })
        for key in [SettingsKey.notificationDistanceLimit, SettingsKey.signalingDistanceLimit,
                    SettingsKey.signalingSuppressionTime, SettingsKey.alertVibrationSignal,
                    SettingsKey.alertSoundSignal] {
            settingsObservers.append(settings.observe(key) { [weak self] in
                self?.applyAlerts()
            })
        }
    }

    /// Redraws the own-location marker when the location changes.
    private func observeLocationDisplay() {
        for key in [SettingsKey.showOwnLocation, SettingsKey.ownLocationSize] {
            settingsObservers.append(settings.observe(key) { [weak self] in
                self?.applyLocation()
            })
        }
    }

    /// Keeps the own-location marker in step with the location source and the
    /// display settings.
    ///
    /// One marker is drawn while a location is known and own-location display is
    /// on, at the size the setting selects, and it moves with the location; no
    /// marker is drawn when either is missing.
    func applyLocation() {
        let shown = mapView.annotations.compactMap { $0 as? OwnLocationAnnotation }
        ownLocationMarker = OwnLocationMarker.make(location: location,
                                                   visible: settings.showOwnLocation,
                                                   diameter: settings.ownLocationDiameter)

        guard let marker = ownLocationMarker else {
            if !shown.isEmpty {
                mapView.removeAnnotations(shown)
            }
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: marker.location.latitude,
                                                longitude: marker.location.longitude)
        if let first = shown.first {
            mapView.removeAnnotations(Array(shown.dropFirst()))
            first.coordinate = coordinate
            // The annotation moved, but MapKit does not rebuild its view for a
            // coordinate change, so refresh what the view draws and reports.
            (mapView.view(for: first) as? OwnLocationAnnotationView)?.configure(marker: marker)
        } else {
            mapView.addAnnotation(OwnLocationAnnotation(marker: marker))
        }
    }

    /// Centres the map on the current location.
    ///
    /// The map is left unchanged when no location is known. The keep-zoom choice
    /// decides whether only the centre moves or the map also zooms out to show
    /// the alarm radar's range around the location.
    func centerOnLocation(animated: Bool = true) {
        guard let location = location else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude,
                                                longitude: location.longitude)
        guard !settings.keepZoomOnCenter else {
            mapView.setCenter(coordinate, animated: animated)
            return
        }
        mapView.setRegion(MKCoordinateRegion(
            center: coordinate,
            span: ViewController.span(aroundRadiusKilometres: ViewController.centerRadiusKilometres,
                                      latitude: location.latitude)),
                          animated: animated)
    }

    /// The radius centring shows around the location, in kilometres: the
    /// outermost ring the alarm radar draws.
    static var centerRadiusKilometres: Double {
        return AlertGeometry.rangeSteps.last ?? 500
    }

    /// The visible span covering `kilometres` in every direction of the centre.
    static func span(aroundRadiusKilometres kilometres: Double, latitude: Double) -> MKCoordinateSpan {
        let latitudeDelta = 2 * kilometres / kilometresPerDegree
        // A degree of longitude shrinks towards the poles; the span keeps the
        // ground distance the same rather than the degree count.
        let narrowing = max(cos(latitude * .pi / 180), 0.01)
        return MKCoordinateSpan(latitudeDelta: latitudeDelta,
                                longitudeDelta: latitudeDelta / narrowing)
    }

    /// The kilometres a degree of latitude covers, as MapKit and the radar
    /// geometry both assume a spherical Earth.
    static let kilometresPerDegree: Double = 111.32

    // MARK: - Rendering settings

    /// Maps the stored map mode to the map type it names.
    static func mapType(for mode: String) -> MKMapType {
        switch mode.lowercased() {
        case "satellite":
            return .satellite
        case "standard", "street", "streetmap":
            return .standard
        case "mutedstandard":
            return .mutedStandard
        default:
            return .hybrid
        }
    }

    /// Whether activity is drawn over a light base map.
    static func baseType(for mapType: MKMapType) -> MapBaseType {
        switch mapType {
        case .standard, .mutedStandard:
            return .streetMap
        default:
            return .satellite
        }
    }

    /// The colours the displayed activity is drawn with.
    var activityColorHandler: ColorHandler {
        return activity?.colorHandler ?? colorHandler
    }

    /// The colours for the stored scheme and the active base map.
    var colorHandler: ColorHandler {
        let scheme = ColorScheme(rawValue: settings.string(for: .colorScheme)) ?? .blitzortung
        return ColorHandler(scheme: scheme, baseType: ViewController.baseType(for: mapView.mapType))
    }

    /// The opacity of the base-map dim, from the stored fade percentage.
    var baseMapDimAlpha: Int {
        let percent = min(max(settings.int(for: .mapFade), 0), 100)
        // Multiply before dividing so the half-way cases stay exact.
        return Int((Double(percent) * 255.0 / 100.0).rounded())
    }

    /// Redraws when one of the rendering settings changes.
    private func observeRenderingSettings() {
        for key in [SettingsKey.colorScheme, SettingsKey.mapFade, SettingsKey.mapMode] {
            settingsObservers.append(settings.observe(key) { [weak self] in
                self?.applyRenderingSettings()
            })
        }
    }

    /// Reflects a changed region, interval duration, or history step without a
    /// relaunch, so the quick-settings dialog applies while the map stays up.
    private func observeSelectableSettings() {
        settingsObservers.append(settings.observe(.region) { [weak self] in
            self?.applyRegionSetting()
        })
        for key in [SettingsKey.intervalDuration, SettingsKey.historicTimestep] {
            settingsObservers.append(settings.observe(key) { [weak self] in
                self?.applyIntervalSettings()
            })
        }
    }

    /// The name of the region the app is requesting.
    var activeRegionName: String {
        return SelectableSettings.name(for: .region, value: regionSetting)
            ?? SelectableSettings.regions[0].name
    }

    /// Adopts the stored region and requests the data it selects.
    func applyRegionSetting() {
        regionSetting = settings.choice(for: .region)
        // The stored data area belongs to the previous region.
        localData = LocalData()
        refreshLegend()
        requestCurrentParameters()
    }

    /// Adopts the stored interval duration and history step, reshaping the
    /// slider, and requests the display it selects.
    func applyIntervalSettings() {
        timeModel.configure(intervalDuration: settings.choice(for: .intervalDuration),
                            historicTimestep: settings.choice(for: .historicTimestep))
        syncModeControls()
        scheduler.selectionChanged(now: Date())
        refreshChrome()
        requestCurrentParameters()
    }

    /// Applies the stored map mode and redraws the displayed activity.
    func applyRenderingSettings() {
        let type = ViewController.mapType(for: settings.string(for: .mapMode))
        if mapView.mapType != type {
            mapView.mapType = type
        }
        guard let result = lastResult else {
            refreshChrome()
            return
        }
        render(result: result)
    }

    // MARK: - Selection

    /// The scale the map is drawn at, in points per map point.
    func currentZoomScale() -> MKZoomScale {
        let visibleWidth = mapView.visibleMapRect.size.width
        guard visibleWidth > 0, mapView.bounds.width > 0 else { return 1 }
        return MKZoomScale(mapView.bounds.width / CGFloat(visibleWidth))
    }

    /// Shows details for the activity under a tap, or clears any shown popup.
    @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
        dismissSelection()

        if let selection = selection(at: gesture.location(in: mapView)) {
            present(selection)
        }
    }

    /// Resolves the activity under a point in the map view, if any.
    ///
    /// Nothing is resolved when no activity is drawn there, so a tap on empty
    /// map shows no popup.
    func selection(at mapPoint: MKMapPoint) -> MapActivitySelection? {
        return activity?.selection(at: mapPoint, zoomScale: currentZoomScale())
    }

    /// The activity under a point in the map view, if any.
    func selection(at point: CGPoint) -> MapActivitySelection? {
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        return selection(at: MKMapPoint(coordinate))
    }

    /// Shows the details popup for a selected tile or strike.
    func present(_ selection: MapActivitySelection) {
        let annotation = ActivitySelectionAnnotation(coordinate: selection.coordinate,
                                                     text: selection.detailsText())
        mapView.addAnnotation(annotation)
    }

    /// Removes the details popup, if one is shown.
    func dismissSelection() {
        let shown = mapView.annotations.filter { $0 is ActivitySelectionAnnotation }
        if !shown.isEmpty {
            mapView.removeAnnotations(shown)
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
