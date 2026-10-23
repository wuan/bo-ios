# Spec Delta

## Purpose

Determines the user's location and exposes it for display, centering, and distance-based features such as the alarm radar. This change delivers the manual path; device-based location and permission handling arrive with the location phase.

## ADDED Requirements

### Requirement: Manual location
The app SHALL support a manual location mode in which the position comes from coordinates the user sets, and SHALL not require device location in that mode.

#### Scenario: Manual coordinates are used
- **WHEN** the manual location mode is active and a position has been set
- **THEN** the app uses that position as the current location

#### Scenario: No device location required
- **WHEN** the manual location mode is active
- **THEN** the current location is available without a location permission being granted

### Requirement: Setting the location by long press
The app SHALL let the user set the current location by long-pressing a position on the map.

#### Scenario: Long press sets the location
- **WHEN** the user long-presses a position on the map
- **THEN** the app sets that position as the current location

#### Scenario: Long press replaces the previous location
- **WHEN** a location is already set and the user long-presses a different position
- **THEN** the current location becomes the new position

### Requirement: Location persists across launches
The app SHALL persist a manually set location and reuse it on the next launch.

#### Scenario: Location survives a relaunch
- **WHEN** the app is relaunched after a location was set
- **THEN** that location is the current location

### Requirement: Own-location display
The app SHALL display a marker at the current location while a location is known.

#### Scenario: Marker shown for a known location
- **WHEN** a location is known
- **THEN** the map shows a marker at that position

#### Scenario: Marker follows a location change
- **WHEN** the current location changes
- **THEN** the marker is drawn at the new position

#### Scenario: No marker without a location
- **WHEN** no location is known
- **THEN** no own-location marker is shown

### Requirement: Location changes propagate
The app SHALL notify interested components when the current location changes.

#### Scenario: Location update observed
- **WHEN** the current location changes
- **THEN** components relying on the location receive a location-update notification

#### Scenario: Setting a location notifies once
- **WHEN** the user sets a location to a different position than the current one
- **THEN** interested components receive exactly one update for that change

### Requirement: Centering on the location
The app SHALL centre the map on the current location on request.

#### Scenario: Center on the current location
- **WHEN** centring on the location is requested and a location is known
- **THEN** the map centres on that position

#### Scenario: Cannot center without a location
- **WHEN** centring on the location is requested and no location is known
- **THEN** the map is left unchanged
