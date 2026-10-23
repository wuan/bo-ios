# Proposal

## Why

Global grid strikes are drawn at the wrong place: `get_global_strikes_grid`
numbers its cells from the origin (prime meridian / equator) and negates its row
index, but the app anchors every grid's offsets at the grid's north-western
corner. Every global cell is therefore displaced by about 180° west and 90°
north, so activity lands in Greenland and other regions with no storms while most
cells fall outside valid coordinates.

The Android reference client works around this by overwriting `x0` and `y1` with
`0.0` for the global method before decoding. The app does not, and its docs
describe one anchoring rule for every grid.

## What Changes

- Derive cell centres from the origin the grid actually uses: a world-spanning
  grid numbers its columns from the prime meridian and its rows from the
  equator, so longitude is `xd * (offset + 0.5)` and latitude is
  `-yd * (offset + 0.5)`. A bounded grid keeps the current
  `x0 + xd * (offset + 0.5)` / `y1 - yd * (offset + 0.5)` anchoring.
- Keep the reported grid bounds (`x0`, `y1`, and the ends derived from them) as
  the geographic extent, because containment, the data-area overview, and the
  histogram zoom read them; only the offset-to-coordinate mapping changes.
- Document the two anchorings in `docs/data-providers.md` and correct the
  cell-centre statement there.
- Add regression coverage with a realistic global payload: decoded cells stay
  within valid coordinates and land where the offsets say, while a bounded grid
  keeps its current centres.

## Capabilities

### New Capabilities
<!-- None: the change corrects existing behavior. -->

### Modified Capabilities

- `lightning-data-model`: the Grid parameters requirement gains the anchor its
  cell centres are derived from, distinguishing a world-spanning grid (offsets
  from the origin) from a bounded grid (offsets from the reported corner).

## Impact

- `monitor/data/GridParameters.swift`: cell-centre derivation from the anchor,
  with the reported bounds left as the geographic extent.
- Tests: `GridParametersTests`, and the raster decode paths that assert cell
  positions (`StrikeDataParserTests`, `JsonRpcGridRequestTests`).
- Docs: `docs/data-providers.md` grid geometry section.
- No change to the request the app sends, the tile geometry, or any other
  consumer of the grid bounds.
