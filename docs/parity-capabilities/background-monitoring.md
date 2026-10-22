# Background monitoring (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/background-monitoring/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Keeps monitoring for nearby lightning while the app is not in the foreground, so alerts continue to work when the screen is closed.

## ADDED Requirements

### Requirement: Background monitoring service
The app SHALL run a background monitoring service while background alerts are enabled and the app is not in the foreground.

#### Scenario: Background alerts enabled
- **WHEN** background alerts are enabled and the app leaves the foreground
- **THEN** the background monitoring service continues fetching data and evaluating alerts

#### Scenario: Background alerts disabled
- **WHEN** background alerts are disabled
- **THEN** the background monitoring service is not started

### Requirement: Periodic data fetching
The app SHALL fetch lightning data periodically in the background at a configurable query period.

#### Scenario: Periodic fetch occurs
- **WHEN** the background query period elapses during background monitoring
- **THEN** the app fetches fresh lightning data

#### Scenario: Period changes take effect
- **WHEN** the user changes the background query period
- **THEN** subsequent background fetches use the new period

### Requirement: Background notification
The app SHALL present a persistent notification while background monitoring is active, consistent with platform foreground-service requirements.

#### Scenario: Monitoring notification shown
- **WHEN** background monitoring is active
- **THEN** a persistent notification indicates that monitoring is running

#### Scenario: Monitoring notification removed
- **WHEN** background monitoring stops
- **THEN** the persistent notification is removed

### Requirement: Lifecycle transitions
The app SHALL start background monitoring when it leaves the foreground with alerts enabled and SHOULD stop it when the app returns to the foreground.

#### Scenario: Enter background
- **WHEN** the app moves to the background with background alerts enabled
- **THEN** background monitoring starts

#### Scenario: Return to foreground
- **WHEN** the app returns to the foreground
- **THEN** foreground data updates resume and background polling stops

### Requirement: Restoration after reboot or relaunch
The app SHALL re-establish background monitoring after a device restart or when monitoring is otherwise interrupted, provided alerts remain enabled.

#### Scenario: Restored after restart
- **WHEN** the device restarts and background alerts are enabled
- **THEN** background monitoring is re-established

#### Scenario: Not restored when disabled
- **WHEN** the device restarts and background alerts are disabled
- **THEN** no background monitoring is started
