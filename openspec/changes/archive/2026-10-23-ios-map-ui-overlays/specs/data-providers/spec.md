# Spec Delta

## ADDED Requirements

### Requirement: Strike-rate histogram in grid results
The app SHALL expose the strike-rate histogram that a grid result reports for the displayed period as part of the parsed result, so the histogram overlay needs no request of its own.

#### Scenario: Histogram parsed with grid results
- **WHEN** a grid result carries a histogram for the displayed period
- **THEN** the parsed result exposes the strike rate for each part of that period

#### Scenario: Result without a histogram
- **WHEN** a result carries no histogram
- **THEN** the parsed result reports no histogram value and no separate request is made for one

#### Scenario: Non-grid source
- **WHEN** the active source does not serve grid data
- **THEN** no histogram is expected or exposed for that result
