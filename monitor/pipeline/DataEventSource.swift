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

/// Provides data pipeline events to views.
///
/// Implemented by ``DataHandler`` (a single provider) and
/// ``DataProviderCoordinator`` (a handler that is rebuilt when the selected
/// source changes), so a view can consume either without knowing which.
public protocol DataEventSource {
    /// Returns a stream of lifecycle events.
    func events() -> AsyncStream<DataEvent>
    /// Starts a data request.
    func requestData(parameters: Parameters)
    /// What the active provider can serve.
    var capabilities: DataProviderCapabilities { get }
}

extension DataHandler: DataEventSource {}

extension DataProviderCoordinator: DataEventSource {}
