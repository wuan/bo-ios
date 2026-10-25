/*

 Copyright 2026 Andreas Würl

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

/// The information screen the menu opens: the app's name, version, project, and
/// copyright, plus whether a newer version is available.
public final class InformationViewController: UIViewController {

    private let version: AppVersion
    private let provider: AvailableVersionProviding

    /// The content the screen shows; the update line is added once the check
    /// answers.
    private(set) var content: InformationContent

    private let nameLabel = UILabel()
    private let versionLabel = UILabel()
    private let projectLabel = UILabel()
    private let copyrightLabel = UILabel()
    private let updateLabel = UILabel()

    public init(version: AppVersion = .read(),
                provider: AvailableVersionProviding = AppStoreVersionLookup()) {
        self.version = version
        self.provider = provider
        self.content = InformationContent.make(version: version, outcome: .unknown)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.version = .read()
        self.provider = AppStoreVersionLookup()
        self.content = InformationContent.make(version: version, outcome: .unknown)
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "appinfo.root"

        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.accessibilityIdentifier = "appinfo.name"

        versionLabel.font = .preferredFont(forTextStyle: .body)
        versionLabel.accessibilityIdentifier = "appinfo.version"

        projectLabel.font = .preferredFont(forTextStyle: .footnote)
        projectLabel.textColor = .secondaryLabel
        projectLabel.accessibilityIdentifier = "appinfo.project"

        copyrightLabel.font = .preferredFont(forTextStyle: .footnote)
        copyrightLabel.textColor = .secondaryLabel
        copyrightLabel.numberOfLines = 0
        copyrightLabel.accessibilityIdentifier = "appinfo.copyright"

        updateLabel.font = .preferredFont(forTextStyle: .subheadline)
        updateLabel.numberOfLines = 0
        updateLabel.accessibilityIdentifier = "appinfo.update"

        let closeButton = UIButton(type: .system)
        closeButton.setTitle(NSLocalizedString("appinfo.close", comment: "Close an information screen"), for: .normal)
        closeButton.accessibilityIdentifier = "appinfo.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [nameLabel, versionLabel, projectLabel,
                                                   copyrightLabel, updateLabel, closeButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])

        render()
        checkForUpdate()
    }

    /// Renders the current content, hiding the update line while it is unknown.
    private func render() {
        nameLabel.text = content.name
        versionLabel.text = content.version
        projectLabel.text = content.project
        copyrightLabel.text = content.copyright
        updateLabel.text = content.update
        updateLabel.isHidden = content.update == nil
    }

    /// Asks the provider for the offered version and applies the outcome.
    func checkForUpdate() {
        provider.availableVersion { [weak self] available in
            guard let self = self else { return }
            self.apply(outcome: UpdateCheck.evaluate(installed: self.version.marketing,
                                                     available: available))
        }
    }

    /// Adopts an update outcome and reflects it on the screen.
    func apply(outcome: UpdateOutcome) {
        content = InformationContent.make(version: version, outcome: outcome)
        render()
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
