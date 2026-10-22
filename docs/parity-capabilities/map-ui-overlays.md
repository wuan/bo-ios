# Map UI overlays (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Being delivered by the
[`ios-map-ui-overlays`](../../openspec/changes/ios-map-ui-overlays/proposal.md) change, whose delta
spec is the source of truth while it is in flight; delete this sketch when that change is archived.

## Purpose

Provides the on-map informational and control components that frame the lightning display: legend, quick settings, alarm radar, histogram, and status.

## ADDED Requirements

### Requirement: Legend
The app SHALL display a legend describing the colour-to-age mapping and the active data region and grid baseline.

#### Scenario: Age colour mapping shown
- **WHEN** the legend is displayed
- **THEN** it shows a colour scale from newest to oldest activity with the corresponding time ranges

#### Scenario: Region and grid baseline shown
- **WHEN** a data region and grid baseline are active
- **THEN** the legend displays the region name and grid baseline value

#### Scenario: Local region size shown
- **WHEN** the local region is active
- **THEN** the legend displays the local region size in degrees

### Requirement: Data-area overview
The app SHALL display an overview of the active data area showing its extent, its cell size, the part of it the map is currently showing, and the current zoom level.

#### Scenario: Overview shows the data area
- **WHEN** a data area is active for the displayed result
- **THEN** the overview shows the area's extent and cell size

#### Scenario: Viewport shown within the data area
- **WHEN** the map is panned or zoomed
- **THEN** the overview shows the portion of the data area the map is currently displaying

### Requirement: Quick settings
The app SHALL open a quick-settings dialog when the user taps the legend, and SHALL apply changes made there without leaving the map.

#### Scenario: Open quick settings
- **WHEN** the user taps the legend
- **THEN** a quick-settings dialog opens

#### Scenario: Apply a quick setting
- **WHEN** the user changes a setting in the quick-settings dialog
- **THEN** the map reflects the change when the dialog closes

### Requirement: Alarm radar
The app SHALL display an alarm radar showing lightning activity by distance from the current location in realtime mode when data and location are available.

#### Scenario: Active radar
- **WHEN** realtime data and a known location are available
- **THEN** the radar displays activity by distance from that location

#### Scenario: Inactive radar
- **WHEN** no activity is present within the radar range
- **THEN** the radar displays an inactive state

#### Scenario: Location outside data area
- **WHEN** the current location lies outside the available lightning data area
- **THEN** the radar displays an outside indicator

#### Scenario: Center on location
- **WHEN** the user taps the alarm radar
- **THEN** the map centers on the current location

#### Scenario: Open enlarged radar
- **WHEN** the user long-presses the alarm radar
- **THEN** an enlarged alarm radar is displayed

### Requirement: Histogram
The app SHALL display a histogram of strike rate over the displayed time period for the data region.

#### Scenario: Histogram reflects rate
- **WHEN** the displayed period contains lightning activity
- **THEN** the histogram shows the variation of strike rate across that period

#### Scenario: Tap to zoom out
- **WHEN** the user taps the histogram
- **THEN** the map zooms out to the region extent

### Requirement: Status line
Already delivered: the `data-modes` requirement *Mode-aware status line* owns the strike count, the interval, and the realtime countdown, and the app ships it. What remains for later phases is the alert and lifecycle indicators (warning text, progress, error badge, background-alert icon), which belong with alerts and background monitoring rather than here.
