# Design

## Context

See proposal.md - Why for the defect. The current state that shapes the fix:

- `ViewController.render(result:)` calls `addDataArea(rasterParameters:)` for
  every result that carries grid parameters. That method builds a bare
  `MKPolygon` from the grid's four corners and adds it to the map.
- `ViewController.drawActivity()` removes and rebuilds the tile and strike
  overlays from the plan; `drawBaseMapDim(_:)` removes and rebuilds the wash.
  Both remove by overlay type. The data-area outline is a plain `MKPolygon`, so
  neither filter matches it and nothing else removes it either.
- `mapView(_:rendererFor:)` gives the tile, strike, and dim overlays their own
  cases; a plain polygon falls into the default case, which strokes it white at
  1 pt. That default case is what draws the boundary today.
- `drawActivity()` also runs on map movement
  (`redrawActivityIfVisibleAreaChanged`), not only from `render`.
- `MapRenderingTests.testDataAreaIsStillDrawn` renders once and asserts a single
  plain polygon, so it never sees outlines accumulate.
- The reference client draws the boundary from the *current* grid parameters on
  every draw (`StrikeListOverlay.drawDataAreaRect`), one at a time.

## Goals / Non-Goals

**Goals:**
- At most one data-area outline on the map, for the displayed result's grid.
- Removing it when the displayed result has no grid.
- The outline keeps its current appearance (white, 1 pt) and geometry.

**Non-Goals:**
- Changing the outline's styling, geometry, or when a data area applies.
- Moving the outline into the render plan, which stays activity-only.
- Changing tile, strike, count, or wash rendering.

## Decisions

### Give the outline its own overlay type

Add an `ActivityDataAreaPolygon` (an `MKPolygon`), built by
`ActivityOverlayBuilder` from the grid's bounds, with its own
`mapView(_:rendererFor:)` case that keeps the white stroke. Removal can then be
precise and the drawing is explicit where it was implied by the default case.

Alternatives considered:

- **Keep the bare `MKPolygon` and remove it in `addDataArea` before adding.**
  Rejected: it leaves the previous outline in place when a grid-less result is
  displayed, and it keeps the removal coupled to the add rather than to the
  result being drawn.
- **Match plain polygons by exclusion in the removal filters.** Rejected: every
  overlay filter in the file is type-based; an exclusion rule would be the odd
  one out and would mis-handle any future plain polygon.

### Replace the outline where the result is rendered

Remove the previous outline and add the current result's in
`render(result:)`, so one result produces one outline and a result without grid
parameters produces none.

Alternatives considered:

- **Replace it in `drawActivity()`, with the tiles and strikes.** Rejected:
  `drawActivity()` also runs on pan and zoom without a new result, so the
  outline would disappear until the next fetch even though the displayed
  result, and therefore its data area, had not changed.
- **Replace it in `drawBaseMapDim()`-style, keyed on a change of grid.** Rejected
  as unnecessary: a rendered result is already the point at which the data area
  can change, and `render` runs once per result rather than per animation tick.

### Leave the default renderer case in place

The default case stays for overlays the app does not classify. It is only
reachable for a plain polygon, and after this change the app adds none, so it
also keeps the file honest about what MapKit may hand back.

## Risks / Trade-offs

- [An outline is removed and re-added on every result, so it can flicker]
  → MapKit already rebuilds the tiles for every result; the outline is one
  four-point polygon and is added in the same pass, so it is no more visible
  than the tiles that change with it.
- [A future plain polygon would silently accumulate again] → The renderer
  default case is the only place a plain polygon is drawn; the new requirement
  and the accumulation test pin the boundary's behavior, so a new overlay would
  have to be given its own type to be removed like this one.
- [The outline's `rendererFor` case and the default case can drift apart]
  → The case is one line and the docs describe the stroke it produces.
