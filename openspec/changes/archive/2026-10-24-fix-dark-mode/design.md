# Design

See `proposal.md` for motivation. This document covers how the app is made to render correctly when the device is in dark appearance.

## Context

The app never sets `overrideUserInterfaceStyle`, has no `UIUserInterfaceStyle` key in `Info.plist`, and ships no launch storyboard or `UILaunchScreen` entry, so iOS falls back to a default launch background and the build emits a "launch configuration ... must be provided" warning. Almost all of the app's own chrome already uses adaptive colours: the settings, quick-settings, and enlarged-radar screens use `.systemBackground` and `.secondaryLabel`, the status and mode bars use `.systemThinMaterial`, and the status/mode/range labels use `.label`/`.secondaryLabel`. Two things do not adapt:

- The map screen's root background is a hardcoded `.white` (`ViewController.viewDidLoad`).
- The launch screen is unconfigured, so a dark-appearance launch can show a light screen before the map draws.

Separately, the on-map overlays (legend, histogram, radar, overview, markers) draw their own dark panels with white text so they read over any base map. That is deliberate and appearance-independent, not a defect: the map imagery, not the app's background, is behind them.

## Goals / Non-Goals

**Goals:**

- The app's own interface renders in the system appearance and never forces light.
- No light flash before the app's interface when launching in dark appearance.
- Every screen the app owns stays legible in both appearances.

**Non-Goals:**

- Adding a user-facing light/dark/follow-system choice (the app follows the system).
- Restyling the on-map overlays to follow the appearance; they keep their fixed high-contrast treatment over the map.
- Darkening base-map imagery; MapKit's base maps are unaffected by the system appearance.

## Decisions

### Map screen root background adapts

Replace `view.backgroundColor = .white` with `.systemBackground`.

- *Why:* it is the one hardcoded colour in the app's own interface, and it shows during launch, rotation, and any moment the full-bleed map has not yet drawn.
- *Alternatives:* `.clear` (rejected: would let the window background show and give no sensible colour while the map loads); keeping `.white` (rejected: the reported defect).

### Add an appearance-following launch screen

Add a `UILaunchScreen` entry to `Info.plist`, and verify on the simulator in both appearances that the launch background follows the appearance.

- *Why:* an unconfigured launch screen does not follow a chosen background and produces a light flash in dark mode, plus a build warning.
- *Fallback:* if an empty `UILaunchScreen` does not adapt, add a `LaunchBackground` colour asset with light and dark variants and reference it through `UILaunchScreen`'s `UIColorName`.

### Keep following the system appearance; add no forcing

Leave `Info.plist` without `UIUserInterfaceStyle` and the code without `overrideUserInterfaceStyle`, and assert both, so a future change cannot silently pin the app to one appearance.

- *Why:* the request is to render correctly in dark mode, not to add a theme setting.

### Keep the on-map overlays appearance-independent

Leave the legend, histogram, radar, overview, and marker colours as they are.

- *Why:* they sit over map imagery, so their contrast must not track the system appearance; making them adapt would reduce their contrast over a light base map.
- *Alternative:* adapt them to the appearance (rejected: couples legibility to the wrong background and is out of scope).

## Risks / Trade-offs

- [An empty `UILaunchScreen` may not follow the appearance] -> Verify in both appearances on the simulator; fall back to a light/dark colour asset referenced by `UIColorName`.
- [`.systemBackground` behind a full-bleed map is rarely visible] -> Harmless; it only shows before the map draws, which is exactly when it matters.
- [The audit may miss a hardcoded colour] -> Grep the target for literal colours and confirm each remaining one belongs to an on-map overlay; the spec's legibility requirement covers the screens, and the manual pass covers what tests cannot.

## Migration Plan

Not applicable: a presentation-only change with no persisted state.

## Open Questions

- None.
