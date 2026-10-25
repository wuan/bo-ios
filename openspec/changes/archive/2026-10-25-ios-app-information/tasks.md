# Tasks

## 1. Application menu and mode controls

- [x] 1.1 Replace the status row's `settings.open` button with a `menu.open` control that presents an action sheet offering settings, alarms, application log, change log, and information, each action carrying a `menu.*` accessibility identifier and reusing `SettingsViewController` and `EnlargedRadarViewController`; verify a UI test opens the menu and reaches each entry, and the settings and platform tests still pass
- [x] 1.2 Add a `realtime.goto` control to the mode row that is shown only in history mode and returns the app to realtime via `TimeModel.setPosition(max)`, and verify a unit test that `syncModeControls` shows it in history and hides it in realtime and animation, plus a UI test that tapping it returns the mode indicator to realtime
- [x] 1.3 Keep the animation control mode-appropriate (start in realtime and history, stop in animation) and verify a UI test per mode that the control offered matches the mode
- [x] 1.4 Externalize the menu entries' and controls' labels into `Localizable.xcstrings`, and verify `LocalizationTests` (or the string audit) reports no literal UI strings left in `ViewController` and the menu

## 2. Application log view and send-for-support

- [x] 2.1 Add a pure content builder that turns `AppLog.entries` into display lines (`<timestamp>  <message>`) and a flat shareable text form, with an explicit empty state; verify unit tests for the ordering, the format, and the empty ring
- [x] 2.2 Add `ApplicationLogViewController` listing the entries with the empty state, and a `sendLog` action that hands the share text to a `UIActivityViewController` (anchored for iPad); verify a unit test of the content it presents and a UI test that opens the log from the menu and finds the send action
- [x] 2.3 Externalize the log view's and send action's labels into `Localizable.xcstrings`, and verify the string audit reports no literal strings left in the view

## 3. Change log

- [x] 3.1 Add a `ChangeLog` parser that reads `## <version>` sections with `- ` bullet lines into entries newest-first, ignoring surrounding prose, and reports an empty result for missing or entryless input; verify unit tests over a fixture string, an empty input, and a body written by hand
- [x] 3.2 Add `monitor/Resources/CHANGELOG.md` to the app target and a `ChangeLogViewController` that renders the parsed entries as version sections with the empty state, and verify the parser test plus a UI test that opens the change log from the menu and finds a version section
- [x] 3.3 Externalize the change log view's and empty state's labels into `Localizable.xcstrings`, and verify the string audit reports no literal strings left in the view

## 4. Information and update check

- [x] 4.1 Add an `AppVersion` value type read from the app bundle (marketing version and build) and a pure comparison that reports update-available, up-to-date, or unknown using numeric version-component ordering, and verify unit tests for a newer patch/minor/major version, equality, a lexically-larger-but-numerically-smaller pair, and a malformed available version
- [x] 4.2 Add an `AvailableVersionProviding` seam with a production implementation that queries the App Store lookup API by bundle id and decodes the available version, and verify a unit test injects a stub provider to drive both the available and up-to-date outcomes with no network
- [x] 4.3 Add `InformationViewController` showing the app name, the installed version and build, the project link, and the copyright, plus the update-check outcome (an available update shown, up-to-date shown, unknown adds nothing), and verify a unit test of the content it presents and a UI test that opens information from the menu and finds the version
- [x] 4.4 Externalize the information view's and update outcome's labels into `Localizable.xcstrings`, and verify the string audit reports no literal strings left in the view

## 5. Documentation

- [x] 5.1 Write `docs/app-information.md` covering the menu and its entries, the mode-appropriate controls, the log and send action, the change-log format and the bundled file, the information/version display, and the update check (including its silent-failure rule), and verify the documented test command runs green
- [x] 5.2 Document the `CHANGELOG.md` format as the file's own contract (header per version, `- ` bullets) and verify the parser test parses the shipped file itself

## 6. Integration verification

- [x] 6.1 Run `openspec validate ios-app-information --strict` and the full `xcodebuild test` suite on the simulator, and verify both pass with no warnings introduced. Validation passes and the unit suite is green (624 tests, 0 failures); the UI suite is green except a pre-existing live check, `testLiveHttpSourceAuthenticatesAgainstRealBackend`, which fails identically with this change stashed (the live HTTP source returns 0 strikes) and five tests that skip for want of a stub server, a fresh install, or a device; no new build warnings come from this change (the remaining ones are pre-existing)
- [x] 6.2 Pass over the app's surfaces on the simulator through the UI tests, which drive the real app: the menu opens every entry (settings, alarms, application log with its send action, change log, information with the version), and the mode controls change with the mode; unobserved and recorded: the share sheet's destination (needs a person to choose one), the live App Store lookup (the app is not listed, so the update line stays unknown), and the Phase 2 point-strike marker check over the live HTTP source (it reported no strikes again)

## Workflow follow-up

- Archive the change (which syncs the `app-information` capability into `openspec/specs/`).
- Update `docs/parity-roadmap.md`: move Phase 8 into *Delivered phases* with the change link and the spec it produced, and delete the consumed `docs/parity-capabilities/app-information.md` sketch.
- Note the new residual (the live App Store lookup cannot be exercised until the app is listed) and carry forward the Phase 2/5/6 device-only residuals.
