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
    private var eventTask: Task<Void, Never>?

    /// The interval/mode state driving requests and the slider.
    var timeModel = TimeModel()
    /// Region and data-area selection for the visible extent.
    var localData = LocalData()
    /// Decides when a refresh is due for the active mode.
    let scheduler = ModeRefreshScheduler()

    /// Region used for requests until the region selector lands (Phase 3).
    var regionSetting = Parameters().region
    /// Count threshold used for requests until the threshold control lands.
    var countThresholdSetting = Parameters().countThreshold

    private var viewExtent: ViewExtent?
    private var lastGridSize: Int?

    /// The activity currently drawn, and the result it came from so a settings
    /// change can redraw the same data.
    private var activity: MapActivity?
    private var lastResult: Result?
    /// The area the drawn activity covers, used to avoid redrawing on every pan tick.
    private var lastPlanVisibleMapRect: MKMapRect?
    /// Tokens for the rendering settings this screen observes.
    private var settingsObservers: [NSObjectProtocol] = []

    var mapView: MKMapView!
    var statusText: UILabel!
    var settingsButton: UIButton!
    var timeSlider: UISlider!
    var animationButton: UIButton!
    var modeLabel: UILabel!

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
        settingsObservers.forEach { settings.removeObserver($0) }
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
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTapped)))
        view.addSubview(mapView)

        buildModeControls()
        constraintsInit()
        syncModeControls()
        observeRenderingSettings()

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
            let renderer = MKPolygonRenderer(polygon: dim)
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
    private func requestCurrentParameters() -> Parameters {
        lastUpdate = Date()

        var parameters = baseParameters()
        parameters = localData.updateParameters(parameters)
        parameters = parameters.gatingGrid(on: dataSource.capabilities)
        self.parameters = parameters
        dataSource.requestData(parameters: parameters)
        return parameters
    }

    private func baseParameters() -> Parameters {
        let gridSize = viewExtent.map { LocalData.gridSize(for: $0) } ?? parameters.rasterBaselength
        return Parameters(region: regionSetting,
                          rasterBaselength: gridSize,
                          intervalDuration: timeModel.interval.duration,
                          intervalOffset: timeModel.interval.offset,
                          countThreshold: countThresholdSetting,
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
            || $0 is ActivityStrikePolygon
            || $0 is ActivityDimPolygon })
        mapView.removeAnnotations(mapView.annotations.filter { $0 is ActivityCountAnnotation })

        guard let activity = activity else { return }

        let zoomScale = currentZoomScale()
        let covered = ActivityRenderPlan.coveringRect(for: mapView.visibleMapRect)
        let plan = ActivityRenderPlan.make(activity: activity,
                                          zoomScale: zoomScale,
                                          visibleMapRect: covered)
        lastPlanVisibleMapRect = covered

        // The dim goes down first so the activity is drawn above it.
        if let dim = plan.baseMapDim {
            mapView.addOverlay(ActivityOverlayBuilder.dimPolygon(for: dim), level: .aboveRoads)
        }
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

    /// Applies the stored map mode and redraws the displayed activity.
    func applyRenderingSettings() {
        let type = ViewController.mapType(for: settings.string(for: .mapMode))
        if mapView.mapType != type {
            mapView.mapType = type
        }
        guard let result = lastResult else { return }
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
