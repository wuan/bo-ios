# Tasks

## 1. Settings inventory and model

- [x] 1.1 Split `SettingsKey` into user-facing settings and internal bookkeeping, keeping the "every case has a default" guarantee, and verify with a unit test that the user-facing set and the internal set are disjoint, that every case has a default, and that the internal set is exactly the four bookkeeping keys
- [x] 1.2 Add the `animationStepDuration` (1 s default, {1, 2, 5, 10}), `animationCyclePause` (0 s default, {0, 1, 2, 5}), `keepScreenAwake` (off), and `diagnosticsEnabled` (off) settings with their defaults and their `SelectableSettings` value sets, and verify `SettingsStoreTests` and `SelectableSettingsTests` cover the defaults and that an out-of-set duration is rejected
- [x] 1.3 Remove the `mapScale` key and its default, and verify no source file or test still references it and the settings-store tests pass
- [x] 1.4 Introduce the declarative preferences model (categories and items binding a setting, an action, or a credential, with its kind) and verify a unit test asserts the seven categories and that every user-facing key appears in exactly one of them

## 2. Animation timing (data-modes)

- [x] 2.1 Give `ModeRefreshScheduler` the configured animation step duration and the cycle pause, tracking the next due time so a wrap defers the next step, and verify `ModeRefreshSchedulerTests` cover the configured step, the wrap pause, and the off value reproducing the current timing
- [x] 2.2 Read both animation settings into the scheduler from the store and record the cycle wrap where the selection advances, and verify a test that a changed step duration reaches the scheduler and that a wrap waits for the cycle pause

## 3. Settings screen

- [x] 3.1 Rewrite `SettingsViewController` as a grouped list rendering the model, keeping the existing `settings.*` identifiers on the equivalent controls, and verify `SettingsViewControllerTests` plus a new test that the screen shows every category with its settings
- [x] 3.2 Fill the data source category with the data source, service URL, region, interval duration, historic timestep, and the credentials offered only for the authenticating source, and verify the existing credential-visibility tests and a new test that a region/interval/timestep change reaches the store
- [x] 3.3 Wire every remaining user-facing setting to the component that consumes it (map mode, fade, colour scheme, own-location display and size, keep-zoom, location mode and manual coordinates, alert enablement and limits, background query period), and verify a test per category that a change made through the screen reaches the store and its observer
- [x] 3.4 Add the keep-screen-awake controller applying the setting to the idle timer at launch and on change, and verify a unit test that the idle timer follows the setting and that its default leaves the timer alone
- [x] 3.5 Externalize the new labels into `Localizable.xcstrings`, and verify `LocalizationTests` (or the string audit) reports no literal UI strings left in the screen
- [x] 3.6 Add a UI test that opens settings, lists all seven categories and a setting in each, and changes one setting per category, and verify it passes on the simulator

## 4. Diagnostics

- [x] 4.1 Add the bounded `AppLog` sink gated by `diagnosticsEnabled`, and verify a unit test that it records while enabled, records nothing while disabled, and stays bounded
- [x] 4.2 Route the app's lifecycle and data-handling events through the sink, and verify a test that an event recorded with diagnostics on is retrievable and that the toggle off stops the recording

## 5. Backup and restore

- [x] 5.1 Build the portable export representation over the user-facing settings only, and verify a round-trip test that an exported document imports to the same values and that no internal key appears in it
- [x] 5.2 Exclude credentials by default and include them only behind the explicit opt-in, and verify tests for both outcomes
- [x] 5.3 Validate an import (version, known key, matching type, value inside the setting's set) and apply all values or none, and verify a test per rejection kind that settings are unchanged and the failure is reported
- [x] 5.4 Add the backup category's export (share sheet with the include-credentials opt-in), import (document picker), and reset actions, and verify a UI test or a manual pass that each action runs and reports its outcome
- [x] 5.5 Implement reset over the user-facing settings, leaving Keychain credentials and clearing the diagnostics record, and verify a test that every user-facing setting reads its default and the credentials survive

## 6. Settings reference

- [x] 6.1 Write `docs/preferences.md` as the settings reference (category, setting, kind, values, default, the `mapScale` removal, and the verification command), and verify a test that parses the document and asserts it matches the model and the code's defaults exactly
- [x] 6.2 Make the reference's verification command (the settings tests) runnable as documented, and verify it runs green

## 7. Integration verification

- [x] 7.1 Run `openspec validate ios-preferences --strict` and the full `xcodebuild test` suite on the simulator, and verify both pass with no warnings introduced
- [x] 7.2 Do a manual pass on the simulator: open settings, change a setting in each category, relaunch to confirm persistence, then export, import, and reset; and fold in the open Phase 2 residual by checking the point-strike marker against the HTTP source, recording what remains unobserved

## Workflow follow-up

- Archive the change (which syncs the `preferences` capability and the `data-modes` delta into `openspec/specs/`).
- Update `docs/parity-roadmap.md`: move Phase 7 into *Delivered phases* with the change link and the specs it produced, and delete the consumed `docs/parity-capabilities/preferences.md` sketch.
- Note the Phase 5 and Phase 6 device-only residuals (notification banner, audible signal, vibration, a real background wake-up) as still unobserved; they need a device and were not covered by this phase's manual pass.
