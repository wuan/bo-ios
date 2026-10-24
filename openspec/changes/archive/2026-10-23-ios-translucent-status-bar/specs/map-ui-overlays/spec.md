# Spec Delta

## ADDED Requirements

### Requirement: Top status row placement
The app SHALL place the top status row - the status line and the settings control - below the top safe area so the row is fully visible and clear of any top cutout, and SHALL keep the legend below the status row.

#### Scenario: Row clears the Dynamic Island
- **WHEN** the device has a Dynamic Island or notch
- **THEN** the whole status row is drawn below the cutout, with no part of its text or controls obscured

#### Scenario: Row on a device without a cutout
- **WHEN** the device has no top cutout
- **THEN** the status row is drawn at the top of the content area with no empty band above it

#### Scenario: Legend stays below the row
- **WHEN** the legend is displayed
- **THEN** it sits below the status row and is not drawn under the top cutout

### Requirement: Translucent status row over a full-bleed map
The app SHALL draw the map across the full width and to the top edge of the screen behind the status row, and SHALL give the status row a translucent background so map content stays visible behind it while the row's text and settings control stay legible.

#### Scenario: Map visible at the top
- **WHEN** the map is displayed
- **THEN** map content is drawn in the area behind the status row instead of an opaque band

#### Scenario: Row stays legible over the map
- **WHEN** map content of any brightness lies behind the status row
- **THEN** the status text and the settings control remain readable against the row's background

#### Scenario: Map attribution stays visible
- **WHEN** the map is displayed
- **THEN** the map's legal attribution remains fully visible and is not covered by the framing chrome

### Requirement: System status bar shown
The app SHALL show the system status bar so the system clock and battery indicators are visible alongside the app's own status row.

#### Scenario: System indicators are visible
- **WHEN** the app is in the foreground
- **THEN** the system status bar presents its clock and battery indicators

### Requirement: Bottom controls bar
The app SHALL present the bottom controls - the mode indicator, the animation control, the time slider, and the range labels - as a translucent bar over the full-bleed map, matching the top status row, and SHALL arrange them in at most two rows.

#### Scenario: Map visible behind the bottom bar
- **WHEN** the map is displayed
- **THEN** map content is drawn behind the bottom controls bar instead of an opaque band

#### Scenario: Bottom controls stay legible over the map
- **WHEN** map content of any brightness lies behind the bottom controls bar
- **THEN** the mode indicator, slider, range labels, and animation control remain readable against the bar's background

#### Scenario: Range labels share the slider row
- **WHEN** the bottom controls are displayed
- **THEN** the oldest and present range labels sit on the same row as the slider, so the controls occupy two rows rather than three

#### Scenario: Map attribution stays visible
- **WHEN** the map is displayed with the bottom bar over it
- **THEN** the map's legal attribution remains fully visible and is not covered by the bar
