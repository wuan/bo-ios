# Proposal

## Why

`ios-data-modes` lets the user choose the interval, region, and grid size, but the map still draws every cell the same way it did in the prototype: one flat rectangle per cell, a single hard-coded palette, zoom-only opacity, no counts, and no way to inspect a strike. `StrikeOverlayRenderer` ignores the `multiplicity` already parsed into `RasterElement`, so the "intensity at a glance" the grid model was built for is not visible. Android renders labelled, age-coloured tiles from three selectable colour schemes, dims the base map so activity stands out, and opens a popup when a strike is tapped. Without that, the data modes just delivered are unreadable at a glance, and the legend, histogram, and alarm components in Phase 3 have no settled visual contract to describe.

## What Changes

- Render grid tiles as **age-coloured rectangles with per-tile strike counts**, matching Android's `GridShape`: the count is drawn when the tile is large enough to be legible, with its own alpha ramp; tiles below a minimum size are still drawn so sparse activity does not disappear.
- Replace the current one-`MKOverlay`-plus-one-renderer-per-cell approach with a **single overlay drawn in one renderer pass**, culling to the visible rect and adjusting detail by zoom, mirroring Android's single `StrikeListOverlay` drawing every shape.
- **Translucency**: per-tile opacity derived from the tile's rendered pixel size, clamped to configured bounds, so large (zoomed-in) tiles are drawn lighter and dense areas do not saturate; plus a **base-map dim** driven by the existing `mapFade` setting, matching Android's `FadeOverlay`.
- **Colour schemes**: adopt Android's `BLITZORTUNG`, `RAINBOW`, and `TEMPERATURE` palettes (replacing the drifted local palette), with per-map-type variants — reduced brightness over street maps, and the matching text/line colour — and render using the scheme selected in settings.
- **Strike selection**: tapping a tile or strike shows a popup identifying it (time plus either its count for a tile or its coordinates for a point strike), and dismissing it leaves the map unchanged.
- **Display activity for the active selection only**, leaving the map unchanged for results belonging to a selection the user has left; the accumulation and expiry of activity over the interval window stay where they already live — in the providers.
- Reconcile the roadmap's `map-rendering` delta so the capability contract describes this behaviour rather than the earlier wording (in particular the fade requirement, the scheme set, and the selection popup content).

This change is rendering only. It executes the roadmap's Phase 2 with the Android reference as the contract where the two disagree.

## Capabilities

### New Capabilities

- `map-rendering`: How lightning activity is drawn on the map — grid tiles sized by the active grid parameters, per-tile counts, age-based colouring and scheme selection, size/zoom-derived translucency and base-map dim, zoom-aware detail with culling, and the strike-selection popup.

### Modified Capabilities

<!-- None: no existing main spec's requirements change. `settings-store` is key-agnostic, so
     adding a colour-scheme setting does not alter it. -->

## Impact

- **Code**: `monitor/mapview/` (a single tile overlay plus its renderer, replacing `StrikeOverlay`/`StrikeOverlayRenderer`; a shape/alpha helper and a colour-handler type with per-map-type variants), `monitor/ColorScheme.swift` (palettes replaced by the three named schemes), `monitor/ViewController.swift` (overlay lifecycle, accumulate/expire, tap handling, and the selection popup), `monitor/settings/SettingsKey.swift` (a colour-scheme key; `mapFade` gains a consumer).
- **Depends on**: `ios-data-modes` for the active interval, region, and grid size, and for grid-capable vs strike-only source gating; `lightning-data-model` for `RasterElement`/`GridParameters` (per-tile multiplicity and cell geometry already exist); `ios-data-providers` for the `Result` including `rasterParameters`.
- **Behaviour**: the same data becomes legible (counts, age, scheme), the map redraws in one pass instead of tearing down an overlay per cell on every refresh, and tiles are now tappable.
- **Out of scope**: Android's cluster overlay (a later Android addition, not part of Phase 2); the legend, quick-settings dialog, histogram, and alarm radar (Phase 3); the full preferences screen and the base-map `mapScale` control (Phase 7) — Phase 2 only consumes the colour-scheme and fade settings it needs.
- **Roadmap artifact**: `openspec/changes/android-feature-parity/specs/map-rendering/spec.md` is updated so the umbrella capability spec matches what this change delivers.
