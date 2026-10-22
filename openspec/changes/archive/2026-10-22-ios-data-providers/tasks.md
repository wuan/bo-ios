# Tasks

## 1. Foundations

- [x] 1.1 Convert `Parameters` to a value type (`struct` conforming to `Equatable`/`Hashable`) while preserving its existing derived behaviour; verified by the existing lightning-data-model and pipeline suites passing and a test asserting two parameter sets built from equal values compare equal.
- [x] 1.2 Add `SettingsKey` entries for the selectable data source and the service-endpoint override with registered defaults; verified by `SettingsStoreTests` (every-key-has-default, persistence, reset) passing with the new keys.
- [x] 1.3 Add a shared request-header helper that composes `User-Agent` as `bo-ios-<CFBundleVersion>` from bundle metadata and replaces the fixed `bo-ios` literal in `JsonRpcClient`; verified by a unit test asserting the format for an injected build number and that a changed build number changes the header without a code change.
- [x] 1.4 Implement a `CredentialStore` protocol with a Keychain-backed implementation for the app and an in-memory implementation for tests; verified by round-trip save/load/clear tests against the in-memory store and a check that credentials are absent from `UserDefaults`.

## 2. Provider selection and configuration

- [x] 2.1 Add a provider-capability descriptor (at minimum: supports grid requests, supports clusters) exposed by `DataProvider`, with the JSON-RPC provider declaring full support; verified by unit tests asserting each provider's declared capabilities.
- [x] 2.2 Add a provider default-endpoint table and a `DataProviderFactory` that maps the `dataSource` setting to a provider and resolves the endpoint from the `serviceEndpoint` override or the default; verified by unit tests for each source and for the unset-endpoint fallback.
- [x] 2.3 Rebuild the data handler and clear cached results whenever the source or endpoint setting changes; verified by a test that switching the source produces requests through the newly selected provider.
- [x] 2.4 Add a minimal in-app surface to choose the source, override the endpoint, and enter credentials (full preferences arrive in Phase 7); verified by a UI test/manual check exercising each field and confirming the values persist across relaunch.
- [x] 2.5 Add an App Transport Security exception for `data.blitzortung.org` alongside the existing `tryb.de` entry; verified by a request to the HTTP source succeeding on device or simulator without an ATS failure.
- [x] 2.6 Document provider configuration (source selection, endpoint override, credentials storage, and the `bo-ios-<build>` user agent) and verify the documented steps and defaults match the code.

## 3. Blitzortung HTTP provider

- [x] 3.1 Implement the HTTP provider's per-minute strike-log fetching over the requested interval using bounded chunk iteration; verified by unit tests driving a stubbed transport and asserting the requested URLs and minute coverage.
- [x] 3.2 Implement incremental accumulation: merge new strikes, expire strikes outside the interval window, track the latest fetched minute, and reset on configuration change; verified by unit tests for merge, expiry, and reset behaviour.
- [x] 3.3 Apply HTTP Basic credentials from the `CredentialStore` only for the authenticated source; verified by tests asserting the authorization header is present for the HTTP source and absent for the JSON-RPC source.
- [x] 3.4 Add fixture-based parsing tests for the log line format, including a malformed line; verified by tests showing valid lines parse to strikes and malformed lines are skipped without failing the batch.
- [x] 3.5 Document the HTTP source (default endpoint shape, authentication, and the capability limits that it serves strike lists only, not grid data or clusters) and verify the documented limits match the capability descriptor.

## 4. Caching and freshness

- [x] 4.1 Implement a `DataCache` keyed by `Parameters` with a five-minute time-to-live in the data-handler layer, serving a matching unexpired result without issuing a request; verified by unit tests for a cache hit, expiry, and a differing-parameters miss.
- [x] 4.2 Implement stale-result rejection by retaining the last accepted reference timestamp and discarding not-newer results; verified by unit tests for an out-of-order response being discarded and a first result being accepted.
- [x] 4.3 Clear the cache when the source or endpoint changes so a cached result from the previous source is never served; verified by a test that switches the source and observes a fresh request rather than a cached result.
- [x] 4.4 Document the cache time-to-live and stale-rejection behaviour and verify the documented values match the code.

## 5. Integration verification

- [x] 5.1 Run the app against a live backend for both sources and confirm strikes render, the selected source persists across relaunch, and each request carries `User-Agent: bo-ios-<build>` (checked with a proxy or server log).
- [x] 5.2 Configure a custom endpoint and credentials and confirm the authenticated source succeeds while the unauthenticated source ignores the credentials.
- [x] 5.3 Run `xcodebuild test` and `openspec validate ios-data-providers --strict` and resolve all failures and warnings.

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied; its `data-providers` capability is copied to the main specs.
- Verify the archived result with `openspec list --specs` and `openspec validate`.
