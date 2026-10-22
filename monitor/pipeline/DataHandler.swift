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

/// Coordinates data requests and publishes lifecycle events to subscribers.
///
/// Subscribe with ``events()`` and cancel the consuming task to unsubscribe.
/// Events are emitted in order: `requestStarted` followed by either
/// `dataReceived` or `failed`. The most recent successful result is retained so
/// consumers can keep showing data after a failure.
public final class DataHandler {

    private let provider: DataProvider
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<DataEvent>.Continuation] = [:]
    private var _latest: Result?

    public init(provider: DataProvider) {
        self.provider = provider
    }

    /// The most recently received result, if any.
    public var latest: Result? {
        lock.lock()
        defer { lock.unlock() }
        return _latest
    }

    /// Returns a stream of lifecycle events. Cancel the consuming task to stop
    /// receiving events.
    public func events() -> AsyncStream<DataEvent> {
        return AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.continuations[id] = nil
                self.lock.unlock()
            }
        }
    }

    /// Starts a data request, emitting a `requestStarted` event immediately.
    public func requestData(parameters: Parameters) {
        emit(.requestStarted(parameters))
        provider.fetchData(parameters: parameters) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.emit(.failed(error))
            } else if let result = result {
                self.lock.lock()
                self._latest = result
                self.lock.unlock()
                self.emit(.dataReceived(result))
            }
        }
    }

    private func emit(_ event: DataEvent) {
        lock.lock()
        let current = Array(continuations.values)
        lock.unlock()
        for continuation in current {
            continuation.yield(event)
        }
    }
}
