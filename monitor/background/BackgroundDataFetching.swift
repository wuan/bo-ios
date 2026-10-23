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

/// Fetches the current realtime result for a background evaluation.
///
/// Behind a port so the monitor's decision can be tested with a canned result,
/// without a network or the data pipeline.
public protocol BackgroundDataFetching: AnyObject {

    /// Requests the current realtime interval and calls `completion` with the
    /// result, or `nil` when none can be made or none arrives in time.
    func fetchRealtime(completion: @escaping (Result?) -> Void)
}

/// ``BackgroundDataFetching`` backed by the shared ``DataEventSource``.
///
/// Subscribes to the source's event stream once and requests through the same
/// source the foreground uses, so a background result also lands in the shared
/// cache. The request is always local, around the current position, at the
/// finest grid - a global query has no extent to bound it and is not allowed the
/// same grid size. A timeout guards the task, which the system may end abruptly.
public final class CoordinatorBackgroundFetcher: BackgroundDataFetching {

    private let source: DataEventSource
    private let settings: SettingsStore
    private let location: () -> Location?
    private let timeout: TimeInterval

    private let lock = NSLock()
    private var pending: ((Result?) -> Void)?
    private var subscribed = false
    private var task: Task<Void, Never>?

    public init(source: DataEventSource,
                settings: SettingsStore,
                location: @escaping () -> Location?,
                timeout: TimeInterval = 20) {
        self.source = source
        self.settings = settings
        self.location = location
        self.timeout = timeout
    }

    deinit {
        task?.cancel()
    }

    public func fetchRealtime(completion: @escaping (Result?) -> Void) {
        guard let location = location() else {
            // Nothing to measure from, so nothing to fetch; the alert decision
            // would only report no location.
            completion(nil)
            return
        }

        lock.lock()
        pending = completion
        let needsSubscription = !subscribed
        subscribed = true
        lock.unlock()

        if needsSubscription {
            subscribe()
        }

        source.requestData(parameters: CoordinatorBackgroundFetcher.localParameters(settings: settings,
                                                                                     location: location))

        if timeout > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.finish(nil)
            }
        }
    }

    /// The local parameters a background request uses.
    ///
    /// The position selects a data area at the coarsest quantization the local
    /// method accepts, and the request asks for the finest supported grid, so the
    /// background evaluation sees activity near the position rather than a
    /// whole-globe grid.
    public static func localParameters(settings: SettingsStore, location: Location) -> Parameters {
        let scale = LocalData.localDataScale
        return Parameters(
            region: Parameters.localRegion,
            rasterBaselength: LocalData.supportedGridSizes.first ?? BackgroundMonitoring.localGridSize,
            intervalDuration: settings.choice(for: .intervalDuration),
            intervalOffset: 0,
            dataArea: DataArea(x: LocalData.localCoordinate(location.longitude, scale: scale),
                               y: LocalData.localCoordinate(location.latitude, scale: scale),
                               scale: scale))
    }

    private func subscribe() {
        task = Task { [weak self] in
            guard let self = self else { return }
            for await event in self.source.events() {
                if case .dataReceived(let result) = event, result.parameters.isRealtime() {
                    self.finish(result)
                }
            }
        }
    }

    private func finish(_ result: Result?) {
        lock.lock()
        let completion = pending
        pending = nil
        lock.unlock()
        completion?(result)
    }
}
