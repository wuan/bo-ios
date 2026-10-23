# Design

## Context

See proposal.md - Why for the defect. The relevant current state:

- `GridParameters` (`monitor/data/GridParameters.swift`) stores the reported
  `x0`/`xd`/`xc` and `y1`/`yd`/`yc` and derives both cell centres
  (`getCenterLongitude`/`getCenterLatitude`) and geographic bounds
  (`longitudeStart`/`longitudeEnd`, `latitudeStart`/`latitudeEnd`) from them.
- `RasterElement` (`monitor/data/RasterElement.swift`) is the only caller of the
  cell-centre methods; it turns each `[x, y, count, age]` entry into a strike
  coordinate and stores the cell's deltas as its extent.
- The bounds feed `AlertAggregation.contains`, `LocalData.isOutside`, the
  data-area overview (`DataAreaOverviewContent`), the histogram zoom
  (`ViewController.histogramTapped`) and the drawn data-area outline
  (`ViewController.addDataArea`).
- The server's global query (`bo-srv-rs/src/service.rs` `build_grid_rows`,
  `global_grid_query`) numbers the global grid's offsets from the origin and
  writes rows as `-ry - 1`; the local query numbers them from the grid's
  north-western corner. Both responses report `x0 = x_min` and
  `y1 = y_max + y_delta`.
- The Android reference client overwrites `x0`/`y1` with `0.0` on the global
  response (`bo-android/.../provider/standard/JsonRpcData.kt`).

## Goals / Non-Goals

**Goals:**
- Global cells decode to their true coordinates.
- Bounded-grid decoding is unchanged.
- The reported bounds keep their geographic meaning for every existing consumer.

**Non-Goals:**
- Changing the request the app sends (method, arguments, or grid size).
- Changing tile geometry, colouring, or render culling.
- Modelling the server's per-request offset convention in the provider or
  payload, as the Android client does.

## Decisions

### Anchor cell centres, not the payload

Change `getCenterLongitude`/`getCenterLatitude` to use the anchor the grid's
backend uses, and leave `longitudeStart`/`latitudeStart` and the derived ends as
the reported geographic extent.

Alternatives considered:

- **Zero `x0`/`y1` in the response before parsing (Android parity).** Rejected:
  in this codebase the bounds are read by containment, the overview, the
  histogram zoom and the outline, so zeroing them would move the global data
  area to the south pole and origin instead of the world. Anchoring only the
  offset mapping fixes the defect without those regressions.
- **Plumb the request method into the parser.** Rejected: it would thread a
  transport concern through an otherwise provider-independent parser for a
  distinction the grid already expresses.

### Detect the anchor with the existing `isGlobal`

A world-spanning grid is already identified by `isGlobal` (`longitudeDelta *
longitudeCount > 350` and `latitudeDelta * latitudeCount > 170`), which the
aggregator and `LocalData` use. Reuse it: `isGlobal` selects the origin anchor,
everything else keeps the corner anchor.

Alternatives considered:

- **An explicit flag set by the provider.** Rejected: the only global response
  comes from the global method, whose grid is always world-spanning, so the flag
  would duplicate the span test and add plumbing.

### Keep the derivation testable at the geometry level

Add the regression tests to `GridParametersTests` with a realistic global grid
(the live `x0 = -180`, `xd ≈ 0.3184`, `xc = 1130`, `y1 ≈ 90.03`, `yd ≈ 0.2356`,
`yc = 763`) plus a cell that decodes to a known location such as an Australian
storm, and an assertion that every decoded centre is within valid coordinates.
Keep the existing bounded-grid expectations.

## Risks / Trade-offs

- [`isGlobal` could misclassify a bounded grid as global] → The thresholds
  (span > 350° and > 170°) are only reachable by the world grid; the largest
  supported data area is 20° and named regions span well under 90°, so no
  bounded grid is near the thresholds. The same test already gates containment,
  so a misclassification would not be a new class of failure.
- [The global grid's reported north edge is one cell above the pole and its south
  edge one cell short] → Unchanged by this design; the bounds are only used as a
  coarse world extent, and `contains` is already skipped for a global grid.
- [A future server change could re-anchor the global offsets] → The anchoring is
  documented in `docs/data-providers.md` next to the geometry, so a server
  change has one place to reconcile with.
