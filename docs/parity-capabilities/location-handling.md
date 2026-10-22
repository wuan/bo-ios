# Location handling (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/location-handling/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Determines the user's location from device sensors or manual input and exposes it for display, data-area computation, and alerts.

## ADDED Requirements

### Requirement: Location modes
The app SHALL support multiple location modes, including network-based, GPS-based, passive, and manual.

#### Scenario: Network mode
- **WHEN** the network location mode is active and a position is available
- **THEN** the app uses the network-provided position

#### Scenario: GPS mode
- **WHEN** the GPS location mode is active and a position is available
- **THEN** the app uses the GPS-provided position

#### Scenario: Manual mode
- **WHEN** the manual location mode is active
- **THEN** the app uses the user-specified coordinates and does not require device location

### Requirement: Location permission handling
The app SHALL request location permission when a device-based mode needs it and SHALL explain any background location use before requesting it.

#### Scenario: Permission granted
- **WHEN** the user grants location permission
- **THEN** device-based location becomes available

#### Scenario: Permission denied
- **WHEN** the user denies location permission
- **THEN** the app continues to function with manual location

#### Scenario: Background disclosure
- **WHEN** the app requires background location for alerts
- **THEN** it presents a disclosure explaining the use before requesting the permission

### Requirement: Manual location by long press
The app SHALL allow the user to set the current location manually by long-pressing a position on the map.

#### Scenario: Long press sets location
- **WHEN** the user long-presses a position on the map
- **THEN** the app sets that position as the current location

### Requirement: Own-location display
The app SHALL optionally display the user's position on the map at a configurable size.

#### Scenario: Show own location
- **WHEN** own-location display is enabled and a location is known
- **THEN** the map shows a marker at the current location

#### Scenario: Hide own location
- **WHEN** own-location display is disabled
- **THEN** no own-location marker is shown

### Requirement: Center on own location
The app SHALL provide a way to center the map on the user's location while honouring the keep-zoom setting.

#### Scenario: Center keeping zoom
- **WHEN** the user centers on the own location and keep-zoom is enabled
- **THEN** the map centers on the location without changing the zoom level

#### Scenario: Center with default zoom
- **WHEN** the user centers on the own location and keep-zoom is disabled
- **THEN** the map centers on the location and adjusts the zoom level

### Requirement: Location changes propagate
The app SHALL notify interested components when the current location changes.

#### Scenario: Location update observed
- **WHEN** the current location changes
- **THEN** components relying on location receive a location-update notification
