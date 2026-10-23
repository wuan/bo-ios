# Design

## Context

See `proposal.md` - Why. What exists to build on:

- `AlertAggregator` (`monitor/alerts/AlertAggregation.swift`) already produces, for realtime data: `AlertActivity.ranges` (ring boundaries 10, 25, 50, 100, 250, 500 km), per-sector cells with `strikeCount` and `latestStrikeTimestamp`, per-sector `closestStrike` (direction label, distance in km, age in seconds), and the overall `closest`. The alert interval is fixed at 600 seconds.
- `RadarContentBuilder` turns that into the radar's content; `AlarmRadarView` draws it and reports its state through its accessibility value.
- `SettingsKey` already has `alertEnabled` (default `true`, matching the reference's `alarm_enabled` default) and `measurementUnit`; the settings store registers defaults, observes single keys, and has a test that every key has a default.
- The reference (`bo-android`): `AlertHandler` gates on `alarm_enabled`, compares the closest strike against `notification_distance_limit` (default 50) and `signaling_distance_limit` (default 25), signals when the newest strike inside a limit is newer than the last signalled timestamp plus `signaling_suppression_time` (default 0 minutes), notifies when the newest strike inside the notification limit is newer than the last notified timestamp, and broadcasts the alert result. Vibration strength defaults to 3, sound to the system default.

## Goals / Non-Goals

**Goals:**

- Turn the aggregation into a decision with the reference's gates, limits, and suppression.
- Keep the decision testable without sound, haptics, or a notification centre.
- Report the alert state so the radar can distinguish a warning from activity in range.

**Non-Goals:**

- Background monitoring, periodic background fetching, and a persistent monitoring notification: those stay with the background phase. This change evaluates what the app fetches while it is in the foreground.
- The full preferences screen: the Phase 7 work adds the labelled controls. This change adds the settings and the behaviour behind them.
- Changing the aggregation, its geometry, or its window.

## Decisions

**One monitor with the effects behind ports.** `ProximityAlertMonitor` holds only the decision; the notification and the signal arrive through `AlertNotifying` and `AlertSignalling`, injected. Alternative considered: calling `UNUserNotificationCenter` and `AudioServices` directly from the monitor. Rejected because the boundary cases that matter (limits, suppression, dedup) would then only be observable through system side effects.

**The limits are ring boundaries.** The settings offer the radar's own ring edges (10, 25, 50, 100, 250, 500 km), so "within a limit" means whole rings inside it and no partial-ring arithmetic is needed. The newest strike inside a limit is the greatest `latestStrikeTimestamp` among the cells of those rings, which the aggregation already records; the reference walks the raw strikes for the same value.

**Suppression and dedup key on strike time, not wall-clock time.** A signal is due when the newest strike inside the signalling limit is newer than the strike that last signalled, plus the suppression time; a notification is due when the newest strike inside the notification limit is newer than the strike last notified. Alternative considered: a wall-clock timer. Rejected because it would make the decision depend on how often the app polls, and would be untestable without a clock.

**The state is reported, not derived twice.** The monitor reports `.active(closestStrike)` while the closest strike is inside the notification limit and `.cancelled` otherwise - including when alerts are off, no location is known, or the data is not realtime. The radar keeps its own states from the aggregation (activity, no activity, no location, outside data area) and additionally marks an active alert, so the two questions - "is there activity in range" and "is the user being warned" - stay separate, as they are in the reference.

**The monitor is evaluated where the reference evaluates it.** On a new result and on a location change, not on every chrome refresh: those are the two moments the answer can change.

**Vibration strength 0 means off.** The reference stores 0...30 milliseconds of vibration; iOS has haptic intensity rather than duration, so the stored value maps to an intensity of `0.1...1.0` at the top of the range and 0 disables the haptic. The deviation is a strength mapping, not a setting.

**The sound setting names a sound; empty means no extra signal sound.** The reference treats an empty sound as the system default notification sound. On iOS the notification already carries the system sound, so an empty setting only means the *signalling* path adds no sound of its own; a stored value is played as a system sound. Recorded as a deviation with its reason.

**Authorization follows the alert switch, not the launch.** The notifier requests notification authorisation when alerts are switched on; a refusal silently drops notifications while the state reporting and the signals keep working. Asking at launch instead would put a system prompt in front of a user who has not asked for alerts, and would make every unrelated test run meet the prompt.

## Risks / Trade-offs

- [A notification refusal is invisible] → the alert state still reaches the radar and the signals still fire, so the feature degrades rather than disappearing; the refusal is recorded as a residual when it can only be observed by hand.
- [Sound and haptics cannot be observed in the simulator] → the decision is unit-tested through stub ports; the audible and felt effects are a device check, recorded as a residual the way the earlier phases recorded theirs.
- [Deriving the newest strike inside a limit from per-cell timestamps misses a strike hidden behind a nearer one in the same cell] → the aggregation records the cell's own latest timestamp, so only sub-cell ordering is lost; the reference's per-strike walk is the authority the difference is measured against.
- [Alerts default to on, as in the reference] → a fresh install notifies only once a device location exists and a strike actually falls inside the limit, and the switch is in the settings store from this change on.

## Migration Plan

No stored data changes shape: the existing `alertEnabled` keeps its `true` default and the new keys default to the reference's values (limits 50 and 25 km, suppression 0, vibration 3, no sound). Rollback is the reverse code change; the added keys are inert. The `proximity-alerts` sketch loses the requirements this change delivers, and the roadmap records the phase.
