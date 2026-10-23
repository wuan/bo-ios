# Background monitoring

Running the proximity alert decision while the app is not in the foreground, so a
qualifying strike still reaches the user with the screen off. This documents the
`background-monitoring` capability delivered by the
[`ios-background-monitoring`](../openspec/changes/ios-background-monitoring/proposal.md)
change, on top of the alert decision the
[`ios-proximity-alerts`](../openspec/changes/archive/2026-10-23-ios-proximity-alerts/proposal.md)
change delivered.

## Gating

`BackgroundMonitor` runs only when the user has opted in on both switches:

```
alertsEnabled && backgroundQueryPeriod > 0
```

Alerts alone do not start background work; a non-off period does. With either
off, a wake-up does nothing and any pending request is cancelled, so a stray
system wake-up cannot do background work after the user turned it off.

## The query period

| Value | Meaning |
| --- | --- |
| `0` (default) | off; no background monitoring |
| `60` | 1 minute |
| `120` | 2 minutes |
| `300` | 5 minutes |
| `600` | 10 minutes |
| `900` | 15 minutes |
| `1800` | 30 minutes |
| `3600` | 60 minutes |
| `7200` | 120 minutes |

The values reproduce the reference client's background query periods. A stored
value outside the set reads as off. The full preferences screen is a later phase;
for now the setting is read by the monitor and has its registered default.

## Scheduling and its latency

The fetch is scheduled through `BGTaskScheduler` behind the
`BackgroundMonitoringScheduling` port: `BGTaskSchedulerScheduling` in the app, a
recording stub in tests. The task is registered before the app finishes launching
(`AppDelegate`), the handler is installed when the scene builds the monitor, and
each wake-up re-arms the next one. Nothing is asked for sooner than
`BackgroundMonitoring.minimumInterval` (60 s).

**iOS does not guarantee the cadence.** `BGAppRefreshTask` is best-effort: the
system may defer or skip a wake-up based on battery, usage, and background
budget. The period is therefore a requested cadence rather than a promise, and
the worst case is longer than it - a platform limit, not something this app can
solve. Background location keeps the position fresh for the evaluation; it does
not itself trigger a fetch.

On a wake-up the monitor fetches the current realtime interval through the same
`DataProviderCoordinator` the foreground uses (so a result also lands in the
shared cache) and evaluates the same `ProximityAlertMonitor`. The decision, the
limits, the ports, and the aggregation are unchanged.

The request is always **local**: the current position selects a data area
(`DataArea` at `LocalData.localDataScale`) and the request asks for the finest
supported grid (5000 m), so the evaluation sees activity around the position.
A global query is never issued - it has no position to bound it, and the backend
allows a global grid no finer than 25 km. With no position known there is nothing
to measure from, so the fetch does nothing and the decision would only report no
location.

## Notification readiness

While monitoring is enabled the app holds notification authorisation, asking for
it if it has not been decided, so a background alert can be delivered as a
notification.

There is **no persistent monitoring notification**: iOS has no foreground-service
equivalent to the reference client's ongoing notification. This is a deliberate
deviation, recorded in the parity roadmap's platform decisions - the readiness
request and the qualifying-strike notification are the only notification
behaviour background monitoring adds. One strike warns once: the monitor's dedup
watermarks are persisted, so a background evaluation and a later foreground one
share them (see [proximity-alerts.md](proximity-alerts.md)).

## Background location

The aggregation needs a position, so in a device-backed mode the app requests
background location authorisation for the same manager the device source uses.
The request goes through `BackgroundLocationPermission`, which asks only in a
device-backed mode and only once `BackgroundLocationDisclosure` has been
acknowledged; a manual location needs no permission, so monitoring still runs on
a fresh install with a hand-set position. `Info.plist` declares the `location`
and `fetch` background modes and the task identifier.

## Lifecycle and restoration

| Transition | What happens |
| --- | --- |
| Launch | The monitor registers the task, and schedules the next wake-up when monitoring is enabled (restoration) |
| Enter background | The next wake-up is scheduled |
| Return to foreground | The scheduled fetch is cancelled; the foreground refresh takes over |
| Wake-up | The interval is fetched, the decision evaluated, and the next wake-up re-armed |

## Settings

| Key | Default | Effect |
| --- | --- | --- |
| `backgroundQueryPeriod` | `0` (off) | The background cadence in seconds; off disables monitoring |

`backgroundQueryPeriod` is a selectable setting (`SelectableSettings`), so a value
outside the set reads as off; `alertEnabled` and the alert settings it depends on
are documented in [proximity-alerts.md](proximity-alerts.md).

## Verifying

| Area | Test |
| --- | --- |
| Period default, values, persistence, rejection | `BackgroundQueryPeriodTests` |
| Gating, submission, lifecycle, wake-up, dedup | `BackgroundMonitoringTests` |
| The declared task identifier and background modes | `BackgroundMonitoringTests` |
| Background location behind the disclosure, modes | `BackgroundLocationPermissionTests` |

What cannot be observed hermetically - a background wake-up actually firing with
live data, and the delivered notification banner - needs a device and is recorded
as a residual check. The iOS Simulator cannot stand in: `BGTaskScheduler` reports
`BGTaskSchedulerErrorDomain Code=1 "BGTaskScheduler is not available on this
platform."` there, so no `BGAppRefreshTask` can be submitted or fired. The alert
decision itself, including the delivered notification, is observed in the
simulator against the live backend; only its background trigger needs a device.
