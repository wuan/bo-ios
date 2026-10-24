# Spec Delta

## Purpose

Aggregates lightning activity relative to the user's location as distance rings and direction sectors, recording the closest strike and its age in each sector, so distance-based displays and alerts share one computation. This change delivers the aggregation; notification, signalling, and suppression behaviour arrive with the alerts phase.

## ADDED Requirements

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
