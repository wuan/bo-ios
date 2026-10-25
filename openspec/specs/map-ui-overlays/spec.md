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
