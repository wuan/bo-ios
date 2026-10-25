# Spec Delta

## Purpose

Provides the application menu and the informational surfaces behind it: the application
log, the change log, and the information/version display with its update check.

## ADDED Requirements

### Requirement: Application menu
The app SHALL provide a menu offering settings, alarms, application log, change log, and
information entries.

#### Scenario: Open menu
- **WHEN** the user opens the menu
- **THEN** the menu presents settings, alarms, application log, change log, and information entries

#### Scenario: Menu entries open their surface
- **WHEN** the user selects a menu entry
- **THEN** the corresponding screen or dialog opens

#### Scenario: Settings entry reaches the settings screen
- **WHEN** the user selects the settings entry
- **THEN** the settings screen opens

#### Scenario: Alarms entry reaches the alarm surface
- **WHEN** the user selects the alarms entry
- **THEN** the alarm surface opens

### Requirement: Control state by mode
The app SHALL present mode-appropriate controls: starting animation in realtime and history
modes, jumping to realtime in history mode, and stopping animation in animation mode.

#### Scenario: Realtime controls
- **WHEN** the app is in realtime mode
- **THEN** the controls offer starting animation

#### Scenario: History controls
- **WHEN** the app is in history mode
- **THEN** the controls offer starting animation and jumping to realtime

#### Scenario: Animation controls
- **WHEN** the app is in animation mode
- **THEN** the controls offer stopping animation

#### Scenario: Jump to realtime
- **WHEN** the user jumps to realtime from history mode
- **THEN** the app returns to realtime mode and shows the most recent interval

### Requirement: Application log
The app SHALL provide a view of the internal log content it records, and SHALL allow the
user to send that log for support.

#### Scenario: View log
- **WHEN** the user opens the application log
- **THEN** the recorded log entries are displayed, oldest first

#### Scenario: Empty log
- **WHEN** the user opens the application log while nothing has been recorded
- **THEN** the view shows an explicit empty state rather than failing

#### Scenario: Send log
- **WHEN** the user chooses to send the log
- **THEN** the app creates a message containing the log content for support

### Requirement: Change log
The app SHALL present recent feature changes by version, read from the app's bundled
change log.

#### Scenario: View change log
- **WHEN** the user opens the change log
- **THEN** recent changes are listed by version, newest first

#### Scenario: Missing or unreadable change log
- **WHEN** the bundled change log cannot be read or contains no entries
- **THEN** the view shows an explicit empty state rather than failing

### Requirement: Information and version
The app SHALL present app information including the installed version and build.

#### Scenario: View information
- **WHEN** the user opens information
- **THEN** the app displays app-related information including the current version

### Requirement: Update check
The app SHALL compare the installed version with the version available from the App Store
and notify the user when a newer version is available, and SHALL not notify when it is up
to date or when the store cannot be reached.

#### Scenario: Update available
- **WHEN** a newer version is available
- **THEN** the app notifies the user

#### Scenario: Up to date
- **WHEN** no newer version is available
- **THEN** the app does not notify the user

#### Scenario: Store unreachable
- **WHEN** the available version cannot be determined
- **THEN** the app does not notify the user
