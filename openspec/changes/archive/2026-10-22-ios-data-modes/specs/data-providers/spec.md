# Spec Delta

## Purpose

Scopes stale-result rejection to a single request selection. Realtime refreshes
repeatedly for the same selection and still needs out-of-order responses
discarded, while history and animation select intervals whose reference
timestamps are older than realtime and must not be mistaken for stale answers.

## MODIFIED Requirements

### Requirement: Stale result rejection
The app SHALL reject a data result that is not newer than the most recently accepted result for the same request parameters, so an out-of-order response for a selection never replaces fresher data for that selection, while a result for a different selection is accepted.

#### Scenario: Older response is discarded
- **WHEN** a response arrives whose freshness indicator is older than the last accepted result for the same request parameters
- **THEN** the app does not replace the current displayed data with it

#### Scenario: First result is always accepted
- **WHEN** a result arrives and no result has been accepted yet for those parameters
- **THEN** the app accepts it as the current data

#### Scenario: Result for a different selection is accepted
- **WHEN** a response arrives for different request parameters than the last accepted result, even with an older freshness indicator
- **THEN** the app accepts it as the current data
