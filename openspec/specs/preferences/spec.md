# preferences Specification

## Purpose

Lets users configure the app's map, animation, data source, location, alarm, and generic
behaviour from one categorised screen, and back up or restore those settings.

## Requirements

### Requirement: Settings screen with categories
The app SHALL provide a settings screen organised into map, animation, data source,
location, alarm, generic, and backup categories.

#### Scenario: Open settings
- **WHEN** the user opens settings from the app's settings control
- **THEN** the settings screen displays the defined categories

#### Scenario: Category contents
- **WHEN** a category is displayed
- **THEN** it contains the settings defined for that category

#### Scenario: Every user-facing setting is reachable
- **WHEN** the settings screen is inspected
- **THEN** every user-facing setting the app persists appears in exactly one category

### Requirement: Setting persistence and defaults
The app SHALL persist every user-facing setting and SHALL apply a defined default for any
setting the user has not changed.

#### Scenario: Setting survives relaunch
- **WHEN** the user changes a setting and relaunches the app
- **THEN** the changed value is in effect

#### Scenario: Default applied when unset
- **WHEN** a setting has never been changed
- **THEN** its documented default value is in effect

### Requirement: Documented settings reference
The app SHALL document each user-facing setting with the category it belongs to and its
default, and the documented defaults SHALL match the values the app applies.

#### Scenario: Documented defaults match the code
- **WHEN** the documented defaults are compared with the defaults the app applies
- **THEN** they agree for every user-facing setting

### Requirement: Map settings
The app SHALL provide map settings for map mode, fade, colour scheme, own-location
display, own-location size, and whether to keep the zoom when going to the own location.

#### Scenario: Map mode change
- **WHEN** the user selects a different map mode
- **THEN** the base map is rendered in the selected mode

#### Scenario: Fade change
- **WHEN** the user changes the fade
- **THEN** the dimming drawn over the base map follows the new value

#### Scenario: Own-location display change
- **WHEN** the user switches the own-location display off
- **THEN** the own-location marker is not drawn while a location is known

#### Scenario: Own-location size change
- **WHEN** the user changes the own-location size
- **THEN** the own-location marker is drawn at the selected size

#### Scenario: Keep-zoom choice is applied
- **WHEN** the user centres the map on the current location
- **THEN** the zoom is kept or reset as the keep-zoom setting says

### Requirement: Animation settings
The app SHALL provide settings for the animation step duration and the cycle pause
duration, and SHALL apply both to animation playback.

#### Scenario: Animation speed change
- **WHEN** the user changes the animation step duration
- **THEN** animation advances at the new rate

#### Scenario: Cycle pause change
- **WHEN** the user changes the cycle pause duration
- **THEN** playback pauses for that duration when it cycles back to the beginning

### Requirement: Data source settings
The app SHALL provide settings for the data region, the interval duration, the historic
timestep, the data source selection, the service URL, and credentials for sources that
require them.

#### Scenario: Data source settings affect requests
- **WHEN** the user changes the data source or service URL
- **THEN** subsequent requests use the new configuration

#### Scenario: Time and region settings apply
- **WHEN** the user changes the region, the interval duration, or the historic timestep
- **THEN** the displayed data follows the new selection

### Requirement: Location and alarm settings
The app SHALL provide location settings for the location mode and the manual coordinates,
and alarm settings for alert enablement, the background query period, the notification and
signalling distance limits, the sound and vibration signals, and the signal suppression
time.

#### Scenario: Manual coordinates accepted
- **WHEN** the user enters manual longitude and latitude
- **THEN** the app uses those coordinates as the current location in manual location mode

#### Scenario: Alarm settings applied
- **WHEN** the user changes an alarm setting
- **THEN** alert behaviour reflects the new value

#### Scenario: Background query period applied
- **WHEN** the user changes the background query period
- **THEN** background monitoring follows the new period, and switches off when the period is off

### Requirement: Generic settings
The app SHALL provide generic settings for measurement units, keeping the screen awake,
and diagnostics enablement.

#### Scenario: Measurement unit change
- **WHEN** the user selects metric or imperial units
- **THEN** displayed distances use the selected units

#### Scenario: Keep-awake change
- **WHEN** the user enables keeping the screen awake
- **THEN** the app keeps the display awake while it is in the foreground, and stops doing so when disabled

#### Scenario: Diagnostics change
- **WHEN** the user enables diagnostics
- **THEN** the app records diagnostic output while it is enabled, and records none while it is disabled

### Requirement: Preferences backup and restore
The app SHALL allow the user to export its user-facing settings to a portable
representation, import settings from such a representation, and reset settings to their
defaults. The export SHALL exclude credentials unless the user explicitly opts in.

#### Scenario: Export settings
- **WHEN** the user exports settings
- **THEN** a portable representation of the user-facing settings is produced

#### Scenario: Credentials excluded by default
- **WHEN** the user exports settings without opting in to including credentials
- **THEN** the representation contains no credentials

#### Scenario: Credentials included on request
- **WHEN** the user exports settings with the opt-in
- **THEN** the representation contains the credentials the app has stored

#### Scenario: Import settings
- **WHEN** the user imports a previously exported representation
- **THEN** the app applies the imported values

#### Scenario: Reset settings
- **WHEN** the user resets settings
- **THEN** every user-facing setting returns to its default value

#### Scenario: Invalid import rejected
- **WHEN** the user imports an unreadable or invalid representation
- **THEN** the app reports the failure and leaves existing settings unchanged
