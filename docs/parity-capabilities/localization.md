# Localization (capability sketch)

Planned capability for the [parity roadmap](../parity-roadmap.md). Lift these
requirements into `openspec/changes/<phase>/specs/localization/spec.md` when the phase
starts; the delta headers are intentional.

## Purpose

Presents all user-facing text in the user's language, matching the language set offered by the Android app.

## ADDED Requirements

### Requirement: Externalized user-facing text
The app SHALL externalize all user-facing text into localizable string resources rather than embedding literal strings in code.

#### Scenario: UI text is localizable
- **WHEN** user-facing text is displayed
- **THEN** it is resolved from a localizable string resource

#### Scenario: No hard-coded user-facing text
- **WHEN** a user-facing label, dialog, or message is added
- **THEN** it is defined as a string resource

### Requirement: Supported languages
The app SHALL provide translations for the same language set as the Android app, at minimum English, Czech, Dutch, French, German, Hungarian, Italian, Polish, Slovak, Russian, and Spanish.

#### Scenario: Translated language available
- **WHEN** the device language is one of the supported languages
- **THEN** the app displays text in that language

#### Scenario: Unsupported language falls back
- **WHEN** the device language is not among the supported languages
- **THEN** the app displays text in the default language

### Requirement: Localized formatting
The app SHALL format numbers, units, and times according to the active locale and the configured measurement system.

#### Scenario: Locale-aware formatting
- **WHEN** values such as distances or times are displayed
- **THEN** they are formatted according to the active locale

#### Scenario: Measurement system honoured
- **WHEN** a measurement unit setting is active
- **THEN** localized value labels use the selected measurement system
