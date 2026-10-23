# Appearance

How the app follows the device's light or dark appearance. This documents the
`appearance` capability delivered by the
[`fix-dark-mode`](../openspec/changes/archive/2026-10-24-fix-dark-mode/proposal.md)
change.

## Following the system

The app follows the system appearance and never pins one: `Info.plist` carries no
`UIUserInterfaceStyle`, and no view sets `overrideUserInterfaceStyle`. A change of
appearance updates the app's own interface without a relaunch.

`AppearanceTests.testTheAppDoesNotForceAnAppearance` asserts both, so a future
change cannot silently pin the app to one appearance.

## Screens the app owns

Every screen the app owns uses adaptive system colours, so it reads correctly in
both appearances:

| Surface | Colour |
| --- | --- |
| Map screen root background (`ViewController`) | `.systemBackground` |
| Status row and bottom controls bars | `.systemThinMaterial` |
| Status line and mode indicator | the default label colour |
| Range labels (`-23 h`, `now`) | `.secondaryLabel` |
| Settings, quick settings, enlarged radar | `.systemBackground` and system controls |

## On-map overlays stay appearance-independent

The overlays drawn over the map keep a fixed, high-contrast treatment instead of
following the appearance, because the map imagery - not the app's own background -
lies behind them. Adapting them to the appearance would reduce their contrast over
a light base map.

| Overlay | Treatment |
| --- | --- |
| Legend, histogram, radar, overview | dark translucent panels (`UIColor(white: 0, alpha: ...)`) with white text |
| Own-location marker | white fill with a coloured ring |
| Selected-activity popup | dark background with white text |
| Activity tiles and count labels | colours from the active `ColorScheme`, chosen for the base-map type |

These are deliberate, not oversights: a review of every literal colour in
`monitor/` finds none left in the app's own chrome.

## Launch

The app declares a `UILaunchScreen` with no entries, so iOS uses the system
background for the launch screen, which follows the appearance: black in dark
appearance, white in light. `AppearanceTests.testTheLaunchScreenIsConfigured`
covers its presence.

## Verifying

```bash
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:monitorTests/AppearanceTests CODE_SIGNING_ALLOWED=NO
```

Switch the simulator appearance with `xcrun simctl ui booted appearance dark` (or
`light`) and check the map screen, settings, quick settings, and the enlarged radar.
