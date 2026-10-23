# Map UI overlays

The chrome that frames the lightning map: the legend, the quick-settings dialog,
the strike-rate histogram, the alarm radar, and the data-area overview. This
documents the `map-ui-overlays` capability delivered by the
[`ios-map-ui-overlays`](../openspec/changes/archive/2026-10-23-ios-map-ui-overlays/proposal.md)
change, together with the manual-location path it carries.

Each component is a plain `UIView` that draws one value type and owns no
policy, so the content is decided - and tested - in a builder:

| Component | View | Content builder |
| --- | --- | --- |
| Legend (top left) | `LegendView` | `LegendContentBuilder` |
| Quick settings | `QuickSettingsViewController` | reads and writes `SettingsStore` directly |
| Alarm radar (bottom left) | `AlarmRadarView` | `RadarContentBuilder` |
| Data-area overview (above the histogram) | `DataAreaOverviewView` | `DataAreaOverviewContentBuilder` |
| Histogram (above the time slider) | `HistogramView` | `HistogramContentBuilder` |

The status row, the time slider, and the animation control keep the places they
had; the chrome is laid out into the reference client's corners and is verified
on the smallest supported screen (the 375 x 667 pt class).

Tapping the legend opens the quick-settings sheet over the map, which writes the
same `SettingsStore` the map already observes. A change therefore applies behind
the sheet and the map is never left.

## Legend

`LegendContentBuilder.make(colorHandler:intervalDuration:regionName:region:dataArea:gridBaselineMetres:)`
produces one entry per palette section plus the region line and the grid line:

| Rule | Value |
| --- | --- |
| Entries | One per `ColorHandler.colors`, newest first (6 for the built-in schemes) |
| Minutes per section | `intervalDuration / numberOfColors` |
| Entry ages | Section `i` covers `[i * m, (i + 1) * m)` minutes; the last section is open-ended |
| Entry text | `< %d min` for a bounded section, `> %d min` for the open-ended one |
| Region name | `ViewController.activeRegionName`, from the `region` setting |
| Grid baseline | `rasterBaselength / 1000` km, e.g. `Grid: 10 km`; shown only when the source serves a grid |
| Local region size | The local data area's `scale` in degrees (`%d°`), shown only for the local region (`-1`) with a known data area |

## Quick settings

Each entry reads and writes one setting; there is no second model that could
diverge. The value sets reproduce the reference client:

| Entry | Setting | Values | Default |
| --- | --- | --- | --- |
| Region | `region` | Local `-1`, Global `0`, Europe `1`, Oceania `2`, N. America `3`, Asia `4`, S. America `5`, Africa `6`, C. America `7` | `1` (Europe) |
| Interval duration | `intervalDuration` | 30, 60, 90, 120, 240 minutes | `60` |
| Historic timestep | `historicTimestep` | 15, 30, 60 minutes | `30` (`History.defaultOffsetIncrement`) |
| Data source | `dataSource` | `rpc`, `http` | `rpc` |
| Colour scheme | `colorScheme` | `BLITZORTUNG`, `RAINBOW`, `TEMPERATURE` | `BLITZORTUNG` |
| Map mode | `mapMode` | `hybrid`, `satellite`, `standard` | `hybrid` |
| Map fade | `mapFade` | 0 - 100 percent | `55` |

The cluster and show-grid toggles of the reference client are omitted: the app
draws neither clusters nor grid lines, so they would be controls with no effect.
The query period and animation cadence stay with the preferences phase.

`SettingsStore.choice(for:)` and `SettingsStore.setChoice(_:for:)` are the
accessors for the three restricted settings. A value outside the setting's set
is rejected on write, and a stored value outside the set falls back to the
registered default on read; `SelectableSettings.allows(_:for:)` is the check.

The interval duration and the timestep reach the display through
`ViewController.applyIntervalSettings()`, which reconfigures `TimeModel`
(`TimeIntervalSelection.withDuration(_:history:)`, `TimeModel.configure`) and
refreshes the chrome. The region reaches the request through
`ViewController.applyRegionSetting()`.

## Strike-rate histogram

The grid response already carries a strike-rate histogram, so the overlay needs
no request of its own: `StrikeDataParser.histogram(from:)` reads the response's
`h` array into `Result.histogram`, and a result without one leaves the view
empty rather than failing.

| Rule | Value |
| --- | --- |
| Bin length | 5 minutes (`HistogramContent.minutesPerBin`) |
| Bins | `ceil(intervalDuration / 5)`, so an interval that is not a whole number of bins keeps its partial last bin |
| Values | `Result.histogram`, oldest bin first; missing bins read as zero, extra values are dropped |
| Bar colour | `ColorHandler.color(ageSeconds:intervalDuration:)`, the age of the bar's bin |
| Bar height | `count / max(counts, 1)` |
| Rate text | `max(counts) / 5` strikes per minute, e.g. `48.2/min` |

The bars' tops are joined into one polyline (`HistogramPlot.segments(for:in:)`),
as the reference draws it: each segment runs from one bin's height to the next
bin's, coloured by the older bin, so the plot reads as a strike-rate curve
rather than as strokes rising from the baseline.

A tap sets the map's region to the data area's extent.

## Alarm radar

The radar renders the pure aggregation in `AlertAggregator`, which takes the
realtime strikes, the data area, the location, and the reference time. Its
geometry and window are fixed, not settings:

