# Design

## Context

See `proposal.md` - Why. The rendering seam today is two files. `StrikeOverlay` wraps a single `Strike`/`RasterElement` and builds an `MKMapRect` from its envelope; `StrikeOverlayRenderer` draws one filled rectangle per overlay, choosing a colour from a single hard-coded palette and an alpha from `log(zoomScale)` mapped 1.0 -> 0.2. `ViewController.render(result:)` tears down and rebuilds every overlay on each response. There is no text drawing, no culling, no selection, and `RasterElement.multiplicity` is parsed but never drawn.

The Android reference (`wuan/bo-android`) organizes the same problem differently: one `StrikeListOverlay` holds a list of item/shape pairs and draws them in a single pass, `GridShape` draws a rectangle plus a count label, `ShapeAlpha.calculateShapeAlpha` maps a size value to an alpha, `ColorHandler`/`ColorScheme` own the palettes and `StrikeColorHandler` adds map-type variants, `FadeOverlay` dims the base map, and a tap is resolved by projecting the touch and testing each shape.

Constraints that shape the approach:

- **MapKit draws in map space.** An `MKOverlayRenderer` receives an `MKMapRect` and a `MKZoomScale` and must project its own geometry (`rect(for:)` / `point(for:)`); there is no `Canvas`-style immediate pass and no built-in hit testing for custom overlays (MapKit's `selectableMapFeatures` covers POIs, not custom shapes).
- **Android's overlay accumulates; iOS providers already do.** `StrikeListOverlay` appends incremental results (`event.updated`) and expires by `referenceTime - intervalDuration`. On iOS, `BlitzortungHttpDataProvider` already accumulates per selection, drops duplicates by position and timestamp, windows by `intervalDuration`, and resets when `parameters` change; the JSON-RPC path returns a whole interval. Accumulating again in the renderer would duplicate that and risk double counting.
- **Two renderable shapes already exist in the model.** `RasterElement` carries a cell span and a multiplicity (grid tiles); `StrikeLogParser` produces `Strike` values with a zero span and multiplicity 1 (point strikes for the non-grid HTTP source).
- **The settings for this already exist.** `SettingsKey` has `mapMode` (hybrid), `mapFade` (55, matching Android's `preferences.xml` default), and `mapScale` (75, Android's base-map `tilesScaleFactor`), but nothing consumes them yet, and `ViewController` hard-codes `MKMapType.hybrid`. A colour-scheme key does not exist yet.

Reference values worth pinning down for parity (Android):

```
tile colour      ColorHandler.getColorSection(reference, timestamp, intervalDuration)
                 minutesPerColor = intervalDuration / colors.size, clamped to the palette
tile alpha       calculateShapeAlpha(tilePixelWidth, 10, 40, 255, 100)   -> 1.0 at <=10pt, ~0.39 at >=40pt
count label      drawn when tilePixelHeight / 2.5 >= 8pt
count alpha      calculateShapeAlpha(textSize, 20, 80, 255, 60)
minimum tile     1.5pt, so a sparse cell is never invisible
point strike     plus-sign, size 2 * (zoomLevel + 1) pt, stroke width size/4
schemes          BLITZORTUNG (default), RAINBOW, TEMPERATURE; 6 colours each
map-type variants street map: colours at 0.8 brightness, black text/line; satellite: as-is, white
base-map dim     FadeOverlay alpha = 255 / 100 * mapFade
selection popup  time as kk:mm:ss, plus "#count" for a tile or "(lon lat)" for a point strike
```

## Goals / Non-Goals

**Goals:**

- One drawing path that renders tiles with counts, colour, translucency, and base-map dim across all modes and grid sizes.
- Keep the geometry, colour-section, and alpha rules as pure, unit-testable types, so parity can be asserted in tests rather than by eye.
- Make a tap on a tile or strike resolve to a popup without disturbing the map.
- Leave the provider, mode, and caching layers untouched.

**Non-Goals:**

- Pixel-exact visual identity with Android (MapKit's label rendering, anti-aliasing, and font metrics differ). Behaviour and colour values are the contract.
- Cluster rendering; `DataProviderCapabilities.supportsClusters` exists, but nothing requests or draws clusters and Android's cluster overlay is a separate later feature.
- The legend, quick-settings dialog, histogram, and alarm radar (Phase 3), the full preferences screen, and the `mapScale` base-map control (Phase 7).
- Moving accumulation or expiry into the view layer (see Context).

## Decisions

### Decision: Draw activity with MapKit's own renderers, driven by one pure render plan
Compute a *render plan* (tile fills, count labels, point-strike marks, base-map dim) from the displayed result, the active scheme and base map, and the map's current scale and visible rect, then materialise it with MapKit's built-in renderers: one filled polygon overlay per drawn tile, a polygon overlay per point strike, the dim as a polygon overlay beneath them, and the per-tile counts as annotation-backed labels for tiles large enough to show them.

- Rationale: MapKit's built-in path renderers composite reliably, whereas a custom `MKOverlayRenderer` drawing per-item fills did not reach the screen during verification (see the render-path note under Risks), while `MKPolygonRenderer` on the existing data-area polygon rendered correctly. Keeping the plan pure keeps the parity numbers (colour section, alpha ramps, thresholds, culling) unit-tested, and lets MapKit own geometry, projection, and compositing.
- Alternatives: one custom `MKOverlayRenderer` for the whole result set (rejected: it did not render in the target environment); `MKTileOverlay` raster tiles (rejected: counts and labels need dynamic drawing, and rasterising per grid size adds a cache to manage); keeping per-item custom renderers (rejected: same compositing behaviour).
- Trade-off: overlays are per item rather than one per result, so creation and teardown cost returns. Mitigated by building overlays only for items the plan keeps (visible-rect culling, unit-tested) and by MapKit culling overlays that fall outside the view.
- Trade-off: the plan owns the projection-independent geometry and all hit testing, so those need their own tests; the maths lives in the pure types of the next decision.

### Decision: Port Android's colour, alpha, and geometry rules as pure types
Introduce testable value types/methods: a colour scheme set with the three Android palettes and their map-type variants, a colour-section function (`minutesPerColor = intervalDuration / colours.count`), a `shapeAlpha(value:minValue:maxValue:maxAlpha:minAlpha:)` helper mirroring `ShapeAlpha`, and a geometry helper converting a tile plus projection into a pixel rect with the 1.5 pt minimum.

- Rationale: these carry the parity-critical numbers from the table above; keeping them pure lets unit tests assert the same cases Android's JUnit tests cover, in the spirit of the alert-logic decision for Phase 5.
- Alternatives: inline the arithmetic in the renderer (rejected: only verifiable visually, and the numbers are the contract).

### Decision: Two distinct "fade" mechanisms, matching Android
Per-tile translucency is a function of the tile's rendered pixel size (clamped), and the base-map dim is a separate translucent layer whose opacity follows the `mapFade` setting (`255 / 100 * percent`). Count labels get their own alpha ramp, independent of the tile's.

- Rationale: this is what Android does; the roadmap's earlier wording ("fade decreases with activity age") does not match the reference and is corrected in the `map-rendering` spec. Age is encoded by colour section, not opacity.
- Alternatives: keep the current `log(zoomScale)` alpha (rejected: at one zoom, a 5 km and a 100 km tile get the same opacity, and it ignores the tile's actual size); age-based opacity (rejected: no Android counterpart, and it would double-encode age).
- Note: Android's dim uses `backgroundColor` per map type (transparent black on satellite, white on street), so the dim is a contrast wash rather than a pure darkening.

### Decision: Tile pixel size is measured in points, with the Android thresholds reused unchanged
Apply the Android constants (min 1.5, alpha ramp 10..40, count threshold 8 pt derived from `height / 2.5`) in points rather than rescaling for Retina density.

- Rationale: MapKit works in points and `MKZoomScale`, and Android's `dp`-like appearance is closest to points; reusing the numbers keeps the parity table meaningful and avoids inventing new constants.
- Alternatives: multiply by `UIScreen.scale` (rejected: makes labels physically larger on Retina than Android's on-dp appearance).

### Decision: Selection via MKAnnotation-anchored popup, hit-tested in the renderer
Resolve a tap by converting the touch to an `MKMapPoint` and testing tiles (rect containment) and point strikes (a square of the drawn strike size around the centre), then present the details as an annotation-backed popup showing `HH:mm:ss` plus either `#count` or coordinates.

- Rationale: MapKit has no custom-overlay hit testing, so the test belongs with the geometry; using an annotation/anchor for the popup lets MapKit keep it anchored to the point as the map moves, which Android emulates by hand with `MapView.LayoutParams`.
- Alternatives: a plain `UIView` subview repositioned on every region change (rejected: re-anchoring bugs, exactly what MapKit's annotation machinery solves); `MKMapView.selectableMapFeatures` (rejected: for map POIs, not overlays).
- Trade-off: popup content is a string built for display; localised formatting and units arrive with Phase 10, so keep the format in one place.

### Decision: Display follows the active selection; accumulation stays in the providers
The renderer draws the latest received result and does not accumulate. A result whose selection differs from the displayed one is ignored, which generalises the interval-offset guard `ViewController` already applies.

- Rationale: `BlitzortungHttpDataProvider` already retains, window-filters, and deduplicates strikes for the active selection and resets on a parameter change; adding overlay-side accumulation would double count and fight that reset. The observable behaviour the spec asks for - activity from the active window, nothing from a left-behind selection - is already produced by the providers.
- Alternatives: mirror Android's append-and-expire in the overlay (rejected: duplicates provider behaviour and needs an `updated` count iOS providers do not report).

### Decision: Colours and text adapt to the base map type; `mapMode` becomes the source of truth
Map `.satellite`/`.hybrid` to Android's satellite target (palette as-is, light text) and `.standard`/`.mutedStandard` to the street target (0.8-brightness palette, dark text), and drive `mapView.mapType` from the `mapMode` setting instead of the hard-coded `MKMapType.hybrid`.

- Rationale: Android's `StrikeColorHandler` and `ColorHandler.getTextColor` key off the map type; without the hook the palettes are only legible on one map type. Wiring `mapMode` also removes a literal the roadmap flagged.
- Alternatives: fixed colours on all map types (rejected: Android gives white strikes on satellite and dark ones on street maps for legibility).

## Risks / Trade-offs

- **Overlay count at global scale** (thousands of tiles in one result) -> Build overlays only for items the plan keeps (visible-rect intersection, unit-tested), reuse the palette lookups, and let MapKit cull overlays outside the view; if profiling still shows interaction lag, the escape hatch is merging adjacent same-colour tiles into one multi-polygon overlay or a raster path.
- **Label count dominates** -> Port Android's legibility floor (8 pt) exactly, build a label annotation only for tiles that clear it, and reuse one label view per text size.
- **Palette change is visible to existing users** (today's palette differs from Android's `BLITZORTUNG`) -> Treat the Android values as canonical, and assert each scheme's exact colour values in unit tests so the intent is explicit.
- **popup anchoring and dismissal** -> Use an annotation view rather than a manually positioned view, and cover the "tap empty map" case with a test so a stray tap does not leave a stale popup.
- **Threshold constants tuned for Android pixels may look off on iOS** -> Keep them in one pure type so a single change re-tunes everything, and revisit after a visual pass at 5 km and 100 km grids.
- **Map type / scheme interaction is easy to mis-thread** -> Compute colours from one place per draw (scheme + map type), and test the two variants rather than both call sites.
- **Render path choice is load-bearing** -> Verified by running the app: a custom `MKOverlayRenderer` filling a chunk-sized rect reached the screen, but item-sized fills did not (with both `MKMapRect.world` and a tight `boundingMapRect`), while MapKit's `MKPolygonRenderer` composited correctly. If a later platform release makes the custom path viable again, only the materialisation step changes, not the plan or its tests.
- **Removing the old renderer is user-visible** -> Keep `StrikeOverlay`/`StrikeOverlayRenderer` until the new path passes the visual checks in the tasks, then delete them in the same change so no dead path lingers.
- **Raster cell ages were 1000x too large** (found while verifying the age colouring: every tile clamped to the oldest colour) -> `RasterElement` scaled the provider's per-cell delay by 1000, a leftover from the millisecond-based reference client, while this app's timestamps are epoch seconds. The delay is already in seconds, so the scale is gone; the parser test asserts every cell's age falls inside the requested interval, and a rendering test asserts cells of different ages get different colours.

## Migration Plan

Deliver as one change with the old path retained until the new one is verified:

1. Pure types first (schemes, colour section, shape alpha, tile geometry) with unit tests pinning the Android values.
2. The render plan plus its MapKit materialisation (tile polygons, counts as labels, dim); route `ViewController.render(result:)` through it.
3. Selection hit testing and the popup.
4. Settings wiring (`colorScheme` key, `mapFade` consumer, `mapMode` -> `mapType`).
5. Delete `StrikeOverlay`/`StrikeOverlayRenderer`, update the docs, and run the visual checks at both grid extremes.

Rollback: revert to the per-cell overlay path (Phase 1 behaviour) by restoring the two deleted files and the old `render(result:)` body; no data, settings, or provider migration is involved. The only lasting effect is a new settings key, which is inert if reverted. Because the plan is pure, keeping it while reverting only the materialisation is also possible.

## Open Questions

- Whether the JSON-RPC provider should ever report incremental updates (Android's `event.updated`). Not needed for this change, since full results are already returned per interval; it would only affect payload size.
- Whether the selection popup's time should follow the device locale and the measurement setting; deferred to the localization phase, which owns formatting.
