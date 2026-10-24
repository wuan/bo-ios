# Spec Delta

## ADDED Requirements

### Requirement: Device location modes
The app SHALL support network-based, GPS-based, and passive device location modes alongside the manual one, and SHALL obtain the position from the device in those modes rather than from stored coordinates.

#### Scenario: Network mode
- **WHEN** the network location mode is active and the device reports a position
- **THEN** the app uses the device's network-provided position as the current location

#### Scenario: GPS mode
- **WHEN** the GPS location mode is active and the device reports a position
- **THEN** the app uses the device's GPS-provided position as the current location

#### Scenario: Passive mode
- **WHEN** the passive location mode is active
- **THEN** the app adopts positions the device produces without requesting location updates of its own

#### Scenario: Device position becomes the current location
- **WHEN** a device-backed mode reports a new position
- **THEN** the current location changes to that position and observers are notified

### Requirement: Location permission handling
The app SHALL request location permission when a device-backed mode needs it, and SHALL leave the app usable with a manual location when that permission is not granted.

#### Scenario: Permission granted
- **WHEN** the user grants location permission for a device-backed mode
- **THEN** device-provided positions become available to the app

#### Scenario: Permission refused
- **WHEN** the user refuses location permission
- **THEN** the app continues to function with a manual location

#### Scenario: Manual mode asks for nothing
- **WHEN** the manual location mode is active
- **THEN** no location permission is requested

### Requirement: Background location disclosure
The app SHALL explain what it uses background location for before that permission is requested, and SHALL show that explanation only until the user has acknowledged it.

#### Scenario: Disclosure precedes the request
- **WHEN** the app is about to request background location
- **THEN** it presents the explanation of that use before the permission is requested

#### Scenario: Disclosure shown once
- **WHEN** the user has acknowledged the background-location explanation
- **THEN** the app does not present it again

## MODIFIED Requirements

### Requirement: Own-location display
The app SHALL display a marker at the current location while a location is known and own-location display is enabled, and SHALL draw that marker at the size the user has chosen.

#### Scenario: Marker shown for a known location
- **WHEN** a location is known and own-location display is enabled
- **THEN** the map shows a marker at that position

#### Scenario: Marker follows a location change
- **WHEN** the current location changes
- **THEN** the marker is drawn at the new position

#### Scenario: No marker without a location
- **WHEN** no location is known
- **THEN** no own-location marker is shown

#### Scenario: No marker while display is switched off
- **WHEN** own-location display is disabled
- **THEN** no own-location marker is shown even while a location is known

#### Scenario: Marker drawn at the chosen size
- **WHEN** the own-location size setting changes
- **THEN** the marker is drawn at the chosen size

### Requirement: Centering on the location
The app SHALL centre the map on the current location on request, honouring the keep-zoom choice.

#### Scenario: Center on the current location
- **WHEN** centring on the location is requested and a location is known
- **THEN** the map centres on that position

#### Scenario: Cannot center without a location
- **WHEN** centring on the location is requested and no location is known
- **THEN** the map is left unchanged

#### Scenario: Center keeps the zoom
- **WHEN** keep-zoom is enabled and centring on the location is requested
- **THEN** the map centres on the location without changing its zoom level

#### Scenario: Center applies the default zoom
- **WHEN** keep-zoom is disabled and centring on the location is requested
- **THEN** the map centres on the location and adjusts its zoom level
