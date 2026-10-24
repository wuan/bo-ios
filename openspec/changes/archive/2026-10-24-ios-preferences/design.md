# Design

## Context

See `proposal.md` - Why, and `specs/preferences/spec.md` for the requirements this design
realises.

The pieces the screen must build on already exist:

- `SettingsStore` is a typed `UserDefaults` wrapper with registered defaults, a
  notification-per-key observation API, `reset()`, and a validated `choice`/`setChoice`
  path for settings restricted to a fixed value set.
- `SettingsKey` holds 27 cases with one default each, and a unit test enforces that every
  case has a default. `SelectableSettings` owns the fixed value sets (region, interval
  duration, historic timestep, background query period) and the accept/reject rules.
- `SettingsViewController` is the deliberately minimal Phase 1 sheet: a hand-built
  `UIStackView` with the data source, service URL, colour scheme, map mode, and the
  credentials for the authenticated source. It is presented modally from the status row's
  `settings.open` control in `ViewController`.
- `QuickSettingsViewController` (Phase 3) already edits region, interval duration, historic
  timestep, data source, colour scheme, map mode, and fade against the same store.
- `ViewController` consumes `mapMode`, `mapFade`, and `colorScheme` and observes them;
  `location-handling` and `proximity-alerts` consume the location, own-location, and alert
  settings; `MeasurementUnit` already converts the distances the chrome shows.
- `ModeRefreshScheduler` decides refresh timing as a pure function of the supplied `now`,
  with a fixed `realtimePeriod` (60 s) and `animationPeriod` (1 s) chosen by
  `ViewController`.
- `CredentialStore` keeps username and password in the Keychain.
- Documentation follows `docs/<capability>.md`, each ending with the command that verifies
  the capability; UI tests drive the app through accessibility identifiers.

Constraints: the app is hand-rolled UIKit with no storyboards; tests are XCTest against
`@testable import monitor` plus XCUITest; the deployment floor is iOS 16; the settings
screen, the quick-settings dialog, and the store must not be able to disagree.

## Goals / Non-Goals

**Goals:**

- One authoritative settings surface, reached from the existing settings control, whose
  categories and contents are described by testable data rather than by hand-built views.
- Every user-facing setting is reachable, wired to the component that consumes it, and
  documented with a default that a test checks against the code.
- The settings this phase adds change observable behaviour.
- Export, import, and reset with defined precedence over secrets and internal bookkeeping.

**Non-Goals:**

- The application menu (Phase 8), application log viewer and send-for-support (Phase 8),
  WidgetKit (Phase 9), and shipping translations (Phase 10).
- Replacing the quick-settings dialog, the store, its observation API, or the value-set
  validation.
- A base-map scale control: MapKit owns the base map and offers no scale factor.
- Any new persistence mechanism beyond `UserDefaults` and the Keychain.

## Decisions

### Decision: A declarative preferences model rendered as a grouped list

Introduce plain value types - a `PreferencesModel` of categories, each a list of
`PreferenceItem`s - that describe the screen: the category name, and for each item its
title, the `SettingsKey` or action it binds, and its kind (choice among
`SelectableSettings.values`, toggle, slider with bounds, text, decimal number, credential,
or action). The rewritten `SettingsViewController` renders the model as a
`UITableView` in the `.insetGrouped` style, one section per category, replacing the
hand-built stack.

- Rationale: the categories, their contents, and the settings reference all derive from one
  description, so the UI test can list categories and their settings, `docs/preferences.md`
  can be checked against it, and adding a setting is one entry. A grouped table is the
  native iOS settings idiom and scrolls, which the current stack does not.
- Alternatives: keep the `UIStackView` (rejected: no grouping, no scrolling, every
  assertion a subview hunt); SwiftUI `Form` (rejected: one screen in a second UI paradigm,
  and the existing test helpers are UIKit-shaped).
- The existing accessibility identifiers that tests rely on (`settings.root`,
  `settings.source`, `settings.endpoint`, `settings.username`, `settings.password`,
  `settings.save`, `settings.close`) are kept on the equivalent controls so
  `monitorUITests` keeps working; new controls get one identifier of the form
  `settings.<key>`.

The categories and their contents:

