# settings-store Specification

## Purpose

Provides a single, typed place for the app to read and write user and application settings, so later features share consistent persistence, defaults, and change notification.

## Requirements

### Requirement: Typed settings access
The app SHALL expose settings through typed, named accessors rather than raw key/value lookups.

#### Scenario: Read a string setting
- **WHEN** the app reads a setting defined as a string
- **THEN** it receives a string value

#### Scenario: Read a numeric setting
- **WHEN** the app reads a setting defined as a number or boolean
- **THEN** it receives the value in that type

### Requirement: Registered defaults
The app SHALL define a default for every setting and SHALL return that default when the user has not changed the setting.

#### Scenario: Unset setting returns default
- **WHEN** a setting has never been changed
- **THEN** reading it returns its registered default

#### Scenario: All settings have defaults
- **WHEN** the set of defined settings is inspected
- **THEN** every setting has an associated default value

### Requirement: Persistence across launches
The app SHALL persist every setting change so that it survives app relaunch.

#### Scenario: Changed setting survives relaunch
- **WHEN** the app changes a setting and is relaunched
- **THEN** reading that setting returns the changed value

#### Scenario: Reset restores defaults
- **WHEN** settings are reset
- **THEN** every setting reads its registered default

### Requirement: Change observation
The app SHALL notify registered observers when a setting changes, identifying which setting changed.

#### Scenario: Observer notified on change
- **WHEN** a setting is changed and an observer is registered for it
- **THEN** the observer is notified of the change

#### Scenario: Observer not notified for other settings
- **WHEN** a setting is changed and an observer is registered for a different setting
- **THEN** that observer is not notified
