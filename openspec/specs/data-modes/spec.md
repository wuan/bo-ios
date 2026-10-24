# data-modes Specification

## Purpose

Controls which time range and geographic extent of lightning data the app displays, covering realtime, historical, and animated playback modes and the region and grid selection that accompanies them.

## Requirements

### Requirement: Realtime mode
The app SHALL provide a realtime mode that shows the most recent interval and refreshes automatically as new data arrives.

#### Scenario: Realtime shows recent data
- **WHEN** the app is in realtime mode
- **THEN** it displays activity for the most recent interval and refreshes automatically as new data arrives

#### Scenario: Returning to realtime
- **WHEN** the user returns to realtime from another mode
- **THEN** the display updates to the most recent interval

### Requirement: History mode with time selection
The app SHALL allow the user to select a point in time within the last 24 hours and SHALL display the activity for the interval ending at that point.

#### Scenario: Select a past time
- **WHEN** the user selects a past point in time within the last 24 hours
- **THEN** the app displays activity for the interval ending at that time

#### Scenario: History range bounds
- **WHEN** the user moves the time selection to its earliest position
- **THEN** the selection is limited to 24 hours before the present

### Requirement: Animation playback
The app SHALL support an animation mode that advances through historical intervals
automatically at a configurable step duration, pause for a configurable cycle pause when
the playback cycles back to the beginning, and can be stopped, holding the interval
reached when it stops.

#### Scenario: Start animation from history
- **WHEN** the user starts animation
- **THEN** the displayed time advances step by step across the history range without further user input

#### Scenario: Stop animation
- **WHEN** the user stops animation
- **THEN** the display holds the current interval and the user can resume manual time selection

#### Scenario: Configured step duration
- **WHEN** the user has set a step duration
- **THEN** animation advances one interval per step duration

#### Scenario: Configured cycle pause
- **WHEN** the playback reaches the present and cycles back to the beginning
- **THEN** it pauses for the configured cycle pause before advancing again

#### Scenario: No cycle pause
- **WHEN** the cycle pause is set to its off value
- **THEN** the playback restarts at the beginning without pausing

### Requirement: Time slider control
The app SHALL provide a time-slider control spanning the last 24 hours whose rightmost position activates realtime mode.

#### Scenario: Slider right activates realtime
- **WHEN** the user moves the time slider fully to the right
- **THEN** the app switches to realtime mode

#### Scenario: Slider position selects history
- **WHEN** the user drags the time slider to a non-rightmost position
- **THEN** the app displays the interval corresponding to that position

### Requirement: Region selection
The app SHALL select the data region from the active data source rather than from the stored setting alone. The JSON-RPC source SHALL use the automatic extent-derived local or global region and SHALL ignore the stored region. The Blitzortung HTTP source SHALL use the stored region when it is a named region, and SHALL resolve any other stored value to Europe.

#### Scenario: JSON-RPC selects the region automatically
- **WHEN** the JSON-RPC source is active
- **THEN** requests use the extent-derived local or global region regardless of the stored region value

#### Scenario: Global region
- **WHEN** the JSON-RPC source selects the global extent
- **THEN** requests cover global data and no local data area is applied

#### Scenario: Local region
- **WHEN** the JSON-RPC source selects the local extent
- **THEN** requests are limited to a data area derived from the current extent

#### Scenario: HTTP uses the stored named region
- **WHEN** the Blitzortung HTTP source is active and the stored region is a named region
- **THEN** requests use that named region

#### Scenario: HTTP resolves a non-named stored region
- **WHEN** the Blitzortung HTTP source is active and the stored region is not a named region
- **THEN** requests use Europe

#### Scenario: Changing the source re-resolves the region
- **WHEN** the active data source changes
- **THEN** the region used for the next request follows the newly active source

### Requirement: Local data area and grid sizing
The app SHALL derive a quantized local data area and SHALL select a grid size appropriate to the view extent, falling back to the global region when the extent is too large for a local area.

#### Scenario: Data area derived from map view
- **WHEN** the visible map extent changes enough to fall outside the current data area
- **THEN** the app recomputes the data area from the visible extent

#### Scenario: Large extent falls back to global
- **WHEN** the visible extent is too large for a local data area
- **THEN** the app uses global data instead

### Requirement: Grid requests respect source capability
The app SHALL issue grid-data requests only when the active data source supports grid data, and SHALL otherwise request the non-grid strike representation.

#### Scenario: Source without grid support
- **WHEN** the active data source does not support grid data
- **THEN** the app requests non-grid strikes and does not issue a grid request

#### Scenario: Source with grid support
- **WHEN** the active data source supports grid data
- **THEN** the app may include the selected grid size in its requests

### Requirement: Mode-aware status line
The app SHALL show the realtime refresh countdown while in realtime mode and SHALL show the start of the selected interval as a wall-clock time while in history or animation mode.

#### Scenario: Realtime shows the countdown
- **WHEN** the app is in realtime mode
- **THEN** the status line shows the refresh countdown

#### Scenario: History shows the interval start
- **WHEN** the app is in history or animation mode
- **THEN** the status line shows the start of the selected interval as a wall-clock time
