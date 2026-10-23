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
    /// result, or `nil` when none arrives in time.
    func fetchRealtime(completion: @escaping (Result?) -> Void)
}

/// ``BackgroundDataFetching`` backed by the shared ``DataEventSource``.
///
/// Subscribes to the source's event stream once and requests through the same
/// source the foreground uses, so a background result also lands in the shared
/// cache. A timeout guards the task, which the system may end abruptly.
public final class CoordinatorBackgroundFetcher: BackgroundDataFetching {

    private let source: DataEventSource
    private let parameters: () -> Parameters
    private let timeout: TimeInterval

    private let lock = NSLock()
    private var pending: ((Result?) -> Void)?
    private var subscribed = false
    private var task: Task<Void, Never>?

    public init(source: DataEventSource,
                parameters: @escaping () -> Parameters,
                timeout: TimeInterval = 20) {
        self.source = source
        self.parameters = parameters
        self.timeout = timeout
    }

    deinit {
        task?.cancel()
    }

    public func fetchRealtime(completion: @escaping (Result?) -> Void) {
        lock.lock()
        pending = completion
        let needsSubscription = !subscribed
        subscribed = true
        lock.unlock()

        if needsSubscription {
            subscribe()
        }

        source.requestData(parameters: parameters())

        if timeout > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.finish(nil)
            }
        }
    }

    /// The realtime parameters a background request uses.
    ///
    /// There is no visible extent to size a local area from, so a stored local
    /// region becomes a global one; a named region is requested as-is.
    public static func realtimeParameters(settings: SettingsStore) -> Parameters {
        let region = settings.choice(for: .region)
        return Parameters(region: region == Parameters.localRegion ? Parameters.globalRegion : region,
                          rasterBaselength: BackgroundMonitoring.gridSize,
                          intervalDuration: settings.choice(for: .intervalDuration),
                          intervalOffset: 0,
                          dataArea: nil)
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
