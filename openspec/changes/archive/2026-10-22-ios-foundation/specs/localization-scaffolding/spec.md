# Spec Delta

## Purpose

Externalizes user-facing text into a base catalog so later phases can add translations without touching code.

## ADDED Requirements

### Requirement: Externalized user-facing text
The app SHALL resolve user-facing text from localizable resources rather than embedding literal strings in code.

#### Scenario: UI text is localizable
- **WHEN** user-facing text is displayed
- **THEN** it is resolved from a localizable resource by key

#### Scenario: New text is externalized
- **WHEN** user-facing text is added
- **THEN** it is defined as a resource entry rather than a code literal

### Requirement: Base catalog
The app SHALL provide a base String Catalog that defines the keys for all externalized text.

#### Scenario: Base catalog present
- **WHEN** the app is built
- **THEN** a base String Catalog containing the externalized keys is included in the bundle

#### Scenario: Keys resolve
- **WHEN** a defined key is looked up
- **THEN** its base-language value is returned

### Requirement: Locale fallback
The app SHALL display base-language text when no translation exists for the active language.

#### Scenario: Missing translation falls back
- **WHEN** the active language has no translation for a key
- **THEN** the base-language value is displayed
