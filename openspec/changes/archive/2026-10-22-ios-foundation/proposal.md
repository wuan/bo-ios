# Proposal

## Why

The `android-feature-parity` roadmap is planning-only; each phase is delivered as its own change, and every later phase depends on a modern build baseline and shared foundations. Phase 0 must land first: the current iOS target (13.5, Swift 5.0, single `ViewController`) blocks WidgetKit, `async/await`, `BGTaskScheduler`, and String Catalogs, and provides no common settings store, domain model, or data pipeline for later capabilities to build on.

## What Changes

- Raise the minimum supported iOS version to 16.0 and align build/Swift settings across all targets. **BREAKING**: drops support for iOS 13.5 and earlier.
- Add a typed settings store over `UserDefaults` with registered defaults and change observation.
- Add a shared lightning domain model and provider-agnostic response parsing.
- Add a data pipeline (provider protocol, data handler, async stream/repository) and route the existing strike rendering through it.
- Add localization scaffolding (a base String Catalog) and externalize existing user-facing strings.
- Add test fixtures and unit tests; the existing map screen continues to display strikes.
- Deliver Phase 0 only. User-facing parity features (time modes, provider selection UI, alerts, background service, widget, full preferences screen, translations) remain in later phase changes.

## Capabilities

### New Capabilities

- `settings-store`: Typed, observable settings persistence with registered defaults.
- `lightning-data-model`: Shared domain types and provider-agnostic parsing for strike, grid, interval, and data-area data.
- `data-pipeline`: Provider abstraction, request lifecycle events, and stream/repository delivery of results.
- `localization-scaffolding`: Externalized user-facing strings in a base catalog with locale fallback.

### Modified Capabilities

<!-- None. The project has no main specs yet; this phase introduces foundational capabilities only. -->

## Impact

- **Code**: new settings, model, pipeline, and localization sources in `monitor/`; `ViewController` and the current `DefaultClient`/`JsonRpcClient` path are refactored to consume the pipeline. Existing overlay/renderer code is retained.
- **Project/targets**: `monitor.xcodeproj` gains new files/resources in the `monitor` target and test fixtures in `monitorTests`; deployment target and Swift settings change for every target.
- **Dependencies**: none added; stays on UIKit/MapKit/Foundation.
- **Users**: no user-visible feature change other than the iOS 16 minimum; the existing screen must keep working.
- **Out of scope**: implementation of any later parity phase; this change is limited to the Phase 0 foundation.
