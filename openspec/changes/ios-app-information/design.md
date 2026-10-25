# Design

## Context

See `proposal.md` - Why, and `specs/app-information/spec.md` for the requirements this design
realises.

What the app already provides, and what this phase builds on:

- `ViewController` builds a full-bleed map with two floating material bars. The top status
  row carries a `status.text` label and one `settings.open` button; the bottom `mode.bar`
  carries the mode indicator, the `time.slider`, and the `animation.toggle` button.
  `showSettings()` presents `SettingsViewController` modally.
- `TimeModel` owns realtime/history/animation and exposes `startAnimation()`,
  `stopAnimation()`, `setPosition(_:)`, `mode`, `position`, and `maxPosition`.
  `syncModeControls()` reflects it in the slider and the animation button,
  `updateAnimationButton()` already switches the button between `animation.start` and
  `animation.stop`, and the status line already renders a wall-clock interval start in
  history and animation.
- `AppLog` (Phase 7) is a bounded ring of `AppLogEntry(date:message:)`, gated by the
  `diagnosticsEnabled` setting, with `entries` (oldest first) and `clear()`. Phase 7's
  comment and proposal name "a later phase's log view and send-for-support action" as this
  phase's work.
- `SettingsViewController` writes an export to a temporary file and hands it to a
  `UIActivityViewController`, and presents `UIAlertController` reports; the same share-sheet
  and alert patterns are reused here.
- `UserAgent(bundle:)` already reads `CFBundleVersion`; `Info.plist` carries
  `CFBundleShortVersionString` and `CFBundleVersion`.
- `Localizable.xcstrings` is the String Catalog every user-facing string goes through; the
  `docs/<capability>.md` pattern ends each page with the command that verifies it.

Constraints: hand-rolled UIKit with no storyboards; tests are XCTest against
`@testable import monitor` plus XCUITest driven by accessibility identifiers; the deployment
floor is iOS 16; the app targets iPhone and iPad, so a presented action sheet needs a
popover anchor.

## Goals / Non-Goals

**Goals:**

- One menu in the status row that reaches every new surface and the existing settings
  screen, with entries and outcomes that a UI test can drive by accessibility identifier.
- The version comparison, the changelog parsing, and the information/log view content are
  pure, unit-testable types; only presentation touches UIKit.
- The update check sits behind a provider seam so its outcomes are testable with stubbed
  version data and no network.
- Every new string goes through the String Catalog, and the new capability gets a
  `docs/app-information.md` ending with its verification command.

**Non-Goals:**

- Publishing or configuring an App Store listing; the lookup is best-effort and silent on
  failure.
- Replacing the on-map chrome (legend, radar, histogram, overview) or the quick-settings
  dialog, and no new alarm screen: the alarms entry reuses `EnlargedRadarViewController`.
- Re-opening `AppLog`'s recording rules, the settings model, or the store.
- Nagging at launch: the update check is evaluated when the information surface is opened,
  not as a startup alert.
- Shipping translations (Phase 10); strings are added in English only.

## Decisions

### Decision: One menu control in the status row, presenting a small menu sheet

Replace the lone `settings.open` button with a `menu.open` button that presents
`AppMenuViewController`: a small sheet whose buttons are **Settings**, **Alarms**,
**Application log**, **Change log**, and **Information**, in that order, each carrying its
`menu.*` accessibility identifier. The settings entry presents the existing
`SettingsViewController`; the alarms entry presents the existing
`EnlargedRadarViewController`; the rest present the new screens. The chosen entry is handed
back after the sheet dismisses, so the surface is presented without a presentation
conflict.

- **Rationale**: Android's options menu is the model the sketch mirrors, and one sheet is
  the closest iOS surface that keeps all five entries in one place. A hand-built sheet of
  identified buttons is what makes the entries drivable from XCUITest by identifier, which
  the tasks require.
- **Alternative considered**: a `UIAlertController` in `.actionSheet` style. Rejected after
  checking the SDK: `UIAlertAction` has no `accessibilityIdentifier`, so the actions could
  only be queried by their visible label and the `menu.*` identifiers could not be attached.
- **Alternative considered**: a `UIMenu` as the button's primary action. Rejected for the
  same reason: its items are not reliably queryable by identifier.
- **Alternative considered**: keep `settings.open` as a shortcut and add a second menu
  control. Rejected as redundant: two controls over the same store invites drift, and the
  menu already offers settings. The existing UI-test helper is updated to open the menu
  first, so the change is contained.
- **iPad**: the sheet is a system sheet with a medium detent, which sizes itself on both
  idioms without a popover anchor.

### Decision: Mode-appropriate controls add an explicit jump to realtime

Keep the existing `animation.toggle` (start in realtime and history, stop in animation) and
add a `realtime.goto` button to the mode row, shown only in history mode, that calls
`TimeModel.setPosition(max)` and refreshes. `syncModeControls()` drives its visibility from
`timeModel.mode`.

