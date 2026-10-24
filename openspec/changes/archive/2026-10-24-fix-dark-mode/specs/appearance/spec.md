# Spec Delta

## Purpose

Keeps the app's own interface in step with the device's light or dark appearance, so every screen stays legible and the app launches without a light flash when the device is dark.

## ADDED Requirements

### Requirement: Follows the system appearance
The app SHALL render its own interface in the system appearance and SHALL NOT force a fixed light or dark appearance.

#### Scenario: Device in dark appearance
- **WHEN** the device is in dark appearance
- **THEN** the app's screen backgrounds, text, and controls render in dark

#### Scenario: Device in light appearance
- **WHEN** the device is in light appearance
- **THEN** the app's screen backgrounds, text, and controls render in light

#### Scenario: Appearance changes while running
- **WHEN** the device appearance changes while the app is in the foreground
- **THEN** the app's own interface updates to the new appearance without a relaunch

### Requirement: Own interface legible in both appearances
Every screen the app owns - the map screen, settings, quick settings, and the enlarged radar - SHALL keep its text and controls legible in both appearances, with each colour belonging to the app's own interface resolving to a contrast with what lies behind it.

#### Scenario: Map screen in dark appearance
- **WHEN** the map screen is shown in dark appearance
- **THEN** the status row and the bottom controls, and their text, remain legible

#### Scenario: Secondary screens in dark appearance
- **WHEN** the settings, quick-settings, or enlarged-radar screen is shown in dark appearance
- **THEN** its background, text, and controls remain legible

### Requirement: Launch appearance
The app SHALL provide a launch-screen appearance that follows the system appearance, so launching while the device is dark does not present a light screen.

#### Scenario: Launch in dark appearance
- **WHEN** the app launches while the device is in dark appearance
- **THEN** no light background is presented before the app's interface

### Requirement: On-map overlays stay legible over the map
The app SHALL keep the on-map overlays - the legend, histogram, radar, overview, and markers - legible over both light and dark base maps, independently of the system appearance, because the map imagery rather than the app's own background lies behind them.

#### Scenario: Overlay over either base map
- **WHEN** an on-map overlay is drawn over a light or a dark base map
- **THEN** its text and marks remain legible regardless of the system appearance
