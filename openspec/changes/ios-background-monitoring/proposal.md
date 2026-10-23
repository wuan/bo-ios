# Proposal

## Why

The app warns about nearby lightning only while it is open. Phase 5 delivered the alert decision, but the aggregation, the limits, and the notify and signal ports are all driven from the foreground: close the app and nothing watches the data. Android keeps monitoring in the background through a periodic query, so an alert can still arrive with the screen off. Delivering that gap is what this phase is for.

## What Changes

- Add the **background monitoring service**: while alerts are on and a background query period is set, the app fetches fresh strike data on that cadence while it is not in the foreground and evaluates the alert decision, so a qualifying strike still notifies.
- Add the **background query period setting** with the reference client's values: off (the default), 1, 2, 5, 10, 15, 30, 60, and 120 minutes. Alerts alone do not enable monitoring; a period does.
- Drive the fetches through the platform's background scheduler (`BGTaskScheduler`) and background location, asking for the execution the fetches need. iOS may throttle or defer them, so the period is a requested cadence rather than a guarantee and the worst case is documented rather than solved.
- Hold the **notification readiness** background alerts need: while monitoring is enabled the app holds notification authorisation, asking for it if needed, so an alert produced with the app closed is delivered as a notification. There is no persistent service notification - iOS has no foreground-service equivalent - so the reference's persistent indicator is replaced by this readiness and a documented latency caveat, not translated literally.
- Make the **location** available with the screen off: request always-authorisation for a device location mode, behind the existing background-location disclosure, so the aggregation has a position to measure from.
- Implement **lifecycle transitions** and **restoration**: monitoring schedules when the app enters the background and stops scheduling when it returns to the foreground, and a relaunch or a system wake-up re-establishes it while alerts and a period remain enabled.

## Capabilities

### New Capabilities

- `background-monitoring`: running the alert decision while the app is not in the foreground - a configurable background query period, background fetching, notification readiness, background location, foreground/background lifecycle transitions, and restoration after relaunch.

### Modified Capabilities

None. The alert decision itself is unchanged; background monitoring only drives it from outside the foreground, from the settings and ports the app already has.

## Impact

- **Code**: a new background monitor that owns scheduling (a testable scheduler port plus a `BGTaskScheduler` implementation) and the fetch-and-evaluate work, reusing `DataProviderCoordinator` and `ProximityAlertMonitor`; `SettingsKey` gains `backgroundQueryPeriod` with its values and registered default; the app lifecycle (the scene delegate or the controller) schedules and stops monitoring; the device location source asks for always-authorisation behind `BackgroundLocationDisclosure`; `Info.plist` gains the location and fetch background modes and the permitted task identifier.
- **Docs**: a new `docs/background-monitoring.md`; `docs/proximity-alerts.md` and `docs/location-handling.md` note the background path; the parity roadmap records the phase and deletes the consumed `background-monitoring.md` sketch.
- **APIs/backends**: no backend change; monitoring reads the same data the app already fetches and the same settings it already stores.
- **Users**: users who leave the background period off see no change at all. Users who enable it get alerts while the app is not in the foreground, best-effort and subject to the system's scheduling.
