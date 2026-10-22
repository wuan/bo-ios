# Tasks

> Prerequisite: this change consumes the interval, region, and grid selection delivered by `ios-data-modes` and the per-tile multiplicity and cell geometry in `lightning-data-model`; both should land first.

## 1. Colour and rendering rules (pure types)

- [x] 1.1 Add the named colour schemes (`BLITZORTUNG`, `RAINBOW`, `TEMPERATURE`) with the reference palette values and the per-map-type variants (satellite as-is, street map at 0.8 brightness) plus the matching text colour; verified by unit tests asserting every scheme's exact colour values and both map-type variants.
- [x] 1.2 Implement the colour-section mapping from reference time, event time, and interval duration, including the section width and clamping to the palette range; verified by unit tests for the newest section, an older section, activity beyond the scale, and a duration that does not divide evenly.
- [x] 1.3 Implement the shape-alpha helper mapping a size value in a range to an alpha between bounds; verified by unit tests at the bounds, inside the range, and outside both ends.
- [x] 1.4 Implement the tile geometry helper turning grid parameters plus a projection into a pixel rect with the minimum-size clamp; verified by unit tests for a fixed projection, a tile below the minimum size, and a global-scale grid.
- [x] 1.5 Add the colour-scheme setting with the reference default and register it; verified by a settings test asserting the default and that a changed value persists.

## 2. Render plan and MapKit materialisation

- [x] 2.1 Add the activity model carrying the displayed result (tiles, point strikes, reference time, interval, scheme, map type) and the pure render plan that turns it into tile fills, count labels, strike marks, and the base-map dim for the current scale and visible rect; verified by routing `ViewController.render(result:)` through it and observing tiles in the simulator.
- [x] 2.2 Draw tiles as age-coloured polygons using the colour section for the tile's most recent activity and the rendered-size-derived alpha clamped to its bounds; verified by unit tests on the colour and alpha selection plus a visual check at the finest and coarsest grid sizes.
- [x] 2.3 Show the per-tile strike count as a label centred on the tile when the tile is large enough for legible text, with the label's own alpha ramp, and omit it otherwise; verified by unit tests for the legibility threshold and the label alpha plus a visual check at several zoom levels.
- [ ] 2.4 Draw point strikes (zero-span results from the non-grid source) as size-scaled markers; verified by a unit test on the marker size across zoom levels and a visual check against the HTTP source.
- [x] 2.5 Keep only the items that intersect the visible map rect in the plan, and adjust label detail with zoom; verified by a unit test showing an offscreen tile produces no drawing and by a performance check with global-scale data.
- [x] 2.6 Draw the base-map dim layer beneath the activity, with opacity derived from a fade percentage; verified by a unit test on the opacity conversion and a visual check that tiles and counts stay legible above it.

## 3. Selection

- [x] 3.1 Resolve a tap point to the tile or point strike under it; verified by unit tests for a hit inside a tile, a hit inside a point strike, and a miss on empty map.
- [x] 3.2 Present the selection as an anchored popup showing the time plus the tile's count or the strike's coordinates, and dismiss it without changing the map; verified by a UI test or manual check for both item kinds, for dismissal, and for a tap on empty map showing nothing.

## 4. Settings wiring and documentation

- [x] 4.1 Apply the selected colour scheme and redraw when it changes; verified by switching schemes manually and confirming the redraw, and by a test that a scheme change triggers a redraw request.
- [x] 4.2 Consume the fade setting so the base-map dim follows it and updates on change; verified by a test on the observed setting change and a manual check of the dim before and after.
- [x] 4.3 Drive the map type from the map-mode setting instead of the hard-coded hybrid type, keeping the map-type-dependent colours consistent with it; verified by a test mapping the setting to the map type and a manual check of both variants.
- [x] 4.4 Document the rendering reference (schemes and their variants, tile minimum size, alpha and count thresholds, base-map dim, selection popup) in `docs/map-rendering.md` and verify the documented defaults and thresholds match the code.

## 5. Remove the legacy path and integration verification

- [x] 5.1 Delete `StrikeOverlay`, `StrikeOverlayRenderer`, and the superseded custom activity renderer once the new path is verified; verified by a clean build and test run and a visual regression check of the map.
- [ ] 5.2 Run the app against a live backend in realtime, history, and animation modes with local and global regions at both grid extremes, confirming the `map-rendering` scenarios for counts, colouring, translucency, dim, culling, and selection.
- [x] 5.3 Run `xcodebuild test` and `openspec validate ios-map-rendering --strict` and resolve all failures and warnings.

## Workflow follow-up

- Keep `android-feature-parity`'s `map-rendering` delta aligned with what this change delivered; it was reconciled during planning and should be re-checked before either change is archived.
- Archive this change after the project's review requirements are satisfied; its `map-rendering` capability is copied to the main specs.
- Verify the archived result with `openspec list --specs` and `openspec validate`.
