# Spec Delta

## MODIFIED Requirements

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
