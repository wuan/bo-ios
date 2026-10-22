# Data modes

How the iOS app chooses the time range and geographic extent of the data it
displays. This documents the `data-modes` capability delivered by the
[`ios-data-modes`](../openspec/changes/archive/2026-10-22-ios-data-modes/proposal.md) change.

## Modes

The display is always in one of three modes, held by `TimeModel`:

| Mode | Selected interval | Refresh cadence |
| --- | --- | --- |
| `realtime` (default) | The most recent interval | Every query period (60 s) |
| `history` | A user-selected point in the last 24 hours | When the selection changes |
| `animation` | Advances automatically through the history | One history step per tick |

A zero interval offset means realtime, so the mode follows directly from the
selected interval rather than being tracked separately.

## Time slider

`ViewController` carries a slider with one position per history step. The
rightmost position maps to a zero offset and therefore activates realtime; any
other position selects the interval ending at that point. `TimeIntervalSelection`
provides the mapping (`position(history:)`, `maxPosition(history:)`,
`withPosition(_:history:)`), so the control stays a plain integer range.

An **Animate** button starts animation playback; pressing it again stops and
holds the interval reached, and the user can resume manual selection. Realtime
is only re-entered by moving the slider to the rightmost position or by
returning explicitly.

## Status line

In realtime the status line shows the refresh countdown (`12/60 s`). A
historical or animated interval has no countdown of its own, so the status line
shows the start of the selected interval as a wall-clock time instead
(`@ 14:30`), computed as the interval end minus its duration.

## Defaults

| Setting | Default | Where |
| --- | --- | --- |
| Mode | `realtime` | `TimeModel()` |
| Interval duration | 60 minutes | `intervalDuration` setting, registered default |
| History range | 24 hours (1440 min) | `History.maxRange` |
| History step | 30 minutes | `historicTimestep` setting, registered default |
| Region | 1 (Europe) | `region` setting, registered default |
| Query period | 60 s | `ModeRefreshScheduler()` |
| Animation step | 1 s | `ModeRefreshScheduler()` |

The region, interval duration, and history step are persisted settings; the
values above are their registered defaults, so an untouched install behaves as
it did when `TimeIntervalSelection()` and `Parameters()` supplied them. See
[map-ui-overlays.md](map-ui-overlays.md) for the settings and the chrome that
edits them.

## Region and data-area rules

`LocalData` maps a region setting to request parameters and reproduces the
Android rules:

| Region setting | Behaviour |
| --- | --- |
| `local` (`-1`) | Uses the derived data area; without one, falls back to global |
| `global` (`0`) | Uses the derived data area when the grid size is finer than the local threshold; otherwise stays global with no data area |
| any other value | Used as-is, with no data area |

The data area is derived by quantizing the visible extent (`ViewExtent`): the
larger span is halved, rounded up to the 5-degree step, and accepted up to the
20-degree maximum. A larger extent is too big for a local area, so the region
falls back to global. Keeping the extent behind a plain value type keeps the
rules testable and leaves a location input point for Phase 4.

The grid geometry of the last received result (`GridParameters`) is remembered
so the area is only recomputed when the visible extent leaves it.

## Grid size

The grid size is chosen from the visible extent's larger span and clamped to the
supported range. The thresholds mirror the Android auto-grid buckets, expressed
in degrees rather than map zoom:

| Larger span | Grid size |
| --- | --- |
| < 3° | 5 km |
| < 16° | 10 km |
| < 45° | 25 km |
| < 90° | 50 km |
| ≥ 90° | 100 km |

The local/global boundary is the 25 km threshold (`LocalData.localRegionGridSizeThreshold`):
a global request with a finer grid and a known data area is upgraded to local,
and a global fallback raises the grid size to at least that threshold.

## Count threshold (retired)

Earlier versions carried a count threshold as a request parameter, but the app
never exposed a control for it and always sent the inactive value, so the
`data-modes` requirement for it was removed by the
[`ios-map-ui-overlays`](../openspec/changes/ios-map-ui-overlays/proposal.md)
change. The provider's grid method is positional and still expects that
argument, so requests keep carrying a constant in its place; nothing else about
the request or the results changes.

## Source capability

`Parameters.gatingGrid(on:)` consults the active provider's
`DataProviderCapabilities`: a source that cannot serve grid data (the
Blitzortung HTTP source) receives no grid size, so no grid request is issued, while the JSON-RPC source carries the selected grid size. See
[data-providers.md](data-providers.md) for the capability table.

## Verifying

The model rules are covered by unit tests:

| Area | Test |
| --- | --- |
| Time stepping and clamping | `TimeIntervalSteppingTests` |
| Slider position mapping | `TimeSliderMappingTests` |
| Mode transitions | `DataModeTests` |
| Extent adapter | `ViewExtentTests` |
| Region/data-area/grid selection | `LocalDataTests` |
| Grid gating | `GridGatingTests` |
| Mode-driven refresh | `ModeRefreshSchedulerTests` |
| Slider control | `monitorUITests.testTimeSliderRightmostActivatesRealtime` |

```bash
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```
