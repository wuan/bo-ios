# App information

Phase 8 of the [Android feature-parity roadmap](parity-roadmap.md): the application menu
and the informational surfaces behind it. It is delivered by the
[`ios-app-information`](../openspec/changes/ios-app-information/proposal.md) change.

## Application menu

The status row's `Menu` control (`menu.open`) opens a small sheet with five entries, in
this order: settings, alarms, application log, change log, and information. Each entry's
button carries a `menu.*` identifier (`menu.settings`, `menu.alarms`, `menu.log`,
`menu.changelog`, `menu.information`), so a UI test reaches every surface by identifier.

- **Settings** opens the categorised settings screen (see [preferences.md](preferences.md)).
- **Alarms** opens the enlarged alarm radar, the same surface a long press on the small
  radar opens.
- **Application log**, **Change log**, and **Information** open the screens described below.

The menu is a hand-built sheet rather than a `UIAlertController` action sheet: `UIAlertAction`
has no accessibility identifier, so the entries could only be queried by their visible
label, not by the `menu.*` identifiers the tests use.

## Mode-appropriate controls

The controls beside the time slider follow the time mode:

| Mode | Controls |
| --- | --- |
| Realtime | start animation (`Animate`) |
| History | start animation and jump to realtime (`Now`, `realtime.goto`) |
| Animation | stop animation (`Stop`) |

The jump to realtime is offered only in history; it selects the rightmost interval, which
is realtime. Stopping animation holds the interval it stopped on - which is realtime if the
playback had not yet taken its first step, and the historical interval otherwise.

## Application log

The log screen lists what `AppLog` recorded, oldest first, one line per entry as
`<timestamp>  <message>`. Recording is gated by the diagnostics setting, so a log with
diagnostics off is empty; the screen then shows an explicit empty state rather than
nothing. **Send for support** hands the whole log, as text, to the system share sheet,
which on a device offers Mail and Messages.

## Change log

The changes are read from `monitor/Resources/CHANGELOG.md`, which is shipped as an app
resource. The format is the file's own contract: one `## <version>` heading per release,
followed by `- ` bullets. Prose outside a heading is ignored, and a heading without a
bullet contributes no entry, so a missing or entryless file yields an empty state rather
than failing. The file lists releases newest first and the screen shows them in that order.

## Information and the update check

The information screen shows the app's name, the installed version and build
(`CFBundleShortVersionString` and `CFBundleVersion`), the project home, and the copyright.

The update check asks the App Store lookup API by bundle id for the version it offers and
compares it with the installed one. The comparison is numeric per version component, so
`1.10` is newer than `1.9`. It reports one of three outcomes:

- a newer version is available, naming the store's version;
- the installed version is up to date;
- the offered version is unknown.

The check is best-effort and silent when unknown: an unreachable store, an unreadable
answer, or a bundle id with no listing shows no update line rather than guessing.

## Verifying

```bash
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:monitorTests/AppVersionTests \
  -only-testing:monitorTests/ChangeLogTests \
  -only-testing:monitorTests/ApplicationLogContentTests \
  -only-testing:monitorTests/AvailableVersionTests \
  -only-testing:monitorTests/InformationContentTests \
  -only-testing:monitorTests/AppInformationScreenTests \
  -only-testing:monitorTests/ViewControllerModeControlTests \
  -only-testing:monitorTests/LocalizationTests \
  -only-testing:monitorUITests/monitorUITests/testTheMenuOpensEveryEntry \
  -only-testing:monitorUITests/monitorUITests/testTheRealtimeControlAppearsInHistoryAndReturnsToRealtime \
  -only-testing:monitorUITests/monitorUITests/testTheAnimationControlMatchesTheMode \
  CODE_SIGNING_ALLOWED=NO
```

`ChangeLogTests` includes a check that the shipped `CHANGELOG.md` parses itself, and
`LocalizationTests` audits that every new label resolves from the catalog.
