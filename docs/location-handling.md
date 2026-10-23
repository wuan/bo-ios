# Location handling

Where the app's current position comes from and what it is used for: the marker,
centring, and the alarm radar's distances. This documents the `location-handling`
capability delivered by the
[`ios-location-handling`](../openspec/changes/archive/2026-10-23-ios-location-handling/proposal.md)
change, which completes the manual path the
[`ios-map-ui-overlays`](../openspec/changes/archive/2026-10-23-ios-map-ui-overlays/proposal.md)
change introduced.

Everything downstream depends on one seam. `LocationSource` exposes `location`
and publishes changes through `LocationSourceNotification.didChange`;
`SettableLocationSource` adds the setter the map's long press drives. Consumers -
the own-location marker, centring, and the aggregation behind the radar - know
nothing about where the position came from.

## Modes

The stored `locationMode` selects the source through `LocationSourceFactory`,
which returns exactly one source: the manual one, or a `DeviceLocationSource`
with its own manager. `manual` is the default, so a fresh install asks for no
permission.

| Mode | Source | How the position is obtained |
| --- | --- | --- |
| `manual` | `ManualLocationSource` | The coordinates the user sets, persisted in `manualLatitude`, `manualLongitude`, and `manualLocationSet` |
| `network` | `DeviceLocationSource` | The device's network-based position, at `kCLLocationAccuracyKilometer` |
| `gps` | `DeviceLocationSource` | The device's GPS position, at `kCLLocationAccuracyBest` |
| `passive` | `DeviceLocationSource` | Positions the device produces for others, at `kCLLocationAccuracyThreeKilometers` via `startMonitoringSignificantLocationChanges()` |

The mapping is a pure function, `DeviceLocationConfiguration.forMode(_:)`, which
returns `nil` for `manual`: a manual install never touches the device, and a long
press has nothing to set in a device mode because `DeviceLocationSource` is not a
`SettableLocationSource`. The manual coordinates are left untouched while a
device mode is active, so returning to manual restores them.

A device source has no position until the device reports one, and publishes one
change per accepted position - an unchanged position notifies nobody. Changing
the mode replaces the source: the previous one is stopped and no longer observed,
so exactly one source can publish, and the new one starts with no position until
the device reports one.

The device path is drawn by the app, not by MapKit: `mapView.showsUserLocation`
stays off and `OwnLocationAnnotationView` draws `OwnLocationMarker`, so the
marker looks the same in every mode.

## Permissions

| Authorisation | What the source does |
| --- | --- |
| Not determined | Asks for when-in-use authorisation once; updates start from the authorisation change |
| When in use, or always | Starts the updates the mode uses |
| Refused or restricted | Asks for nothing and stays without a position; the manual path carries on |

The two usage descriptions live in `monitor/Info.plist` and are localised through
`monitor/Resources/InfoPlist.xcstrings`:
`NSLocationWhenInUseUsageDescription` for the map marker and the distances to
strikes, and `NSLocationAlwaysAndWhenInUseUsageDescription` for the proximity
alerts the background phase will add. Without them iOS ignores the request and
shows no prompt, which reads as a refusal.

This change asks for **no** background authorisation: nothing runs in the
background until monitoring exists, and asking for a permission the app does not
use is both pointless and a review hazard. What it does deliver is the
explanation that has to come first.

## Background-location disclosure

`BackgroundLocationDisclosure` holds the two moves the background phase will call:
`isDue` reads the persisted `backgroundLocationDisclosureShown` flag, and
`request(disclosing:requesting:)` presents the explanation and returns without
requesting while it is due. Once the user has acknowledged it, the flag is set
and the explanation is never shown again; only then does the request run. The
flag defaults to `false`, so a fresh install is due the explanation.

## Own-location display

| Rule | Value |
| --- | --- |
| Shown at all | `showOwnLocation`, default `true` |
| Size | `ownLocationSize` as a percentage, default `100`, clamped to `50...400` |
| Diameter | `OwnLocationMarker.diameter(percent:)` scales the 14 pt base, so 100 percent reproduces the marker as it was |
| Redrawn | When the location, the display flag, or the size changes; a location change moves the existing view rather than adding another |

The marker starts visible because it is the only confirmation that a long press
took effect; the reference client defaults its layer to off, which would read as
the press having failed on a fresh install.

## Centring

`ViewController.centerOnLocation()` leaves the map alone when no location is
known and otherwise honours the keep-zoom choice:

| `keepZoomOnCenter` | What centring does |
| --- | --- |
| `true` | `setCenter` on the location: MapKit refits the span to the new latitude but the zoom the user was looking at is kept |
| `false` (default) | `setRegion` on a span showing the alarm radar's outer ring, `AlertGeometry.rangeSteps.last` (500 km), in every direction |

The span is `2 x radius / 111.32` degrees of latitude, with the longitude widened
by `1 / cos(latitude)` (floored at 0.01) so the ground distance matches rather
than the degree count. The reference client zooms to the alert distance limit
instead; that limit arrives with the alerts phase, which can narrow this.

The radar's tap routes through this, so tapping a radar that has a location
centres the map with the stored choice, and a radar without one keeps presenting
its state.

## Settings

| Key | Default | Effect |
| --- | --- | --- |
| `locationMode` | `manual` | Which source supplies the current location |
| `manualLocationSet`, `manualLatitude`, `manualLongitude` | `false`, `0.0`, `0.0` | The manual position, once set |
| `showOwnLocation` | `true` | Whether the own-location marker is drawn |
| `ownLocationSize` | `100` | The marker's diameter as a percentage of 14 pt |
| `keepZoomOnCenter` | `false` | Whether centring keeps the current zoom level |
| `backgroundLocationDisclosureShown` | `false` | Whether the background-location explanation has been acknowledged |

## Verifying

| Area | Test |
| --- | --- |
| Mode mapping, accuracy, update style | `DeviceLocationSourceTests` |
| Positions, notifications, stopping | `DeviceLocationSourceTests` |
| Permission states, no background request | `DeviceLocationSourceTests` |
| Factory, source per mode, not settable | `DeviceLocationSourceTests` |
| Disclosure due, acknowledgement, gating | `BackgroundLocationDisclosureTests` |
| Manual coordinates, modes, display and zoom settings | `ManualLocationSourceTests` |
| Marker visibility and size, centring, mode swap | `ViewControllerLocationTests` |
| Radar tap with the choice, device position reaching the chrome | `ViewControllerChromeTests` |
| Usage descriptions present in the bundle | `LocalizationTests` |
