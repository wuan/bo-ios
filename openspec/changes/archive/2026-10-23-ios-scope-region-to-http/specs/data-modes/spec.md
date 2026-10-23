# Spec Delta

## MODIFIED Requirements

### Requirement: Region selection
The app SHALL select the data region from the active data source rather than from the stored setting alone. The JSON-RPC source SHALL use the automatic extent-derived local or global region and SHALL ignore the stored region. The Blitzortung HTTP source SHALL use the stored region when it is a named region, and SHALL resolve any other stored value to Europe.

#### Scenario: JSON-RPC selects the region automatically
- **WHEN** the JSON-RPC source is active
- **THEN** requests use the extent-derived local or global region regardless of the stored region value

#### Scenario: Global region
- **WHEN** the JSON-RPC source selects the global extent
- **THEN** requests cover global data and no local data area is applied

#### Scenario: Local region
- **WHEN** the JSON-RPC source selects the local extent
- **THEN** requests are limited to a data area derived from the current extent

#### Scenario: HTTP uses the stored named region
- **WHEN** the Blitzortung HTTP source is active and the stored region is a named region
- **THEN** requests use that named region

#### Scenario: HTTP resolves a non-named stored region
- **WHEN** the Blitzortung HTTP source is active and the stored region is not a named region
- **THEN** requests use Europe

#### Scenario: Changing the source re-resolves the region
- **WHEN** the active data source changes
- **THEN** the region used for the next request follows the newly active source
