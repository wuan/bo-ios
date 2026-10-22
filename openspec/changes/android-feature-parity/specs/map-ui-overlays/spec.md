# Spec Delta

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

#### Scenario: Threshold shown only when active
- **WHEN** the count threshold is greater than zero
- **THEN** the legend displays the threshold value

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
The app SHALL display a status line reporting the current strike count, interval, and refresh countdown.

#### Scenario: Status reflects current data
- **WHEN** a result is displayed
- **THEN** the status line shows the strike count and the active interval

#### Scenario: Refresh countdown
- **WHEN** the app is awaiting the next refresh
- **THEN** the status line shows the remaining time until the next update
