# Proximity alerts (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/proximity-alerts/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Warns the user when lightning occurs near their location, using sector/range aggregation, configurable limits, and sound or vibration signals.

## ADDED Requirements

### Requirement: Enabling proximity alerts
The app SHALL allow proximity alerts to be enabled or disabled, and SHALL only monitor when enabled.

#### Scenario: Alerts enabled
- **WHEN** proximity alerts are enabled and a location is known
- **THEN** the app monitors incoming lightning data for nearby activity

#### Scenario: Alerts disabled
- **WHEN** proximity alerts are disabled
- **THEN** the app performs no alert monitoring or signalling

### Requirement: Sector and range aggregation
The app SHALL divide the surroundings into angular sectors and distance ranges and SHALL assign each monitored strike to a sector and range.

#### Scenario: Strike assigned to sector and range
- **WHEN** a strike is evaluated
- **THEN** it is assigned to the sector and distance range matching its bearing and distance from the current location

#### Scenario: Closest strike tracked
- **WHEN** multiple strikes are within the monitored window
- **THEN** the app tracks the closest strike and its distance and bearing

### Requirement: Monitored time window
The app SHALL consider only strikes within a configurable time window when computing alert state.

#### Scenario: Strike outside window ignored
- **WHEN** a strike is older than the monitored time window
- **THEN** it does not contribute to the current alert state

### Requirement: Notification distance limit
The app SHALL raise a notification when lightning is detected within a configurable notification distance limit.

#### Scenario: Strike inside notification limit
- **WHEN** a detected strike falls within the notification distance limit
- **THEN** the app raises a notification

#### Scenario: Strike outside notification limit
- **WHEN** a detected strike is farther than the notification distance limit
- **THEN** the app raises no notification

### Requirement: Signalling distance limit
The app SHALL emit a sound and/or vibration signal when lightning is detected within a configurable signalling distance limit that is normally closer than the notification limit.

#### Scenario: Strike inside signalling limit
- **WHEN** a detected strike falls within the signalling distance limit
- **THEN** the app emits the configured sound and vibration signals

#### Scenario: Configurable signal strength
- **WHEN** the user changes the vibration signal or sound setting
- **THEN** subsequent signals use the new setting

### Requirement: Signal suppression
The app SHALL suppress repeated signals for a configurable duration after a signal is emitted.

#### Scenario: Suppression window active
- **WHEN** a signal has been emitted and the suppression duration has not elapsed
- **THEN** no further signal is emitted even if new qualifying strikes arrive

### Requirement: Alert state reporting
The app SHALL report alert state so that the alarm radar can display active, inactive, and outside-data-area states.

#### Scenario: Active alert reported
- **WHEN** a qualifying strike is detected
- **THEN** the app reports an active alert state with the closest strike information

#### Scenario: Alert cancelled
- **WHEN** no qualifying strikes remain within the monitored window
- **THEN** the app reports that the alert is cancelled