- **Rationale**: start/stop already matches the realtime, history, and animation cases; only
  "jump to realtime" is missing as a control. The slider's right end reaches realtime today,
  but the requirement asks for an explicit, discoverable control, and a button is trivial to
  assert per mode in a UI test.
- **Alternative considered**: make the menu itself mode-aware (Android's start/stop items
  live in its options menu). Rejected: the controls the user is actively looking at are on
  the map, not behind a menu; the mode bar is where the slider already lives.

### Decision: The log and change-log views render testable content builders

Introduce value types that build the view content, so presentation stays thin:

- `AppLogPresenter` (or a `content` type) formats `AppLog.entries` into display lines
  (`<timestamp>  <message>`) and a flat text form for sharing, plus an explicit empty state.
- `ChangeLog` parses the bundled `CHANGELOG.md` into `[ChangeLogEntry(version, lines)]`,
  newest first, and reports `.empty` when the file is missing or holds no recognised
  entries.

`ApplicationLogViewController` lists the log lines and carries a `sendLog` action that
takes the flat text into a `UIActivityViewController` (the log text and a written-to-file
variant, mirroring `SettingsExportFile`); `ChangeLogViewController` renders the entries as
sections. Both are `UITableView`-backed, matching `SettingsViewController`.

- **Rationale**: the parser is the parity-critical, spec-visible part ("read from the app's
  bundled change log"), so keeping it pure lets a unit test assert versions and ordering
  without a UI, exactly as the settings reference and the alert logic are tested.
- **Rationale for sharing via `UIActivityViewController`**: the sketch's "creates a message
  containing the log content" is satisfied by handing the text to the share sheet, which on
  a device offers Mail and Messages; this reuses the export pattern and needs no mail
  entitlement, unlike a bare `MFMailComposeViewController`.
- **Alternative considered**: parse the repository `ChangeLog` (autotools format). Rejected:
  it belongs to a different component and is not shipped; a dedicated `CHANGELOG.md`
  resource keeps the format ours and the fixture small.

### Decision: Bundled `CHANGELOG.md` as the change-log source

Add `monitor/Resources/CHANGELOG.md` to the app target and read it via `Bundle.main`. The
format is one `## <version>` header per release followed by `- ` bullet lines; the parser
tolerates surrounding prose and ignores anything before the first header.

- **Rationale**: the sketch says "parsed from the change log file"; a resource file keeps
  release notes editable without code, and the format is small enough to unit-test with a
  fixture string and an empty/missing case.

### Decision: Version reading and update check behind a provider seam

Add a pure value type `AppVersion(marketing:build:)` read from `Bundle.main`, and a pure
comparison `UpdateCheck.evaluate(installed:available:) -> .updateAvailable(version)` /
`.upToDate` / `.unknown`. The available version comes from an `AvailableVersionProviding`
seam whose production implementation queries the App Store lookup API
(`https://itunes.apple.com/lookup?bundleId=<bundle id>`) and decodes `results[0].version`;
tests inject a stub.

`InformationViewController` shows the app name, `AppVersion`, the project link, and the
copyright, and renders the update-check outcome: an available update (with the store's
version) is shown, up-to-date is shown, and an undetermined result adds nothing.

- **Rationale**: the App Store lookup is the iOS analogue of Android's version check and
  needs no backend; keeping the comparison pure and the fetch behind a protocol means the
  spec's available/up-to-date/unreachable outcomes are unit-tested with stubbed data, as the
  sketch requires.
- **Comparison rule**: compare marketing-version components numerically (`1.10 > 1.9`), not
  lexically. A malformed available version yields `.unknown`, never a false "update".
- **Failure is silent**: the lookup is best-effort; an unreachable store or an empty result
  (an app not yet listed) leaves the user unnotified, and the fetch is skipped when offline.

## Risks / Trade-offs

- **The app may not be published yet** → the lookup returns no result, so every user sees no
  update notice; the seam and the `.unknown` outcome keep this correct-by-default and let
  the listing be flipped on later without a spec change.
- **Removing the `settings.open` shortcut changes an existing test path** → the UI-test
  helper is updated in this change, and the menu's settings action reuses the same
  `SettingsViewController`, so no screen behaviour changes.
- **An action sheet hides the entries behind one tap** → acceptable: it mirrors Android, and
  the mode-appropriate animation control stays on the map where it is used.
- **`CHANGELOG.md` can drift from the shipped release** → the parser has an explicit empty
  state and the file is a normal resource; a release step for updating it is out of scope.
- **A background App Store request could fire in tests** → the production provider is
  injected only by the app; unit tests use the stub, and the UI test asserts the information
  screen's static content, not a live lookup.

## Migration Plan

No stored-data migration. The new group `monitor/appinfo/` and the resource are additive;
`ViewController` swaps one status-row button for the menu control, and the UI-test helper is
updated alongside. Rollback is reverting the change; no user-visible state depends on it.

## Open Questions

- The App Store listing's numeric id and the marketing version the first release will carry
  are set outside this change; the lookup uses the bundle id, so the code is unaffected.
