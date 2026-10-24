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

/// Keeps the active provider in step with the selected source and endpoint.
///
/// Changing either setting clears cached results and rebuilds the data handler,
/// so a result fetched from the previous source is never served. Consumers
/// subscribe once through ``events()`` and keep receiving events across rebuilds.
public final class DataProviderCoordinator {

    /// Builds a provider for a source and endpoint override.
    public typealias ProviderBuilder = (_ type: DataProviderType, _ endpointOverride: String) -> DataProvider

    private let settings: SettingsStore
    private let cache: DataCache
    private let providerBuilder: ProviderBuilder

    private let lock = NSLock()
    private var handler: DataHandler
    private var consumers: [UUID: AsyncStream<DataEvent>.Continuation] = [:]
    private var subscribedHandler: DataHandler?
    private var handlerSubscription: UUID?
    private var observers: [NSObjectProtocol] = []

    /// How many times the handler has been rebuilt.
    public private(set) var rebuildCount = 0

    public init(settings: SettingsStore,
                cache: DataCache = DataCache(),
                providerBuilder: @escaping ProviderBuilder) {
        self.settings = settings
        self.cache = cache
        self.providerBuilder = providerBuilder
        self.handler = DataHandler(provider: providerBuilder(DataProviderCoordinator.source(in: settings),
                                                             settings.string(for: .serviceEndpoint)),
                                   cache: cache,
                                   freshness: FreshnessValidator())

        attach(to: handler)
        observe()
    }

    /// Creates a coordinator backed by a ``DataProviderFactory``.
    public convenience init(settings: SettingsStore,
                            factory: DataProviderFactory,
                            cache: DataCache = DataCache()) {
        self.init(settings: settings, cache: cache) { type, endpointOverride in
            factory.makeProvider(type: type, endpointOverride: endpointOverride)
        }
    }

    deinit {
        stop()
    }

    /// The currently selected source.
    public var source: DataProviderType {
        return DataProviderCoordinator.source(in: settings)
    }

    /// What the active provider can serve.
    public var capabilities: DataProviderCapabilities {
        return handler.capabilities
    }

    /// Returns a stream of events from the active handler; it survives rebuilds.
    public func events() -> AsyncStream<DataEvent> {
        return AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            consumers[id] = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.consumers[id] = nil
                self.lock.unlock()
            }
        }
    }

    /// Starts a request through the active handler.
    public func requestData(parameters: Parameters) {
        handler.requestData(parameters: parameters)
    }

    /// Clears cached results and rebuilds the handler from the current settings.
    public func rebuild() {
        cache.clear()

        let rebuilt = DataHandler(provider: providerBuilder(source, settings.string(for: .serviceEndpoint)),
                                 cache: cache,
                                 freshness: FreshnessValidator())

        lock.lock()
        handler = rebuilt
        rebuildCount += 1
        lock.unlock()

        attach(to: rebuilt)
    }

    /// Stops observing settings and stops forwarding events.
    public func stop() {
        detachFromHandler()
        for observer in observers {
            settings.removeObserver(observer)
        }
        observers.removeAll()

        lock.lock()
        let current = Array(consumers.values)
        consumers.removeAll()
        lock.unlock()
        for continuation in current {
            continuation.finish()
        }
    }

    private func observe() {
        observers = [
            settings.observe(.dataSource) { [weak self] in self?.rebuild() },
            settings.observe(.serviceEndpoint) { [weak self] in self?.rebuild() },
        ]
    }

    /// Subscribes to a handler's events synchronously, replacing any previous subscription.
    private func attach(to handler: DataHandler) {
        detachFromHandler()
        subscribedHandler = handler
        handlerSubscription = handler.subscribe { [weak self] event in
            self?.broadcast(event)
        }
    }

    private func detachFromHandler() {
        if let subscribed = subscribedHandler, let id = handlerSubscription {
            subscribed.unsubscribe(id)
        }
        subscribedHandler = nil
        handlerSubscription = nil
    }

    private func broadcast(_ event: DataEvent) {
        lock.lock()
        let current = Array(consumers.values)
        lock.unlock()
        for continuation in current {
            continuation.yield(event)
        }
    }

    /// Resolves the selected source from the settings store.
    static func source(in settings: SettingsStore) -> DataProviderType {
        return DataProviderType(rawValue: settings.string(for: .dataSource)) ?? .rpc
    }
}
