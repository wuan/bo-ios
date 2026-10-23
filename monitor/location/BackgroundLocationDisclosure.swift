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

/// The explanation the app owes the user before it asks for background
/// location, and the record that the explanation has been given.
///
/// Only the two moves live here - whether the explanation is still due and how
/// the request is gated on it - so the background phase can present it from
/// wherever the request is made. Nothing in this phase requests background
/// location on its own; the app does not use it until monitoring exists.
public final class BackgroundLocationDisclosure {

    private let settings: SettingsStore

    public init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }

    /// Whether the explanation still has to be presented.
    public var isDue: Bool {
        return !settings.bool(for: .backgroundLocationDisclosureShown)
    }

    /// Records that the user has seen and acknowledged the explanation.
    public func acknowledge() {
        settings.set(true, for: .backgroundLocationDisclosureShown)
    }

    /// Runs `requesting` once the explanation has been acknowledged, presenting
    /// it first while it is still due.
    ///
    /// - Returns: whether the request ran. While the explanation is due nothing
    ///   is requested: the permission may only be asked for after the user has
    ///   been told what it is for.
    @discardableResult
    public func request(disclosing: () -> Void, requesting: () -> Void) -> Bool {
        guard !isDue else {
            disclosing()
            return false
        }
        requesting()
        return true
    }
}
