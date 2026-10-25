# Proposal

## Why

The data-area overview (the small box above the histogram) is always drawn, at a fixed
130 by 90 points. In the reference it is a diagnostics aid: Android's `RegionView` is
visible only while the diagnosis preference is on, and it resizes itself from the map's
latitude and longitude deltas so the drawn area keeps the map's proportions. On iOS the
overview is permanent chrome competing with the histogram and legend for space, and its
fixed shape misrepresents the visible extent when the map is wider or taller than the
2:1-it-assumes box.

## What Changes

- Show the data-area overview **only while the diagnostics setting is on**, hiding it and
  the space it takes otherwise, and following a change to the setting without a relaunch.
- **Size the box from the visible map extent's ratio**: its height is the width scaled by
  the visible extent's latitude span over its longitude span, clamped to a usable range so
  an extreme extent cannot collapse or balloon the panel.
- Update the `map-ui-overlays` spec and `docs/map-ui-overlays.md` to record the gate and
  the sizing.

## Capabilities

### New Capabilities

<!-- None. -->

### Modified Capabilities

- `map-ui-overlays`: the data-area overview is shown only while the diagnostics setting is
  on, and its box is sized from the visible extent's latitude-to-longitude ratio.

## Impact

- `monitor/chrome/DataAreaOverviewContent.swift`: the builder takes the diagnostics setting
  and returns no content while it is off; the content carries the box's ratio.
- `monitor/mapview/view/DataAreaOverviewView.swift`: the drawn height follows the ratio.
- `monitor/ViewController.swift`: passes the setting in and refreshes the overview when it
  changes.
- `docs/map-ui-overlays.md`: the overview section gains the gate and the sizing rule.
- Tests in `monitorTests/` (the builder's gate and ratio, the view's size) and the chrome
  controller tests, whose setup turns diagnostics on for the overview cases.
