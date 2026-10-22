# Proposal

## Why

The iOS app (`monitor/`) is an early prototype: a single screen with realtime-only strike rendering against a test backend. The Android app (`wuan/bo-android`) is the mature reference implementation with history/animation playback, pluggable data sources, grid tiles, proximity alerts, a background service, a home-screen widget, extensive preferences, and 10+ translations. The two apps have drifted far apart, so users and maintainers lack a shared feature baseline. This change defines the full roadmap to bring the iOS app to feature parity with Android, so the work can be planned, sequenced, and delivered in verifiable increments.

## What Changes

- Introduce a **pluggable data layer**: JSON-RPC and Blitzortung HTTP providers, selectable data source, configurable service URL and credentials, response parsing, caching, incremental updates, and stale-data protection.
- Add **time modes** beyond realtime: history scrubbing across the last 24 hours and animation playback, driven by interval duration/offset and a time-slider control.
- Add **region and data-area handling**: local, regional, and global data areas with grid-size selection, matching Android's request quantisation and privacy model.
- Upgrade **map rendering**: variable-size grid tiles (5–100 km in the current Android set) with per-tile strike counts, age-based colour/fade, multiple colour schemes, zoom-aware detail, and strike selection popups.
- Add **map UI overlays/components**: legend (colour scale, region, grid baseline, count threshold), quick-settings dialog, alarm radar, histogram, and a status line consistent with Android.
- Add a **preferences screen** with Android's categories (map, animation, data source, location, alarm, generic, backup) plus persistence of defaults.
- Add **location handling**: GPS/network/manual/passive providers, permission flows, manual location via long-press, own-location overlay, and location-size/keep-zoom options.
- Add **proximity alerts**: sector/range strike computation, notification and signalling distance limits, sound/vibration signals, suppression window, and alert-radar states.
- Add **background monitoring**: a background service, periodic fetch scheduling, notifications, and boot/relaunch handling for location-based alerting.
- Add a **home-screen widget** that renders the alarm radar, updates periodically, and supports tap-to-refresh / tap-to-open.
- Add **app information surfaces**: overflow menu, application log, change log, info dialog, and version/update check.
- Add **localization** infrastructure and the Android language set.
- **BREAKING**: the current hard-coded test endpoint (`bo-test.tryb.de`), fixed region, and 60 s realtime-only polling are replaced by the configurable provider/mode model.

## Capabilities

### New Capabilities

- `data-providers`: Pluggable lightning data sources (JSON-RPC, Blitzortung HTTP), provider selection, service URL/credentials, response parsing, caching, sequence validation.
- `data-modes`: Realtime/history/animation time model, time slider over the last 24 hours, interval duration/offset, region and data-area/grid selection.
- `map-rendering`: Strike and grid-tile overlays, variable tile sizes with per-tile counts, age-based colour/fade, colour schemes, zoom-aware rendering, strike selection.
- `map-ui-overlays`: Legend, quick-settings dialog, alarm radar view, histogram, and status component.
- `preferences`: Settings screen and categories, defaults and persistence, measurement units, and preferences backup/import/reset.
- `location-handling`: Location providers (GPS/network/manual/passive), permission flows, manual location selection, and own-location display options.
- `proximity-alerts`: Sector/range alert computation, notification/signalling distance limits, sound/vibration signals, suppression, and alert-radar states.
- `background-monitoring`: Background data service, periodic scheduling, notifications, and app lifecycle/boot handling for alerting.
- `home-screen-widget`: Home-screen widget rendering the alarm radar, periodic updates, and tap actions.
- `app-information`: Overflow menu, application log, change log, info dialog, and version/update check.
- `localization`: Multi-language string resources and locale selection matching Android's language set.

### Modified Capabilities

<!-- None: the project currently has no main specs; all capabilities are new. -->

## Impact

- **Code**: `monitor/` gains new subsystems (data providers, time model, region/data-area, UI components, preferences, location, alerts, background service, widget extension, localization). `ViewController.swift` and the current polling timer are replaced by a mode-aware map screen; `DefaultClient`/`JsonRpcClient` are generalised.
- **Project/targets**: new widget extension target, background modes and location/notification entitlements, localized string resources in `monitor.xcodeproj`.
- **APIs/backends**: depends on the blitzortung.org/`bo-android` JSON-RPC and HTTP provider contracts; no backend changes required.
- **Dependencies**: possible additions for tile/section rendering helpers and settings UI; existing MapKit/UIKit stack retained (deployment target may need raising above the current 9.0/13.5 split).
- **Users**: behaviour changes from realtime-only test data to configurable realtime/history/animation with alerts; the app moves from prototype to a shippable feature set.
- **Out of scope (this change)**: actual implementation. This change delivers the roadmap, capability specs, design, and phased tasks; each phase is implemented as its own follow-up change.