| Category | Settings |
| --- | --- |
| Map | map mode, fade, colour scheme, own-location display, own-location size, keep zoom on centring |
| Animation | animation step duration, animation cycle pause |
| Data source | data source, service URL, region, interval duration, historic timestep, username, password |
| Location | location mode, manual latitude, manual longitude |
| Alarm | alerts enabled, background query period, notification distance limit, signalling distance limit, sound, vibration, suppression time |
| Generic | measurement unit, keep screen awake, diagnostics |
| Backup | export (with an include-credentials opt-in), import, reset |

### Decision: Split the settings into user-facing and internal

Add to `SettingsKey` the notion of a user-facing setting (a `userFacing` collection, or
`isInternal` on each case). The screen, the settings reference, and export/import operate
on the user-facing set; the internal bookkeeping - `manualLocationSet`,
`backgroundLocationDisclosureShown`, `lastNotifiedStrikeTimestamp`,
`lastSignalledStrikeTimestamp` - stays persisted but is off the screen, out of the export,
and cleared by reset.

- Rationale: the dedup watermarks and the "has the disclosure been shown" flag are
  bookkeeping, not preferences; treating them as settings would put them on the screen and
  put watermarks into a portable export that another install would then masquerade with.
- Alternatives: expose every key (rejected: meaningless toggles and exportable watermarks);
  keep one flat list and special-case the screen (rejected: three call sites would each
  need the exception).

### Decision: New settings and their defaults

| Setting | Kind and values | Default | Rationale |
| --- | --- | --- | --- |
| `animationStepDuration` | choice, seconds {1, 2, 5, 10} | 1 | Reproduces today's fixed 1 s step, so the default changes nothing |
| `animationCyclePause` | choice, seconds {0, 1, 2, 5} | 0 | Zero keeps today's wrap with no pause |
| `keepScreenAwake` | toggle | off | Matches Android's `do_not_sleep` default |
| `diagnosticsEnabled` | toggle | off | Diagnostics are opt-in |

The two animation durations join `SelectableSettings.values(for:)`, so the existing
`choice`/`setChoice` validation rejects an out-of-set value written by anything else.

- Rationale for whole-second sets: it reuses the `Int`-based selectable machinery and the
  `SelectableSettings` validation unchanged, and no plausible cadence needs sub-second
  steps.
- Alternatives: free-form numeric text fields (rejected: no validation, absurd values
  possible); fractional seconds (rejected: forces a new storage/validation shape for no
  user benefit).

### Decision: Animation timing lives in `ModeRefreshScheduler`, driven by the two settings

`ModeRefreshScheduler` takes the step duration for `animationPeriod` and gains
`animationCyclePause`. It tracks the *next due* time rather than the last refresh, so a
wrap can defer the next step by the cycle pause. Whether a step wrapped is decided where
the selection advances: `TimeModel`/`TimeIntervalSelection.animationStep` already knows the
wrap case (offset zero jumps to the history lower limit), so the controller records the
wrap and asks the scheduler for the due time accordingly. The decision stays a pure
function of the supplied `now`, as it is today.

- Rationale: the parity-critical timing stays unit-testable without a run loop, and the
  step duration and pause reach the only component that schedules animation.
- Alternatives: a `Timer` carrying the pause in `ViewController` (rejected: untestable,
  duplicates scheduling); pausing inside `TimeIntervalSelection` (rejected: a time model
  has no notion of wall-clock pacing).

### Decision: Keep-awake toggles the idle timer

A small controller sets `UIApplication.shared.isIdleTimerDisabled` from
`keepScreenAwake` at launch and whenever the setting changes; iOS releases the assertion
when the app leaves the foreground anyway.

- Rationale: this is the only supported way to keep the display awake, and it mirrors
  Android's `do_not_sleep`. Default off.
- Alternatives: none with a user-visible difference.

### Decision: A minimal diagnostics sink behind the toggle

Introduce `AppLog`, an append-only, bounded recorder (an in-memory ring backed by `OSLog`)
whose `record` receives events from the app's lifecycle, data handling, and settings when
`diagnosticsEnabled` is on and drops them when it is off. Phase 8's log view and
send-for-support read the same sink.

- Rationale: the generic-settings requirement says diagnostics enablement *changes
  behaviour*, and this gives Phase 8 a seam without building the viewer early.
- Alternatives: store the toggle alone (rejected: a setting with no effect); rely on
  `OSLog` alone (rejected: Phase 8 needs content it can display and send).

