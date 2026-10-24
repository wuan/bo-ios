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
| 3 - Map UI overlays | [`ios-map-ui-overlays`](../openspec/changes/archive/2026-10-23-ios-map-ui-overlays/proposal.md) | `map-ui-overlays`, `location-handling` (manual path), `proximity-alerts` (aggregation), and `data-providers` and `data-modes` (modified) |
| 4 - Location handling | [`ios-location-handling`](../openspec/changes/archive/2026-10-23-ios-location-handling/proposal.md) | `location-handling` (modified: device modes, permissions, display and centring choices) |
| 5 - Proximity alerts | [`ios-proximity-alerts`](../openspec/changes/archive/2026-10-23-ios-proximity-alerts/proposal.md) | `proximity-alerts` (modified: gating, limits, signals, suppression, state) and `map-ui-overlays` (modified: the radar's alert mark) |
| 6 - Background monitoring | [`ios-background-monitoring`](../openspec/changes/archive/2026-10-23-ios-background-monitoring/proposal.md) | `background-monitoring` |
| 7 - Preferences | [`ios-preferences`](../openspec/changes/archive/2026-10-24-ios-preferences/proposal.md) | `preferences`, and `data-modes` (modified: animation step duration and cycle pause) |

Delivered foundations that later phases build on:

- Raised the floor to iOS 16 / Swift 5.0 across all targets (breaking).
- Typed `UserDefaults` settings store with registered defaults and observation;
  credentials in the Keychain.
- Shared data model, provider protocol/factory with JSON-RPC and Blitzortung
  HTTP providers, TTL cache, sequence validation, and lifecycle events.
- Realtime/history/animation time model with the time slider, and region and
  data-area/grid selection.
- One location seam with manual and device-backed (network, GPS, passive) modes,
  permission gating, the background-location disclosure, and the own-location
  display and centring choices.
- Proximity alerts with the enable switch, the notification and signalling
  limits, sound and vibration, suppression, and the alert state the radar marks.
- Background monitoring with the configurable query period, a best-effort
  `BGTaskScheduler` fetch that reuses the alert decision, a persisted dedup so one
  strike warns once, and the background-location request behind the disclosure.
- Age-coloured grid tiles with per-tile counts, translucency, base-map fade,
  three colour schemes with base-map variants, zoom-aware culling, and tap
  selection with a details popup.
- Localization scaffolding and the documentation pattern under `docs/`.
- A categorised settings screen whose contents come from one declarative model, with
  every user-facing setting reachable, the settings reference checked against the code,
  and export (credentials opt-in only), validated import, and reset.
- Animation step duration and cycle pause pacing playback, a keep-awake switch, and a
  bounded diagnostics log behind the diagnostics setting.

Open residual from Phase 2 (still open): the point-strike marker check against the
HTTP source and the live sweep across history/animation and both grid extremes were
never observed by hand (recorded when the change was archived). Later phases should
fold those checks into their manual pass.

Open residual from Phase 5: the radar's alert mark was observed in the simulator
against live data (with the limits opened up, the mark showed and the run kept a
screenshot), and the decision behind it is covered by the monitor's unit tests and
the controller's integration tests, including the mark clearing when the activity
leaves the range. Unobserved: the notification banner - the app asking for
authorisation is verified, the request it posts is unit-tested, but whether a
strike qualifies is data-dependent and the rendered banner did not appear to the
UI test's queries; and the audible signal and the felt vibration, which need a
device.

Open residual from Phase 6: the monitor's gating, scheduling, wake-up, dedup, and
background-location request are covered by unit tests, the task identifier and
background modes are asserted against the app's `Info.plist`, and the alert
decision and its notification were observed in the simulator against the live
backend (a position on an active cell produced "Lightning nearby / N 0.0 km").
Unobserved: a background wake-up actually firing with live data - the simulator
cannot, because `BGTaskScheduler` reports itself unavailable there, so no
`BGAppRefreshTask` can be submitted or fired - and the platform's worst-case
scheduling latency, which is best-effort by design. Both need a device.

Open residual from Phase 7: the settings screen's categories, one change per category,
the export's credentials opt-in, and reset were exercised in the simulator by a UI test,
and the store, the settings model, the export/import logic, the screen's import callback,
and the settings reference are covered by unit tests. Unobserved: the share sheet an
export hands its file to and the document picker an import reads from, which need a person
to choose a destination or a file; and the Phase 2 point-strike marker check, which the
live HTTP source left unobserved again (it reported no strikes). The Phase 5 and Phase 6
device-only residuals stand.

## Remaining phases

Each phase below becomes its own change when it starts.

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
