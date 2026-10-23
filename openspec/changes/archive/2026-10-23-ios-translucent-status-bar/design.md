# Design

See `proposal.md` for motivation. This document covers how the top status row is restructured so it clears the top cutout and floats over a full-bleed map.

## Context

Today the top status row is a pair of subviews (`statusText`, `settingsButton`) pinned to `view.topAnchor` and `view.leftAnchor`/`view.rightAnchor`, with the map pinned to `statusText.bottomAnchor`. The row therefore sits at the physical top edge, inside the Dynamic Island / notch band on modern phones, and an opaque band (the view's white background) fills the area above the map. Because the map never reaches the top, there is no map content behind the row to reveal.

Two facts make the current layout look correct on small screens and wrong on large ones:

- The app hides the system status bar (`prefersStatusBarHidden == true`). With no cutout, the top safe-area inset is then `0`, so a row at `y = 0` is fine on the 375 x 667 class the chrome is verified against.
- On a cutout device the inset stays at the cutout height regardless, so the same row lands under the island.

Subviews are added in this order in `viewDidLoad`: `statusText`, `settingsButton`, `mapView`, then mode controls and chrome. The map is therefore *above* the status row in z-order; they only avoid overlap because the map starts below the row.

## Goals / Non-Goals

**Goals:**

- Place the status row fully below the top safe area on every device.
- Show the map behind the status row, with the row legible over the base map.
- Show the system status bar (clock, battery).
- Keep the legend clear of the top cutout.
- Present the bottom controls as a matching translucent bar over the map, compacted to two rows to reclaim vertical space.

**Non-Goals:**

- Changing the status line's content or the map's data behaviour.
- Re-designing the radar/overview/histogram corners or the quick-settings sheet.
- Adding a user setting for bar opacity, map extent, or control density.

## Decisions

### Status row becomes a material-backed overlay

Wrap `statusText` and `settingsButton` in a single container view with a `UIVisualEffectView` (`UIBlurEffect(style: .systemThinMaterial)`) as its background, and pin that container's content to the top safe area.

- *Why:* the map must show through; a solid container would just move today's opaque band. A material keeps the text and the `.system`-tinted button legible over arbitrary map content.
- *Alternatives:* keep the row as a plain sibling above the map (rejected: no map behind it); fully transparent row with a text shadow (rejected: fragile over bright satellite imagery, hard to test).

### Material strength: `.systemThinMaterial`

- *Why:* the default map mode is `hybrid` (photographic). A thin material reliably separates the row's black text and blue button from bright imagery, and it inherits the base-map dim already applied by default (`mapFade` 55).
- *Alternatives:* `.systemUltraThinMaterial` (more map through, weaker contrast), `.systemMaterial` (more opaque, hides more map), a custom gradient scrim (more work, less consistent).

### Material extends behind the Dynamic Island

Pin the container's top to `view.topAnchor` while its *content* is pinned to `view.safeAreaLayoutGuide.topAnchor`.

- *Why:* no hard seam between the cutout band and the bar; the top strip reads as one continuous frosted surface.
- *Alternative:* start the material below the cutout, leaving raw map under the island - rejected, visible seam.

### Map is full-bleed at the top only

Change `mapView.topAnchor` from `statusText.bottomAnchor` to `view.topAnchor`; leave `mapView.bottomAnchor` at `modeControls.topAnchor` as today.

- *Why:* the issue is only at the top, and keeping the map's bottom at the controls leaves the map's legal attribution visible - a launch-review concern if chrome overlaps it.
- *Alternative:* full-bleed in both directions - rejected, would let the bottom controls overlap the attribution and enlarge the change.

### Fix z-order explicitly

After the chrome is built, bring the status container in front of the map (e.g. `view.bringSubviewToFront(container)` in `constraintsInit`, or add it after `buildChrome()`).

- *Why:* `mapView` is added after the row, so a full-bleed map would otherwise cover it.

### Re-anchor the legend to the status row

Change `legendView.topAnchor` from `mapView.topAnchor + 8` to `statusBar.bottomAnchor + 8`.

- *Why:* the legend previously sat just under the row via the map's top edge; with the map now full-bleed it would otherwise slide under the cutout. Anchoring to the bar preserves the current relationship.

### Show the system status bar

Change `prefersStatusBarHidden` to `false`.

- *Why:* the user wants the clock and battery visible alongside the app's row.
- *Consequence:* with the system bar shown, the top safe-area inset is non-zero on non-cutout devices too (the status bar height), so the safe-area pin places the row below the real indicators there as well. This is the intended behaviour, not a regression; it does add a status-bar-height band to the smallest supported layout.

### Bottom controls become a matching material bar

Wrap the mode/slider/range stack in the same `.systemThinMaterial` container used at the top, floating at the safe-area bottom with its content pinned to the bottom safe area and its material reaching the bottom edge.

- *Why:* the user asked for the lower controls to match the top; a material bar keeps them legible over the map, as at the top.
- *Alternative:* restyle the controls without putting the map behind them - rejected, the material would reveal the white view background instead of the map and look inconsistent with the top.

### Map full-bleed at the bottom too

Change `mapView.bottomAnchor` to `view.bottomAnchor` so the map runs behind the bottom bar. MapKit already places its legal attribution well clear of the bar - verified on the simulator, where the attribution sits ~57 pt above the bar's top - so no explicit inset is applied.

- *Why:* the map must be visible behind the bar, and the attribution must stay uncovered (a launch-review requirement; a blur is not legible).
- *Alternatives:* keep the map's bottom at the bar (rejected - no map behind the material); raise the attribution via `mapView.layoutMargins.bottom` (rejected - `MKMapView` ignores it for the attribution, so it was a no-op; it also risked a `viewDidLayoutSubviews` loop).

### Compact the bottom controls to two rows

Collapse the three-row stack to two: move the range labels onto the slider row (`[start, slider, end]`), reduce the vertical stack spacing from 8 to 4, and use a smaller (footnote) mode indicator.

- *Why:* the measured bottom band was ~139 pt (~16% of an 874 pt screen); two rows bring it to ~106 pt.
- *Alternative:* a single row (rejected - cramped at 375 pt width and fragile under localization, where longer words overflow).

## Risks / Trade-offs

- [Low contrast for the button/text over a bright, unlimited base map] -> `.systemThinMaterial` plus the default base-map dim; verify against `hybrid`, `satellite`, and `standard`.
- [The full-width bar swallows taps in its empty area, so map taps near the top are lost] -> Accepted and generally desirable; it prevents stray taps just under the cutout. Note it so it is a conscious choice, not a surprise.
- [Landscape, where the cutout moves to the left edge and the top inset shrinks] -> The safe-area anchor tracks the inset automatically; confirm visually on a cutout device in both orientations.
- [UI tests use normalized map coordinates and capture screenshots] -> The map frame changes, so those offsets and images shift; update the affected UI tests alongside the layout change.
- [Dark mode] -> The app still sets `view.backgroundColor = .white` and the material adapts by trait; confirm the row reads correctly in both appearances, or scope dark mode out explicitly.
- [MapKit's attribution placement is not ours to control] -> Verified on the simulator that the attribution sits well above the bottom bar; re-check on a device if a future change makes the bar substantially taller.

## Migration Plan

Not applicable: a single-screen UI change with no persisted state, and the existing accessibility identifiers (`status.text`, `settings.open`, `legend.view`) are preserved for the UI tests.

## Open Questions

- Whether the bar should carry a hairline separator along its lower edge, or blend straight into the map. Deferrable; a visual choice that does not affect the specs, approach, or task breakdown.
