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

import UIKit

/// The quick-settings sheet the legend opens.
///
/// Every entry reads and writes the same ``SettingsStore`` the map already
/// observes, so a change applies to the map behind the sheet without leaving
/// it, and the quick dialog and the settings screen cannot diverge.
public final class QuickSettingsViewController: UIViewController,
                                                UIPickerViewDataSource,
                                                UIPickerViewDelegate {

    private let settings: SettingsStore

    /// Token for the data-source observation that toggles the region row.
    private var dataSourceObserver: NSObjectProtocol?

    private let titleLabel = UILabel()
    private let regionLabel = UILabel()
    private let regionPicker = UIPickerView()
    private let intervalLabel = UILabel()
    private let intervalControl = UISegmentedControl(items: SelectableSettings.intervalDurations.map { $0.name })
    private let timestepLabel = UILabel()
    private let timestepControl = UISegmentedControl(items: SelectableSettings.historicTimesteps.map { $0.name })
    private let sourceLabel = UILabel()
    private let sourceControl = UISegmentedControl(items: [
        NSLocalizedString("settings.source.rpc", comment: "JSON-RPC data source name"),
        NSLocalizedString("settings.source.http", comment: "Blitzortung HTTP data source name"),
    ])
    private let schemeLabel = UILabel()
    private let schemeControl = UISegmentedControl(items: ColorScheme.allCases.map {
        NSLocalizedString("settings.scheme.\($0.rawValue.lowercased())", comment: "Colour scheme name")
    })
    private let mapModeLabel = UILabel()
    private let mapModeControl = UISegmentedControl(items: SettingsViewController.mapModes.map {
        NSLocalizedString("settings.mapmode.\($0)", comment: "Map type name")
    })
    private let fadeLabel = UILabel()
    private let fadeControl = UISlider()
    private let closeButton = UIButton(type: .system)

    public init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.settings = SettingsStore()
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "quick.root"

        buildLayout()
        loadValues()
        // A source change inside the open dialog toggles the region row without
        // closing the sheet.
        dataSourceObserver = settings.observe(.dataSource) { [weak self] in
            self?.updateRegionVisibility()
        }
        updateRegionVisibility()
    }

    deinit {
        if let dataSourceObserver = dataSourceObserver {
            settings.removeObserver(dataSourceObserver)
        }
    }

    private func buildLayout() {
        titleLabel.text = NSLocalizedString("quick.title", comment: "Quick settings sheet title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.accessibilityIdentifier = "quick.title"

        regionLabel.text = NSLocalizedString("quick.region", comment: "Label for the region selector")
        regionPicker.accessibilityIdentifier = "quick.region"
        regionPicker.dataSource = self
        regionPicker.delegate = self

        intervalLabel.text = NSLocalizedString("quick.intervalDuration", comment: "Label for the interval duration selector")
        intervalControl.accessibilityIdentifier = "quick.intervalDuration"
        intervalControl.addTarget(self, action: #selector(intervalChanged), for: .valueChanged)

        timestepLabel.text = NSLocalizedString("quick.historicTimestep", comment: "Label for the historic timestep selector")
        timestepControl.accessibilityIdentifier = "quick.historicTimestep"
        timestepControl.addTarget(self, action: #selector(timestepChanged), for: .valueChanged)

        sourceLabel.text = NSLocalizedString("quick.dataSource", comment: "Label for the data source selector")
        sourceControl.accessibilityIdentifier = "quick.dataSource"
        sourceControl.addTarget(self, action: #selector(sourceChanged), for: .valueChanged)

        schemeLabel.text = NSLocalizedString("quick.colorScheme", comment: "Label for the colour scheme selector")
        schemeControl.accessibilityIdentifier = "quick.colorScheme"
        schemeControl.addTarget(self, action: #selector(schemeChanged), for: .valueChanged)

        mapModeLabel.text = NSLocalizedString("quick.mapMode", comment: "Label for the map mode selector")
        mapModeControl.accessibilityIdentifier = "quick.mapMode"
        mapModeControl.addTarget(self, action: #selector(mapModeChanged), for: .valueChanged)

        fadeLabel.text = NSLocalizedString("quick.fade", comment: "Label for the base-map fade slider")
        fadeControl.accessibilityIdentifier = "quick.fade"
        fadeControl.minimumValue = 0
        fadeControl.maximumValue = 100
        fadeControl.addTarget(self, action: #selector(fadeChanged), for: .valueChanged)

        closeButton.setTitle(NSLocalizedString("quick.close", comment: "Close quick settings button"), for: .normal)
        closeButton.accessibilityIdentifier = "quick.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            regionLabel,
            regionPicker,
            intervalLabel,
            intervalControl,
            timestepLabel,
            timestepControl,
            sourceLabel,
            sourceControl,
            schemeLabel,
            schemeControl,
            mapModeLabel,
            mapModeControl,
            fadeLabel,
            fadeControl,
            closeButton,
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scroller = UIScrollView()
        scroller.translatesAutoresizingMaskIntoConstraints = false
        scroller.addSubview(stack)
        view.addSubview(scroller)

        for label in [regionLabel, intervalLabel, timestepLabel, sourceLabel, schemeLabel, mapModeLabel, fadeLabel] {
            label.font = .preferredFont(forTextStyle: .subheadline)
        }

        NSLayoutConstraint.activate([
            scroller.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            scroller.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            scroller.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            scroller.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: scroller.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroller.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroller.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroller.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroller.widthAnchor),
        ])

        // The picker keeps its height while shown, but the stack must be able to
        // collapse the row, so the height yields below the hiding constraint.
        let pickerHeight = regionPicker.heightAnchor.constraint(equalToConstant: 110)
        pickerHeight.priority = UILayoutPriority(999)
        pickerHeight.isActive = true
    }

    /// Shows the region row only while the active source applies the stored
    /// region; the JSON-RPC source derives its region from the extent.
    private func updateRegionVisibility() {
        let source = DataProviderType(rawValue: settings.string(for: .dataSource)) ?? .rpc
        let showsRegion = source.selectsRegion
        regionLabel.isHidden = !showsRegion
        regionPicker.isHidden = !showsRegion
    }

    /// Reflects the stored settings in the controls.
    private func loadValues() {
        let region = SelectableSettings.httpRegion(for: settings.choice(for: .region))
        if let row = SelectableSettings.namedRegions.firstIndex(where: { $0.value == region }) {
            regionPicker.selectRow(row, inComponent: 0, animated: false)
        }
        intervalControl.selectedSegmentIndex =
            SelectableSettings.intervalDurations.firstIndex { $0.value == settings.choice(for: .intervalDuration) } ?? 1
        timestepControl.selectedSegmentIndex =
            SelectableSettings.historicTimesteps.firstIndex { $0.value == settings.choice(for: .historicTimestep) } ?? 1

        let type = DataProviderType(rawValue: settings.string(for: .dataSource)) ?? .rpc
        sourceControl.selectedSegmentIndex = DataProviderType.allCases.firstIndex(of: type) ?? 0

        let scheme = ColorScheme(rawValue: settings.string(for: .colorScheme)) ?? .blitzortung
        schemeControl.selectedSegmentIndex = ColorScheme.allCases.firstIndex(of: scheme) ?? 0

        mapModeControl.selectedSegmentIndex = SettingsViewController.mapModes.firstIndex(of: settings.string(for: .mapMode)) ?? 0
        fadeControl.value = Float(min(max(settings.int(for: .mapFade), 0), 100))
    }

    // MARK: - Changes

    @objc private func intervalChanged() {
        let index = intervalControl.selectedSegmentIndex
        guard index >= 0, index < SelectableSettings.intervalDurations.count else { return }
        settings.setChoice(SelectableSettings.intervalDurations[index].value, for: .intervalDuration)
    }

    @objc private func timestepChanged() {
        let index = timestepControl.selectedSegmentIndex
        guard index >= 0, index < SelectableSettings.historicTimesteps.count else { return }
        settings.setChoice(SelectableSettings.historicTimesteps[index].value, for: .historicTimestep)
    }

    @objc private func sourceChanged() {
        let index = sourceControl.selectedSegmentIndex
        guard index >= 0, index < DataProviderType.allCases.count else { return }
        settings.set(DataProviderType.allCases[index].rawValue, for: .dataSource)
    }

    @objc private func schemeChanged() {
        let index = schemeControl.selectedSegmentIndex
        guard index >= 0, index < ColorScheme.allCases.count else { return }
        settings.set(ColorScheme.allCases[index].rawValue, for: .colorScheme)
    }

    @objc private func mapModeChanged() {
        let index = mapModeControl.selectedSegmentIndex
        guard index >= 0, index < SettingsViewController.mapModes.count else { return }
        settings.set(SettingsViewController.mapModes[index], for: .mapMode)
    }

    @objc private func fadeChanged() {
        settings.set(Int(fadeControl.value.rounded()), for: .mapFade)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Region picker

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return SelectableSettings.namedRegions.count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return SelectableSettings.namedRegions[row].name
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        settings.setChoice(SelectableSettings.namedRegions[row].value, for: .region)
    }
}
