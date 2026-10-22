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
///
/// A request served from ``DataCache`` is delivered as `dataReceived` without a
/// `requestStarted` event, because no fetch begins. Results that are not newer
/// than the last accepted result for the same parameters are discarded by
/// ``FreshnessValidator``, so a historical selection is not mistaken for a stale
/// realtime answer.
public final class DataHandler {

    private let provider: DataProvider
    private let cache: DataCache
    private let freshness: FreshnessValidator
    private let lock = NSLock()
    private var subscribers: [UUID: (DataEvent) -> Void] = [:]
    private var _latest: Result?

    public init(provider: DataProvider,
                cache: DataCache = DataCache(),
                freshness: FreshnessValidator = FreshnessValidator()) {
        self.provider = provider
        self.cache = cache
        self.freshness = freshness
    }

    /// The most recently received result, if any.
    public var latest: Result? {
        lock.lock()
        defer { lock.unlock() }
        return _latest
    }

    /// What the active provider can serve.
    public var capabilities: DataProviderCapabilities {
        return provider.capabilities
    }

    /// Registers `block` to receive every event and returns a token for
    /// ``unsubscribe(_:)``.
    ///
    /// Registration is synchronous, so events emitted after this call are
    /// always delivered.
    @discardableResult
    public func subscribe(_ block: @escaping (DataEvent) -> Void) -> UUID {
        let id = UUID()
        lock.lock()
        subscribers[id] = block
        lock.unlock()
        return id
    }

    /// Stops delivering events to a subscription token.
    public func unsubscribe(_ id: UUID) {
        lock.lock()
        subscribers[id] = nil
        lock.unlock()
    }

    /// Returns a stream of lifecycle events. Cancel the consuming task to stop
    /// receiving events.
    public func events() -> AsyncStream<DataEvent> {
        return AsyncStream { continuation in
            let id = self.subscribe { continuation.yield($0) }
            continuation.onTermination = { [weak self] _ in
                self?.unsubscribe(id)
            }
        }
    }

    /// Starts a data request, emitting a `requestStarted` event immediately.
    ///
    /// When a valid cached result exists for the same parameters it is delivered
    /// without contacting the provider.
    public func requestData(parameters: Parameters) {
        if let cached = cache.result(for: parameters) {
            emit(.dataReceived(cached))
            return
        }

        emit(.requestStarted(parameters))
        provider.fetchData(parameters: parameters) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.emit(.failed(error))
                return
            }
            guard let result = result else { return }
            guard self.freshness.accept(referenceTimestamp: result.referenceTimestamp, for: parameters) else {
                return
            }
            self.cache.store(result, for: parameters)
            self.lock.lock()
            self._latest = result
            self.lock.unlock()
            self.emit(.dataReceived(result))
        }
    }

    private func emit(_ event: DataEvent) {
        lock.lock()
        let current = Array(subscribers.values)
        lock.unlock()
        for subscriber in current {
            subscriber(event)
        }
    }
}
