# Proposal

## Why

Phase 7 of the [Android feature-parity roadmap](../../../docs/parity-roadmap.md). The app's
settings have accumulated across Phases 0-6 faster than any surface to edit them: the
settings screen is still the deliberately minimal, data-source-only sheet built for Phase
1, several settings are reachable only from the legend's quick-settings dialog, the region,
interval duration, and historic timestep have no full-screen home, and there is no way to
back settings up, restore them, or reset them from the UI. Android offers a categorised
settings screen with export, import, and reset; without it the remaining phases have no
settled settings contract and users cannot configure the map, animation, location, alarm,
or generic behaviour from one place.

## What Changes

- Replace the minimal settings screen with a **categorised settings screen** covering map,
  animation, data source, location, alarm, generic, and backup categories, reachable from
  the existing settings control. (The application menu that will also offer it arrives in
  Phase 8.)
- **Surface every user-facing setting** in that screen and wire each one to the component
  that consumes it, including the region, interval duration, historic timestep, map fade,
  own-location display and size, keep-zoom-on-centre, location mode and manual
  coordinates, alert enablement, background query period, distance limits, suppression,
  sound, and vibration.
- **Add the settings the phase requires but the app lacks**: animation step duration,
  animation cycle pause duration, keep-screen-awake, and diagnostics enablement.
- **Remove the inert `mapScale` setting**: MapKit renders the base map itself and offers no
  base-map scale factor, so the key has been stored but unused since Phase 0. Its removal
  and the reason are recorded in the settings reference.
- Make **animation playback honour the step duration and the cycle pause**, so the new
  animation settings change observable behaviour rather than only being stored.
- Add **preferences export, import, and reset** in a portable form, excluding credentials
  unless the user explicitly opts in, and rejecting unreadable or invalid input without
  changing existing settings.
- Add a **settings reference** under `docs/` that lists every setting, its category, and
  its documented default, verified against the code by a test.

## Capabilities

### New Capabilities

- `preferences`: the categorised settings screen, its per-category contents, the defined
  defaults and persistence behind them, measurement units, the screen-awake and
  diagnostics toggles, and settings export, import, and reset.

### Modified Capabilities

- `data-modes`: animation playback gains a configurable step duration and a configurable
  pause when the playback cycles back to the beginning.

## Impact

- `monitor/settings/`: `SettingsKey` (new keys, `mapScale` removed, user-facing vs internal
  split), the rewritten `SettingsViewController`, and new types for the settings model,
  export/import, and the settings reference.
- `monitor/modes/ModeRefreshScheduler.swift`: animation step duration and cycle pause.
- `monitor/ViewController.swift`: animation wiring, keep-screen-awake, and observation of
  the settings the screen changes.
- `monitor/client/CredentialStore.swift`: credentials stay out of the export unless opted
  in.
- `monitor/Resources/Localizable.xcstrings`: labels for the new screen, categories, and
  backup actions.
- `docs/preferences.md` (new) and `docs/parity-roadmap.md` (move Phase 7 to delivered,
  delete the consumed sketch).
- Tests in `monitorTests/` (settings model, defaults, export/import, animation scheduling,
  reference-vs-code) and `monitorUITests/` (the categories and their settings).

Not in scope: the application menu, application log viewer, change log, and information
surfaces (Phase 8); the WidgetKit extension (Phase 9); shipping translations (Phase 10).
