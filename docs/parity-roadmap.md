# Android feature-parity roadmap

How the iOS app (`monitor/`) is brought to feature parity with the Android
reference (`wuan/bo-android`).

This document replaces the `android-feature-parity` OpenSpec change, which was
planning-only and could never be archived as delivered. The roadmap and the
platform decisions for the remaining phases live here; the capability sketches
live in [`parity-capabilities/`](parity-capabilities/), and **each phase is
proposed and delivered as its own OpenSpec change**.

## Why

The iOS app started as a prototype: one screen, realtime-only strike rendering
against a test backend. Android has history and animation playback, pluggable
data sources, grid tiles, proximity alerts, a background service, a home-screen
widget, extensive preferences, and 10+ translations. This roadmap sequences the
work so each increment can be verified on its own; the specs, not the Android
implementation, are the contract.

## How a phase is delivered

1. Propose a change for the phase (`openspec propose`), taking the matching
   sketch from [`parity-capabilities/`](parity-capabilities/) as the starting
   point for its delta specs. Sketches are delta-style on purpose: lift the
   requirements into `specs/<capability>/spec.md` and refine them there.
2. Implement it, with `openspec validate <change> --strict` and
   `xcodebuild test` as the gates.
3. Archive it, which syncs its specs into `openspec/specs/`.
4. Update this document: move the phase into *Delivered phases*, note the specs
   it produced, and delete the capability sketch it consumed.

## Delivered phases

| Phase | Change | Main specs produced |
| --- | --- | --- |
| 0 - Foundation and project modernization | [`ios-foundation`](../openspec/changes/archive/2026-10-22-ios-foundation/proposal.md) | `data-pipeline`, `lightning-data-model`, `localization-scaffolding`, `settings-store` |
| 1 - Data providers | [`ios-data-providers`](../openspec/changes/archive/2026-10-22-ios-data-providers/proposal.md) | `data-providers` |
| 1 - Data modes | [`ios-data-modes`](../openspec/changes/archive/2026-10-22-ios-data-modes/proposal.md) | `data-modes`, and `data-providers` (modified) |
| 2 - Map rendering | [`ios-map-rendering`](../openspec/changes/archive/2026-10-22-ios-map-rendering/proposal.md) | `map-rendering` |

**In flight:** Phase 3 - Map UI overlays, as the change
[`ios-map-ui-overlays`](../openspec/changes/ios-map-ui-overlays/proposal.md). It also carries the
manual location slice of `location-handling`, the sector/range aggregation slice of
`proximity-alerts`, the histogram in `data-providers`, and the retirement of the count-threshold
requirement from `data-modes`.

Delivered foundations that later phases build on:

- Raised the floor to iOS 16 / Swift 5.0 across all targets (breaking).
- Typed `UserDefaults` settings store with registered defaults and observation;
  credentials in the Keychain.
- Shared data model, provider protocol/factory with JSON-RPC and Blitzortung
  HTTP providers, TTL cache, sequence validation, and lifecycle events.
- Realtime/history/animation time model with the time slider, and region and
  data-area/grid selection.
- Age-coloured grid tiles with per-tile counts, translucency, base-map fade,
  three colour schemes with base-map variants, zoom-aware culling, and tap
  selection with a details popup.
- Localization scaffolding and the documentation pattern under `docs/`.

Open residual from Phase 2: the point-strike marker check against the HTTP
source and the live sweep across history/animation and both grid extremes were
never observed by hand (recorded when the change was archived). Phase 3 and
later phases should fold those checks into their manual pass.

## Remaining phases

Each phase below becomes its own change when it starts.

### Phase 3 - Map UI overlays

Change: [`ios-map-ui-overlays`](../openspec/changes/ios-map-ui-overlays/proposal.md) (in flight)

- Legend: active colour scale with its age ranges, region name, grid baseline, and local region size.
- Quick settings, opened from the legend and applied without leaving the map: region, interval duration, historic timestep, data source, colour scheme, map mode, and fade. Region, interval duration, and historic timestep become persisted settings in this phase.
- Strike-rate histogram for the displayed period, fed by the histogram the grid response already carries, with tap-to-zoom-out to the data area.
- Alarm radar: activity by distance and direction from the current location, its no-location, no-data, and outside-data-area states, tap-to-centre, and an enlarged view on long-press.
- Data-area overview: the data area's extent and cell size, the viewport within it, and the zoom level.
- Manual location, delivered here rather than with the location phase: long-press to set, persisted, published to consumers, shown as a marker, and used for centring.
- The count-threshold requirement is retired: it was never settable and always inactive.

Dropped from this phase as already delivered: the status line (see the `data-modes` requirement
for the realtime countdown and the history interval start).

### Phase 4 - Location handling

Sketch: [`location-handling.md`](parity-capabilities/location-handling.md) - reduced to device location.

Phase 3 delivers the manual path (set by long-press, persistence, propagation, marker, centring).
What remains here:

- Implement the device provider modes (network, GPS, passive) behind the location source interface; verified by unit tests with stubbed providers.
- Implement permission flows including background-location disclosure; verified by manual checks for granted, denied, and disclosure paths.
- Implement the own-location display size setting and the keep-zoom versus default-zoom centring choice; verified by manual checks of both modes.

### Phase 5 - Proximity alerts

Sketch: [`proximity-alerts.md`](parity-capabilities/proximity-alerts.md) - the aggregation lands in Phase 3.

Phase 3 delivers the pure sector/range aggregation with closest-strike tracking, the fixed radar
geometry, the alert-interval window, and the aggregation states. What remains here:

