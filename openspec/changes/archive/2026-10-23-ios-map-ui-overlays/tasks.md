# Tasks

> Prerequisite: this change builds on the rendering path delivered by `ios-map-rendering` (a pure render plan materialised as polygon overlays and annotation views) and on the region, grid, and time-model plumbing delivered by `ios-data-modes`. It introduces the manual slice of `location-handling` and the aggregation slice of `proximity-alerts`; the device-location and alerting behaviour stay with their own phases.

## 1. Retire the count threshold

- [x] 1.1 Remove the threshold from the request-building surface: drop the in-memory placeholder in `ViewController`, the settings-facing normalisation API on `Parameters`, and the threshold default, while keeping the provider protocol's positional argument as a constant at the call site; verified by a unit test asserting the grid request still carries the argument in the reference's position and by a compile of every `Parameters` copy helper.
- [x] 1.2 Delete the threshold-only tests and fold any still-meaningful case (a non-grid source requesting without a grid size) into the grid-gating tests; verified by `xcodebuild test` passing with the threshold suite removed.

## 2. Real settings behind the chrome

- [x] 2.1 Add persisted `region`, `intervalDuration`, and `historicTimestep` settings with registered defaults matching today's behaviour (Europe, 60 minutes, and the current history step) and value sets from the reference; verified by unit tests for defaults, persistence across a reload, and rejection of a value outside the set.
- [x] 2.2 Feed the interval duration and history step from the settings into the time model and the request, replacing the type defaults, and observe changes so an edit applies without relaunch; verified by unit tests that a changed duration reaches the request parameters and reshapes the slider's history range.
- [x] 2.3 Feed the region setting into the request parameters and expose the active region's display name; verified by unit tests that each region value produces the expected request parameter and name.

## 3. Manual location

- [x] 3.1 Add a location source protocol exposing the current location and publishing changes, with a manual implementation backed by persisted coordinates; verified by unit tests that set coordinates, read them back, and observe exactly one update per change.
- [x] 3.2 Persist the manually set location and the active location mode with defaults that leave a fresh install without a location; verified by unit tests for persistence and for "no location" before anything is set.
- [x] 3.3 Set the location by long-pressing the map, replacing any previous position; verified by a unit test on the gesture's coordinate mapping and a UI test that a long press changes the drawn marker's position.
- [x] 3.4 Draw an own-location marker while a location is known, updating it on change and drawing nothing when none is known; verified by unit tests on the marker's content and a visual check in the simulator.
- [x] 3.5 Centre the map on the current location on request, leaving the map unchanged when no location is known; verified by unit tests for both cases.

## 4. Radar aggregation (pure)

- [x] 4.1 Implement range rings and direction sectors with the reference's fixed geometry (10, 25, 50, 100, 250, and 500 km; eight equal sectors); verified by unit tests asserting the ring boundaries and that the sectors cover the full circle equally.
- [x] 4.2 Aggregate strikes into sectors, recording each sector's closest strike distance and age, and defining distance from the current location rather than the sector centre; verified by unit tests porting the reference's cases for in-sector strikes, competing distances, and strike age.
- [x] 4.3 Apply the alert interval as the aggregation window, independently of the displayed interval, over realtime data only; verified by unit tests that activity outside the window is ignored, that a longer display interval does not widen the window, and that non-realtime data yields no activity.
- [x] 4.4 Report the aggregation states (no location, outside data area, no data, activity) and the closest-strike summary with its direction and distance; verified by unit tests for each state and for the summary with and without any strike.
- [x] 4.5 Confirm the aggregation reports every ring and sector, including empty ones, so the radar can draw a complete face; verified by a unit test counting the reported sectors and rings.

## 5. Chrome content (pure)

- [x] 5.1 Build the legend content: one entry per colour section with its colour and age range, plus the region name, grid baseline, and local region size when a local region is active; verified by unit tests over several schemes, regions, and grid sizes.
- [x] 5.2 Build the histogram content from the result's histogram values and the displayed period, mapping values to bins and their colour sections; verified by unit tests for a typical period, an empty period, and a period whose length is not a whole number of bins.
- [x] 5.3 Build the radar content from the aggregation: sector fills coloured by closest-strike age, ring labels in the active measurement unit, and the state to present; verified by unit tests for an active radar, each empty state, and label formatting in both units.
- [x] 5.4 Build the data-area overview content: the data area's extent and cell size, the visible map rect as a box within it, and the zoom level, or nothing when there is no data area; verified by unit tests including a viewport fully inside, partly outside, and a result with no data area.

