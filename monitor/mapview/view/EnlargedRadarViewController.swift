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

/// The enlarged alarm radar the small one opens on a long press.
///
/// It draws the same ``RadarContent`` the small radar does, only larger, and
/// leaves the radar's state untouched; dismissing it shows the map again.
public final class EnlargedRadarViewController: UIViewController {

    /// The identifier the enlarged radar is queried by.
    public static let accessibilityIdentifier = "radar.enlarged"

    private let titleLabel = UILabel()
    private let radarView = AlarmRadarView()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = EnlargedRadarViewController.accessibilityIdentifier

        titleLabel.text = NSLocalizedString("radar.enlarged.title", comment: "Enlarged radar title")
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle(NSLocalizedString("quick.close", comment: "Close quick settings button"), for: .normal)
        dismissButton.accessibilityIdentifier = "radar.close"
        dismissButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        radarView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [titleLabel, radarView, dismissButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            radarView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            radarView.heightAnchor.constraint(equalTo: radarView.widthAnchor),
        ])
    }

    /// Draws the given radar content.
    public func configure(content: RadarContent?) {
        loadViewIfNeeded()
        radarView.configure(content: content)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