| Rule | Value |
| --- | --- |
| Rings | 10, 25, 50, 100, 250, and 500 km from the location |
| Sectors | 8 equal sectors of 45 degrees |
| Sector labels | `S`, `SW`, `W`, `NW`, `N`, `NE`, `E`, `SE`, starting at bearing -180 degrees |
| Alert window | 10 minutes (600 s) ending at the reference time, independent of the displayed interval |
| Outlying inset | 0.2 degrees inside the data area's edges |
| Distance | Great-circle distance from the current location to the strike, not to the sector centre |
| Grid cells | A strike that covers a cell contributes the point of that cell nearest the location |
| Closest strike | Per sector, the nearest strike inside the alert window, with its age in minutes |
| Cell counts | Every ring of every sector is reported, including the empty ones (8 x 6 = 48 cells) |
| Summary | The nearest of the sectors' closest strikes, shown as `<direction> <distance> <unit>` |

The states, in the order they are decided: `noLocation` when no location is
known, `noData` when the data is not realtime or no result is available,
`outsideDataArea` when the location lies outside the data area, and otherwise
`activity` - which the radar presents as `active` when a sector holds a strike
within range and `inactive` when none does. A strike beyond the 500 km ring is
ignored. Sector fills are drawn **per ring**, from the activity that ring holds -
its newest strike's age decides the colour - so a strike in the outer ring leaves
the rings inside it clear; ring labels are shown in the active measurement unit,
with the unit name beside the outermost ring.

Tapping the radar centres the map on the current location (`centerOnLocation`);
when no location is known the map is left unchanged and the radar's state is
left intact. Long-pressing it opens the enlarged radar, which draws the same
content larger.

The radar also marks an **active alert**: `ProximityAlertMonitor` decides whether
the closest strike lies inside the notification limit and reports
`.active(closestStrike)` or `.cancelled`, which reaches the content as
`RadarContent.alert`. The view draws a red outer ring for it and says so in the
accessibility value, so a warning can be told apart from activity that is merely
in range - the activity states above are unchanged by it. The decision, its
limits, and its suppression are documented in
[`proximity-alerts.md`](proximity-alerts.md).

## Data-area overview

`DataAreaOverviewContentBuilder.make(grid:viewport:zoomLevel:)` returns `nil`
when the displayed result carries no data area, so the view disappears with no
further logic.

| Rule | Value |
| --- | --- |
| Extent | The area's longitude and latitude ranges, e.g. `-25.0..56.9` and `27.1..72.0` |
| Cell size | The grid's `longitudeDelta` and `latitudeDelta`, e.g. `0.1 0.1` |
| Viewport | The visible extent as fractions of the area (`x`, `y`, `width`, `height`), so `0...1` is the whole area; anything outside is clipped |
| Zoom level | `log2(360 / visible longitude span)` |

## Manual location

The `LocationSource` protocol exposes the current location and publishes changes;
`ManualLocationSource` satisfies it from persisted coordinates and needs no
location permission. The device-backed modes - network, GPS, and passive, with
their permission and disclosure rules and the two map choices - are documented in
[`location-handling.md`](location-handling.md), which also covers how the mode
selects the source.

| Rule | Value |
| --- | --- |
| Setting the location | A long press on the map, replacing any previous position; a device mode has nothing to set |
| Persistence | `manualLocationSet`, `manualLatitude`, `manualLongitude`; a fresh install has no location |
| Publication | `LocationSourceNotification.didChange`, posted once per change and not at all for an unchanged position |
| Marker | `OwnLocationMarker`, 14 pt at 100 percent, drawn by the app rather than by MapKit's user-location dot, so no location permission is needed for the manual path |
| Centring | `ViewController.centerOnLocation()`, which honours the keep-zoom choice and leaves the map unchanged without a location |

`mapView.showsUserLocation` stays off: the app draws its own marker from the
location source, so the marker is the same in every mode.

## Settings

| Key | Default | Effect |
| --- | --- | --- |
| `region` | `1` | The requested data region |
| `intervalDuration` | `60` | The displayed interval, the legend's age ranges, the histogram's bins, the radar's colour sections |
| `historicTimestep` | `30` | The history step behind the slider |
| `locationMode` | `manual` | How the current location is determined |
| `manualLocationSet` | `false` | Whether a manual location has been set |
| `manualLatitude`, `manualLongitude` | `0.0` | The manual position, once set |
| `showOwnLocation` | `true` | Whether the own-location marker is drawn |
| `ownLocationSize` | `100` | The marker's diameter as a percentage of 14 pt |
| `keepZoomOnCenter` | `false` | Whether centring keeps the current zoom level |
| `alertEnabled` | `true` | Whether proximity alerts are evaluated |
| `notificationDistanceLimit` | `50` | The notification limit in kilometres |
| `signalingDistanceLimit` | `25` | The signalling limit in kilometres |
| `signalingSuppressionTime` | `0` | The suppression window in minutes |
| `measurementUnit` | `metric` | Kilometres or miles for the radar's labels (1 mile = 1.609344 km) |

## Verifying

| Area | Test |
| --- | --- |
| Selectable settings, defaults, rejection | `SelectableSettingsTests` |
| Settings reach the time model and request | `ViewControllerSettingsTests` |
| Location source, persistence, updates | `ManualLocationSourceTests` |
| Long press, marker, centring | `ViewControllerLocationTests`, `monitorUITests.testLongPressSetsAndMovesTheOwnLocationMarker` |
| Ring and sector geometry | `AlertGeometryTests` |
| Aggregation, window, states, summary | `AlertAggregationTests` |
| Legend, histogram, radar, overview content | `LegendContentTests`, `HistogramContentTests`, `RadarContentTests`, `DataAreaOverviewContentTests` |
| Chrome presentation and interaction | `ViewControllerChromeTests` |
| Histogram parsing | `HistogramParsingTests` |
| Legend, quick settings, radar interactions | `monitorUITests` (chrome tests) |

```bash
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17'
openspec validate ios-map-ui-overlays --strict
```
