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
import UniformTypeIdentifiers

/// The app's settings screen.
///
/// The categories and their contents come from ``PreferencesModel``, so the
/// screen, the settings reference, and the settings export cannot disagree about
/// which settings exist. Every setting the user can change is reachable here;
/// credentials are offered only for the source that authenticates, and the
/// backup row exports, imports, or resets the settings.
public final class SettingsViewController: UIViewController,
                                          UITableViewDataSource,
                                          UITableViewDelegate,
                                          UIDocumentPickerDelegate {

    private let settings: SettingsStore
    private let credentialStore: CredentialStore
    private let appLog: AppLog
    private let categories = PreferencesModel.categories

    private let titleLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    /// Token for the data-source observation that toggles the credential rows.
    private var dataSourceObserver: NSObjectProtocol?

    public init(settings: SettingsStore = SettingsStore(),
                credentialStore: CredentialStore = KeychainCredentialStore(),
                appLog: AppLog = .shared) {
        self.settings = settings
        self.credentialStore = credentialStore
        self.appLog = appLog
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.settings = SettingsStore()
        self.credentialStore = KeychainCredentialStore()
        self.appLog = .shared
        super.init(coder: coder)
    }

    deinit {
        if let dataSourceObserver = dataSourceObserver {
            settings.removeObserver(dataSourceObserver)
        }
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "settings.root"

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        buildHeader()
        buildTable()

        // The credential rows belong to the authenticating source, so a source
        // change reshapes the data-source section without closing the screen.
        dataSourceObserver = settings.observe(.dataSource) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func buildHeader() {
        titleLabel.text = NSLocalizedString("settings.title", comment: "Settings screen title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        // The title is the safe place to tap to dismiss the keyboard: it carries
        // no control, unlike the table below it.
        titleLabel.accessibilityIdentifier = "settings.title"

        saveButton.setTitle(NSLocalizedString("settings.save", comment: "Save settings button"), for: .normal)
        saveButton.accessibilityIdentifier = "settings.save"
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        closeButton.setTitle(NSLocalizedString("settings.close", comment: "Close settings button"), for: .normal)
        closeButton.accessibilityIdentifier = "settings.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, saveButton, closeButton])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .firstBaseline
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])
    }

    private func buildTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Table data

    /// The items a section shows.
    ///
    /// The credentials belong to the source that authenticates, so they are left
    /// out while a source that takes none is selected.
    func items(in section: Int) -> [PreferenceItem] {
        let items = categories[section].items
        guard categories[section].id == "data-source" else { return items }
        return items.filter { $0.credential == nil || showsCredentials }
    }

    /// Whether the active source authenticates.
    var showsCredentials: Bool {
        return DataProviderType(rawValue: settings.string(for: .dataSource)) == .http
    }

    func item(at indexPath: IndexPath) -> PreferenceItem {
        return items(in: indexPath.section)[indexPath.row]
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items(in: section).count
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section].title
    }

    // MARK: - Cells

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = item(at: indexPath)

        switch item.kind {
        case .toggle:
            return toggleCell(item)
        case .intSlider(let minimum, let maximum):
            return sliderCell(item, minimum: minimum, maximum: maximum)
        case .intChoice(let values):
            return choiceCell(item, names: values.map { $0.name })
        case .stringChoice(let values):
            return choiceCell(item, names: values.map { $0.name })
        case .decimalChoice(let values):
            return choiceCell(item, names: values.map { PreferencesModel.distanceName(kilometres: $0) })
        case .text:
            return textCell(item, keyboard: .default, secure: false)
        case .password:
            return textCell(item, keyboard: .default, secure: true)
        case .decimal:
            return textCell(item, keyboard: .decimalPad, secure: false)
        case .button:
            return buttonCell(item)
        }
    }

    /// The identifier a row's control carries.
    ///
    /// The data source and service URL keep the identifiers the app has always
    /// used, so the existing UI tests drive the same controls.
    func identifier(for item: PreferenceItem) -> String {
        if let key = item.key {
            switch key {
            case .dataSource:
                return "settings.source"
            case .serviceEndpoint:
                return "settings.endpoint"
            default:
                return "settings.\(key.rawValue)"
            }
        }
        if let field = item.credential {
            return "settings.\(field.rawValue)"
        }
        if let action = item.action {
            return "settings.action.\(action.rawValue)"
        }
        return "settings.row"
    }

    /// Whether a choice fits a segmented control beside its title.
    ///
    /// A long list would not fit, so those rows show the current value and open
    /// a picker when tapped instead.
    func usesSegmentedControl(_ item: PreferenceItem) -> Bool {
        let names = item.choiceNames
        return names.count <= 4 && names.joined().count <= 24
    }

    private func toggleCell(_ item: PreferenceItem) -> UITableViewCell {
        let toggle = UISwitch()
        toggle.accessibilityIdentifier = identifier(for: item)
        toggle.isOn = settings.bool(for: item.key!)
        toggle.addAction(UIAction { [weak self] action in
            guard let self = self, let key = item.key,
                  let control = action.sender as? UISwitch else { return }
            self.settings.set(control.isOn, for: key)
        }, for: .valueChanged)

        return inlineCell(item, control: toggle)
    }

    private func sliderCell(_ item: PreferenceItem, minimum: Int, maximum: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        let valueLabel = UILabel()
        valueLabel.font = .preferredFont(forTextStyle: .footnote)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.accessibilityIdentifier = "\(identifier(for: item)).value"
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let slider = UISlider()
        slider.accessibilityIdentifier = identifier(for: item)
        slider.minimumValue = Float(minimum)
        slider.maximumValue = Float(maximum)
        slider.value = Float(min(max(settings.int(for: item.key!), minimum), maximum))
        valueLabel.text = String(Int(slider.value))

        slider.addAction(UIAction { [weak self, weak valueLabel] action in
            guard let self = self, let key = item.key,
                  let control = action.sender as? UISlider else { return }
            let value = Int(control.value.rounded())
            self.settings.set(value, for: key)
            valueLabel?.text = String(value)
        }, for: .valueChanged)

        // The title and its value share the first line and the slider spans the
        // row beneath it, so its track is wide enough to aim at; a slider in the
        // cell's accessory slot would be squeezed to a fraction of the width.
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .firstBaseline

        let stack = UIStackView(arrangedSubviews: [titleRow, slider])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor, constant: -8),
        ])

        return cell
    }

    /// A choice is offered as a segmented control when it fits; a longer one
    /// opens a picker when its row is tapped.
    private func choiceCell(_ item: PreferenceItem, names: [String]) -> UITableViewCell {
        guard usesSegmentedControl(item) else {
            return valueCell(item)
        }

        let control = UISegmentedControl(items: names)
        control.accessibilityIdentifier = identifier(for: item)
        control.selectedSegmentIndex = currentChoiceIndex(item)
        control.addAction(UIAction { [weak self] action in
            guard let self = self, let control = action.sender as? UISegmentedControl else { return }
            self.select(index: control.selectedSegmentIndex, for: item)
        }, for: .valueChanged)

        return inlineCell(item, control: control)
    }

    /// The row for a choice with too many values for a segmented control.
    private func valueCell(_ item: PreferenceItem) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.text = currentChoiceName(item)
        cell.detailTextLabel?.accessibilityIdentifier = identifier(for: item)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func textCell(_ item: PreferenceItem, keyboard: UIKeyboardType, secure: Bool) -> UITableViewCell {
        let field = UITextField()
        field.accessibilityIdentifier = identifier(for: item)
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = keyboard
        field.isSecureTextEntry = secure
        field.clearButtonMode = .whileEditing

        if let key = item.key {
            field.text = storedText(for: key)
            // A field commits when editing ends rather than when the screen is
            // saved, so scrolling a field off screen cannot lose the edit.
            field.addAction(UIAction { [weak self, weak field] _ in
                guard let self = self, let field = field else { return }
                self.commit(field, for: key)
            }, for: .editingDidEnd)
        } else if let credential = item.credential {
            let stored = credentialStore.load()
            field.text = credential == .username ? stored.username : stored.password
            field.addAction(UIAction { [weak self] _ in
                self?.saveCredentials()
            }, for: .editingDidEnd)
        }

        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: SettingsViewController.inlineControlWidth).isActive = true
        return inlineCell(item, control: field)
    }

    private func buttonCell(_ item: PreferenceItem) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = item.action == .reset ? .systemRed : .systemBlue
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessibilityIdentifier = identifier(for: item)
        return cell
    }

    /// A cell with the row's title beside its control.
    ///
    /// The title and the control are laid out inside the content view rather
    /// than as the cell's `accessoryView`: an accessory whose
    /// `translatesAutoresizingMaskIntoConstraints` is off has no constraints
    /// placing it, so UIKit and Auto Layout disagree and the control lands at
    /// the leading edge - over the title - on some layout passes.
    private func inlineCell(_ item: PreferenceItem, control: UIView) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // The control keeps its own size and the title takes the space that is
        // left, so a long title shrinks instead of pushing the control off.
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, control])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor, constant: -8),
        ])

        return cell
    }

    /// The width an inline control reserves, so a title and its control share a
    /// single row.
    static let inlineControlWidth: CGFloat = 170

    // MARK: - Choice values

    private func currentChoiceIndex(_ item: PreferenceItem) -> Int {
        guard let key = item.key else { return 0 }
        switch item.kind {
        case .intChoice(let values):
            return values.firstIndex { $0.value == settings.choice(for: key) } ?? 0
        case .stringChoice(let values):
            let stored = settings.string(for: key)
            return values.firstIndex { $0.value == stored } ?? 0
        case .decimalChoice(let values):
            return values.firstIndex { $0 == settings.double(for: key) } ?? 0
        default:
            return 0
        }
    }

    private func currentChoiceName(_ item: PreferenceItem) -> String {
        let names = item.choiceNames
        let index = currentChoiceIndex(item)
        return index < names.count ? names[index] : ""
    }

    /// Writes the value a choice row picked, which is what both the segmented
    /// control and the picker call.
    func select(index: Int, for item: PreferenceItem) {
        guard let key = item.key, index >= 0 else { return }
        switch item.kind {
        case .intChoice(let values):
            guard index < values.count else { return }
            settings.setChoice(values[index].value, for: key)
        case .stringChoice(let values):
            guard index < values.count else { return }
            settings.set(values[index].value, for: key)
        case .decimalChoice(let values):
            guard index < values.count else { return }
            settings.set(values[index], for: key)
        default:
            break
        }
    }

    // MARK: - Text values

    private func storedText(for key: SettingsKey) -> String {
        switch key.storage {
        case .string:
            return settings.string(for: key)
        case .int:
            return String(settings.int(for: key))
        case .double:
            return SettingsValueFormatter.string(kilometres: settings.double(for: key))
        case .bool:
            return settings.bool(for: key) ? "true" : "false"
        }
    }

    /// Writes a field's value to the setting it edits.
    ///
    /// The manual coordinates are the one pair: writing either makes the entered
    /// position the current location, so they are committed together.
    private func commit(_ field: UITextField, for key: SettingsKey) {
        switch key.storage {
        case .string:
            settings.set(field.text ?? "", for: key)
        case .int:
            if let value = Int(field.text ?? "") {
                settings.set(value, for: key)
            }
        case .double:
            if key == .manualLatitude || key == .manualLongitude {
                commitManualCoordinates()
            } else if let value = Double(field.text ?? "") {
                settings.set(value, for: key)
            }
        case .bool:
            break
        }
    }

    /// Writes the manual coordinates and makes them the current location.
    ///
    /// Both fields have to be on screen to commit the pair; a field that is not
    /// on screen keeps the stored coordinate rather than a made-up zero.
    private func commitManualCoordinates() {
        guard let latitudeText = text(in: "settings.manualLatitude"),
              let longitudeText = text(in: "settings.manualLongitude"),
              let latitude = Double(latitudeText), let longitude = Double(longitudeText) else { return }
        settings.set(latitude, for: .manualLatitude)
        settings.set(longitude, for: .manualLongitude)
        settings.set(true, for: .manualLocationSet)
    }

    /// Stores the credentials the fields hold.
    ///
    /// A field that is not on screen keeps the stored value, so saving from the
    /// screen cannot silently blank a credential that was scrolled away.
    private func saveCredentials() {
        guard showsCredentials else { return }
        let stored = credentialStore.load()
        let username = text(in: "settings.username") ?? stored.username
        let password = text(in: "settings.password") ?? stored.password
        credentialStore.save(Credentials(username: username, password: password))
    }

    /// The text of the field with an identifier, when it is on screen.
    private func text(in identifier: String) -> String? {
        return (find(identifier, in: view) as? UITextField)?.text
    }

    /// The view carrying an accessibility identifier, anywhere on the screen.
    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier {
            return view
        }
        for subview in view.subviews {
            if let found = find(identifier, in: subview) {
                return found
            }
        }
        return nil
    }

    // MARK: - Table interaction

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = item(at: indexPath)
        dismissKeyboard()

        if let action = item.action {
            perform(action)
            return
        }

        guard PreferencesModel.isChoice(item.kind), !usesSegmentedControl(item) else { return }
        presentOptionPicker(for: item, at: indexPath)
    }

    private func presentOptionPicker(for item: PreferenceItem, at indexPath: IndexPath) {
        let picker = OptionPickerViewController(title: item.title,
                                                names: item.choiceNames,
                                                selectedIndex: currentChoiceIndex(item),
                                                identifier: identifier(for: item))
        picker.onSelect = { [weak self] index in
            self?.select(index: index, for: item)
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }
        picker.modalPresentationStyle = .pageSheet
        present(picker, animated: true)
    }

    // MARK: - Save and close

    @objc private func save() {
        // Ending editing commits the focused field; the others committed as the
        // user left them.
        view.endEditing(true)
        saveCredentials()
        appLog.record("settings saved")
        reload()
    }

    /// Reflects the stored settings in the rows.
    func reload() {
        tableView.reloadData()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Backup actions

    private func perform(_ action: PreferenceAction) {
        switch action {
        case .export:
            presentExportOptions()
        case .importSettings:
            presentImportPicker()
        case .reset:
            confirmReset()
        }
    }

    /// Asks whether credentials travel with the export; they do not by default.
    private func presentExportOptions() {
        let alert = UIAlertController(title: NSLocalizedString("settings.export.title",
                                                              comment: "Export settings dialog title"),
                                      message: NSLocalizedString("settings.export.message",
                                                                 comment: "Explains what an export contains"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("settings.export.withoutCredentials",
                                     comment: "Export settings without credentials"),
            style: .default) { [weak self] _ in
            self?.export(includeCredentials: false)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("settings.export.withCredentials",
                                     comment: "Export settings including credentials"),
            style: .destructive) { [weak self] _ in
            self?.export(includeCredentials: true)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings.cancel",
                                                              comment: "Cancel button"),
                                      style: .cancel))
        present(alert, animated: true)
    }

    /// Writes the settings to a file and offers it for sharing.
    func export(includeCredentials: Bool) {
        let document = PreferencesBackup.export(settings: settings,
                                                credentials: credentialStore.load(),
                                                includeCredentials: includeCredentials)
        guard let data = try? PreferencesBackup.encode(document),
              let url = SettingsExportFile.write(data) else {
            presentReport(title: NSLocalizedString("settings.export.failed",
                                                   comment: "Export failed message"),
                          message: nil)
            return
        }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = view
        present(activity, animated: true)
    }

    private func presentImportPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController,
                               didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first,
              let data = try? Data(contentsOf: url) else {
            reportImportFailure(PreferencesBackupError.unreadable)
            return
        }

        do {
            let document = try PreferencesBackup.decode(data)
            try PreferencesBackup.apply(document, to: settings, credentialStore: credentialStore)
            reload()
            presentReport(title: NSLocalizedString("settings.import.done",
                                                   comment: "Import applied message"),
                          message: nil)
        } catch let error as PreferencesBackupError {
            reportImportFailure(error)
        } catch {
            reportImportFailure(.unreadable)
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }

    private func reportImportFailure(_ error: PreferencesBackupError) {
        let message: String
        switch error {
        case .unreadable:
            message = NSLocalizedString("settings.import.error.unreadable",
                                        comment: "Import error: the file cannot be read")
        case .unsupportedVersion:
            message = NSLocalizedString("settings.import.error.version",
                                        comment: "Import error: the file was written by another version")
        case .unknownSetting:
            message = NSLocalizedString("settings.import.error.unknown",
                                        comment: "Import error: the file names an unknown setting")
        case .wrongType, .valueNotAllowed:
            message = NSLocalizedString("settings.import.error.value",
                                        comment: "Import error: the file carries a value the app does not accept")
        }
        presentReport(title: NSLocalizedString("settings.import.failed",
                                               comment: "Import failed message"),
                      message: message)
    }

    private func confirmReset() {
        let alert = UIAlertController(title: NSLocalizedString("settings.reset.title",
                                                              comment: "Reset settings dialog title"),
                                      message: NSLocalizedString("settings.reset.message",
                                                                 comment: "Explains what a reset does"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings.cancel",
                                                              comment: "Cancel button"),
                                      style: .cancel))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("settings.reset.confirm", comment: "Confirms resetting settings"),
            style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            PreferencesBackup.reset(settings: self.settings, log: self.appLog)
            self.reload()
        })
        present(alert, animated: true)
    }

    private func presentReport(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings.ok", comment: "OK button"),
                                      style: .default))
        present(alert, animated: true)
    }

    // MARK: - Map modes

    /// The map types the selectors offer.
    static let mapModes = ["hybrid", "satellite", "standard"]
}

/// The file an export is written to before it is shared.
enum SettingsExportFile {

    static let name = "blitzortung-settings.json"

    /// Writes the document to a temporary file and returns its location.
    static func write(_ data: Data, directory: URL = FileManager.default.temporaryDirectory) -> URL? {
        let url = directory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

/// A picker for a choice with too many values for a segmented control.
final class OptionPickerViewController: UITableViewController {

    private let heading: String
    private let names: [String]
    private let identifierPrefix: String
    private var selectedIndex: Int
    var onSelect: ((Int) -> Void)?

    init(title: String, names: [String], selectedIndex: Int, identifier: String) {
        self.heading = title
        self.names = names
        self.identifierPrefix = identifier
        self.selectedIndex = selectedIndex
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = heading
        tableView.accessibilityIdentifier = "\(identifierPrefix).picker"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = names[indexPath.row]
        cell.accessibilityIdentifier = "\(identifierPrefix).\(indexPath.row)"
        cell.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        onSelect?(indexPath.row)
        dismiss(animated: true)
    }
}
