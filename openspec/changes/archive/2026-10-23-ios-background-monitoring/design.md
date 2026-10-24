# Design

## Context

See `proposal.md` - Why. The pieces this phase composes already exist:

- `DataProviderCoordinator` holds the active provider, a cache, and an event stream, and rebuilds on a source change. `ViewController` drives it from a one-second timer and a `ModeRefreshScheduler`.
- `ProximityAlertMonitor` turns an `AlertAggregation` into the alert decision and keys notification/signal dedup on strike timestamps held in memory.
- `AlertAggregator` builds the aggregation from a `Result`, a data area, a location, and whether the interval is realtime.
- `DeviceLocationSource` requests only `whenInUse`; `BackgroundLocationDisclosure` is a ready seam that nothing calls yet.
- `SettingsStore` persists typed settings and observes changes; `SceneDelegate` builds the store, credential store, provider coordinator, and controller.
- `Info.plist` has no `UIBackgroundModes` and no background task identifier.

## Goals / Non-Goals

**Goals:**

- Run the existing alert decision from outside the foreground, on a configurable cadence, without changing the decision itself.
- Keep the scheduling and the system effects behind ports so the logic is testable without `BGTaskScheduler` or a device.
- Share dedup state between foreground and background so one strike produces one notification.

**Non-Goals:**

- A guaranteed always-on service. iOS does not offer one; the period is a requested cadence and the worst case is documented, not solved.
- Bundling the settings UI for the period. The full preferences screen is Phase 7; the period is a stored setting this phase reads, as the alert settings were in Phase 5.
- The home-screen widget. That is Phase 9; it may later reuse the same background fetch.

## Decisions

**1. Schedule with `BGTaskScheduler`, not location wake-ups alone.**
A `BGAppRefreshTask` wakes the app for a short fetch, which is exactly the work needed. Relying on significant-location changes would only wake a moving user, so a stationary user would never be checked. The task is registered at launch, submitted when the app backgrounds with monitoring enabled, and re-submitted when it runs. Alternative considered: a single `BGProcessingTask` (heavier, no refresh benefit here) and background `URLSession` (more moving parts for one small request).

**2. A `BackgroundMonitoringScheduling` port.**
The coordinator depends on a protocol - `submit(requestAfter:)`, `cancel()`, and a registration hook - with a `BGTaskScheduler` implementation in production and a recording stub in tests. The same shape the location and alert ports already use, so the decision and the gating are unit-tested without the scheduler.

**3. Reuse the provider coordinator and the alert monitor.**
A background wake-up requests the current realtime interval through the same `DataProviderCoordinator` and evaluates the same `ProximityAlertMonitor`; nothing about the fetch or the decision is reimplemented. The controller and the background task share one coordinator so a background result also refreshes the cache the foreground would use. The request is always **local**, bounded by a data area derived from the current position, at the finest supported grid (5000 m); a global query is never issued because it has no position to bound it and the backend allows a global grid no finer than 25 km, so it would be too coarse - and below that minimum it is refused outright rather than clamped. With no position there is nothing to measure from, so no request is made.

**4. Persist the dedup watermarks.**
`ProximityAlertMonitor`'s `lastNotifiedTimestamp` / `lastSignalledTimestamp` live in memory. A background task can run in a freshly launched process, so in-memory state would be lost and the same strike could notify again on the next launch. The watermarks are therefore stored in the settings store and read back by the monitor, so a strike that was notified in the background is not notified again when the app opens. Alternative considered: a single long-lived monitor instance - insufficient because the process may not survive.

**5. Enabling rule: `alertEnabled && backgroundQueryPeriod > 0`.**
This mirrors the reference client, where the background service runs when alerts are on and the background query period is not `off`. Alerts alone must not start background work; the user opts into the background cadence explicitly, and `off` is the default.

**6. Notification readiness, not a persistent notification.**
iOS has no foreground-service notification. While monitoring is enabled the app requests notification authorisation (if undecided) so a background alert can be delivered; there is no ongoing notification. This is the platform decision recorded in the roadmap, applied narrowly to the one requirement it affects.

**7. Request background location behind the disclosure.**
When monitoring is enabled in a device-backed mode, the app runs the always-authorisation request through `BackgroundLocationDisclosure.request(disclosing:requesting:)`, so the explanation is shown first while still due. A manual location needs no request; monitoring still runs with the manual position.

**8. Lifecycle lives with the scene.**
`SceneDelegate` already owns the shared coordinator and store, so it schedules on `sceneDidEnterBackground` and cancels on `sceneWillEnterForeground`, and the task handler re-submits itself. `AppDelegate` registers the task identifier at launch (required before the system can run it) and re-schedules on launch when monitoring is enabled.

## Risks / Trade-offs

- **The system may defer or skip a background refresh.** → The period is documented as a requested cadence and the worst-case latency is stated in `docs/background-monitoring.md`. This is a platform limit, accepted as the roadmap's background phase records.
- **A background fetch competes with the foreground timer and cache.** → Both go through the one `DataProviderCoordinator`, whose cache and freshness validator already suppress a duplicate request for the same parameters, so an extra wake-up does not double-fetch or double-render.
- **Battery and data use.** → Background work only runs when the user sets a non-off period; the shortest cadence (1 minute) is the user's explicit choice, matching the reference client.
- **Persisting the watermarks adds write traffic.** → Written only when a signal or notification is emitted, not on every evaluation.

## Migration Plan

No data migration: the new period setting has a registered default (`off`), so an existing install does not start background work on update. `Info.plist` gains `UIBackgroundModes` (`fetch`, `location`) and `BGTaskSchedulerPermittedIdentifiers`; no entitlements beyond what the app already has. A user who enables a period can disable it by returning the setting to `off`.

## Open Questions

None that affect the specs or the task breakdown. The achievable background latency is a property of the platform and is documented rather than decided here.
