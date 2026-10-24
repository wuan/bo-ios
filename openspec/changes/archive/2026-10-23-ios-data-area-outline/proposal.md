# Proposal

## Why

The map draws a boundary rectangle around the displayed data area, but nothing
ever removes it. Every render leaves its own outline behind — one per polling
tick and one per grid/data-area change while zooming in and out — so the
outlines pile up as nested white rectangles that stay on the map.

The boundary is not described by any requirement, which is how the leak went
unnoticed: the rendering spec never mentions it, so nothing pinned down that
there should be exactly one.

## What Changes

- Specify the data-area boundary as map-rendering behavior: the map shows at
  most one outline, for the grid of the displayed result, replaced whenever a
  result is rendered, and none while the displayed result carries no grid.
- Make the outline an overlay type of its own, built alongside the other
  activity overlays, so it is replaced with them instead of being added and
  forgotten.
- Cover the boundary with tests: repeated renders leave exactly one outline, a
  result without grid parameters leaves none, and the outline still spans the
  grid's bounds.
- Document the boundary in `docs/map-rendering.md`, where it is currently only
  an aside.

## Capabilities

### New Capabilities
<!-- None: the change specifies and fixes existing behavior. -->

### Modified Capabilities

- `map-rendering`: gains a requirement for the data-area boundary — a single
  outline for the displayed result's grid, replaced on each render.

## Impact

- `monitor/ViewController.swift`: the data-area drawing and the overlay
  renderer.
- `monitor/mapview/view/ActivityOverlayBuilder.swift`: the outline's overlay
  type and builder.
- Tests: `MapRenderingTests`.
- Docs: `docs/map-rendering.md`.
- No change to the grid, the plan, the tiles, or the requests the app sends.
