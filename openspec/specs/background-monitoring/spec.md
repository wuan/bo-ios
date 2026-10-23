# background-monitoring Specification

## Purpose

Keeps the proximity alert decision running while the app is not in the foreground, so a qualifying strike still reaches the user with the screen off, within the platform's best-effort background scheduling.

## Requirements

### Requirement: Background monitoring service
The app SHALL monitor for lightning while it is not in the foreground whenever proximity alerts are enabled and a background query period is set, and SHALL NOT run that monitoring otherwise.

#### Scenario: Enabled by alerts and a period
- **WHEN** alerts are enabled and the background query period is not off
- **THEN** the app monitors for lightning while it is not in the foreground

#### Scenario: Period off
- **WHEN** the background query period is off
- **THEN** no background monitoring runs even while alerts are enabled

#### Scenario: Alerts off
- **WHEN** proximity alerts are disabled
- **THEN** no background monitoring runs regardless of the period

### Requirement: Background query period
The app SHALL let the user set a background query period, SHALL pace background fetches at that interval, and SHALL offer the values off, 1, 2, 5, 10, 15, 30, 60, and 120 minutes, with off as the default.

#### Scenario: Period selected
- **WHEN** the user selects a background query period
- **THEN** background fetches are paced at that interval

#### Scenario: Period change takes effect
- **WHEN** the user changes the period while monitoring is enabled
- **THEN** subsequent background fetches use the new period

#### Scenario: Default is off
- **WHEN** the period has never been set
- **THEN** it is off and no background monitoring runs

#### Scenario: Value outside the set
- **WHEN** a stored period is not one of the offered values
- **THEN** it is treated as off

### Requirement: Periodic background fetching
The app SHALL fetch the current strike data on each background wake-up while monitoring is enabled and SHALL evaluate the alert decision on the result, using the same data source and decision as the foreground.

#### Scenario: Background fetch and evaluation
- **WHEN** a background wake-up occurs while monitoring is enabled
- **THEN** the app fetches the current interval and evaluates the alert decision on the result

#### Scenario: Deferred wake-up
- **WHEN** the system defers a background wake-up beyond the configured period
- **THEN** the fetch happens at the later time the system allows

#### Scenario: No fetch without monitoring
- **WHEN** monitoring is not enabled
- **THEN** no background fetch is made

#### Scenario: The same strike is not warned twice
- **WHEN** a strike notified in the background is still the newest qualifying strike at the next evaluation
- **THEN** no second notification is raised for it

### Requirement: Background notification readiness
The app SHALL hold notification authorisation while monitoring is enabled, asking for it if not yet decided, so a qualifying strike found in the background is delivered as a notification.

#### Scenario: Authorisation requested
- **WHEN** background monitoring becomes enabled and notification authorisation has not been decided
- **THEN** the app asks for it

#### Scenario: Alert delivered in the background
- **WHEN** a background evaluation finds a qualifying strike and notification authorisation is granted
- **THEN** the app delivers a notification for that strike

### Requirement: No persistent monitoring notification
The app SHALL NOT present a persistent notification for a running background monitoring session, because the platform provides no foreground service; the notification for a qualifying strike is the only notification monitoring produces.

#### Scenario: Monitoring runs without a persistent notification
- **WHEN** background monitoring is active
- **THEN** no persistent notification is shown

### Requirement: Background location
The app SHALL obtain a device position while monitoring in a device-backed location mode, requesting background location authorisation behind the background-location disclosure.

#### Scenario: Background authorisation requested
- **WHEN** monitoring is enabled in a device-backed location mode and only foreground authorisation is held
- **THEN** the app requests background location authorisation

#### Scenario: Disclosure precedes the request
- **WHEN** background location authorisation is about to be requested
- **THEN** the background-location explanation is presented first while it is still due

#### Scenario: Position available with the screen off
- **WHEN** monitoring is enabled in a device-backed mode and background location is authorised
- **THEN** the app receives device positions while it is not in the foreground

### Requirement: Lifecycle transitions
The app SHALL schedule background monitoring when it enters the background with monitoring enabled, and SHALL stop scheduling it when it returns to the foreground.

#### Scenario: Enter background
- **WHEN** the app moves to the background with monitoring enabled
- **THEN** background fetching is scheduled

#### Scenario: Return to foreground
- **WHEN** the app returns to the foreground
- **THEN** background fetching stops and foreground updates resume

### Requirement: Restoration after relaunch
The app SHALL re-establish background monitoring on launch while alerts are enabled and the period is not off, so an interrupted or restarted app resumes monitoring.

#### Scenario: Restored on launch
- **WHEN** the app launches with alerts enabled and a period set
- **THEN** background monitoring is scheduled again

#### Scenario: Not restored when disabled
- **WHEN** the app launches with alerts disabled or the period off
- **THEN** no background monitoring is scheduled