## 6. Chrome views and layout

- [x] 6.1 Add the legend view, drawing its content and reporting taps; verified by a visual check at two schemes and by a UI test that a tap opens quick settings.
- [x] 6.2 Add the quick-settings dialog as a sheet over the map with the region, interval duration, historic timestep, data source, colour scheme, map mode, and fade entries, each read from and written to the settings store; verified by a UI test that every entry is present, that a change applies to the map without leaving it, and that the map is still there when the dialog closes.
- [x] 6.3 Add the data-area overview view; verified by a visual check that it shows the area, the viewport box, and the zoom level, and that it disappears for a result without a data area.
- [x] 6.4 Add the histogram view with tap-to-zoom-out to the data area; verified by a visual check and a UI test that a tap changes the map's visible region to the data area.
- [x] 6.5 Add the alarm radar view with its states, tap-to-centre, and long-press to open the enlarged radar; verified by UI tests for the tap and the long press and by a visual check of the states.
- [x] 6.6 Lay the chrome out in the reference's corners (legend top-left, radar bottom-left, overview above the histogram bottom-right, histogram above the time slider) without disturbing the status row or the mode controls; verified by a visual check on the smallest supported screen size.

## 7. Histogram from the provider

- [x] 7.1 Parse the grid response's histogram into the result and expose it to the chrome, leaving a result without a histogram empty rather than failing; verified by a parser test using a fixture with and without the histogram, and by a test that no separate request is issued for it.
- [x] 7.2 Confirm the non-grid source path reports no histogram and still renders; verified by a test that a non-grid result leaves the histogram view empty.

## 8. Wiring and integration

- [x] 8.1 Present the chrome from the displayed result, the active settings, the current location, and the map's visible rect, refreshing the affected components when any of those changes; verified by unit tests that a result, a setting change, a location change, and a pan each refresh the right components.
- [x] 8.2 Route the radar's tap through the location source's centring and leave the radar's state intact when it cannot centre; verified by a unit test for both cases.
- [x] 8.3 Confirm the retired threshold changes nothing a user sees: with default settings the app issues the same request as before the change and renders the same activity; verified by a test comparing the request parameters before and after the retirement.

## 9. Documentation

- [x] 9.1 Add a capability page documenting the chrome components, their content rules, the radar geometry and window, and the manual-location path, with the reference values; verified by reading it against the code for every documented threshold and value.
- [x] 9.2 Remove the count-threshold section from `docs/data-modes.md` and note the provider argument that remains; verified by a search showing no stale threshold references in the delivered documentation.
- [x] 9.3 Update the parity roadmap: mark the phase, note the manual-location slice in `location-handling`, record `proximity-alerts` as partially delivered, and record the location phase as device location and permissions only; verified by reading the roadmap against the change's capabilities.

## 10. Verification

- [x] 10.1 Run the full suite and `openspec validate ios-map-ui-overlays --strict`; verified by both passing with no new warnings.
- [x] 10.2 Run the app in the simulator with a manually set location: set the location by long press, confirm the marker, the radar's active state against live realtime data, tap-to-centre, the enlarged radar, the histogram, the legend, and the overview; verified by a screenshot of each.
- [x] 10.3 Confirm each quick setting applies without leaving the map and survives a relaunch; verified by changing each entry and relaunching once.

## Workflow follow-up

- Correct the `data-modes` purpose sentence, which still names threshold selection, when this change is archived; the requirement itself is removed by this change's delta, and the instruction for an existing capability is to edit that sentence in the main spec directly.

## Fixes after verification

Both were found by using the delivered screens and corrected in place, with unit
tests where the geometry is testable.

- Histogram: the plot drew every value up from the baseline instead of joining one
  cell's top to the next, so the line never connected. `HistogramPlot.segments`
  now joins neighbouring tops, coloured by the older cell, and is covered by
  tests over the plot geometry.
- Base-map wash: the wash was sized to the visible map rect, so MapKit composited
  it from tiles rendered at different times while the map moved: zooming out
  showed rectangular patches of wash and areas that were not dimmed at all. It is
  now one overlay covering the whole map (`ActivityRenderPlan.dimMapRect`) and is
  kept on the map while it is unchanged.
