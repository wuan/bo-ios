# Preferences (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/preferences/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Lets users configure map, animation, data source, location, alarm, and generic behaviour, and to back up or restore those settings.

## ADDED Requirements

### Requirement: Settings screen with categories
The app SHALL provide a settings screen organised into map, animation, data source, location, alarm, generic, and backup categories.

#### Scenario: Open settings
- **WHEN** the user opens settings from the menu
- **THEN** the settings screen displays the defined categories

#### Scenario: Category contents
- **WHEN** a category is displayed
- **THEN** it contains the settings defined for that category

### Requirement: Setting persistence and defaults
The app SHALL persist every setting and SHALL apply a defined default for any setting the user has not changed.

#### Scenario: Setting survives relaunch
- **WHEN** the user changes a setting and relaunches the app
- **THEN** the changed value is in effect

#### Scenario: Default applied when unset
- **WHEN** a setting has never been changed
- **THEN** its documented default value is in effect

### Requirement: Map settings
The app SHALL provide map settings for map mode, map scale, fade, colour scheme, own-location display, own-location size, and whether to keep zoom when going to the own location.

#### Scenario: Map mode change
- **WHEN** the user selects a different map mode
- **THEN** the base map is rendered in the selected mode

#### Scenario: Own-location size change
- **WHEN** the user changes the own-location size
- **THEN** the own-location marker is drawn at the selected size

### Requirement: Animation settings
The app SHALL provide settings for the animation step duration and the cycle pause duration.

#### Scenario: Animation speed change
- **WHEN** the user changes the animation step duration
- **THEN** animation advances at the new rate

### Requirement: Data source settings
The app SHALL provide settings for data source selection, service URL, and credentials, as defined by the data-providers capability.

#### Scenario: Data source settings affect requests
- **WHEN** the user changes the data source or service URL
- **THEN** subsequent requests use the new configuration

### Requirement: Location and alarm settings
The app SHALL provide location settings for location mode and manual coordinates, and alarm settings for alert enablement, background query period, distance limits, signals, and suppression.

#### Scenario: Manual coordinates accepted
- **WHEN** the user enters manual longitude and latitude
- **THEN** the app uses those coordinates as the current location in manual location mode

#### Scenario: Alarm settings applied
- **WHEN** the user changes an alarm setting
- **THEN** alert behaviour reflects the new value

### Requirement: Generic settings
The app SHALL provide generic settings for measurement units, keeping the screen awake, and diagnostics enablement.

#### Scenario: Measurement unit change
- **WHEN** the user selects metric or imperial units
- **THEN** displayed distances use the selected units

### Requirement: Preferences backup and restore
The app SHALL allow the user to export all settings to a portable form, import settings from such a form, and reset settings to defaults.

#### Scenario: Export settings
- **WHEN** the user exports settings
- **THEN** a portable representation of all settings is produced

#### Scenario: Import settings
- **WHEN** the user imports previously exported settings
- **THEN** the app applies the imported values

#### Scenario: Reset settings
- **WHEN** the user resets settings
- **THEN** all settings return to their default values

#### Scenario: Invalid import rejected
- **WHEN** the user imports an unreadable or invalid settings representation
- **THEN** the app reports the failure and leaves existing settings unchanged
