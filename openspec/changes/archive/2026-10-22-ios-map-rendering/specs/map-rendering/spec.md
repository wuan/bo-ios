# Spec Delta

## Purpose

Renders lightning activity on the map as age-coloured grid tiles of the active grid size, labelled with per-tile strike counts and selectable by tap, so users can read activity intensity and recency at a glance.

## ADDED Requirements

### Requirement: Grid tiles sized by the active grid parameters
The app SHALL render lightning activity as one tile per received grid cell, whose geographic size follows the grid parameters of the displayed result.

#### Scenario: Tile size follows grid parameters
- **WHEN** a result includes grid parameters with a given grid size
- **THEN** the app renders activity as tiles of that size

#### Scenario: Tile size follows the grid selection
- **WHEN** the user selects a different grid or view scale
- **THEN** the rendered tiles use the corresponding size

#### Scenario: Sparse tiles stay visible
- **WHEN** a tile's rendered size falls below the supported minimum
- **THEN** the app still draws it at the minimum size rather than omitting it

### Requirement: Per-tile strike counts
The app SHALL display, within each active tile, the number of lightning events recorded in that tile during the relevant interval.

#### Scenario: Count shown for an active tile
- **WHEN** a tile contains one or more lightning events and its rendered size is large enough for legible text
- **THEN** the number of events is drawn inside the tile

#### Scenario: Count omitted when illegible
- **WHEN** a tile's rendered size is too small for legible text
- **THEN** the tile is drawn without a count

#### Scenario: Count text fades with tile size
- **WHEN** a tile's rendered size grows
- **THEN** the count text is drawn with decreasing opacity within its configured bounds

### Requirement: Age-based colouring
The app SHALL colour each tile according to the age of the most recent activity in that tile relative to the reference time of the displayed result, using the sections of the active colour scheme.

#### Scenario: Recent activity uses the newest colour
- **WHEN** a tile's most recent activity falls in the newest section of the active colour scheme
- **THEN** the tile uses the newest colour of that scheme

#### Scenario: Older activity uses an older colour
- **WHEN** a tile's most recent activity falls in an older section of the active colour scheme
- **THEN** the tile uses that section's colour

#### Scenario: Activity older than the scale uses the oldest colour
- **WHEN** a tile's most recent activity is older than the last section of the active colour scheme
- **THEN** the tile uses the oldest colour of that scheme

### Requirement: Translucency derived from rendered tile size
The app SHALL apply a translucency to each drawn tile derived from its rendered size, so that larger tiles are drawn with lower opacity, clamped to configured minimum and maximum bounds.

#### Scenario: Larger tiles are drawn lighter
- **WHEN** two tiles of different rendered sizes are drawn
- **THEN** the larger tile is drawn with lower opacity

#### Scenario: Opacity stays within bounds
- **WHEN** an extreme rendered tile size is drawn
- **THEN** the opacity is clamped to the configured minimum and maximum

### Requirement: Base-map dim from the fade setting
The app SHALL draw a translucent layer whose opacity follows the configured fade setting over the base map and beneath the rendered activity.

#### Scenario: Fade setting applies to the base map
- **WHEN** the fade setting changes
- **THEN** the opacity of the layer over the base map changes accordingly

#### Scenario: Activity remains visible over the dim
- **WHEN** the base-map layer is drawn
- **THEN** the tiles and their counts remain visible above it

### Requirement: Colour scheme selection
The app SHALL support multiple named colour schemes, SHALL render activity using the currently selected scheme, and SHALL adjust rendering colours to the active base map type.

#### Scenario: Selected scheme is applied
- **WHEN** the user selects a colour scheme
- **THEN** the map is redrawn using that scheme's colour gradient

#### Scenario: Selected scheme persists
- **WHEN** the app is relaunched after a scheme was selected
- **THEN** the map renders using that scheme

#### Scenario: Colours adapt to the base map type
- **WHEN** the user changes the base map type
- **THEN** the activity and text colours are adjusted for legibility on that map type

### Requirement: Zoom-aware rendering detail
The app SHALL keep activity legible across zoom levels and SHALL avoid drawing activity outside the visible map.

#### Scenario: Detail adapts to zoom
- **WHEN** the user zooms the map
- **THEN** the rendered activity adjusts its opacity and label detail for the new zoom level

#### Scenario: Activity outside the view is not drawn
- **WHEN** a tile or strike falls outside the visible map rect
- **THEN** it is not drawn

### Requirement: Strike selection
The app SHALL allow the user to select a rendered tile or strike and SHALL show details for the selection in a popup.

#### Scenario: Select a tile
- **WHEN** the user taps a rendered tile
- **THEN** a popup shows that tile's time and strike count

#### Scenario: Select a point strike
- **WHEN** the user taps a rendered point strike
- **THEN** a popup shows that strike's time and coordinates

#### Scenario: Dismiss strike details
- **WHEN** the user dismisses the popup
- **THEN** the popup closes and the map remains unchanged

#### Scenario: Tap where no activity is rendered
- **WHEN** the user taps the map where no activity is rendered
- **THEN** no popup is shown

### Requirement: Displayed activity follows the active selection
The app SHALL draw the activity of the result it is displaying, SHALL leave the display unchanged for a result belonging to a selection the user has left, and SHALL draw no activity outside the active interval window.

#### Scenario: Activity of the displayed selection is drawn
- **WHEN** a result arrives for the selection currently displayed
- **THEN** its tiles and strikes are drawn

#### Scenario: Activity for a left-behind selection is not drawn
- **WHEN** a result arrives for a selection other than the one currently displayed
- **THEN** the displayed activity is left unchanged

#### Scenario: Activity outside the interval window is not drawn
- **WHEN** the active interval window advances
- **THEN** activity that has fallen outside the window is no longer drawn
