# Design

## Context

See `proposal.md` - Why. Concrete current state: Xcode 27.1 with the iOS 27.1 SDK; `monitor.xcodeproj` sets `IPHONEOS_DEPLOYMENT_TARGET` to 9.0 at the project level and 13.5 on the `monitor` target, `SWIFT_VERSION = 5.0`; `monitorTests` and `monitorUITests` exist as 2015-era stubs; `monitor/` holds a single-screen app (`ViewController`, `DefaultClient`, `JsonRpcClient`, `Strike`/`RasterElement`, `StrikeOverlay(Renderer)`, `ColorScheme`, `Parameters`, `RasterParameters`, `Result`). Source files are added to the target explicitly in `project.pbxproj` (no synchronized groups).

This phase is the platform-neutral foundation for the `android-feature-parity` roadmap; see that change's `design.md` for the overall architecture this builds toward.

## Goals / Non-Goals

**Goals:**

- Land a buildable, testable iOS 16 baseline.
- Provide the shared settings, model, and data-pipeline seams later phases extend.
- Keep the existing screen working with no new user-facing features.

**Non-Goals:**

- Any parity feature (modes, provider selection UI, alerts, background, widget, settings screen, translations).
- Changing the map rendering approach or adding dependencies.
- A release/packaging pipeline.

## Decisions

### Decision: Minimum iOS 16, Swift 5.9 language mode
Set `IPHONEOS_DEPLOYMENT_TARGET = 16.0` on every target and a modern `SWIFT_VERSION` consistent across the project.

- Rationale: unlocks WidgetKit, `async/await`, `BGTaskScheduler`, and String Catalogs needed by later phases. Alternatives: iOS 15 (weaker concurrency/observation) or staying at 13.5 (blocks the roadmap) - rejected. This is the one hard-to-reverse choice; confirmed with the maintainer.

### Decision: Settings via `UserDefaults` + change notification
Implement a `SettingsKey` enumeration (typed) and a `SettingsStore` that registers defaults and posts a `NotificationCenter` notification naming the changed key; expose typed getters/setters.

- Rationale: `UserDefaults` is the idiomatic store; `NotificationCenter` gives observation without a third-party dependency and works with both UIKit and later SwiftUI/Combine consumers. Alternatives: a Combine `CurrentValueSubject` hub (fine, but heavier now), Core Data (overkill) - rejected.

### Decision: Value-type domain model in a dedicated group
Model `Strike`, `GridElement`/`Event`, `GridParameters`, `Location`, `Parameters`, `DataArea`, `TimeInterval`, and `History` as Swift value types in `monitor/data/`, replacing the class-based `Strike`/`RasterElement` where practical while preserving the fields the renderer needs. Parsing lives beside the model and is transport-agnostic.

- Rationale: matches the reference seams in `bo-android` and makes parsing unit-testable with fixtures. Alternative: keep the `NSObject`-based classes - rejected, they carry UIKit coupling and hinder value semantics. Note: the map overlay currently relies on `Strike.envelope`/`MKCoordinateRegion`; the model may expose the geometry it needs without importing MapKit to stay testable.

### Decision: Pipeline with `DataProvider` protocol + `DataHandler` + `AsyncStream`
Define `DataProvider` (fetch for parameters → result/error), a `DataHandler` that schedules fetches and emits `DataEvent` values (`requestStarted`, `dataReceived`, `status`/error), and expose events through an `AsyncStream` that consumers subscribe to and cancel. The existing `JsonRpcClient` is wrapped as the first provider; `ViewController` consumes the stream.

- Rationale: mirrors `bo-android`'s provider/handler/repository layering with Swift concurrency, and directly satisfies the pipeline spec. Alternatives: keep the callback `DefaultClient` - rejected, does not scale to modes/providers; Combine - viable but `AsyncStream` is lighter and aligns with `async/await`. Concurrency caveat: event emission must be marshalled to the main actor for UI consumers.

### Decision: String Catalog for localization scaffolding
Add a base `Localizable.xcstrings` and externalize the strings currently in `ViewController`.

- Rationale: Xcode-native and ready for the later translation phase. Alternatives: `Base.lproj/Localizable.strings` - works but noisier; deferred entirely - would violate the spec.

### Decision: Manage `project.pbxproj` by editing it directly
Add new source/resource files to the `monitor` target and fixtures to `monitorTests` by editing the project file, since it uses explicit file references.

- Rationale: no migration risk to synchronized groups mid-roadmap; keeps diffs reviewable. Risk noted below. Alternative: migrate to `PBXFileSystemSynchronizedRootGroup` - rejected as a larger, riskier change that belongs in its own task if desired.
- Verification must include an actual `xcodebuild` build/test, since a malformed project file fails loudly but subtly.

## Risks / Trade-offs

- **Project-file edits are error-prone** → Make minimal, well-formed additions; verify with `xcodebuild build` and `xcodebuild test` after each batch; keep a clean git state to diff against.
- **Refactoring the live render path can regress the screen** → Route the existing behavior through the pipeline incrementally and require the app to still display strikes before marking the task done.
- **Swift concurrency + UIKit threading** → Contain UI updates on `@MainActor`; emit pipeline events on the main actor; cover with a test that delivery reaches consumers.
- **Model rewrite vs. renderer coupling** → Keep the geometry the renderer needs on the model (coordinate + span) without importing MapKit into pure model types; build the `MKCoordinateRegion` at the overlay boundary.
- **Deployment-target raise is breaking** → Confirmed with maintainer (iOS 16); documented in the proposal; only reverted by lowering the floor and losing later phases.
- **Raising the floor may surface deprecated API warnings under the iOS 27 SDK** → Fix or explicitly silence only what the build reports; keep the build warning-clean where practical.
