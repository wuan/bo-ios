# Spec Delta

## Purpose

Provides the application menu and informational surfaces for settings, alerts, diagnostics, release notes, and version info.

## ADDED Requirements

### Requirement: Application menu
The app SHALL provide a menu offering settings, alarms, application log, change log, and information.

#### Scenario: Open menu
- **WHEN** the user opens the menu
- **THEN** the menu presents settings, alarms, application log, change log, and information entries

#### Scenario: Menu entries open their surface
- **WHEN** the user selects a menu entry
- **THEN** the corresponding screen or dialog opens

### Requirement: Control state by mode
The app SHALL present mode-appropriate controls: start animation in realtime and history modes, and stop animation in animation mode.

#### Scenario: Realtime controls
- **WHEN** the app is in realtime mode
- **THEN** the controls offer starting animation

#### Scenario: History controls
- **WHEN** the app is in history mode
- **THEN** the controls offer starting animation and jumping to realtime

#### Scenario: Animation controls
- **WHEN** the app is in animation mode
- **THEN** the controls offer stopping animation

### Requirement: Application log
The app SHALL provide a view of internal log content and SHALL allow the user to send that log for support.

#### Scenario: View log
- **WHEN** the user opens the application log
- **THEN** recent internal log entries are displayed

#### Scenario: Send log
- **WHEN** the user chooses to send the log
- **THEN** the app creates a message containing the log content for support

### Requirement: Change log
The app SHALL present recent feature changes by version.

#### Scenario: View change log
- **WHEN** the user opens the change log
- **THEN** recent changes are listed by version

### Requirement: Information and version
The app SHALL present app information and its current version.

#### Scenario: View information
- **WHEN** the user opens information
- **THEN** the app displays app-related information including the current version

### Requirement: Update check
The app SHALL evaluate installed version information and notify the user when an update is available.

#### Scenario: Update available
- **WHEN** a newer version is available
- **THEN** the app notifies the user

#### Scenario: Up to date
- **WHEN** no newer version is available
- **THEN** the app does not notify the user
