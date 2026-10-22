# Tasks

## 1. Platform baseline

- [x] 1.1 Raise `IPHONEOS_DEPLOYMENT_TARGET` to `16.0` and set a consistent modern `SWIFT_VERSION` on all targets; verify with a successful `xcodebuild -scheme monitor -sdk iphonesimulator build`.
- [x] 1.2 Confirm `monitor`, `monitorTests`, and `monitorUITests` all resolve at the new floor; verify with `xcodebuild test` running the existing stub suites.

## 2. Settings store

- [x] 2.1 Implement the typed `SettingsKey` set and a `SettingsStore` exposing typed access with registered defaults; verified by unit tests that unset keys return their default.
- [x] 2.2 Implement persistence, reset-to-defaults, and per-key change observation; verified by unit tests for persistence across store reload, reset, and observers not firing for unrelated keys.

## 3. Lightning data model

- [x] 3.1 Implement the shared domain types (`Strike`, `GridElement`/`Event`, `GridParameters`, `Location`, `Parameters`, `DataArea`, `TimeInterval`, `History`) without UIKit coupling; verified by unit tests for derived cell centers, grid bounds, realtime detection, and history bounds.
- [x] 3.2 Implement provider-agnostic response parsing using saved fixtures; verified by unit tests covering a complete response and a response without grid parameters.

## 4. Data pipeline

- [x] 4.1 Define the `DataProvider` protocol and data lifecycle event types; verified by unit tests using a stub provider (success and failure).
- [x] 4.2 Implement `DataHandler` with `AsyncStream` delivery and lifecycle events, retaining prior data on failure; verified by unit tests asserting event order, delivery, cancellation, and retained data.
- [x] 4.3 Wrap the existing JSON-RPC client as the first provider and route `ViewController` strike rendering through the pipeline; verified by building and running the app in the simulator and observing strikes render.
- [x] 4.4 Document the pipeline API (provider/handler/stream usage) and verify the documented sample matches the code.

## 5. Localization scaffolding

- [x] 5.1 Add a base `Localizable.xcstrings` and externalize the user-facing strings in `ViewController`; verified by an audit showing no remaining literal UI strings in touched files and by the catalog being present in the built bundle.
- [x] 5.2 Verify locale fallback for a key without a translation; verified by a test/check showing the base-language value is returned.

## 6. Test and project hygiene

- [x] 6.1 Add test fixtures and wire all new test files into the `monitorTests` target; verified by `xcodebuild test` passing with the new suites included.
- [x] 6.2 Document the foundation (module layout and how to add files to the targets) and verify the documented build and test commands succeed as written.

## 7. Integration verification

- [x] 7.1 Run `xcodebuild build` and `xcodebuild test` clean and confirm the specs for settings, model, pipeline, and localization hold.
- [x] 7.2 Smoke-test the app in the simulator and confirm the existing map screen still displays strikes through the new pipeline with no user-visible regressions.
- [x] 7.3 Run `openspec validate ios-foundation --strict` and resolve all warnings.

## Workflow follow-up

- Archive this change after review; its capabilities (`settings-store`, `lightning-data-model`, `data-pipeline`, `localization-scaffolding`) become the main specs later phases build on.
- Verify the archived result with `openspec list --specs` and `openspec validate`.
