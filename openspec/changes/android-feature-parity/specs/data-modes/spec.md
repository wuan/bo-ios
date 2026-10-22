# Spec Delta

## Purpose

Controls which time range and geographic region of lightning data the app displays, covering realtime, historical, and animated playback modes.

## ADDED Requirements

### Requirement: Realtime mode
The app SHALL support a realtime mode that continuously shows the most recent lightning activity for the configured interval.

#### Scenario: Realtime shows recent data
- **WHEN** the app is in realtime mode
- **THEN** it displays activity for the most recent interval and refreshes automatically as new data arrives

#### Scenario: Returning to realtime
- **WHEN** the user returns to realtime from another mode
- **THEN** the display updates to the most recent interval

### Requirement: History mode with time selection
The app SHALL allow the user to select a point in time within the last 24 hours and SHALL display the lightning activity for that time range.

#### Scenario: Select a past time
- **WHEN** the user selects a past point in time within the last 24 hours
- **THEN** the app displays activity for the interval ending at that time

#### Scenario: History range bounds
- **WHEN** the user moves the time selection to its earliest position
- **THEN** the selection is limited to 24 hours before the present

### Requirement: Animation playback
The app SHALL support an animation mode that advances through historical intervals automatically and can be stopped.

#### Scenario: Start animation from history
- **WHEN** the user starts animation
- **THEN** the displayed time advances step by step across the history range without further user input

#### Scenario: Stop animation
- **WHEN** the user stops animation
- **THEN** the display holds the current interval and the user can resume manual time selection

### Requirement: Time slider control
The app SHALL provide a time-slider control spanning the last 24 hours whose rightmost position activates realtime mode.

#### Scenario: Slider right activates realtime
- **WHEN** the user moves the time slider fully to the right
- **THEN** the app switches to realtime mode

#### Scenario: Slider position selects history
- **WHEN** the user drags the time slider to a non-rightmost position
- **THEN** the app displays the interval corresponding to that position

### Requirement: Interval configuration
The app SHALL group time selection into an interval with a duration and an offset, and SHALL treat a zero offset as realtime.

#### Scenario: Realtime determined by offset
- **WHEN** the interval offset is zero
- **THEN** the parameters are considered realtime

#### Scenario: Historical offset retained
- **WHEN** a non-zero offset is selected
- **THEN** the offset is applied when requesting data

### Requirement: Region selection
The app SHALL allow selection of a data region, including local, regional, and global extents.

#### Scenario: Global region
- **WHEN** the global region is selected
- **THEN** requests cover global data and no local data-area is applied

#### Scenario: Local region uses a computed data area
- **WHEN** the local region is selected and a location is known
- **THEN** requests are limited to a data area derived from that location

### Requirement: Local data area and grid sizing
The app SHALL compute a quantized local data area from the current location or map view, and SHALL select a grid size appropriate to the view extent.

#### Scenario: Data area derived from map view
- **WHEN** the visible map extent changes enough to fall outside the current data area
- **THEN** the app recomputes the data area from the visible map center

#### Scenario: Large extent falls back to global
- **WHEN** the visible extent is too large for a local data area
- **THEN** the app uses global data instead

### Requirement: Count threshold filtering
The app SHALL support a count threshold that hides grid cells whose strike count is below the threshold, and SHALL treat a zero threshold as inactive.

#### Scenario: Threshold hides sparse cells
- **WHEN** a count threshold greater than zero is set
- **THEN** only grid cells with counts meeting or exceeding the threshold are displayed

#### Scenario: Zero threshold inactive
- **WHEN** the count threshold is zero
- **THEN** no cells are filtered out and no threshold is shown in the legend
