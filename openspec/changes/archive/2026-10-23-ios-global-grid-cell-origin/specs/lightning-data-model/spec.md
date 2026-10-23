# Spec Delta

## MODIFIED Requirements

### Requirement: Grid parameters
The app SHALL represent grid parameters by origin, per-cell delta, and cell counts, and SHALL derive cell centers and grid bounds from them. A bounded grid SHALL anchor its cell centers at its reported north-western corner; a world-spanning grid SHALL anchor them at the origin, whose offsets its backend numbers from the prime meridian and the equator.

#### Scenario: Cell center derived
- **WHEN** a grid offset is requested
- **THEN** the corresponding cell center coordinate is derived from the grid parameters

#### Scenario: Grid bounds derived
- **WHEN** the grid extent is requested
- **THEN** the start and end coordinates are derived from the grid parameters

#### Scenario: Bounded grid anchored at its corner
- **WHEN** a grid offset is requested for a bounded grid
- **THEN** the first cell center lies half a cell inside the reported north-western corner and each further offset lies one cell further east and south

#### Scenario: World-spanning grid anchored at the origin
- **WHEN** a grid offset is requested for a world-spanning grid
- **THEN** the cell center is derived from the origin rather than the reported corner, so its longitude is the column's center measured east of the prime meridian and its latitude is the row's center measured south of the equator

#### Scenario: Reported bounds stay geographic
- **WHEN** the extent of a world-spanning grid is requested
- **THEN** the reported start and end coordinates still describe the geographic area the grid covers
