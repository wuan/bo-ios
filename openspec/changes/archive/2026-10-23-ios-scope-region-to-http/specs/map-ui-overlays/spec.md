# Spec Delta

## MODIFIED Requirements

### Requirement: Legend
The app SHALL display a legend describing the colour-to-age mapping and the region actually requested, together with the grid baseline when one is active.

#### Scenario: Age colour mapping shown
- **WHEN** the legend is displayed
- **THEN** it shows a colour scale from newest to oldest activity with the corresponding time ranges

#### Scenario: Region and grid baseline shown
- **WHEN** a grid baseline is active for the displayed result
- **THEN** the legend displays the grid baseline value together with the region name

#### Scenario: Region name reflects the request
- **WHEN** the app requests data for a region
- **THEN** the legend displays the name of that requested region, so a JSON-RPC request shows the automatically selected local or global region and an HTTP request shows its named region

#### Scenario: Local region size shown
- **WHEN** the local region is active
- **THEN** the legend displays the local region size

### Requirement: Quick settings
The app SHALL open a quick-settings dialog when the user taps the legend, offering the interval duration, historic timestep, data source, colour scheme, map mode, and base-map fade, and SHALL offer a region selection only while the Blitzortung HTTP source is active, listing named regions. It SHALL apply a change without leaving the map.

#### Scenario: Open quick settings
- **WHEN** the user taps the legend
- **THEN** a quick-settings dialog opens

#### Scenario: Change applies to the map
- **WHEN** the user changes a setting in the quick-settings dialog
- **THEN** the map reflects the change when the dialog closes and the map is never left

#### Scenario: Changed setting persists
- **WHEN** the app is relaunched after a quick setting was changed
- **THEN** the app uses the changed value

#### Scenario: Region offered only for the HTTP source
- **WHEN** the active data source is the JSON-RPC source
- **THEN** the quick-settings dialog does not offer a region selection

#### Scenario: Region lists named regions for HTTP
- **WHEN** the active data source is the Blitzortung HTTP source
- **THEN** the quick-settings dialog offers the named regions

#### Scenario: Region appears when the source changes
- **WHEN** the user changes the data source to the Blitzortung HTTP source within the open dialog
- **THEN** the region selection becomes available without closing the dialog
