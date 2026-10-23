# Proposal

## Why

The app's top status row - the strike/refresh status line and the settings button - is pinned to the screen's top edge, so on phones with a Dynamic Island or notch it sits inside the cutout and is partly obscured. The map also stops below the row, leaving an opaque, content-free band across the top. On modern devices the status line cannot be read reliably, and the top of the screen is wasted.

## What Changes

- Place the top status row below the top safe area (the status bar / Dynamic Island) so it is fully visible on every device, including notched and Dynamic Island phones.
- Let the map fill the screen edge-to-edge behind the status row, so map content is visible at the very top instead of a blank band.
- Draw the status row as a translucent, material-backed overlay above the map, so the map shows through while the status text and settings button stay legible over the base map.
- Show the system status bar (clock, battery) again rather than hiding it, so the system indicators and the app's own row coexist below the cutout.
- Keep the legend anchored below the status row so it does not slide up under the cutout when the map becomes full-bleed.
- Restyle the bottom controls - the mode indicator, the animation control, the time slider, and the range labels - as a matching translucent material bar over the full-bleed map.
- Compact the bottom controls to two rows, moving the range labels onto the slider row and tightening spacing, so they use less vertical space.

No settings are added or removed; the status line's content and the map's data behaviour are unchanged.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `map-ui-overlays`: add requirements for the top status row and the bottom controls bar - both placed clear of the top and bottom safe areas, presented as translucent material overlays over a full-bleed map, and legible; the system status bar is shown.

## Impact

- `monitor/ViewController.swift`: subview construction and constraints for the status row, the bottom controls, the map extent, the legend anchor, and the `prefersStatusBarHidden` override.
- `docs/map-ui-overlays.md`: the status-row and bottom-controls layout notes.
- `map-ui-overlays` spec: two added requirements.
- No changes to the data model, pipeline, providers, settings, or localization.
- UI tests: the map's frame changes, so normalized tap coordinates and captured screenshots shift; the existing status/mode/legend accessibility identifiers and behaviour are preserved.
