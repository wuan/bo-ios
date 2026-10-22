# Proposal

## Why

`ios-data-providers` makes the source of data configurable, but the app still only ever asks for one thing: the most recent interval, a fixed region, a fixed grid. `ViewController` owns a 1-second timer with a 60-second realtime period and hard-coded region/grid literals. Android users scrub across a 24-hour history, play it back as animation, and choose local, regional, or global extents with a grid size matched to the visible area. Without that model, later rendering, overlays, and alerts have nothing to display beyond a single realtime frame.

## What Changes

- Add the **realtime/history/animation time model**: a 24-hour history range, interval duration and offset, animation stepping, and a return to realtime.
- Add the **24-hour time-slider control** whose rightmost position activates realtime.
- Add **region selection** (local, regional, global) with a computed, quantized **local data area**, **grid sizing** suited to the view extent, and a fallback to global when the extent is too large.
- Add **count-threshold filtering**, with a zero threshold meaning inactive.
- Consult the active provider's **capability descriptor** so grid requests are issued only when the selected source supports them.
- Replace the fixed realtime-only polling in `ViewController` with a **mode-driven refresh**.
- Show the **start of the selected interval** in the status line in history and animation mode, keeping the realtime refresh countdown in realtime.

The interval/offset representation and the quantized data area already exist in `lightning-data-model`; this change adds the behaviour that drives them rather than redefining them.

## Capabilities

### New Capabilities

- `data-modes`: Realtime, history, and animation time selection over a bounded history range, the time-slider control, region and local data-area/grid selection, and count-threshold filtering.

### Modified Capabilities

- `data-providers`: stale-result rejection is scoped to a single request selection, so a historical interval — whose reference timestamp is older than realtime — is not discarded as an out-of-order response.

## Impact

- **Code**: `monitor/ViewController.swift` (mode-driven refresh and the slider control), a new mode/region module (time model, region and data-area selection, grid sizing, threshold), `monitor/Parameters.swift` (region constants and data-area carry-through), and `monitor/pipeline/FreshnessValidator.swift` (selection-scoped staleness).
- **Depends on**: `ios-data-providers` for the selectable source, the settings keys, and the provider capability descriptor that gates grid requests; it should land first.
- **Behaviour**: the prototype's fixed 60-second realtime poll and hard-coded region/grid become a user-selectable mode and extent.
- **Out of scope**: grid-tile rendering, colouring, and strike selection (Phase 2); legend, quick settings, histogram, and alarm radar (Phase 3); GPS/network location providers and manual location entry (Phase 4) — data-area derivation here uses the visible map extent, with location-based refinement arriving with Phase 4.
