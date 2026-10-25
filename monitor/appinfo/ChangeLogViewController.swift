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

/// The change log the menu opens: the bundled release notes by version.
public final class ChangeLogViewController: UIViewController, UITableViewDataSource {

    /// The parsed entries the screen lists; read by the tests.
    let entries: [ChangeLogEntry]
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let latestLabel = UILabel()
    private let emptyLabel = UILabel()

    public init(entries: [ChangeLogEntry] = ChangeLog.load()) {
        self.entries = entries
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.entries = []
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "appinfo.changelog.root"

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("appinfo.changelog.title", comment: "Change log screen title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.accessibilityIdentifier = "appinfo.changelog.title"

        let closeButton = UIButton(type: .system)
        closeButton.setTitle(NSLocalizedString("appinfo.close", comment: "Close an information screen"), for: .normal)
        closeButton.accessibilityIdentifier = "appinfo.changelog.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .firstBaseline
        header.translatesAutoresizingMaskIntoConstraints = false

        // The newest version, kept where a test can read it whatever the table
        // shows on screen.
        latestLabel.text = entries.first?.version ?? ""
        latestLabel.font = .preferredFont(forTextStyle: .subheadline)
        latestLabel.textColor = .secondaryLabel
        latestLabel.accessibilityIdentifier = "appinfo.changelog.latest"
        latestLabel.translatesAutoresizingMaskIntoConstraints = false
        latestLabel.isHidden = entries.isEmpty

        emptyLabel.text = NSLocalizedString("appinfo.changelog.empty",
                                            comment: "Change log shown when the file carries no entries")
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.accessibilityIdentifier = "appinfo.changelog.empty"
        emptyLabel.isHidden = !entries.isEmpty
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.accessibilityIdentifier = "appinfo.changelog.list"
        tableView.isHidden = entries.isEmpty
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(latestLabel)
        view.addSubview(emptyLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            latestLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            latestLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            latestLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: latestLabel.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Table

    public func numberOfSections(in tableView: UITableView) -> Int {
        return entries.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries[section].changes.count
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return entries[section].version
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "change")
            ?? UITableViewCell(style: .default, reuseIdentifier: "change")
        var configuration = cell.defaultContentConfiguration()
        configuration.text = entries[indexPath.section].changes[indexPath.row]
        configuration.textProperties.numberOfLines = 0
        cell.contentConfiguration = configuration
        return cell
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
