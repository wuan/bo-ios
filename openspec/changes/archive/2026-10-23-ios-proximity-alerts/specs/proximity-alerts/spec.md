# Spec Delta

## ADDED Requirements

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
