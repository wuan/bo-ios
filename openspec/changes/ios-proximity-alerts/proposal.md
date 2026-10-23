# Proposal

## Why

Phase 3 delivered the sector/range aggregation the alarm radar draws, but nothing watches it: the app can tell the user where lightning was, never that it is coming close. Android gates this on an enable switch, compares the closest strike against a notification limit and a nearer signalling limit, emits a sound and a vibration, suppresses repeats for a configurable time, and reports an active or cancelled alert. Delivering that is what turns the aggregation into the warning the capability is named for.

## What Changes

- Add the **alert monitor**: it evaluates the aggregation's closest strike against the stored limits, raises a notification, emits the sound and vibration signals, suppresses repeats, and reports an active or cancelled alert with the closest strike's bearing and distance.
- Add **enable gating**: while alerts are off, no monitoring, no signal, and no notification; the state reports cancelled.
- Persist the **alert settings** with the reference's defaults: enabled, the notification limit (50 km), the signalling limit (25 km), the suppression time (0 minutes), the vibration strength (3), and the sound (the system notification sound).
- Add the **signals**: a notification through the notification centre when a strike falls within the notification limit, and the configured sound and vibration when it falls within the nearer signalling limit. The suppression time governs how often a signal may repeat, independently of how often new strikes arrive.
- Add **alert-state reporting**: consumers see an active alert - with the closest strike's bearing and distance - and its cancellation, and the alarm radar marks an active alert so the user can tell a warning from mere activity in range.
- **Modify** `proximity-alerts` with those requirements, and `map-ui-overlays` so the radar's display covers an active alert.

## Capabilities

### New Capabilities

None. The aggregation this builds on is already specified in `proximity-alerts`.

### Modified Capabilities

- `proximity-alerts`: adds enable gating, the notification and signalling limits, the signals and their settings, suppression, and the reported alert state; the existing aggregation, geometry, window, states, and summary are unchanged.
- `map-ui-overlays`: the alarm radar's display gains the active-alert indication, so a warning is distinguishable from activity that is merely in range.

## Impact

- **Code**: `monitor/alerts/` gains the monitor and the ports it signals through (a notifier and a signaller, both injectable so the decision is testable without sound or a notification centre); `SettingsKey` gains the limit, suppression, sound, and vibration settings; `ViewController` feeds the monitor the aggregation it already builds and reflects the reported state on the radar; the notifier asks for notification authorisation when alerts are enabled.
- **Docs**: `docs/proximity-alerts.md` documents the decision, the limits, suppression, and the signals with the reference values; `docs/map-ui-overlays.md` records the alert indication; the parity roadmap records the phase and shrinks the alerts sketch.
- **APIs/backends**: no backend change; the monitor only reads the data the app already fetches and the settings it already stores.
- **Users**: users who leave alerts off see no change at all. Users who enable them get a notification, sound, and vibration when lightning comes within range, with repeats suppressed for the configured time.
