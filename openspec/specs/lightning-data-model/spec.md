# lightning-data-model Specification

## Purpose

Defines the shared, provider-independent representation of lightning data so that all data sources, rendering, and alerts speak the same domain language.

## Requirements

### Requirement: Strike representation
The app SHALL represent a strike by its position, timestamp, and multiplicity.

#### Scenario: Strike carries position and time
- **WHEN** a strike is created
- **THEN** it exposes its coordinate, timestamp, and multiplicity

#### Scenario: Strike extent
- **WHEN** a strike has a non-zero grid extent
- **THEN** it exposes the rectangular area it covers

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

### Requirement: Time interval and history
The app SHALL represent a time selection as an interval with duration and offset, SHALL treat an offset of zero as realtime, and SHALL bound history to a maximum range.

#### Scenario: Realtime detection
- **WHEN** the interval offset is zero
- **THEN** the interval is considered realtime

#### Scenario: History bounded
- **WHEN** a history position is requested beyond the maximum range
- **THEN** it is limited to the maximum history range

### Requirement: Data area
The app SHALL represent a quantized data area by grid index and scale, and SHALL derive its bounds from them.

#### Scenario: Data area bounds derived
- **WHEN** a data area's bounds are requested
- **THEN** they are derived from its index and scale

### Requirement: Provider-agnostic parsing
The app SHALL parse provider responses into a common result carrying a reference timestamp and a list of strikes, independent of the transport used.

#### Scenario: Parse a complete response
- **WHEN** a response contains a reference time and strike records
- **THEN** parsing yields a result with the reference timestamp and the corresponding strikes

#### Scenario: Parse a response without grid data
- **WHEN** a response omits grid parameters
- **THEN** parsing still yields the strikes and leaves grid parameters unset
