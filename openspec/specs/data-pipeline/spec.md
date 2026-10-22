# data-pipeline Specification

## Purpose

Fetches lightning data through a provider abstraction and delivers request lifecycle events and results to consumers as a stream, so rendering and later features share one data path.

## Requirements

### Requirement: Provider abstraction
The app SHALL fetch lightning data through a provider interface defined independently of any concrete transport.

#### Scenario: Provider returns a result
- **WHEN** a provider is asked for data with given parameters
- **THEN** it returns a result or an error

#### Scenario: Provider is replaceable
- **WHEN** a different provider implementation is supplied
- **THEN** the data handler uses it without changes to consumers

### Requirement: Request lifecycle events
The app SHALL emit a request-started event when a fetch begins and a data-received event on success, or a status/error event on failure.

#### Scenario: Successful fetch
- **WHEN** a fetch succeeds
- **THEN** a request-started event and then a data-received event are emitted

#### Scenario: Failed fetch
- **WHEN** a fetch fails
- **THEN** a request-started event and then a status/error event are emitted, and previously delivered data is retained

### Requirement: Stream delivery
The app SHALL deliver data results and lifecycle events to consumers as an asynchronous stream that consumers can subscribe to and cancel.

#### Scenario: Consumer receives events
- **WHEN** a consumer subscribes to the data stream and a fetch occurs
- **THEN** the consumer receives the lifecycle events and any resulting data

#### Scenario: Unsubscribing stops delivery
- **WHEN** a consumer cancels its subscription
- **THEN** it receives no further events

### Requirement: Existing rendering uses the pipeline
The app SHALL render the current map strike overlay from results delivered by the data pipeline.

#### Scenario: Map updates from pipeline data
- **WHEN** the pipeline delivers a result
- **THEN** the map displays the strikes from that result
