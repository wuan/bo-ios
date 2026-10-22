# data-providers Specification

## Purpose

Supplies lightning strike data to the app from selectable, configurable remote sources, insulating the rest of the app from provider-specific transport, endpoint configuration, credentials, and freshness rules.

## Requirements

### Requirement: Selectable data source
The app SHALL allow the user to select which data source implementation supplies lightning data, and SHALL persist that selection so the same source is used on the next launch.

#### Scenario: User selects the JSON-RPC source
- **WHEN** the user selects the JSON-RPC data source
- **THEN** subsequent strike requests are issued through the JSON-RPC provider

#### Scenario: User selects the Blitzortung HTTP source
- **WHEN** the user selects the Blitzortung HTTP data source
- **THEN** subsequent strike requests are issued through the HTTP provider

#### Scenario: Selected source persists across launches
- **WHEN** the app is relaunched after a data source was selected
- **THEN** the previously selected data source is used

### Requirement: Configurable service endpoint
The app SHALL allow the user to override the service URL used by the active data source, and SHALL use the provider's built-in default when no override is set.

#### Scenario: Custom URL is used
- **WHEN** the user sets a custom service URL and triggers a data request
- **THEN** the request is sent to the custom URL

#### Scenario: Default endpoint when unset
- **WHEN** no service URL has been configured
- **THEN** requests are sent to the provider's default endpoint

### Requirement: Provider credentials
The app SHALL allow the user to supply credentials for data sources that require authentication, SHALL keep them in secure device storage rather than the app's plain preferences, and SHALL send them only to sources that require authentication.

#### Scenario: Credentials sent to an authenticated provider
- **WHEN** the user has configured a username and password and an authenticated data source is active
- **THEN** requests include the configured credentials

#### Scenario: Unauthenticated source ignores credentials
- **WHEN** the active data source does not require authentication
- **THEN** the saved credentials do not prevent requests from succeeding

#### Scenario: Credentials persist without plain-text storage
- **WHEN** the app is relaunched after credentials were saved
- **THEN** the credentials are still available to the active data source and are not stored in the app's plain preferences

### Requirement: Result caching
The app SHALL cache fetched results for a bounded time-to-live and SHALL serve a request from the cache while a matching cached result is still valid.

#### Scenario: Cache hit avoids a request
- **WHEN** a data request occurs within the cache time-to-live of the previous successful request for the same parameters
- **THEN** the cached result is reused and no new request is issued

#### Scenario: Cache expiry triggers a request
- **WHEN** the cache time-to-live for the matching parameters has elapsed
- **THEN** the app issues a new request to the data source

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

### Requirement: Client identification
The app SHALL identify itself on every data request with a `User-Agent` header of the form `bo-ios-<build>`, where `<build>` is the app's build number as declared in its bundle metadata.

#### Scenario: User agent carries the client and build
- **WHEN** any provider issues a request
- **THEN** the request carries a `User-Agent` header beginning with `bo-ios-` followed by the app's current build number

#### Scenario: User agent tracks the build number
- **WHEN** the app's build number changes
- **THEN** subsequent requests carry the new build number without any code change
