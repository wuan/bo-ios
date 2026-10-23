# map-ui-overlays Specification

## Purpose

Frames the lightning display with on-map information and controls - a legend, quick settings, a strike-rate histogram, a distance radar, and a data-area overview - so users can read the current activity and adjust what they are looking at without leaving the map.

## Requirements

### Requirement: Legend
The app SHALL display a legend describing the colour-to-age mapping and the region actually requested, together with the grid baseline when one is active.

#### Scenario: Age colour mapping shown
- **WHEN** the legend is displayed
- **THEN** it shows a colour scale from newest to oldest activity with the corresponding time ranges

#### Scenario: Region and grid baseline shown
- **WHEN** a grid baseline is active for the displayed result
- **THEN** the legend displays the grid baseline value together with the region name

#### Scenario: Region name reflects the request
- **WHEN** the app requests data for a region
- **THEN** the legend displays the name of that requested region, so a JSON-RPC request shows the automatically selected local or global region and an HTTP request shows its named region

#### Scenario: Local region size shown
- **WHEN** the local region is active
- **THEN** the legend displays the local region size

### Requirement: Quick settings
The app SHALL open a quick-settings dialog when the user taps the legend, offering the interval duration, historic timestep, data source, colour scheme, map mode, and base-map fade, and SHALL offer a region selection only while the Blitzortung HTTP source is active, listing named regions. It SHALL apply a change without leaving the map.

#### Scenario: Open quick settings
- **WHEN** the user taps the legend
- **THEN** a quick-settings dialog opens

#### Scenario: Change applies to the map
- **WHEN** the user changes a setting in the quick-settings dialog
- **THEN** the map reflects the change when the dialog closes and the map is never left

#### Scenario: Changed setting persists
- **WHEN** the app is relaunched after a quick setting was changed
- **THEN** the app uses the changed value

#### Scenario: Region offered only for the HTTP source
- **WHEN** the active data source is the JSON-RPC source
- **THEN** the quick-settings dialog does not offer a region selection

#### Scenario: Region lists named regions for HTTP
- **WHEN** the active data source is the Blitzortung HTTP source
- **THEN** the quick-settings dialog offers the named regions

#### Scenario: Region appears when the source changes
- **WHEN** the user changes the data source to the Blitzortung HTTP source within the open dialog
- **THEN** the region selection becomes available without closing the dialog

### Requirement: Strike-rate histogram
The app SHALL display a histogram of the strike rate across the displayed period for the active data area, and SHALL zoom the map out to that data area when the histogram is tapped.

#### Scenario: Histogram reflects the period
- **WHEN** the displayed period contains lightning activity
- **THEN** the histogram shows how the strike rate varies across that period

#### Scenario: Tap zooms out to the data area
- **WHEN** the user taps the histogram
- **THEN** the map zooms out to the extent of the active data area

#### Scenario: Histogram available without an extra request
- **WHEN** a grid result is displayed
- **THEN** the histogram is drawn from that result and needs no request of its own

### Requirement: Alarm radar display
The app SHALL display an alarm radar showing lightning activity by distance and direction from the current location while realtime data and a location are available, SHALL indicate when no location is known, when no activity is present within range, and when the location lies outside the data area, and SHALL mark an active alert.

#### Scenario: Active radar
- **WHEN** realtime data and a known location inside the data area are available and activity is present
- **THEN** the radar shows that activity by distance and direction from the location

#### Scenario: No location known
- **WHEN** no location is known
- **THEN** the radar shows a no-location state

#### Scenario: No activity within range
- **WHEN** no activity is present within the radar range
- **THEN** the radar shows an inactive state

#### Scenario: Location outside the data area
- **WHEN** the current location lies outside the available lightning data area
- **THEN** the radar shows an outside-data-area state

#### Scenario: Radar without realtime data
- **WHEN** the displayed data is not realtime
- **THEN** the radar shows no activity

#### Scenario: Active alert marked
- **WHEN** an alert is active
- **THEN** the radar marks it, so a warning is distinguishable from activity that is merely in range

#### Scenario: Alert cleared
- **WHEN** the alert is cancelled
- **THEN** the radar stops marking it while it keeps showing the activity in range

### Requirement: Alarm radar interaction
The app SHALL centre the map on the current location when the alarm radar is tapped, and SHALL open an enlarged alarm radar when the radar is long-pressed.

#### Scenario: Center on location
- **WHEN** the user taps the alarm radar
- **THEN** the map centres on the current location

#### Scenario: Open enlarged radar
- **WHEN** the user long-presses the alarm radar
- **THEN** an enlarged alarm radar is displayed

#### Scenario: Enlarged radar closes
- **WHEN** the user dismisses the enlarged radar
- **THEN** the map is shown again with the radar unchanged

### Requirement: Data-area overview
The app SHALL display an overview of the active data area showing its extent, its cell size, the part of it the map is currently showing, and the current zoom level.

#### Scenario: Overview shows the data area
- **WHEN** a data area is active for the displayed result
- **THEN** the overview shows the area's extent and cell size

#### Scenario: Viewport shown within the data area
- **WHEN** the map is panned or zoomed
- **THEN** the overview shows the portion of the data area the map is currently displaying

#### Scenario: Zoom level shown
- **WHEN** the overview is displayed
- **THEN** it shows the map's current zoom level

#### Scenario: No overview without a data area
- **WHEN** the displayed result carries no data area
- **THEN** no data-area overview is shown
