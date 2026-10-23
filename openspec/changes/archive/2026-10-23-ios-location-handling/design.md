# Design

## Context

See `proposal.md` - Why. The pieces this builds on already exist:

- `monitor/location/LocationSource.swift` defines the seam: a `LocationSource` protocol with `location`, `observe`, and `removeObserver`, a `SettableLocationSource` refinement that the map's long press drives, a `LocationSourceNotification.didChange` notification posted by `publishLocationChange()`, and a `LocationMode` enum that currently has only `manual`.
- `ManualLocationSource` reads the mode and the persisted coordinates from `SettingsStore`; `ViewController` builds it in `init` and re-registers observation on a mode change at run time (`locationSource = ManualLocationSource(settings:)`).
- Consumers - the own-location marker (`OwnLocationMarker.make`, `applyLocation()`), centring (`centerOnLocation`), and the alarm radar - depend only on the seam.
- `SettingsKey` has `locationMode` (default `manual`), `manualLatitude`, `manualLongitude`, `manualLocationSet`, and a unit test that requires a default for every case.
- `monitor/Info.plist` carries no location usage description, so a permission request today would be silent.
- The reference implementation (`/Users/andi/projects/blitzortung/bo-android`) offers `network`, `gps`, `passive`, and `manual` providers, an `own_location_size` percentage defaulting to 100, a `keep_zoom_goto_own_location` flag defaulting to false, and a background-location disclosure governed by a `background_location_disclosure_shown` flag.

## Goals / Non-Goals

**Goals:**

- Serve device positions through the existing seam so no consumer changes.
- Make the active mode decide which source is in effect, at launch and after a change.
- Keep manual mode and a refused permission fully working.
- Give the marker and centring the two choices the reference exposes.

**Non-Goals:**

- Background monitoring, background fetches, and a persisted monitoring state - these stay with the background phase. This change delivers the disclosure and the permission seam only.
- The full preferences screen: the Phase 7 work adds the labelled controls. This change adds the settings and the map behaviour behind them, exercised through the existing settings surface.
- Point-strike markers, data-area computation, and alerting behaviour: unchanged.

## Decisions

**One device source parameterised by mode, chosen by a factory.** `DeviceLocationSource` wraps a single `CLLocationManager` and applies the active mode's accuracy and update style; `LocationSourceFactory(settings:)` returns the device source for the three device modes and `ManualLocationSource` for `manual`. Alternative considered: one class per mode, mirroring the reference's `GPSLocationProvider`/`NetworkLocationProvider`/`PassiveLocationProvider`. Rejected because the difference between them is configuration, not behaviour - a per-mode class would triplicate the delegate plumbing for a different accuracy constant.

**Mode-to-CoreLocation mapping.** `network` uses `kCLLocationAccuracyKilometer`, `gps` uses `kCLLocationAccuracyBest`, and `passive` uses `kCLLocationAccuracyThreeKilometers` with `startMonitoringSignificantLocationChanges()` instead of continuous updates. iOS has no direct counterpart to Android's passive provider; significant-change monitoring is the closest equivalent - the app adopts positions the device produces without asking for a stream of its own. The mode's mapping is a pure function so it can be unit-tested without a `CLLocationManager`.

**Manual stays the default mode.** A fresh install therefore asks for no permission, and the Phase 3 behaviour - long press, then the radar and the marker work - is unchanged until the user chooses a device mode. Alternative considered: the reference's network default. Rejected because it would put a permission prompt in front of a first launch that has nothing to lose by staying manual.

**A device source is not settable; the long press keeps its meaning.** `DeviceLocationSource` does not conform to `SettableLocationSource`, so `ViewController.setLocation(at:)` already ignores a long press in a device mode. No new switch-to-manual behaviour is invented: the mode is set where the other settings are.

**Observation is re-registered when the source is replaced.** `ViewController` observes `SettingsStore` for a `locationMode` change and rebuilds the source only when the mode actually changed, keeping the last known position out of the picture - a device source starts with no position until the device reports one, exactly as a fresh manual source has none until set.

**Marker visibility defaults to on, size defaults to the current diameter.** `showOwnLocation` defaults to `true` and `ownLocationSize` to 100 percent of the existing `OwnLocationMarker.defaultDiameter` (14 points). The reference defaults its marker layer to off, but on iOS the marker is the only confirmation that a long press took effect, and a fresh install has no other location surface; turning it off by default would read as the long press having failed. Alternative considered: copying the reference's `false`. Rejected for that reason.

**Keep-zoom defaults to off, matching the reference.** With keep-zoom on, centring moves the map centre and leaves the span alone. With it off, centring also sets a span that shows the alarm radar's outer ring - `AlertGeometry.rangeSteps.last`, 500 kilometres - which is the distance the radar already draws and the reason a user taps it. The reference zooms to the alert distance limit instead; that limit arrives with the alerts phase, so this change uses the radar geometry it has and leaves the refinement to that phase.

**The background disclosure is a flag plus a presentation seam, not a request.** `backgroundLocationDisclosureShown` persists the acknowledgement, and a disclosure presenter runs before any background permission request. This change does not request `always` on its own: nothing in the app runs in the background until the background phase, and asking for a permission the app does not use is both pointless and a review hazard. The requirement's scenario is satisfied by the disclosure sitting in front of the request path that phase will use.

**Info.plist gains both usage descriptions.** `NSLocationWhenInUseUsageDescription` for the device modes and `NSLocationAlwaysAndWhenInUseUsageDescription` for the disclosure's request path, localised in `Resources/Localizable.xcstrings`. Without them iOS ignores the request and shows no prompt, which is silent and easy to mistake for user refusal.

## Risks / Trade-offs

- [A missing usage description makes a device mode look like a refusal] → add both strings, and a unit test that fails when either key is absent from the built bundle's plist.
- [Passive mode cannot be exercised in the simulator] → unit-test the mode-to-configuration mapping and the delegate's position handling with a stub; record the on-device check as a residual the way Phase 2 and Phase 3 did.
- [Two sources alive at once could double-publish] → the factory returns exactly one source, `ViewController` stops the old one's updates before swapping, and only a replaced source is re-observed.
- [A device position arriving after a manual one could silently move the radar] → a mode change is the only way to reach a device source, and the manual coordinates are left intact so returning to manual restores them.
- [Marker size as a percentage of a fixed diameter is a smaller range than the reference's] → the percentage maps to the existing 14-point base, so 100 percent reproduces today's marker and the setting is a scale, not a new geometry.

## Migration Plan

No stored data changes shape and no default moves an existing install: `locationMode` already exists and still defaults to `manual`, the two new map settings default to today's behaviour, and the disclosure flag defaults to unshown. Rollback is the reverse code change; the added keys are inert. The Phase 3 leftovers in `docs/` - the roadmap's "in flight" Phase 3 and its now-moved link, the consumed `map-ui-overlays` sketch, and the delivered requirements still sitting in the `location-handling` sketch - are corrected as documentation tasks of this change.
