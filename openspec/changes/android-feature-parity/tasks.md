# Tasks

> Roadmap note: this change is the parity plan. Each phase is delivered later as its own OpenSpec change, so the tasks below are the phased checklist for that journey. Verification for each phase is stated inline; `openspec validate` and `xcodebuild test` gates apply throughout.

## 1. Phase 0 - Foundation and project modernization

- [ ] 1.1 Confirm the supported iOS floor with the maintainer, then raise `IPHONEOS_DEPLOYMENT_TARGET` and `SWIFT_VERSION` consistently across all targets; verified by a clean build for device and simulator.
- [ ] 1.2 Add a typed, `UserDefaults`-backed settings store with registered defaults and change observation; verified by unit tests for persistence, defaults, and observation.
- [ ] 1.3 Define the shared data model (`Strike`, `Event`/`GridElement`, `GridParameters`, `Location`, `Parameters`, `DataArea`, `TimeInterval`, `History`) in a new module; verified by parsing unit tests using provider fixtures.
- [ ] 1.4 Introduce the event/repository layer (provider protocol, data handler, async stream adapter) and render existing data through it; verified by a running app shows the current strike overlay via the new path.
- [ ] 1.5 Add localization scaffolding (base `.xcstrings` catalog) and remove hard-coded user-facing strings from touched code; verified by a grep/audit showing no literal UI strings remain in touched files.
- [ ] 1.6 Extend the test target with provider and alert fixtures; verified by `xcodebuild test` succeeding with the new suites.

## 2. Phase 1 - Data providers and data modes

- [ ] 2.1 Implement the `DataProvider` protocol, `DataProviderFactory`, and selectable JSON-RPC and Blitzortung HTTP providers with configurable URL and Keychain-backed credentials; verified by unit tests per provider and manual requests to both sources.
- [ ] 2.2 Implement result caching (bounded TTL) and stale-result rejection; verified by unit tests for cache-hit avoidance, expiry, and out-of-order rejection.
- [ ] 2.3 Emit request-started, data-received, and status/error lifecycle events; verified by a test asserting each event on success and on failure.
- [ ] 2.4 Implement the realtime/history/animation time model with interval duration/offset and history range; verified by unit tests for realtime detection, offsets, and animation stepping.
- [ ] 2.5 Implement the 24-hour time-slider control where the rightmost position activates realtime; verified by UI test/manual checks for history selection and realtime activation.
- [ ] 2.6 Implement region selection, local data-area computation, grid sizing, and fallback to global; verified by unit tests for data-area derivation and the too-large-extent fallback.
- [ ] 2.7 Implement count-threshold filtering with zero meaning inactive; verified by unit tests and the legend reflecting an active threshold.
- [ ] 2.8 Document the provider configuration and mode controls (README/docs) and verify documented commands/steps work as written.

## 3. Phase 2 - Map rendering

- [ ] 3.1 Render variable-size grid tiles from grid parameters; verified by a renderer unit test and visual check across sizes.
- [ ] 3.2 Draw per-tile strike counts; verified by unit tests for count aggregation and a visual check at multiple zooms.
- [ ] 3.3 Implement age-based colouring across the active colour scheme; verified by unit tests mapping ages to colour sections.
- [ ] 3.4 Implement fade by age and zoom with clamped bounds; verified by unit tests on the opacity function.
- [ ] 3.5 Add selectable colour schemes and apply the selected scheme; verified by switching schemes and confirming redraw.
- [ ] 3.6 Add zoom-aware rendering detail with viewport culling/single-pass drawing; verified by a performance check with global-scale data.
- [ ] 3.7 Implement strike selection with a details popup and dismissal; verified by UI test/manual check.

## 4. Phase 3 - Map UI overlays

- [ ] 4.1 Implement the legend (age colour scale, region, grid baseline, local size, threshold-only-when-active); verified by unit tests of its content model plus visual checks.
- [ ] 4.2 Implement the quick-settings dialog opened from the legend and applied without leaving the map; verified by UI test/manual check.
- [ ] 4.3 Implement the status line (strike count, interval, refresh countdown); verified by unit tests and manual observation.
- [ ] 4.4 Implement the histogram of strike rate with tap-to-zoom-out; verified by unit tests on rate aggregation and a visual check.
- [ ] 4.5 Implement the alarm radar with active/inactive/outside states, tap-to-center, and long-press enlargement; verified by UI tests for each state and interaction.

## 5. Phase 4 - Location handling

- [ ] 5.1 Implement location provider modes (network, GPS, passive, manual) behind a provider interface; verified by unit tests with stubbed providers.
- [ ] 5.2 Implement permission flows including background-location disclosure; verified by manual checks for granted, denied, and disclosure paths.
- [ ] 5.3 Implement manual location entry and long-press-to-set-location; verified by UI test/manual check that the location changes.
- [ ] 5.4 Implement own-location display at a configurable size and center-on-location honoring keep-zoom; verified by manual checks of both keep-zoom modes.
- [ ] 5.5 Emit location-update notifications to consumers; verified by a test observing a location change.

