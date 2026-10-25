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

/// The application log the menu opens: the recorded diagnostics, with a
/// send-for-support action.
public final class ApplicationLogViewController: UIViewController, UITableViewDataSource {

    /// The rendered log the screen lists; read by the tests.
    let content: ApplicationLogContent
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let sendButton = UIButton(type: .system)

    public init(appLog: AppLog = .shared) {
        self.content = ApplicationLogContent.make(entries: appLog.entries)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.content = ApplicationLogContent.make(entries: [])
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "appinfo.log.root"

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("appinfo.log.title", comment: "Application log screen title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.accessibilityIdentifier = "appinfo.log.title"

        let closeButton = UIButton(type: .system)
        closeButton.setTitle(NSLocalizedString("appinfo.close", comment: "Close an information screen"), for: .normal)
        closeButton.accessibilityIdentifier = "appinfo.log.close"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .firstBaseline
        header.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = NSLocalizedString("appinfo.log.empty",
                                            comment: "Application log shown while nothing was recorded")
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.accessibilityIdentifier = "appinfo.log.empty"
        emptyLabel.isHidden = !content.isEmpty

        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "log")
        tableView.accessibilityIdentifier = "appinfo.log.list"
        tableView.isHidden = content.isEmpty
        tableView.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle(NSLocalizedString("appinfo.log.send", comment: "Send the log for support"), for: .normal)
        sendButton.accessibilityIdentifier = "appinfo.log.send"
        sendButton.addTarget(self, action: #selector(sendLog), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(emptyLabel)
        view.addSubview(tableView)
        view.addSubview(sendButton)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            tableView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -12),

            emptyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Table

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.lines.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "log", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = content.lines[indexPath.row]
        configuration.textProperties.font = .preferredFont(forTextStyle: .caption1)
        configuration.textProperties.numberOfLines = 0
        cell.contentConfiguration = configuration
        return cell
    }

    // MARK: - Actions

    /// Hands the whole log to the system share sheet for support.
    @objc func sendLog() {
        let activity = UIActivityViewController(activityItems: [content.text], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sendButton
        activity.popoverPresentationController?.sourceRect = sendButton.bounds
        present(activity, animated: true)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
