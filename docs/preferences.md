# Preferences

How the app's settings are organised, what each one does, and what a fresh install
uses. This documents the `preferences` capability delivered by the
[`ios-preferences`](../openspec/changes/ios-preferences/proposal.md) change.

## Categories

The settings screen renders `PreferencesModel`, one section per category. The
screen, the export, and this reference all read the same model, so they cannot
disagree about which settings exist.

| Category | What it holds |
| --- | --- |
| Map | The base map, the activity colours, and the own-location marker. |
| Animation | How fast playback steps and how long it pauses between cycles. |
| Data source | Where the data comes from and which region, interval, and history step it covers. |
| Location | How the current location is determined. |
| Alarm | The proximity alerts and their limits and signals. |
| Generic | Units, keeping the screen awake, and diagnostics. |
| Backup | Export, import, and reset. |

Credentials are offered only for the source that authenticates, so they are left
out of the data-source section while the JSON-RPC source is selected.

## Settings reference

The **Setting** column names the key as the app stores it. A **choice** accepts
only the values in the **Values** column; a **slider** accepts any integer in the
range its kind carries.

| Category | Setting | Kind | Values | Default |
| --- | --- | --- | --- | --- |
| map | mapMode | choice | hybrid, satellite, standard | hybrid |
| map | mapFade | slider | - | 55 |
| map | colorScheme | choice | BLITZORTUNG, RAINBOW, TEMPERATURE | BLITZORTUNG |
| map | showOwnLocation | toggle | - | true |
| map | ownLocationSize | slider | - | 100 |
| map | keepZoomOnCenter | toggle | - | false |
| animation | animationStepDuration | choice | 1, 2, 5, 10 | 1 |
| animation | animationCyclePause | choice | 0, 1, 2, 5 | 0 |
| data-source | dataSource | choice | rpc, http | rpc |
| data-source | serviceEndpoint | text | - | (empty) |
| data-source | region | choice | -1, 0, 1, 3, 7, 5, 2, 4, 6 | 0 |
| data-source | intervalDuration | choice | 30, 60, 90, 120, 240 | 60 |
| data-source | historicTimestep | choice | 15, 30, 60 | 30 |
| data-source | username | password | - | (empty) |
| data-source | password | password | - | (empty) |
| location | locationMode | choice | manual, network, gps, passive | manual |
| location | manualLatitude | decimal | - | 0 |
| location | manualLongitude | decimal | - | 0 |
| alarm | alertEnabled | toggle | - | true |
| alarm | backgroundQueryPeriod | choice | 0, 60, 120, 300, 600, 900, 1800, 3600, 7200 | 0 |
| alarm | notificationDistanceLimit | choice | 0, 10, 25, 50, 100, 250, 500 | 50 |
| alarm | signalingDistanceLimit | choice | 0, 10, 25, 50, 100, 250, 500 | 25 |
| alarm | alertSoundSignal | text | - | (empty) |
| alarm | alertVibrationSignal | slider | - | 3 |
| alarm | signalingSuppressionTime | choice | 0, 5, 15, 30 | 0 |
| generic | measurementUnit | choice | metric, imperial | metric |
| generic | keepScreenAwake | toggle | - | false |
| generic | diagnosticsEnabled | toggle | - | false |
| backup | export | action | - | - |
| backup | importSettings | action | - | - |
| backup | reset | action | - | - |

`(empty)` marks the empty string. The section and setting names shown to the user
come from `Localizable.xcstrings`, not from this table.

## Internal bookkeeping

Four keys are persisted but are not settings: `manualLocationSet`,
`backgroundLocationDisclosureShown`, `lastNotifiedStrikeTimestamp`, and
`lastSignalledStrikeTimestamp`. They record what the app has already done - whether
a manual location was set, whether the background-location explanation has been
shown, and which strike was last notified or signalled - so they are kept off the
screen, out of an export, and cleared by reset.

## Backup

- **Export** writes the user-facing settings as JSON. Credentials travel with the
  document only when the user picks the option that includes them; the default
  option leaves them behind.
- **Import** validates the whole document - the layout version, every key, every
  value's type, and whether a choice accepts the value - before it applies
  anything. A document with one bad value changes nothing and reports the failure.
- **Reset** returns every setting to the default in the table above. Credentials
  live in the Keychain rather than in the settings, so reset leaves them alone,
  and the diagnostics ring is cleared with the settings it belongs to.

## Removed settings

`mapScale` (default 75) was stored but never read: it stood for the reference
client's base-map scale factor, and MapKit renders the base map itself without one.
The `ios-preferences` change removed it; a value left behind by an earlier install
is ignored and cleared by reset.

## Verifying

```bash
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:monitorTests/SettingsStoreTests \
  -only-testing:monitorTests/SelectableSettingsTests \
  -only-testing:monitorTests/PreferencesModelTests \
  -only-testing:monitorTests/SettingsReferenceTests \
  -only-testing:monitorTests/PreferencesBackupTests \
  CODE_SIGNING_ALLOWED=NO
```

`SettingsReferenceTests` parses the table above and fails when it drifts from
`PreferencesModel` or `SettingsKey.defaultValues`.