## 6. Phase 5 - Proximity alerts

- [ ] 6.1 Implement pure sector/range aggregation with closest-strike tracking and the monitored time window; verified by unit tests porting Android `AlertResult` cases.
- [ ] 6.2 Implement enable/disable gating of monitoring; verified by unit tests and manual checks.
- [ ] 6.3 Implement notification distance limit and signalling distance limit; verified by unit tests on limit boundaries.
- [ ] 6.4 Implement sound/vibration signals with configurable strength; verified by manual checks on a device.
- [ ] 6.5 Implement signal suppression for the configured duration; verified by unit tests on the suppression window.
- [ ] 6.6 Implement alert-state reporting (active/cancelled) consumed by the alarm radar; verified by integration test with simulated strikes.

## 7. Phase 6 - Background monitoring

- [ ] 7.1 Implement background monitoring using `BGTaskScheduler` plus background location, enabled only when background alerts are on; verified by device/simulator tests of enable/disable paths.
- [ ] 7.2 Implement periodic background fetching at the configurable query period; verified by observing background fetches and by a settings-change test.
- [ ] 7.3 Present and remove a persistent monitoring notification; verified by manual checks on state transitions.
- [ ] 7.4 Implement foreground/background lifecycle transitions; verified by manual checks entering and leaving the foreground.
- [ ] 7.5 Implement restore-after-relaunch when alerts remain enabled; verified by a relaunch/restart test (documented latency caveats).

## 8. Phase 7 - Preferences

- [ ] 8.1 Implement the settings screen with map, animation, data source, location, alarm, generic, and backup categories; verified by a UI test listing all categories and their settings.
- [ ] 8.2 Wire every setting to the settings store with documented defaults; verified by tests that changed values survive relaunch and unset values use defaults.
- [ ] 8.3 Implement measurement-unit selection affecting displayed distances; verified by unit tests on formatting.
- [ ] 8.4 Implement preferences export, import, and reset, excluding secrets by default and rejecting invalid input; verified by round-trip and invalid-input tests.
- [ ] 8.5 Document the settings reference and verify documented defaults match the code.

## 9. Phase 8 - App information

- [ ] 9.1 Implement the application menu with settings, alarms, application log, change log, and information entries; verified by a UI test opening each entry.
- [ ] 9.2 Implement mode-appropriate control states (start animation; start animation + jump to realtime; stop animation); verified by UI tests per mode.
- [ ] 9.3 Implement the application log view and send-for-support action; verified by manual checks that log content appears and a message is created.
- [ ] 9.4 Implement the change log view parsed from the change log file; verified by a parser test and a visual check.
- [ ] 9.5 Implement the information/version display and the update check with available/up-to-date outcomes; verified by unit tests with stubbed version data.

## 10. Phase 9 - Home-screen widget

- [ ] 10.1 Add a WidgetKit extension target and render the alarm radar from the app snapshot, with an inactive/unavailable state; verified by adding the widget and observing both states.
- [ ] 10.2 Implement timeline refresh and graceful degradation to the last snapshot; verified by observing scheduled refresh behaviour.
- [ ] 10.3 Implement single-tap refresh (with progress indicator) and double-tap open-app actions; verified by manual checks of both actions.
- [ ] 10.4 Document widget capabilities and refresh caveats.

## 11. Phase 10 - Localization

- [ ] 11.1 Externalize all remaining user-facing strings into `.xcstrings`; verified by an audit showing no literal UI strings remain.
- [ ] 11.2 Add translations for English, Czech, Dutch, French, German, Hungarian, Italian, Polish, Slovak, Russian, and Spanish; verified by launching under each language.
- [ ] 11.3 Implement locale-aware number/unit/time formatting honoring the measurement system; verified by unit tests across locales.
- [ ] 11.4 Verify unsupported device languages fall back to the default language.

## 12. Integration verification

- [ ] 12.1 Run the full app end-to-end against a live backend in realtime, history, and animation modes and verify the specs for data, rendering, overlays, and alerts hold.
- [ ] 12.2 Verify cross-cutting behaviour on a physical device: background alerts, signalling, widget, and localization together.
- [ ] 12.3 Run `openspec validate android-feature-parity --strict` for each delivered phase change and resolve all warnings.

## Workflow follow-up

- Archive the umbrella roadmap change once the phase changes have been reviewed and the specs have been copied to the main specs, per the project's review requirements.
- Verify the archived result with `openspec list --specs` and `openspec validate`.
