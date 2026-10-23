# proximity-alerts Specification

## Purpose

Aggregates lightning activity relative to the user's location as distance rings and direction sectors, recording the closest strike and its age in each sector, so distance-based displays and alerts share one computation. It also turns that aggregation into a warning: gated by an enable switch and bounded by notification and signalling distance limits, it raises a notification, emits a configurable sound and vibration, suppresses repeats for a configurable time, and reports the alert state the radar marks.

## Requirements

### Requirement: Sector and range aggregation
The app SHALL aggregate realtime activity into distance rings and direction sectors around the current location, and SHALL record for each sector the distance to its closest strike and that strike's age.

#### Scenario: Activity is bucketed by distance and direction
- **WHEN** activity occurs near the current location
- **THEN** it is aggregated into the ring and sector containing its position

#### Scenario: Closest strike is kept per sector
- **WHEN** several strikes fall in the same sector
- **THEN** the sector reports the nearest of them and its age

#### Scenario: Empty sector reports no strike
- **WHEN** no activity falls in a sector
- **THEN** that sector reports no strike rather than a zero distance

#### Scenario: Aggregation covers the whole radar
- **WHEN** the aggregation is available
- **THEN** it reports every ring and sector the radar displays, including the empty ones

### Requirement: Radar geometry
The aggregation SHALL use range boundaries of 10, 25, 50, 100, 250, and 500 kilometres and eight equally wide direction sectors.

#### Scenario: Fixed range rings
- **WHEN** the aggregation is produced
- **THEN** its rings end at 10, 25, 50, 100, 250, and 500 kilometres from the location

#### Scenario: Equally wide sectors
- **WHEN** the aggregation is produced
- **THEN** it reports eight direction sectors of equal width covering the full circle

### Requirement: Aggregation window
The aggregation SHALL only consider activity within the alert interval ending at the reference time, independent of the interval the map displays.

#### Scenario: Activity older than the alert interval is ignored
- **WHEN** activity older than the alert interval is present
- **THEN** it does not affect the reported closest strikes

#### Scenario: Alert interval differs from the display interval
- **WHEN** the displayed interval is longer than the alert interval
- **THEN** the aggregation still uses only the alert interval

#### Scenario: No aggregation without realtime data
- **WHEN** the available data is not realtime
- **THEN** the aggregation reports no activity

### Requirement: Aggregation states
The aggregation SHALL report a no-location state when no location is known, an outside-data-area state when the location lies outside the data area, a no-data state when no realtime activity is available, and activity otherwise.

#### Scenario: No location known
- **WHEN** no location is available
- **THEN** the aggregation reports the no-location state

#### Scenario: Location outside the data area
- **WHEN** the current location lies outside the data area of the available data
- **THEN** the aggregation reports the outside-data-area state

#### Scenario: No activity available
- **WHEN** no realtime activity is available to aggregate
- **THEN** the aggregation reports the no-data state

#### Scenario: Activity available
- **WHEN** a location inside the data area and realtime activity are available
- **THEN** the aggregation reports the activity result for the sectors and rings

### Requirement: Closest strike summary
The aggregation SHALL identify the sector whose closest strike is nearest, and SHALL report its direction and distance for display.

#### Scenario: Nearest sector is reported
- **WHEN** the aggregation reports activity
- **THEN** it identifies the sector with the nearest closest-strike and that distance

#### Scenario: No strike anywhere
- **WHEN** no sector contains a strike
- **THEN** the summary reports no distance rather than an arbitrary direction

### Requirement: Enabling proximity alerts
The app SHALL allow proximity alerts to be switched on and off, and SHALL monitor, signal, and notify only while they are on.

#### Scenario: Alerts switched on
- **WHEN** proximity alerts are switched on and a location is known
- **THEN** the app evaluates the nearby activity against the limits and signals what falls inside them

#### Scenario: Alerts switched off
- **WHEN** proximity alerts are switched off
- **THEN** no signal and no notification are emitted, and the reported alert state is cancelled

### Requirement: Notification distance limit
The app SHALL raise a notification when the closest strike is within a configurable notification distance limit, and SHALL raise none for a strike beyond it.

#### Scenario: Strike inside the notification limit
- **WHEN** the closest strike is within the notification distance limit
- **THEN** the app raises a notification naming that strike

#### Scenario: Strike outside the notification limit
- **WHEN** every strike is farther than the notification distance limit
- **THEN** the app raises no notification

#### Scenario: Notification limit on the boundary
- **WHEN** the closest strike's distance equals the notification distance limit
- **THEN** the app treats it as within the limit

### Requirement: Signalling distance limit
The app SHALL emit the configured sound and vibration when the closest strike is within a configurable signalling distance limit, which is normally nearer than the notification limit.

#### Scenario: Strike inside the signalling limit
- **WHEN** the closest strike is within the signalling distance limit
- **THEN** the app emits the configured sound and vibration

#### Scenario: Strike between the limits
- **WHEN** the closest strike is inside the notification limit but beyond the signalling limit
- **THEN** the app notifies without emitting a signal

#### Scenario: Signal settings take effect
- **WHEN** the user changes the sound or the vibration setting
- **THEN** subsequent signals use the new setting

### Requirement: Signal suppression
The app SHALL suppress further signals for a configurable time after a signal, and SHALL notify only for strikes newer than the one last notified.

#### Scenario: Suppression window active
- **WHEN** a signal has been emitted and the suppression time has not elapsed since the strike that caused it
- **THEN** no further signal is emitted, even for a newer qualifying strike

#### Scenario: Suppression window elapsed
- **WHEN** the suppression time has elapsed since the strike that caused the last signal
- **THEN** a newer qualifying strike signals again

#### Scenario: The same activity notifies once
- **WHEN** the same result is evaluated again with no newer qualifying strike
- **THEN** no second notification is raised

### Requirement: Alert state reporting
The app SHALL report the alert state to its consumers as active, carrying the closest strike's bearing and distance, or cancelled when nothing qualifies.

#### Scenario: Active alert reported
- **WHEN** the closest strike is within the notification distance limit
- **THEN** the app reports an active alert with that strike's bearing and distance

#### Scenario: Alert cancelled
- **WHEN** nothing qualifies within the limits, alerts are switched off, or no location or realtime data is available
- **THEN** the app reports the alert as cancelled