### Decision: Export, import, and reset over the user-facing settings

A Codable `PreferencesExport` (`{version, settings: [key: value], credentials?}`) is
written as JSON to a temporary file and offered through a share sheet; import reads a
document through `UIDocumentPickerViewController`. Only user-facing settings are written.
Credentials are included only when the user turns on an explicit include-credentials
opt-in, as the roadmap's platform decision requires. Import validates the version and every
value against its setting's kind and value set, then applies all values or none: a failure
changes nothing and reports the failure. Reset reuses `SettingsStore.reset()` over the
user-facing keys and clears the animation and diagnostics records, leaving Keychain
credentials untouched (they are not settings).

- Rationale: JSON is portable, inspectable, and testable without a UI; all-or-nothing
  avoids a half-applied configuration; excluding secrets by default and requiring opt-in is
  the recorded platform decision.
- Alternatives: a plist (rejected: less inspectable, no benefit on iOS); embedding the
  Keychain item in the export (rejected: machine-bound, and the reason credentials live in
  the Keychain at all); per-setting partial import (rejected: leaves the app in a mixed,
  hard-to-explain state).

### Decision: Remove `mapScale`

Delete the `mapScale` case and its default. A value left in `UserDefaults` from an earlier
install is inert and cleared by reset; no spec references the key (only the archived Phase
2 design mentioned it). `docs/preferences.md` records the removal and why.

- Rationale: MapKit renders the base map itself and exposes no base-map scale factor, so
  the key has been stored but never consumed since Phase 0; a screen that exists to be
  authoritative should not carry a dead control. This follows the roadmap's "behavioural,
  not literal, parity" and its non-goal of carrying over Android concerns with no iOS
  meaning.
- Alternatives: bind it to the rendered activity tile size (rejected: diverges from
  `map-rendering`'s rule that a tile's size follows the grid parameters); keep it inert
  (rejected: a dead setting on the new screen).

### Decision: The settings reference is checked against the code

`docs/preferences.md` follows the existing documentation pattern and carries a table of
section, setting, kind, values, and default, ending with the verification command. A unit
test parses that table and asserts it covers exactly the user-facing keys and that each
documented default equals `SettingsKey.defaultValues`, and that its categories match the
model.

- Rationale: the roadmap requires the reference and a check that documented defaults match
  the code; parsing the real document catches drift a hand-maintained test list would not.
- Alternatives: a hand-maintained test list (rejected: drifts from the document).

### Decision: Keep the quick-settings dialog

The Phase 3 quick-settings dialog stays as it is and keeps editing the same store, so the
screen and the dialog cannot disagree for the settings they share; the full screen is
authoritative for everything the dialog does not offer. The settings screen remains
reachable from the existing `settings.open` control; Phase 8's menu adds a second entry.

- Rationale: no spec change, no duplicated state, and the settings capability's "Open
  settings" scenario does not depend on the menu Phase 8 has not built yet.

## Risks / Trade-offs

- **The screen rewrite breaks the identifiers the UI tests use** → keep the existing
  identifiers on the equivalent controls and update `monitorUITests` in the same change;
  the data-source persistence UI test must still pass.
- **New animation pacing regresses playback** → the defaults (1 s step, no pause)
  reproduce today's behaviour exactly, and the scheduler tests are extended to cover the
  configured values and the wrap pause.
- **A large screen is hard to scan** → grouped sections with one category each, and the
  reference test guarantees nothing is silently missing.
- **Exporting credentials is a privacy risk** → excluded by default, included only behind an
  explicit opt-in that names what it adds.
- **A bad import corrupts the configuration** → validate-then-apply as one unit, with a
  test per invalid input kind (unknown key, wrong type, out-of-set value, wrong version,
  unreadable file).
- **Documented defaults drift from the code** → the reference test fails the build on a
  mismatch.
- **Removing a key discards a stored value** → the value was never read; reset clears it and
  the reference records why.
- **`AppLog` grows unbounded** → a bounded ring, fixed at construction.

## Migration Plan

Not applicable: no data migration. An earlier install's stored `mapScale` value is ignored
and removed by reset; every other key keeps its meaning.

## Open Questions

- Whether the diagnostics sink should survive a relaunch, which Phase 8's log view may want.
  It can be answered in Phase 8 without changing this change's specs or approach.
