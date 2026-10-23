# Tasks

> Prerequisite: this change builds on the aggregation delivered by `ios-map-ui-overlays` (`AlertAggregator`, `AlertGeometry`, the radar's content and view) and on the settings store. The aggregation, its geometry, and its window are unchanged; this change adds the decision that turns them into a warning.

## 1. Alert settings

- [x] 1.1 Add `notificationDistanceLimit` (default `50`), `signalingDistanceLimit` (default `25`), `signalingSuppressionTime` (default `0`), `alertVibrationSignal` (default `3`), and `alertSoundSignal` (default `""`) to `SettingsKey` with their registered defaults and checked accessors, the two limits taking their values from the radar's ring edges; verified by unit tests for each default, for persistence across a store reload, and for a stored value outside the value set falling back to the default.

## 2. The alert decision

- [x] 2.1 Add the `AlertNotifying` and `AlertSignalling` ports and implement `ProximityAlertMonitor` over them, gated on the stored enable switch; verified by unit tests that with alerts off nothing signals or notifies and the state is cancelled, and with alerts on the configured ports are used.
- [x] 2.2 Apply the two limits: signal through the signalling limit, notify through the notification limit, treat a distance equal to a limit as inside it, and notify without signalling for a strike between the limits; verified by unit tests on each boundary and on both sides of it.
- [x] 2.3 Key suppression and notification dedup on the strike that last caused them: a signal is due once the newest strike inside the signalling limit is newer than that strike plus the suppression time, and a notification once the newest strike inside the notification limit is newer than the one last notified; verified by unit tests for the suppression window active and elapsed, and for evaluating the same activity twice raising exactly one notification and one signal.
- [x] 2.4 Report the alert state as active with the closest strike's bearing and distance, or cancelled when nothing qualifies, alerts are off, no location is known, or the data is not realtime; verified by unit tests for the active state's content and for each cancelled cause.

## 3. The system effects

- [ ] 3.1 Implement `SystemAlertSignaller` (haptics at the stored strength, and a sound only when one is configured) and `LocalAlertNotifier` (a notification carrying the closest strike, asking for notification authorisation the first time alerts are on and a location is known); verified by unit tests over the stored strength and sound reaching the ports, by a simulator check that a notification is delivered when a qualifying strike arrives, and by recording the audible and haptic effect as a device check.

## 4. The radar's alert indication

- [x] 4.1 Extend the radar's content and view with the alert indication, leaving its activity states as they are; verified by unit tests that the content carries the alert while one is active and not once it is cancelled, and by a simulator check that the radar marks it.

## 5. Wiring

- [x] 5.1 Evaluate the monitor on each new result and on each location change, and re-read the settings when they change; verified by unit tests with stub ports that a strike inside the limit notifies and signals, that re-evaluating the same result does neither again, and that switching alerts off stops both without a relaunch.
- [x] 5.2 Confirm the alarm radar marks the alert while it is active and stops when it is cancelled, over a location change that takes the strike out of range; verified by an integration test with simulated strikes through the controller.

## 6. Documentation and the roadmap

- [x] 6.1 Add the proximity-alerts capability page: the decision and its order, the two limits with their defaults, suppression, the two signals, the alert state, and the two documented deviations from the reference (empty sound means no extra signal sound; vibration strength maps to haptic intensity); verified by reading it against the code for every limit, default, and deviation it states.
- [x] 6.2 Update `docs/map-ui-overlays.md` for the radar's alert indication and the settings table, and remove any claim that alerting is still to come; verified by a search showing no stale claim.
- [x] 6.3 Update `docs/parity-roadmap.md`: record this phase as delivered by this change, delete the consumed `docs/parity-capabilities/proximity-alerts.md` sketch, and shrink the background phase's list; verified by reading the roadmap against the change's capabilities and by every relative link in the document resolving to a file that exists.

## 7. Verification

- [x] 7.1 Run the full suite and `openspec validate ios-proximity-alerts --strict`; verified by both passing with no new warnings.
- [ ] 7.2 Run the app in the simulator with alerts on, a simulated location, and live realtime data: confirm a notification and the radar's alert mark when a strike lands inside the notification limit, and that the mark clears when the activity ages out; verified by a screenshot of each.
- [x] 7.3 Record the checks that need a device - the audible signal and the felt vibration - as a residual, naming what was observed and what was not; verified by the recorded note matching what was actually run.

## Residuals

The radar's alert mark is verified in the simulator against live data: with the
limits opened up, a location pressed into the live data area showed the mark
(`testAnActiveAlertMarksTheRadar`), and the run kept a screenshot. The live UI
tests that had been skipping now pass with the backend back.

Still outstanding for tasks 3.1 and 7.2:

- The notification banner was not observed. That the app asks for authorisation
  once alerts are on and a location is known is verified
  (`testAlertsAskForTheNotificationAuthorisationOnceALocationIsKnown`, with a
  screenshot of the prompt, run against a freshly installed app because the
  decision is per install; the test skips when it has already been answered), and
  the controller asks only with a location. Whether a strike qualifies is
  data-dependent, though, and the system-rendered banner never appeared to the UI
  test's queries in three attempts.
- The audible signal and the felt vibration need a device, not a simulator.

The mark's own live check is data-dependent too: it passed once with a screenshot
(`testAnActiveAlertMarksTheRadar`) and now skips when the live window has no
activity within range of the pressed point, which is what it was changed to do.

The alert's clearing is covered by `ProximityAlertMonitorTests` and by the
controller's integration test rather than by a live UI run, which cannot age the
same strike out of the window. What remains is recorded in
`docs/parity-roadmap.md` as the phase's open residual.

## Workflow follow-up

- On archive, move this change's roadmap row to its archive link, sync the `proximity-alerts` and `map-ui-overlays` deltas, and check the two capability purposes for wording that this phase makes stale.
