# Spec Delta

## Purpose

Supplies lightning strike data to the app from configurable remote sources, insulating the rest of the app from provider-specific transport and payload formats.

## ADDED Requirements

### Requirement: Selectable data source
The app SHALL allow the user to select which data source implementation supplies lightning data, and SHALL persist the selection.

#### Scenario: User selects the JSON-RPC source
- **WHEN** the user selects the JSON-RPC data source
- **THEN** subsequent strike requests are issued through the JSON-RPC provider

#### Scenario: User selects the Blitzortung HTTP source
- **WHEN** the user selects the Blitzortung HTTP data source
- **THEN** subsequent strike requests are issued through the HTTP provider

#### Scenario: Selected source persists across launches
- **WHEN** the user relaunches the app after selecting a data source
- **THEN** the previously selected data source is used

### Requirement: Configurable service endpoint
The app SHALL allow the user to override the service URL used by the active data source, and SHALL fall back to a built-in default when no override is set.

#### Scenario: Custom URL is used
- **WHEN** the user sets a custom service URL and triggers a data request
- **THEN** the request is sent to the custom URL

#### Scenario: Default endpoint when unset
- **WHEN** no service URL has been configured
- **THEN** requests are sent to the provider's default endpoint

### Requirement: Provider credentials
The app SHALL allow the user to supply credentials for data sources that require authentication and SHALL store them persistently.

#### Scenario: Credentials sent to an authenticated provider
- **WHEN** the user has configured a username and password and an authenticated data source is active
- **THEN** requests include the configured credentials

#### Scenario: Unauthenticated source ignores credentials
- **WHEN** the active data source does not require authentication
- **THEN** the saved credentials do not prevent requests from succeeding

### Requirement: Unified strike payload parsing
The app SHALL parse each provider's response into a common result containing a reference timestamp, strike entries, and data-area/grid parameters where provided.

#### Scenario: Parse a strike response
- **WHEN** a provider returns a valid response
- **THEN** the app produces a result with a reference timestamp and a list of strikes carrying position, timestamp, and multiplicity

#### Scenario: Missing optional grid parameters
- **WHEN** a provider response omits data-area/grid parameters
- **THEN** the app produces a result without grid parameters and does not fail

### Requirement: Result caching
The app SHALL cache fetched results for a bounded time-to-live and SHALL serve requests from cache while the cached result is still valid.

#### Scenario: Cache hit avoids a request
- **WHEN** a data request occurs within the cache time-to-live of the previous successful request for the same parameters
- **THEN** the cached result is reused and no new request is issued

#### Scenario: Cache expiry triggers a request
- **WHEN** the cache time-to-live has elapsed
- **THEN** the app issues a new request to the data source

### Requirement: Stale result rejection
The app SHALL reject results that are older than the most recently accepted result so that out-of-order responses do not replace fresher data.

#### Scenario: Older response is discarded
- **WHEN** a response arrives whose reference timestamp is older than the last accepted result
- **THEN** the app does not replace the current displayed data with it

### Requirement: Request lifecycle reporting
The app SHALL report the lifecycle of each data request as request-started, data-received, and status/error events to interested components.

#### Scenario: Progress is observable
- **WHEN** a data request starts and later completes
- **THEN** a request-started notification is emitted at the start and a data-received notification is emitted on success

#### Scenario: Failure is observable
- **WHEN** a data request fails
- **THEN** an error/status notification is emitted and the previously displayed data is retained
