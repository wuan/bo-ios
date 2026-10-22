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

/// Minimal in-app surface for choosing the data source and configuring it.
///
/// Deliberately small: the full preferences screen arrives in a later phase.
/// This exists so the selected source, the endpoint override, and the stored
/// credentials can be exercised in the running app.
public final class SettingsViewController: UIViewController {

    private let settings: SettingsStore
    private let credentialStore: CredentialStore

    private let titleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let sourceControl = UISegmentedControl(items: [
        NSLocalizedString("settings.source.rpc", comment: "JSON-RPC data source name"),
        NSLocalizedString("settings.source.http", comment: "Blitzortung HTTP data source name"),
    ])
    private let endpointLabel = UILabel()
    private let endpointField = UITextField()
    private let endpointHint = UILabel()
    private let usernameLabel = UILabel()
    private let usernameField = UITextField()
    private let passwordLabel = UILabel()
    private let passwordField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    public init(settings: SettingsStore = SettingsStore(),
                credentialStore: CredentialStore = KeychainCredentialStore()) {
        self.settings = settings
        self.credentialStore = credentialStore
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.settings = SettingsStore()
        self.credentialStore = KeychainCredentialStore()
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "settings.root"

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        buildLayout()
        loadValues()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func buildLayout() {
        titleLabel.text = NSLocalizedString("settings.title", comment: "Settings screen title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0

        sourceLabel.text = NSLocalizedString("settings.source", comment: "Label for the data source selector")
        sourceLabel.font = .preferredFont(forTextStyle: .subheadline)

        sourceControl.selectedSegmentIndex = 0
        sourceControl.accessibilityIdentifier = "settings.source"
        sourceControl.addTarget(self, action: #selector(sourceChanged), for: .valueChanged)

        endpointLabel.text = NSLocalizedString("settings.endpoint", comment: "Label for the service endpoint field")
        endpointLabel.font = .preferredFont(forTextStyle: .subheadline)

        endpointField.borderStyle = .roundedRect
        endpointField.autocapitalizationType = .none
        endpointField.autocorrectionType = .no
        endpointField.keyboardType = .URL
        endpointField.clearButtonMode = .whileEditing
        endpointField.accessibilityIdentifier = "settings.endpoint"
        endpointField.placeholder = NSLocalizedString("settings.endpoint.placeholder",
                                                      comment: "Placeholder for the service endpoint field")
        endpointField.addTarget(self, action: #selector(sourceChanged), for: .editingChanged)

        endpointHint.font = .preferredFont(forTextStyle: .footnote)
        endpointHint.textColor = .secondaryLabel
        endpointHint.numberOfLines = 0

        usernameLabel.text = NSLocalizedString("settings.username", comment: "Label for the username field")
        usernameLabel.font = .preferredFont(forTextStyle: .subheadline)

        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.accessibilityIdentifier = "settings.username"

        passwordLabel.text = NSLocalizedString("settings.password", comment: "Label for the password field")
        passwordLabel.font = .preferredFont(forTextStyle: .subheadline)

        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.accessibilityIdentifier = "settings.password"

        saveButton.setTitle(NSLocalizedString("settings.save", comment: "Save settings button"), for: .normal)
        saveButton.accessibilityIdentifier = "settings.save"
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        closeButton.setTitle(NSLocalizedString("settings.close", comment: "Close settings button"), for: .normal)
        closeButton.accessibilityIdentifier = "settings.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            sourceLabel,
            sourceControl,
            endpointLabel,
            endpointField,
            endpointHint,
            usernameLabel,
            usernameField,
            passwordLabel,
            passwordField,
            saveButton,
            closeButton,
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }

    /// Reflects the stored source, endpoint, and credentials in the controls.
    private func loadValues() {
        let type = DataProviderType(rawValue: settings.string(for: .dataSource)) ?? .rpc
        sourceControl.selectedSegmentIndex = DataProviderType.allCases.firstIndex(of: type) ?? 0
        endpointField.text = settings.string(for: .serviceEndpoint)

        let credentials = credentialStore.load()
        usernameField.text = credentials.username
        passwordField.text = credentials.password

        updateHint()
    }

    private var selectedType: DataProviderType {
        let index = sourceControl.selectedSegmentIndex
        guard index >= 0, index < DataProviderType.allCases.count else {
            return .rpc
        }
        return DataProviderType.allCases[index]
    }

    private func updateHint() {
        let resolved = DataProviderFactory.resolvedEndpoint(for: selectedType, override: endpointField.text ?? "")
        endpointHint.text = String(format: NSLocalizedString("settings.endpoint.resolved",
                                                            comment: "Shows the endpoint that will be used"), resolved)
    }

    @objc private func sourceChanged() {
        updateHint()
    }

    @objc private func save() {
        settings.set(selectedType.rawValue, for: .dataSource)
        settings.set(endpointField.text ?? "", for: .serviceEndpoint)
        credentialStore.save(Credentials(username: usernameField.text ?? "",
                                         password: passwordField.text ?? ""))
        loadValues()
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
