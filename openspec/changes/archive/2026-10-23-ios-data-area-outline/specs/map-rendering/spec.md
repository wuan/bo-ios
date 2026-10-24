# Spec Delta

## ADDED Requirements

### Requirement: Data-area boundary
The app SHALL draw the boundary of the displayed result's data area as a single outline on the map, replacing any outline already drawn, and SHALL draw none while the displayed result carries no data area.

#### Scenario: Boundary drawn for the displayed result
- **WHEN** a displayed result carries a data area
- **THEN** the map shows the boundary of that data area

#### Scenario: Boundary follows the data area
- **WHEN** a later result carries a different data area
- **THEN** the map shows the boundary of the new data area instead of the previous one

#### Scenario: Boundary is not accumulated
- **WHEN** several results are displayed one after another
- **THEN** only one boundary outline remains on the map

#### Scenario: No boundary without a data area
- **WHEN** the displayed result carries no data area
- **THEN** the map shows no boundary outline
