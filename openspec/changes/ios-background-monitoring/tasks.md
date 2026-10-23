# Tasks

> Prerequisite: this change builds on the alert decision delivered by `ios-proximity-alerts` (`ProximityAlertMonitor`, the alert ports, and the alert settings), on the `DataProviderCoordinator` and its event stream, and on the `BackgroundLocationDisclosure` seam. The decision, the aggregation, and the ports are unchanged; this phase drives them from outside the foreground.

## 1. Background query period

- [x] 1.1 Add `backgroundQueryPeriod` to `SettingsKey` with a registered default of `off` (`0`) and a checked accessor that accepts only the offered values and treats anything else as `off`; add the values to `SelectableSettings` so the setting is a selectable one, with names `off`, `1 min`, `2 min`, `5 min`, `10 min`, `15 min`, `30 min`, `60 min`, and `120 min`. Verify by unit tests for the default, persistence across a store reload, each accepted value, and a stored value outside the set falling back to `off`.

## 2. Scheduling seam

- [x] 2.1 Add the `BackgroundMonitoringScheduling` port (`register`, `submit(after:)`, `cancel`) and a `BGTaskScheduler`-backed implementation, plus a recording stub for tests, following the shape of the existing location and alert ports. Verify by a unit test that the port's consumer submits with the configured period and cancels when monitoring stops.
- [x] 2.2 Register the background task identifier at launch and add `UIBackgroundModes` (`fetch`, `location`) and `BGTaskSchedulerPermittedIdentifiers` to `monitor/Info.plist`. Verify by a test that the identifier in the plist matches the code constant, and by a simulator launch showing no `BGTaskScheduler` registration error in the console.

## 3. The background monitor

- [x] 3.1 Implement the background monitor: gate on `alertEnabled && backgroundQueryPeriod > 0`, on each wake-up fetch the current realtime interval through the shared `DataProviderCoordinator`, and evaluate the shared `ProximityAlertMonitor` on the result. Verify by unit tests with a stub provider and scheduler for the gating (alerts off, period off, both on), a fetch-and-evaluate on wake-up, and no fetch when monitoring is disabled.
- [x] 3.2 Persist the monitor's notification and signal watermarks in the settings store and read them back, so a strike notified in one process is not notified again after a relaunch. Verify by unit tests that a second monitor over the same store does not re-notify for the same strike, and that a newer qualifying strike does.

## 4. Notification readiness and background location

- [x] 4.1 Request notification authorisation when monitoring becomes enabled (alongside the existing foreground request), so a background alert can be delivered. Verify by a unit test that enabling monitoring asks the notifier once, and that with authorisation granted a qualifying background strike notifies.
- [x] 4.2 Request background location authorisation behind `BackgroundLocationDisclosure` when monitoring is enabled in a device-backed mode, and request nothing in the manual mode. Verify by unit tests that the disclosure is presented before the request while it is due, that the request is made after acknowledgement, and that the manual mode asks for nothing; record the simulator permission prompt as a screenshot.
- [x] 4.3 Update `docs/location-handling.md` for the background request and `docs/proximity-alerts.md` for the background path. Verify by reading each against the code for the request site and the alert path it describes.

## 5. Lifecycle and restoration

- [x] 5.1 Schedule through the monitor when the scene enters the background and cancel when it returns to the foreground, passing it the current period. Verify by unit tests over the scene hooks with the stub scheduler for schedule-on-background and cancel-on-foreground.
- [x] 5.2 Register the task and re-submit it at launch, and re-submit it from the task handler while monitoring remains enabled. Verify by a unit test that a launch with alerts enabled and a period set schedules, and that a launch with either disabled does not.

## 6. Documentation and the roadmap

- [x] 6.1 Add `docs/background-monitoring.md`: the gating rule, the period and its values, the scheduling and its latency caveat, notification readiness with the no-persistent-notification deviation, the background-location request, the lifecycle transitions, and restoration. Verify by reading it against the code for every value and deviation it states.
- [x] 6.2 Update `docs/parity-roadmap.md`: record this phase as delivered by this change and delete the consumed `docs/parity-capabilities/background-monitoring.md` sketch. Verify by reading the roadmap against the change's capability and by every relative link in the document resolving to a file that exists.

## 7. Verification

- [x] 7.1 Run the full suite and `openspec validate ios-background-monitoring --strict`. Verify by both passing with no new warnings.
- [ ] 7.2 Simulator check: with a device location mode, background location granted, alerts on, and a short period, background the app, then confirm a qualifying strike is delivered as a notification and that no persistent monitoring notification is shown. Verify by a screenshot of the delivered notification.
- [x] 7.3 Record the checks that need a device and the platform latency caveat as a residual, naming what was observed and what was not. Verify by the recorded note matching what was actually run.

## Residuals

The monitor's gating, scheduling, wake-up, dedup, and background-location request
are covered by unit tests, and the task identifier and background modes are
asserted against the app's `Info.plist`. Still outstanding for task 7.2:

- A background wake-up actually firing with live data was not observed. The
  simulator does not reliably run a `BGAppRefreshTask` on demand, so whether a
  qualifying strike arrives as a notification with the screen off needs a device
  or a data-dependent simulator run.
- The delivered notification banner was not observed for the same reason.
- The platform's worst-case scheduling latency is not observable from tests:
  `BGAppRefreshTask` is best-effort, so the period is a requested cadence and the
  delay is a property of the system. This is recorded, not solved, in
  `docs/background-monitoring.md` and `docs/parity-roadmap.md`.

## Workflow follow-up

- On archive, move this change's roadmap row to its archive link, sync the `background-monitoring` delta, and check the capability purpose for wording this phase makes stale.
