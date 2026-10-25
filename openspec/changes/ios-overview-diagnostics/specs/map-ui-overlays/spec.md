# Spec Delta

## MODIFIED Requirements

### Requirement: Data-area overview
The app SHALL display an overview of the active data area, showing its extent, its cell
size, the part of it the map is currently showing, and the current zoom level, but only
while the diagnostics setting is on. The overview's box SHALL take its height from the
visible map extent's latitude span relative to its longitude span, within a usable range.

#### Scenario: Overview hidden while diagnostics is off
- **WHEN** the diagnostics setting is off
- **THEN** no data-area overview is shown, whether or not a data area is active

#### Scenario: Overview shows the data area
- **WHEN** the diagnostics setting is on and a data area is active for the displayed result
- **THEN** the overview shows the area's extent and cell size

#### Scenario: Diagnostics change applies without a relaunch
- **WHEN** the user turns the diagnostics setting on or off
- **THEN** the overview appears or disappears accordingly

#### Scenario: Viewport shown within the data area
- **WHEN** the map is panned or zoomed
- **THEN** the overview shows the portion of the data area the map is currently displaying

#### Scenario: Box follows the visible extent's proportions
- **WHEN** the visible map extent is wider than it is tall, or taller than it is wide
- **THEN** the overview's box is correspondingly flatter or taller, within its usable range

#### Scenario: Zoom level shown
- **WHEN** the overview is displayed
- **THEN** it shows the map's current zoom level

#### Scenario: No overview without a data area
- **WHEN** the displayed result carries no data area
- **THEN** no data-area overview is shown
