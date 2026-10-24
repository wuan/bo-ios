# Spec Delta

## MODIFIED Requirements

### Requirement: Animation playback
The app SHALL support an animation mode that advances through historical intervals
automatically at a configurable step duration, pause for a configurable cycle pause when
the playback cycles back to the beginning, and can be stopped, holding the interval
reached when it stops.

#### Scenario: Start animation from history
- **WHEN** the user starts animation
- **THEN** the displayed time advances step by step across the history range without further user input

#### Scenario: Stop animation
- **WHEN** the user stops animation
- **THEN** the display holds the current interval and the user can resume manual time selection

#### Scenario: Configured step duration
- **WHEN** the user has set a step duration
- **THEN** animation advances one interval per step duration

#### Scenario: Configured cycle pause
- **WHEN** the playback reaches the present and cycles back to the beginning
- **THEN** it pauses for the configured cycle pause before advancing again

#### Scenario: No cycle pause
- **WHEN** the cycle pause is set to its off value
- **THEN** the playback restarts at the beginning without pausing
