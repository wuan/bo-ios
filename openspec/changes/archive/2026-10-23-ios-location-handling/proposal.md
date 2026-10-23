# Proposal

## Why

Phase 3 gave the app a location only when the user sets one by hand, so the alarm radar, the own-location marker, and centring all depend on a long press before they say anything. Android asks the device for the position in network, GPS, or passive mode, and every permission prompt there has an explanation behind it. Delivering that here is what turns the location seam the map chrome left behind into the feature the remaining phases assume, and it completes the `location-handling` capability.

## What Changes

- Add the **device location modes**: network-based, GPS-based, and passive positions behind the existing `LocationSource` seam, selectable through the stored location mode next to manual. Manual stays the default, so a fresh install still needs no permission.
- Add **location permission handling**: a device mode requests the permission it needs, and a refusal leaves the app working with a manual location rather than blocking it.
- Add the **background location disclosure**: the app explains what background location is for before that permission is asked for, and does not repeat itself once acknowledged.
- Add the **own-location display setting**: the marker can be switched off, and its size is configurable, replacing the fixed 14-point dot.
- Add the **keep-zoom choice** to centring: centring on the location either preserves the current zoom level or applies the default one.
- **Clean up the Phase 3 leftovers** in the documentation: the roadmap still calls Phase 3 "in flight" and links a change path that archiving moved, and the `map-ui-overlays` sketch has been consumed but not deleted.

## Capabilities

### New Capabilities

None. The device modes and the two settings extend the capability Phase 3 introduced.

### Modified Capabilities

- `location-handling`: adds device-backed modes behind the existing location source, permission flows with the background disclosure, and the own-location display and keep-zoom choices; the existing own-location display and centring requirements gain those choices.

## Impact

- **Code**: `monitor/location/` gains device-backed sources and a mode-driven selection alongside `ManualLocationSource`; `LocationMode` grows the device cases; `SettingsKey` gains the own-location display, own-location size, keep-zoom, and disclosure-acknowledged settings; `ViewController` applies the display setting and the keep-zoom choice and hands the mode to the source; the app bundle gains the location usage descriptions it currently lacks.
- **Docs**: `docs/parity-roadmap.md` records Phase 3 as delivered and Phase 4 as delivered with this change; the consumed `docs/parity-capabilities/map-ui-overlays.md` sketch is deleted and `location-handling.md` drops the requirements Phase 3 delivered; `docs/map-ui-overlays.md` and the location documentation cover the new settings.
- **APIs/backends**: no backend change and no request change; the position only decides what the radar and the marker draw.
- **Users**: a user who grants permission gets an automatic position instead of setting one by hand; a user who refuses keeps today's manual behaviour and loses nothing. The background-location disclosure arrives ahead of the permission it explains, and no background monitoring is added by this change.
