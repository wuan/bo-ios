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

/// One entry of the application menu.
///
/// The entries are the contract the menu, the localisation, and the UI test
/// share: the raw value names both the string and the accessibility identifier.
public enum AppMenuEntry: String, CaseIterable {
    case settings
    case alarms
    case log
    case changelog
    case information

    /// The identifier the entry's control is queried by.
    public var accessibilityIdentifier: String {
        return "menu.\(rawValue)"
    }

    /// The name the entry is shown under.
    public var title: String {
        return NSLocalizedString("menu.\(rawValue)", comment: "Application menu entry")
    }
}

/// The application menu.
///
/// A small sheet of one identified button per ``AppMenuEntry``, so every entry
/// can be reached and asserted by identifier. The selection is handed to the
/// caller after the sheet has dismissed, so the chosen surface can be presented
/// without a presentation conflict.
public final class AppMenuViewController: UIViewController {

    private let onSelect: (AppMenuEntry) -> Void

    public init(onSelect: @escaping (AppMenuEntry) -> Void) {
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
        }
    }

    public required init?(coder: NSCoder) {
        self.onSelect = { _ in }
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "menu.root"

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("menu.open", comment: "Button opening the application menu")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(NSLocalizedString("menu.cancel", comment: "Dismiss the application menu"), for: .normal)
        cancelButton.accessibilityIdentifier = "menu.cancel"
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        var rows: [UIView] = [titleLabel]
        for (index, entry) in AppMenuEntry.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(entry.title, for: .normal)
            button.accessibilityIdentifier = entry.accessibilityIdentifier
            button.tag = index
            button.addTarget(self, action: #selector(choose(_:)), for: .touchUpInside)
            rows.append(button)
        }
        rows.append(cancelButton)

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    /// Hands the chosen entry on once the sheet has gone.
    @objc private func choose(_ sender: UIButton) {
        let entry = AppMenuEntry.allCases[sender.tag]
        dismiss(animated: true) { [weak self] in
            self?.onSelect(entry)
        }
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }
}