- Implement enable/disable gating of monitoring; verified by unit tests and manual checks.
- Implement notification distance limit and signalling distance limit; verified by unit tests on limit boundaries.
- Implement sound/vibration signals with configurable strength; verified by manual checks on a device.
- Implement signal suppression for the configured duration; verified by unit tests on the suppression window.
- Implement alert-state reporting (active/cancelled) consumed by the alarm radar; verified by integration test with simulated strikes.

### Phase 6 - Background monitoring

Sketch: [`background-monitoring.md`](parity-capabilities/background-monitoring.md)

- Implement background monitoring using `BGTaskScheduler` plus background location, enabled only when background alerts are on; verified by device/simulator tests of enable/disable paths.
- Implement periodic background fetching at the configurable query period; verified by observing background fetches and by a settings-change test.
- Present and remove a persistent monitoring notification; verified by manual checks on state transitions.
- Implement foreground/background lifecycle transitions; verified by manual checks entering and leaving the foreground.
- Implement restore-after-relaunch when alerts remain enabled; verified by a relaunch/restart test (documented latency caveats).

### Phase 7 - Preferences

Sketch: [`preferences.md`](parity-capabilities/preferences.md)

- Implement the settings screen with map, animation, data source, location, alarm, generic, and backup categories; verified by a UI test listing all categories and their settings.
- Wire every setting to the settings store with documented defaults; verified by tests that changed values survive relaunch and unset values use defaults.
- Implement measurement-unit selection affecting displayed distances; verified by unit tests on formatting.
- Implement preferences export, import, and reset, excluding secrets by default and rejecting invalid input; verified by round-trip and invalid-input tests.
- Document the settings reference and verify documented defaults match the code.

### Phase 8 - App information

Sketch: [`app-information.md`](parity-capabilities/app-information.md)

- Implement the application menu with settings, alarms, application log, change log, and information entries; verified by a UI test opening each entry.
- Implement mode-appropriate control states (start animation; start animation + jump to realtime; stop animation); verified by UI tests per mode.
- Implement the application log view and send-for-support action; verified by manual checks that log content appears and a message is created.
- Implement the change log view parsed from the change log file; verified by a parser test and a visual check.
- Implement the information/version display and the update check with available/up-to-date outcomes; verified by unit tests with stubbed version data.

### Phase 9 - Home-screen widget

Sketch: [`home-screen-widget.md`](parity-capabilities/home-screen-widget.md)

- Add a WidgetKit extension target and render the alarm radar from the app snapshot, with an inactive/unavailable state; verified by adding the widget and observing both states.
- Implement timeline refresh and graceful degradation to the last snapshot; verified by observing scheduled refresh behaviour.
- Implement single-tap refresh (with progress indicator) and double-tap open-app actions; verified by manual checks of both actions.
- Document widget capabilities and refresh caveats.

### Phase 10 - Localization

Sketch: [`localization.md`](parity-capabilities/localization.md)

- Externalize all remaining user-facing strings into `.xcstrings`; verified by an audit showing no literal UI strings remain.
- Add translations for English, Czech, Dutch, French, German, Hungarian, Italian, Polish, Slovak, Russian, and Spanish; verified by launching under each language.
- Implement locale-aware number/unit/time formatting honoring the measurement system; verified by unit tests across locales.
- Verify unsupported device languages fall back to the default language.

## Integration verification

Once the phases land:

- Run the full app end-to-end against a live backend in realtime, history, and animation modes and verify the specs for data, rendering, overlays, and alerts hold.
- Verify cross-cutting behaviour on a physical device: background alerts, signalling, widget, and localization together.
- Run `openspec validate --specs --strict` and resolve all warnings.

## Platform decisions

Android mechanisms that have no direct iOS equivalent, and the choices made for
them. Phase-local decisions were settled in each phase's own design; these are
the ones that shape the remaining phases.

- **Layered, protocol-oriented architecture.** Mirror Android's seams in Swift
  idioms: `DataProvider` behind a factory, a `DataHandler` owning scheduling,
  cache, and validation, repository/`AsyncStream` adapters, and a shared data
  model. Delivered in Phases 0-1.
- **Behavioural, not literal, parity.** No Dagger, osmdroid, Robolectric, build
  variants, or ProGuard equivalents; the specs describe observable behaviour.
- **Settings and credentials.** A typed store over `UserDefaults`, with secrets
  in the Keychain and excluded from settings export unless the user opts in.
  Delivered in Phase 0; the full screen is Phase 7.
- **Alerts as pure logic.** Port Android's `AlertDataHandler` as a pure Swift
  type (sector/range buckets, bearing/distance, closest strike, time window,
  suppression) and wire `UNUserNotificationCenter`, `AudioToolbox`, and haptics
  on top. Phase 5.
- **Background work.** `BGAppRefreshTask` for periodic fetches plus background
  `CLLocationManager` updates, raising local notifications. iOS may throttle or
  defer refreshes; a true always-on service is impossible, so worst-case
  latency is documented rather than solved. Phase 6.
- **Home-screen widget.** A WidgetKit extension rendering the alarm radar from
  the app's snapshot, with a system-controlled timeline refresh. Phase 9.
- **Localization.** String Catalogs (`.xcstrings`) with `Locale` and
  `MeasurementFormatter` for numbers and units. Phase 10.
- **Map rendering.** MapKit with MapKit's own renderers, driven by a pure render
  plan, rather than custom `MKOverlayRenderer` drawing - the custom path did not
  composite item-level drawing in the target environment (see
  [`map-rendering.md`](map-rendering.md)). Delivered in Phase 2.

## Open questions

- Acceptable worst-case background alert latency, and whether silent push from
  the backend is ever expected - affects Phase 6 tuning only.
- Whether credentials belong in settings export behind an explicit opt-in -
  affects Phase 7 UX, not behaviour.
