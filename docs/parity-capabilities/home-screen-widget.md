# Home-screen widget (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/home-screen-widget/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Surfaces current local lightning activity on the home screen so users can check alert status without opening the app.

## ADDED Requirements

### Requirement: Widget content
The app SHALL provide a home-screen widget that displays the alarm radar for the user's current location.

#### Scenario: Radar shown with data
- **WHEN** lightning data and a location are available
- **THEN** the widget displays the alarm radar reflecting current nearby activity

#### Scenario: Radar shown without data
- **WHEN** no lightning data or location is available
- **THEN** the widget displays an inactive or unavailable state

### Requirement: Automatic widget updates
The app SHALL refresh the widget automatically on a periodic schedule.

#### Scenario: Scheduled refresh
- **WHEN** the widget refresh interval elapses
- **THEN** the widget requests current data and redraws

### Requirement: Widget tap actions
The widget SHALL trigger an immediate data refresh on a single tap and open the app on a double tap.

#### Scenario: Single tap refreshes
- **WHEN** the user single-taps the widget
- **THEN** the widget triggers an immediate data update and shows a progress indicator

#### Scenario: Double tap opens app
- **WHEN** the user double-taps the widget
- **THEN** the main app opens
