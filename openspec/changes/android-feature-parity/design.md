# Design

## Context

See `proposal.md` - Why. The iOS target is a small UIKit app built from a handful of classes (`monitor/`): `ViewController` owns an `MKMapView` and a 1 s `Timer`, `DefaultClient` hard-codes a JSON-RPC call to the test endpoint, `JsonRpcClient` builds requests with `NSURLConnection`, and rendering is split between `StrikeOverlay`/`StrikeOverlayRenderer` and a small `ColorScheme`. Everything else (poll interval 60 s, region 1, 10 km grid, hybrid map) is a literal in `ViewController`.

The Android app (`wuan/bo-android`) is the behavioural reference. Its `AGENTS.md` documents the architecture to mirror conceptually: Dagger-wired singletons, a `ConsumerContainer` pub/sub layer adapted to repositories/ViewModels exposing flows, a strategy-pattern provider layer, sector/range alert computation, and map overlays drawn on a canvas. The specs in this change capture the externally observable behaviour; this document captures how to reach it on Apple platforms, where several Android mechanisms have no direct equivalent.

Constraints that shape the approach:

- **Platform model differs.** Android runs a foreground service for background alerting and a home-screen widget with a 15-minute refresh. iOS restricts background execution to `BGTaskScheduler` opportunistic windows and background location updates, and widgets refresh on a system-controlled budget. Parity must be behavioural, not literal.
- **Existing project settings are dated.** The Xcode project mixes `IPHONEOS_DEPLOYMENT_TARGET` 9.0 and 13.5 with `SWIFT_VERSION = 5.0` and a `UIApplicationSceneManifest`. Modern APIs (WidgetKit, `async/await`, `BGTaskScheduler`, String Catalogs) require a higher floor.
- **MapKit, not osmdroid.** Android uses osmdroid with `Overlay.draw`. The iOS equivalent is `MKMapView` + custom `MKOverlayRenderer`, which can already render tiles and text via Core Graphics (as `StrikeOverlayRenderer` demonstrates).

## Goals / Non-Goals

**Goals:**

- Establish a layered architecture (data providers → data handler → repositories → view models/views) that mirrors Android's seams, so each capability can be implemented and tested independently.
- Convert the roadmap into a dependency-ordered phase plan where each phase is independently deliverable and verifiable.
- Choose concrete Apple-platform mechanisms for each Android behaviour (background work, widget, notifications, localization, settings, credentials storage).
- Keep the existing MapKit-based rendering approach, extended rather than replaced.

**Non-Goals:**

- Reproducing Android's literal implementation (Dagger, osmdroid, Robolectric, Gradle variants). Only externally observable behaviour must match.
- Achieving exact parity of background timing or widget refresh cadence, which the OS controls.
- Carrying over Android-specific concerns with no iOS meaning (build variants, ProGuard, Play Store metadata, `armv7` capability).
- Implementing anything in this change; it is planning only.

## Decisions

### Decision: Deliver parity as a sequence of independent OpenSpec changes
This umbrella change defines the target and phase order; each phase is implemented later as its own change so it can be verified in isolation.

- Alternatives considered: (a) one giant change - rejected, unreviewable and unshippable; (b) ad-hoc tickets with no shared spec baseline - rejected, loses the contract that keeps both apps aligned.

### Decision: Adopt a layered, protocol-oriented architecture in Swift
Structure the app as Android does conceptually, using Swift idioms:

- `DataProvider` protocol with `JsonRpcDataProvider` and `BlitzortungHttpDataProvider` implementations behind a `DataProviderFactory`, selected from settings.
- A `DataHandler` orchestrator owning fetch scheduling, `DataCache` (TTL), and `SequenceValidator`, publishing events.
- Repository/`AsyncStream` (or Combine) adapters that views/`ObservableObject` view models consume, replacing `ConsumerContainer`.
- Shared data model (`Strike`, `GridElement`/`Event`, `GridParameters`, `Location`, `Parameters`, `DataArea`).

- Rationale: matches the reference seams, keeps provider and UI testable, and isolates the platform-specific pieces. Alternatives: extending the current `DefaultClient`/`ViewController` pair directly - rejected, it does not scale to modes, regions, and alerts.

### Decision: Build on MapKit with custom overlay renderers
Render grid tiles, counts, and strike points as `MKOverlay`s with custom `MKOverlayRenderer`s that draw rectangles and text with Core Graphics, extending the current `StrikeOverlayRenderer` approach. Keep `ColorScheme` and add schemes.

- Rationale: preserves working code and avoids new map dependencies; text-in-tile is achievable in a renderer, though costlier than a raster layer. Alternatives: `MKTileOverlay` raster tiles - rejected for counts/labels and dynamic colouring; a third-party vector map - rejected, unnecessary dependency and licence risk.
- Trade-off to watch: many small overlays hurt scroll/zoom performance at global scale. Mitigation: merge into a single renderer pass, cull to the visible `MKMapRect`, and follow Android's `canDraw`/zoom-aware detail.

### Decision: Settings via a typed `UserDefaults`-backed store
Introduce a `SettingsStore` exposing typed, observable settings keyed like Android's `PreferenceKey`, with explicit defaults registered at launch. Views and handlers observe changes.

- Rationale: `UserDefaults` is the natural iOS settings backing and satisfies persistence/default requirements. Alternatives: Core Data - overkill; a third-party defaults library - unnecessary.
- Credentials are the exception: store username/password in the Keychain rather than `UserDefaults`, and export/import settings **without** secrets unless the user opts in.

