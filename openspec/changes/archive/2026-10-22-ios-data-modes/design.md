# Design

## Context

See `proposal.md` - Why. The model side already exists from the foundation: `TimeIntervalSelection` (duration/offset, `isRealtime`), `History` (`timeIncrement` 30, `maxRange` 1440, `lowerLimit(of:)`, `clampedPosition`), and `DataArea` (x, y, scale with derived bounds). `Parameters` carries `region`, `rasterBaselength`, `intervalDuration`, `intervalOffset`, and `countThreshold`, and becomes a value type in `ios-data-providers`. Today `ViewController` ignores all of it: a 1-second timer fires and requests every 60 seconds with default parameters.

The Android reference keeps the same model and adds behaviour: `TimeInterval` exposes `rewInterval`/`ffwdInterval`/`animationStep`/`goRealtime`, all clamping to `History.lowerLimit` and aligning offsets to `timeIncrement`; `Parameters.withPosition`/`intervalPosition`/`intervalMaxPosition` convert between a slider position and an offset; and `LocalData.updateParameters` maps a region setting plus the visible extent to a `Parameters` carrying region, `DataArea`, and `gridSize`, with `LOCAL_REGION = -1`, `GLOBAL_REGION = 0`, and `LOCAL_REGION_GRID_SIZE_THRESHOLD = 25000` deciding the local/global boundary.

## Goals / Non-Goals

**Goals:**

- Express mode, region, and threshold selection as pure, unit-testable value transformations with no UIKit or MapKit types in the core.
- Keep the map view as the source of the extent, behind a small value type, so the algorithm is testable and Phase 4 can add location as a second input.
- Make refresh cadence a function of the active mode.

**Non-Goals:**

- Rendering grid tiles, counts, or colours (Phase 2).
- The legend, quick-settings dialog, status line, histogram, or alarm radar (Phase 3).
- GPS/network/manual location providers or the permission flow (Phase 4). This change derives the data area from the visible extent and leaves a location input point for Phase 4.
- Choosing a source or endpoint (`ios-data-providers`).

## Decisions

### Decision: Port time stepping into a pure value type
Add the stepping operations (`rewind`, `fastForward`, `animationStep`, `goRealtime`) to the time model, clamping offsets to the history lower limit and aligning them to the history increment exactly as Android does.

- Rationale: the stepping rules are the parity-critical part and are trivially testable without a view.
- Alternatives: mutating `Parameters` in `ViewController` (rejected - untestable and duplicates clamping logic at every call site).

### Decision: Model the time slider in integer positions
Express the slider as positions across the history range, converting a position to an offset via the same arithmetic as Android's `withPosition`/`intervalPosition`/`intervalMaxPosition`, with the rightmost position mapping to a zero offset.

- Rationale: it keeps the control a plain integer range and makes "rightmost means realtime" a direct consequence of offset zero rather than a special case bolted onto the UI.
- Alternatives: a continuous 0-1 fraction (rejected - loses the alignment to `timeIncrement` that prevents jitter).

### Decision: Isolate the visible extent behind a `ViewExtent` value type
Have the map view produce a `ViewExtent` (center and span) that the region/grid logic consumes, instead of passing `MKMapRect` or `MKCoordinateRegion` into the core.

- Rationale: the region, data-area, and grid-size rules become testable with plain values, and Phase 4 can add an optional location input without changing the algorithm's shape.
- Alternatives: computing region parameters inside `ViewController` (rejected - untestable, and Phase 3 needs the same logic); importing MapKit into the mode module (rejected - couples core logic to a UI framework).

### Decision: Port region/data-area/grid selection with Android's automatic local/global switching
Implement a selection function that maps the region setting, the current data area, and the extent to concrete parameters, reproducing Android's rules: local without a derivable area falls back to global; global with a grid size below the local threshold and a known data area switches to local; otherwise the region is used as-is. Derive a local data area by quantizing the extent.

- Rationale: the automatic switch is observable parity behaviour; omitting it would make iOS behave differently from Android at the same zoom.
- Alternatives: a purely manual region with no automatic switching (rejected - divergent behaviour); deriving the area from location now (rejected - deferred to Phase 4).

### Decision: Derive grid size from the extent, bounded by the supported range
Compute the grid size from the extent span and clamp it to the supported range, using the same local/global threshold as Android, and send it only when the active source supports grid data (per the `ios-data-providers` capability descriptor).

- Rationale: grid size is what makes tile rendering meaningful in Phase 2 and what the backend quantizes requests by.
- Alternatives: a fixed grid size (rejected - defeats the purpose and diverges from Android); letting the renderer pick the grid size (rejected - the request must carry it).

### Decision: Drive refresh from the mode, not a fixed period
Replace the fixed 60-second realtime poll with a mode-driven scheduler: realtime refreshes on the configured query period, history refreshes when the selection changes, and animation advances one step per tick. Keep the existing status countdown as a separate presentation concern.

- Rationale: the current single timer conflates countdown display with fetch triggering, which cannot express three modes.
- Alternatives: keep one timer and branch inside it (rejected - the branch would grow with every later mode and overlay).

### Decision: Send the count threshold as a request parameter
Treat the threshold as a request parameter (as Android does) with zero meaning inactive, rather than filtering client-side.

- Rationale: matches the backend contract and keeps Phase 3's legend able to report an active threshold.

## Risks / Trade-offs

- **Automatic region switching surprises users** → Keep the resolved region and grid size visible in the status line (Phase 3 consumes it) and cover the transitions with unit tests.
- **Slider jitter from unaligned offsets** → Align every offset to the history increment, as Android does, and test the alignment.
- **Grid-size derivation needs a map extent, which is UI state** → Keep the rule behind the `ViewExtent` value type and test it with fixed extents.
- **Phase 4 expands the data-area inputs** → Keep an optional location parameter in the selection function now so Phase 4 adds a value rather than reshaping the API.
- **Mode-driven refresh can starve the UI of updates in history mode** → Refresh on selection change and confirm the manual experience with the Phase 1 integration check.

## Migration Plan

- Default to realtime with the existing defaults, so launch behaviour stays familiar; history, animation, and region selection are opt-in.
- Remove the fixed realtime poll and the hard-coded region/grid literals in the same change.
- Rollback: revert the change; the app returns to realtime-only rendering through the pipeline.

## Open Questions

- Confirm the animation step rate (assumed one history increment, 30 minutes, per step) and whether it should become user-configurable; this affects presentation only and is revisited with the Phase 7 preferences and Phase 8 controls.
