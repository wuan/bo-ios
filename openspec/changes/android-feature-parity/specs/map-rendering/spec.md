# Spec Delta

## Purpose

Renders lightning strike data on the map as age-coloured tiles of varying size, with per-tile counts and selection, so users can read activity intensity and recency at a glance.

## ADDED Requirements

### Requirement: Variable-size grid tiles
The app SHALL render lightning activity as grid tiles whose size is selected from a discrete set appropriate to the current interval and zoom level.

#### Scenario: Tile size follows grid parameters
- **WHEN** a result includes grid parameters with a given grid size
- **THEN** the app renders activity as tiles of that size

#### Scenario: Tile size changes with selection
- **WHEN** the user selects a different grid or view scale
- **THEN** the rendered tiles use the corresponding size

### Requirement: Per-tile strike counts
The app SHALL display, within each active tile, the number of lightning events recorded in that tile during the relevant interval.

#### Scenario: Count shown for active tile
- **WHEN** a tile contains one or more lightning events
- **THEN** the number of events is displayed inside the tile

### Requirement: Age-based colouring
The app SHALL colour each tile according to the age of the most recent activity in that tile relative to the reference time.

#### Scenario: Recent activity is the brightest colour
- **WHEN** a tile's most recent activity falls in the newest interval section
- **THEN** the tile uses the newest colour of the active colour scheme

#### Scenario: Older activity is a darker colour
- **WHEN** a tile's most recent activity is older
- **THEN** the tile uses a correspondingly older colour of the active colour scheme

### Requirement: Fade by age and zoom
The app SHALL apply a translucency to rendered activity that decreases with activity age and increases with zoom level within configured bounds.

#### Scenario: Fade reduces with age
- **WHEN** two tiles of equal zoom but different activity ages are rendered
- **THEN** the older activity is drawn with lower opacity

#### Scenario: Opacity stays within bounds
- **WHEN** an extreme age or zoom is rendered
- **THEN** the opacity is clamped to the configured minimum and maximum

### Requirement: Colour scheme selection
The app SHALL support multiple colour schemes and SHALL render activity using the currently selected scheme.

#### Scenario: Selected scheme is applied
- **WHEN** the user selects a colour scheme
- **THEN** the map is redrawn using that scheme's colour gradient

### Requirement: Zoom-aware rendering detail
The app SHALL adjust rendering detail so that activity remains legible across zoom levels.

#### Scenario: Detail adapts to zoom
- **WHEN** the user zooms the map
- **THEN** the rendered activity adjusts its opacity/detail as defined for the new zoom level

### Requirement: Strike selection
The app SHALL allow the user to select a strike and SHALL show details for the selected strike.

#### Scenario: Select a strike
- **WHEN** the user taps a rendered strike
- **THEN** the app shows a popup with information about that strike

#### Scenario: Dismiss strike details
- **WHEN** the user dismisses the strike popup
- **THEN** the popup closes and the map remains unchanged
