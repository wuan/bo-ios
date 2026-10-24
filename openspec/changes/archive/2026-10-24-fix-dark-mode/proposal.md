# Proposal

## Why

The app follows the system appearance but hardcodes colours in its own interface, so parts of it break when the device is dark: the map screen's root background is a fixed white (`view.backgroundColor = .white`), and there is no launch-screen configuration, so launching in dark appearance can show a light flash before the map. The chrome recently moved onto material bars happens to adapt, but nothing guarantees it, and the app has never been checked as a whole in dark mode.

## What Changes

- Make every colour in the app's own interface adapt to the system appearance - screen backgrounds, the status row, the bottom controls, labels, and controls - replacing hardcoded colours such as the map screen's `view.backgroundColor = .white`.
- Add a launch-screen configuration that follows the appearance, so launching in dark appearance does not flash a light screen.
- Keep the on-map overlays (legend, histogram, radar, overview, and markers) on their existing appearance-independent high-contrast treatment, because they sit over map imagery rather than over the app's own background; record that boundary so it is a deliberate choice, not an oversight.
- Keep the app following the system appearance - no forced appearance - and leave a user-facing light/dark choice out of scope.
- Verify every screen (map, settings, quick settings, enlarged radar) in both appearances: tests where the appearance is observable (resolved colours, Info.plist keys), a manual pass otherwise.

## Capabilities

### New Capabilities

- `appearance`: the app renders its own interface in the system appearance, stays legible in both light and dark, and launches without a light flash in dark appearance.

### Modified Capabilities

- None.

## Impact

- `monitor/ViewController.swift`: the map screen's root background and any other colour belonging to the app's own interface.
- `monitor/Info.plist`: the launch-screen configuration (and an Assets colour set only if one is needed to make the launch background adapt).
- New `appearance` spec. No changes to the data model, pipeline, providers, settings, or localization.
- Tests: new unit tests for resolved colours and the Info.plist launch key; a manual dark-appearance pass across the screens.
