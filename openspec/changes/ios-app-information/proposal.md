# Proposal

## Why

Phase 8 of the [Android feature-parity roadmap](../../../docs/parity-roadmap.md). The app now
has every user-facing capability Phases 0-7 promised, but only one way into them: the
status row's single settings button and the on-map chrome. There is no menu, no view of the
diagnostic log that Phase 7 started recording, no release notes, and nothing that tells the
user which version they have or that a newer one exists. Android offers an options menu
with alarms, the application log, the change log, and version information; without those
surfaces the remaining phases (the Phase 9 widget and Phase 10 translations) have no place
to announce themselves, and a user hitting a problem has no way to send the app's log to
support.

## What Changes

- Add an **application menu** reachable from the status row, offering settings, alarms,
  application log, change log, and information entries.
- Implement **mode-appropriate controls**: starting animation from realtime and history,
  jumping straight to realtime from history, and stopping animation while it plays; the
  existing animation toggle keeps its behaviour and gains the history-mode realtime jump.
- Add an **application log view** that shows the diagnostic ring `AppLog` already records
  (Phase 7) and a **send-for-support action** that hands the log's text to the system share
  sheet.
- Add a **change log view** that parses a bundled `CHANGELOG.md` and lists recent changes
  by version, degrading to an explicit empty state when the file is missing or unparseable.
- Add an **information view** showing app name, version, and build plus the project and
  copyright text, and an **update check** against the App Store lookup API that reports an
  available update or that the app is up to date, staying silent when the store is
  unreachable.

Not in scope: publishing or configuring an App Store listing; the WidgetKit extension
(Phase 9); shipping translations (Phase 10).

## Capabilities

### New Capabilities

- `app-information`: the application menu and its entries, the mode-appropriate control
  states, the application log viewer and send-for-support action, the change log viewer and
  its bundled changelog, and the information/version display with the update check.

### Modified Capabilities

<!-- None: the menu and surfaces are new behaviour, and the existing data-modes,
     preferences, and proximity-alerts requirements keep their current meaning. -->

## Impact

- `monitor/` (new `appinfo/` group): the menu, the log/change-log/information view
  controllers, the changelog parser and bundled `CHANGELOG.md`, and the version/update-check
  types behind a provider seam.
- `monitor/ViewController.swift`: the status row presents the menu instead of the lone
  settings button, and the mode controls gain the history-mode jump to realtime.
- `monitor/settings/AppLog.swift`: the log view and send action read the existing ring; no
  change to recording.
- `monitor/Resources/Localizable.xcstrings`: labels for the menu, the log, change log, and
  information screens, and the update-check outcomes.
- `docs/app-information.md` (new) and `docs/parity-roadmap.md` (move Phase 8 to delivered,
  delete the consumed sketch).
- Tests in `monitorTests/` (changelog parsing, version comparison, the update check with a
  stubbed store lookup, the information/log content builders) and `monitorUITests/` (the
  menu and each entry, and the mode-appropriate controls).
