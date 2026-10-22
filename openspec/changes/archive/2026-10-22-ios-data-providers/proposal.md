# Proposal

## Why

Phase 0 delivered a single-provider pipeline: `JsonRpcDataProvider` posting to one endpoint, with no source selection, no credentials, no caching, and no out-of-order protection. The Android reference (`wuan/bo-android`) treats the source as pluggable — a `DataProviderFactory` picks between a JSON-RPC provider and a Blitzortung HTTP provider from a persisted preference, with a 5-minute parameter-keyed cache and a sequence check. Without those, iOS cannot host the later data-mode, region, and alert behaviour, and the backend cannot distinguish iOS clients from one another for diagnostics.

## What Changes

- Introduce a **selectable data source** by adding a provider factory keyed by the persisted `dataSource` setting (default `rpc`), so the active provider is resolved at runtime and survives relaunches.
- Add the **Blitzortung HTTP provider** alongside JSON-RPC, resolving its base URL from the `serviceEndpoint` setting and falling back to a built-in default when unset.
- Add **provider credentials** for authenticated sources, stored in the **Keychain** (not `UserDefaults`) and applied to qualifying requests only.
- Add a **bounded-TTL result cache** keyed by request parameters, plus **stale-result rejection** so an out-of-order response never replaces fresher data.
- Add **client identification**: send `User-Agent: bo-ios-<build number>` (the app's `CFBundleVersion`) on every provider request, replacing the current fixed `bo-ios`, mirroring Android's `bo-android-<versionCode>`.
- Convert `Parameters` to a **value type** so it can key the cache; the request lifecycle events already provided by the `data-pipeline` capability are reused unchanged.

## Capabilities

### New Capabilities

- `data-providers`: Selectable and configurable lightning data sources with credentials, a bounded-TTL cache, stale-result rejection, and client identification on requests. (Common result parsing is already owned by `lightning-data-model` and is reused rather than redefined.)

### Modified Capabilities

<!-- None: `data-pipeline` already owns the provider abstraction and request lifecycle events; this change adds source selection/configuration around it without changing those requirements. -->

## Impact

- **Code**: `monitor/pipeline/` (provider factory, HTTP provider, cache, sequence/age validation, user-agent construction), `monitor/client/` (endpoint and credential handling), `monitor/Parameters.swift` (value semantics), `monitor/settings/` (`SettingsKey` additions for endpoint, source, and credentials), plus a minimal in-app surface so source/endpoint/credential selection is verifiable before the Phase 7 preferences screen exists.
- **Dependencies**: none expected; Keychain uses the built-in Security framework.
- **Behaviour**: fixes the prototype's hard-coded `http://bo-test.tryb.de` endpoint and single source behind the selectable/overridable model.
- **Out of scope**: time modes, region/data-area/grid selection (`ios-data-modes`), the full preferences screen (Phase 7), and clusters — Android's HTTP source cannot serve grid or cluster data, so those remain RPC-only.
