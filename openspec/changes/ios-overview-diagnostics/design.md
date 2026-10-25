# Design

## Context

See `proposal.md` - Why, and `specs/map-ui-overlays/spec.md` for the requirements.

- `DataAreaOverviewView` is a fixed-size (130 by 90 pt) custom view whose
  `intrinsicContentSize` is that constant. `ViewController` pins it to the trailing edge
  above the histogram with no size constraints, so the constant drives its layout.
- `DataAreaOverviewView.configure(content:)` already treats a `nil` content as "hide the
  view", and `DataAreaOverviewContentBuilder.make(grid:viewport:zoomLevel:)` returns `nil`
  when the result carries no data area. The builder is pure and takes the displayed
  result, the visible `ViewExtent`, and the zoom level.
- `SettingsStore` holds `diagnosticsEnabled` (off by default) and publishes per-key changes
  through `observe(_:)`; `ViewController` already observes several settings this way.
- Android's `RegionView` is the reference: its visibility is set from the
  `DIAGNOSIS_ENABLED` preference, and its `updateViewSize()` sets
  `height = width * (latitudeDelta / longitudeDelta)` of the map's bounding box, with a
  minimum height for its text.

## Goals / Non-Goals

**Goals:**

- One source of truth for both the gate and the ratio, in the pure content the view draws,
  so both are unit-testable without a view.
- The gate follows the setting live, like the app's other observed settings.

**Non-Goals:**

- The three text lines, the viewport box, the zoom line, and the corner placement are
  unchanged.
- No new setting: the existing diagnostics toggle is the gate.

## Decisions

### Decision: The builder takes the diagnostics flag and returns no content while it is off

`DataAreaOverviewContentBuilder.make(grid:viewport:zoomLevel:diagnosticsEnabled:)` returns
`nil` when the flag is false, reusing the existing "no content hides the view" path, and
`ViewController` passes `settings.bool(for: .diagnosticsEnabled)`.

- **Rationale**: it keeps the gate in one testable place and reuses the established
  mechanism rather than adding visibility logic to the view or the controller. The settings
  are already an input to the builder, so this does not widen its remit.
- **Alternative considered**: hiding the view in `ViewController.refreshOverview`. Rejected:
  it puts the same rule in a second place and leaves the builder able to produce content the
  screen must not show.

### Decision: The box ratio comes from the visible extent, carried on the content

`DataAreaOverviewContent` gains `aspectRatio` (height over width), computed as the visible
extent's `latitudeSpan / longitudeSpan`, falling back to the current 90/130 when the map has
not reported an extent. `DataAreaOverviewView.intrinsicContentSize` returns the fixed width
with `height = width * aspectRatio`, clamped to 72...240 pt, and `configure(content:)`
invalidates the intrinsic size so a ratio change relayouts.

- **Rationale**: this is Android's `updateViewSize` rule, and the visible extent is already
  passed to the builder, so the ratio costs nothing new. Keeping it on the pure content lets
  a unit test pin the number rather than the pixels.
- **Alternative considered**: sizing from the data area's own spans. Rejected in review: the
  visible extent is what the reference uses, and the viewport box drawn inside is a fraction
  of the visible extent, so the visible extent's ratio is the one that keeps the panel
  faithful to the map.
- **Clamp**: the text needs about four short lines, so a very flat extent would otherwise
  draw an unreadable sliver; the range keeps it legible without pretending to a ratio the
  screen cannot show.

## Risks / Trade-offs

- **A flatter or taller box changes the chrome's footprint** -> the clamp bounds it, and the
  panel is only present while diagnostics is on.
- **The overview is now hidden by default** -> intended: it is a diagnostics aid, and the
  histogram keeps its place; the docs and spec record the change so it is not read as a
  regression.

## Migration Plan

No stored data or API changes. Existing tests that expect the overview while rendering a
result set the diagnostics setting on in their setup; rollback is reverting the change.