### Decision: Port the alert computation as pure, testable logic
Reimplement Android's `AlertDataHandler` as a pure Swift type (sector/range buckets, bearing/distance, closest strike, time window, suppression) with no UIKit dependencies, then wire signalling (local notifications via `UNUserNotificationCenter`, sound via `AudioToolbox`, vibration via haptics) on top.

- Rationale: the algorithm is the parity-critical part; keeping it pure makes it unit-testable exactly like Android's JUnit tests. Alternatives: folding it into the view controller - rejected, untestable.

### Decision: Model background monitoring with `BGTaskScheduler` plus background location
Use a `BGAppRefreshTask` registered for periodic fetches and `CLLocationManager` background updates for location-driven alerts, and raise local notifications for warnings. Present an ongoing-activity/notification indication where the platform allows.

- Rationale: this is the closest behavioural match to Android's foreground service within iOS rules; a true always-on service is impossible. Alternatives: silent push (requires server support - out of scope), continuous background audio (policy violation - rejected).
- Trade-off: iOS may throttle or defer refreshes. Accepted; documented as an open question on acceptable worst-case latency.

### Decision: WidgetKit extension for the home-screen widget
Implement the widget as a WidgetKit extension rendering the alarm radar from the snapshot written by the app, with a timeline refresh and `Link`/tap intents for refresh and open.

- Rationale: the only supported home-screen widget mechanism. Alternatives: legacy Today extension - deprecated.
- Trade-off: refresh cadence is system-controlled, not a strict 15 minutes. Documented as a parity caveat.

### Decision: Raise the deployment target and modernize the project
Raise the minimum iOS version (target iOS 16 unless constrained) to enable WidgetKit, `async/await`, `BGTaskScheduler`, and String Catalogs; adopt Swift 5.x concurrency and `ObservableObject`/`@Observable`.

- Rationale: the current 9.0/13.5 split blocks several required mechanisms and modern tooling. Alternatives: keeping iOS 9/13 - rejected, would force legacy notification, widget, and concurrency approaches for no user benefit.
- Because this is a **BREAKING** project change, it is Phase 0 and must land first.

### Decision: Localization via String Catalogs
Externalize strings into `.xcstrings` catalogs, ship the Android language set, and localize number/unit formatting with `Locale`/`MeasurementFormatter`.

- Rationale: Xcode-native, diff-friendly, supports the required language set. Alternatives: legacy `.strings` per locale - workable but noisier; third-party tooling - unnecessary.

## Risks / Trade-offs

- **Background timing parity** (iOS cannot guarantee Android-like intervals) → Use `BGTaskScheduler` earliest-begin dates plus background location; surface last-update time; document expected latency.
- **Map performance with many overlays** → Single-pass renderer, viewport culling, zoom-aware detail, tile merging; profile against Android's large-data behaviour.
- **Widget refresh budget** → Keep the app's snapshot authoritative; make the widget degrade gracefully to the last snapshot and support manual refresh.
- **Deployment-target raise** drops older devices → Confirm the supported-OS floor with the maintainer before Phase 0; it is the one decision that is hard to reverse.
- **Provider payload drift** (shared backend with Android) → Parse defensively, keep provider contracts in sync with `bo-android`, and cover with fixture-based unit tests.
- **Credentials handling** → Keychain, not `UserDefaults`; keep secrets out of settings export by default.
- **Scope breadth** → The phase plan is large; each phase must ship independently. If a phase grows, split it rather than expanding this change.
- **UI parity subjectivity** (layout/colours) → Treat the specs as the contract; match Android's components functionally and defer pixel-level styling to design review.

## Migration Plan

Deliver as dependency-ordered phases; each phase is a separate follow-up change that must pass `openspec validate` and its own tests before the next begins.

- **Phase 0 - Foundation (BREAKING):** raise deployment target/Swift toolchain, add settings store, shared data model, event/repository layer, localization scaffolding, and test target structure.
- **Phase 1 - Data providers & data modes:** provider protocol/factory, JSON-RPC + HTTP providers, caching, sequence validation, realtime/history/animation time model, interval/offset, region and data-area/grid handling, count threshold, time-slider control.
- **Phase 2 - Map rendering:** grid tiles with counts, age colouring, fade by age/zoom, colour schemes, zoom-aware detail, strike selection.
- **Phase 3 - Map UI overlays:** legend, quick settings, status line, histogram, alarm radar.
- **Phase 4 - Location handling:** provider modes, permissions and disclosure, manual/long-press location, own-location display and centering.
- **Phase 5 - Proximity alerts:** sector/range computation, limits, signalling, suppression, alert-state reporting.
- **Phase 6 - Background monitoring:** `BGTaskScheduler` + background location, notifications, restore-on-relaunch.
- **Phase 7 - Preferences:** full settings screen and categories, measurement units, backup/import/reset.
- **Phase 8 - App information:** menu, control states by mode, application log, change log, info/version, update check.
- **Phase 9 - Home-screen widget:** WidgetKit extension, timeline refresh, tap actions.
- **Phase 10 - Localization:** externalize and ship the language set; locale-aware formatting.

Rollback: each phase is independently revertable; Phase 0's deployment-target change is the only one with lasting effect and is reverted only by re-lowering the floor (accepting loss of later phases).

## Open Questions

- Confirm the minimum supported iOS version with the maintainer (assumed iOS 16) - affects Phase 0 and all later phases but not the specs.
- Confirm acceptable worst-case background alert latency and whether silent push from the backend is ever expected - affects Phase 6 tuning only.
- Decide whether credentials should be included in settings export behind an explicit opt-in - affects Phase 7 UX, not behaviour.
