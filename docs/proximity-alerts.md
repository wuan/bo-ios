# Proximity alerts

Warning the user when lightning comes close: the decision that turns the alarm
radar's aggregation into a notification and a signal. This documents the
`proximity-alerts` capability delivered by the
[`ios-proximity-alerts`](../openspec/changes/ios-proximity-alerts/proposal.md)
change, on top of the aggregation the
[`ios-map-ui-overlays`](../openspec/changes/archive/2026-10-23-ios-map-ui-overlays/proposal.md)
change delivered.

## The decision

`ProximityAlertMonitor.evaluate(_:)` takes the aggregation the radar already
draws and returns the alert state, having notified and signalled what qualifies.
The order matters:

1. **Alerts off** - nothing is evaluated, nothing is emitted, the state is
   cancelled.
2. **No location, no realtime data, or a location outside the data area** - the
   aggregation reports it, and the state is cancelled.
3. **The closest strike against the signalling limit** - inside it, the
   configured sound and vibration are emitted, unless the suppression window
   holds them back.
4. **The closest strike against the notification limit** - inside it, a
   notification is raised, unless the same strike has already been notified, and
   the state is active.
5. **Otherwise** - the state is cancelled.

A limit of `0` switches that step off, which is the reference client's "off"
entry.

## Limits

Both limits take their values from the radar's own ring edges, so "inside a
limit" always means whole rings and no partial-ring arithmetic.

| Setting | Default | Values | Meaning |
| --- | --- | --- | --- |
| `notificationDistanceLimit` | `50` km | off, 10, 25, 50, 100, 250, 500 | The distance inside which a notification is raised |
| `signalingDistanceLimit` | `25` km | off, 10, 25, 50, 100, 250, 500 | The nearer distance inside which sound and vibration are emitted |
| `signalingSuppressionTime` | `0` min | off, 5, 15, 30 | How long after a signal the next one is held back |

A distance equal to a limit counts as inside it. A strike between the two limits
notifies without signalling, which is the ordinary case: the notification says
something came close, the signal says it is very close.

A stored value outside a setting's values falls back to that setting's default,
so a limit the radar has no ring for cannot take effect.

## Suppression and the once-only notification

Neither is a timer. A signal is due when the newest strike inside the signalling
limit is newer than the strike that last caused a signal, plus the suppression
time; a notification is due when the newest strike inside the notification limit
is newer than the strike last notified. The newest strike inside a limit is the
greatest of the per-cell `latestStrikeTimestamp` values in the rings that limit
covers, which the aggregation already records.

Keying on strikes rather than the clock means how often the app happens to
evaluate the data cannot change what the user hears: the same activity evaluated
again emits nothing.

## Signals and the notification

| Port | Implementation | Effect |
| --- | --- | --- |
| `AlertSignalling` | `SystemAlertSignaller` | Haptics at `alertVibrationSignal` strength (default `3`, range `0...30`), and a sound only when `alertSoundSignal` names a system sound |
| `AlertNotifying` | `LocalAlertNotifier` | A notification for the closest strike, carrying the system's own sound, composed in the active measurement unit |

Two deliberate deviations from the reference client, both narrow:

- The reference reads an empty sound setting as "the system default notification
  sound". On iOS the notification already carries that sound, so an empty
  `alertSoundSignal` means the *signalling* path adds no sound of its own; a
  stored value is played as a system sound.
- The reference stores a vibration duration (default 3 ms, up to 30). iOS has
  haptic intensity, so the stored value maps to an intensity of `0.1...1.0`
  across that range and `0` disables the haptic.

The notifier asks for notification authorisation once, the first time alerts are
on and a location is known - the moment the app could actually warn. Asking at
launch would prompt a user the app cannot warn yet; asking only when the switch
is toggled would leave a default install unauthorised until the preferences phase
provides that switch. A refusal drops the notification while the state reporting
and the signals keep working.

## The state and the radar

The monitor reports `.active(closestStrike)` with the closest strike's bearing,
distance, and age, or `.cancelled`. The radar keeps its own activity states and
additionally marks an active alert, so "there is activity in range" and "the user
is being warned" stay two separate answers; the mark clears when the alert is
cancelled while the activity is still shown.

## Settings

| Key | Default | Effect |
| --- | --- | --- |
| `alertEnabled` | `true` | Whether alerts are evaluated at all |
| `notificationDistanceLimit` | `50` | The notification limit in kilometres |
| `signalingDistanceLimit` | `25` | The signalling limit in kilometres |
| `signalingSuppressionTime` | `0` | The suppression window in minutes |
| `alertVibrationSignal` | `3` | The haptic strength, `0...30` |
| `alertSoundSignal` | `""` | A system sound to play, or none |

## Verifying

| Area | Test |
| --- | --- |
| Defaults, persistence, rejected values | `ProximityAlertMonitorTests` |
| Gating, limits, the boundary, suppression, dedup | `ProximityAlertMonitorTests` |
| The reported state and the configured signal | `ProximityAlertMonitorTests` |
| The decision through the controller, the radar's mark | `ViewControllerChromeTests` |

What cannot be observed in a simulator - the audible signal and the felt
vibration - needs a device and is recorded as a residual check.
