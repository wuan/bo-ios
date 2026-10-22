# Map rendering

How the iOS app draws lightning activity on the map. This documents the
`map-rendering` capability delivered by the
[`ios-map-rendering`](../openspec/changes/archive/2026-10-22-ios-map-rendering/proposal.md) change.

## Shapes

One displayed result becomes one *render plan*, computed by
`ActivityRenderPlan.make(activity:zoomScale:visibleMapRect:)` from the activity
model (`MapActivity`) and the map's current scale and visible area. The view
layer only materialises the plan with MapKit's own renderers:

| Part of the plan | Drawn as |
| --- | --- |
| `tileFills` | one `ActivityTilePolygon` per cell, filled by `MKPolygonRenderer` |
| `countLabels` | one `ActivityCountAnnotation` per cell large enough for text |
| `strikeMarks` | one `ActivityStrikePolygon` (a plus) per point strike |
| `baseMapDim` | one `ActivityDimPolygon` over the covered area, added first |
| not in the plan | data-area outline keeps its own plain `MKPolygon` |

The plan carries every colour, opacity, and culling decision, so it can be
asserted in tests; MapKit owns projection and compositing.

## Reference values

These mirror the Android client (`wuan/bo-android`) and are asserted in tests.

| Rule | Value |
| --- | --- |
| Tile colour | `ColorHandler.colorSection`: `minutesPerColor = intervalDuration / 6`, clamped to the palette |
| Tile opacity | `ShapeAlpha.alpha(tileWidth, 10, 40, 255, 100)` -> opaque at <= 10 pt, 0.39 at >= 40 pt |
| Count drawn when | `tileHeight / 2.5 >= 8` pt (`TileLabel.minimumSize`) |
| Count opacity | `ShapeAlpha.alpha(textSize, 20, 80, 255, 60)` |
| Minimum tile | `TileGeometry.minimumHalfExtent` = 1.5 pt half-extent, so a sparse cell is never invisible |
| Point strike | plus of `2 * (zoomLevel + 1)` pt, arms `size / 4` wide |
| Base-map dim | `255 / 100 * mapFade` percent, black on satellite, white on street maps |
| Covered area | `ActivityRenderPlan.coverage` = 2x the visible map rect per plan |

`StrikeMarker.zoomScaleExponentOffset` converts MapKit's `MKZoomScale` (which is
`2^(zoomLevel - 20)`) into the zoom level the reference sizes markers with.

Timestamps are epoch **seconds** everywhere, and the raster payload's fourth
value is a cell's age in **seconds** (the reference client works in
milliseconds, which is why the port originally scaled it). A cell's age is
`referenceTimestamp - cellTimestamp`, so a cell inside the requested interval
never falls outside the colour scale for a unit reason.

## Colour schemes

`ColorScheme` holds the three palettes, six colours each, newest activity first.
`ColorScheme.streetMapBrightness` (0.8) darkens every palette for a light base
map, and `textColor(for:)` picks the count colour: black on satellite, white on
a street map.

| Scheme | Newest colour | Oldest colour |
| --- | --- | --- |
| `BLITZORTUNG` (default) | `#ffffff` | `#e05050` |
| `RAINBOW` | `#ff0000` | `#6699ff` |
| `TEMPERATURE` | `#ff5030` | `#4060ff` |

The scheme is the `colorScheme` setting (raw value of `ColorScheme`, default
`BLITZORTUNG`), the base map is `mapMode` (`.satellite`/`.hybrid` -> satellite,
`.standard`/`.mutedStandard` -> street map), and the dim is `mapFade`.

## Selection

`MapActivity.selection(at:zoomScale:)` resolves a tap in map space: rect
containment for cells, and a square of the drawn marker size for point strikes.
The details are presented as `ActivitySelectionAnnotation`, whose view shows the
selection's time (`HH:mm:ss`) plus `#count` for a cell or `(lon lat)` for a
strike. Rendering a new result clears the popup, and a tap that resolves to
nothing leaves the map unchanged.

Annotation views are sized by `frame` in their `configure` methods: MapKit
positions them by frame, so Auto Layout constraints inside the view leave it
zero-sized and invisible.

## Settings

| Key | Default | Effect |
| --- | --- | --- |
| `colorScheme` | `BLITZORTUNG` | palette, and its street-map variant |
| `mapMode` | `hybrid` | `mapView.mapType` and the palette variant |
| `mapFade` | `55` | opacity of the base-map wash (0 disables it) |

A change to any of the three applies immediately: the map type is set and the
displayed result is re-rendered with the new colours.
