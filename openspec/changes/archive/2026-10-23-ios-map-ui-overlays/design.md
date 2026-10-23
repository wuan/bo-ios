# Design

## Context

See `proposal.md` - Why. Three facts about the current state shape the approach.

**Map chrome is subviews, and the rendering path is settled.** `ViewController` builds a status label, a settings button, a full-bleed `MKMapView`, and a mode-control stack (mode label, time slider, animation button), all plain UIKit. Phase 2 established that MapKit's own renderers composite here while a custom `MKOverlayRenderer` does not draw item-level content, and the current rendering path - a pure render plan materialised as polygon overlays and annotation views - is built on that finding.

**Two values the chrome must show are in-memory placeholders.** `ViewController.regionSetting` and `countThresholdSetting` are plain properties, and the interval duration and history step live in `TimeIntervalSelection` defaults. The legend has nothing real to display until region, interval duration, and the history step become persisted settings.

**The provider already sends what the radar and histogram need.** The grid response carries a strike-rate histogram and the grid parameters, and the request already carries the region, interval duration, and grid size in fixed positions.

## Goals / Non-Goals

**Goals:**

- Chrome content decided in pure, testable types, drawn by views that own no policy.
- A location seam that manual location satisfies today and device providers satisfy later without reworking consumers.
- Port the radar's aggregation faithfully, including its window and states, so the alerts phase layers behaviour on top instead of rewriting the computation.
- Make region, interval duration, and the history step real, persisted settings, so the chrome's numbers are true.

**Non-Goals:**

- Device location, permission flows, and background location - the location phase.
- Alerting behaviour: enable gating, notification and signalling limits, sound, vibration, suppression, alert-state reporting.
- The preferences screen, measurement-unit selection UI, and the query-period and animation-cadence settings, which stay with the preferences phase.
- Charting or layout frameworks; the chrome is drawn with Core Graphics in plain views.

## Decisions

### Decision: Decide chrome content in pure types, draw it in plain subviews

Each component gets a small value type holding exactly what it draws - legend entries with colours and age labels plus region and grid text, histogram bins, radar rings/sectors/states, overview boxes - computed by a pure builder from the displayed result, the active settings, the location, and the map's visible rect. Views take one of these and draw it.

- Rationale: the same split that made Phase 2's rendering testable. Thresholds, labels, and states get unit tests without a view hierarchy, and the components avoid a dependency on MapKit internals.
- Alternatives: draw each component directly from `ViewController` state (rejected: untestable policy, duplicated derivations); use `MKOverlay`s for the chrome (rejected: the compositing behaviour that forced Phase 2's approach applies equally to chrome drawn in a renderer).
- Consequence: the histogram and radar are custom-drawn views. That is plain `UIView.draw(_:)`, which renders normally, unlike a custom `MKOverlayRenderer`.

### Decision: One location source behind a protocol, manual first

A `LocationSource` exposes a current location and publishes changes; a `ManualLocationSource` fulfils it from persisted coordinates, and the location phase adds device-backed implementations behind the same seam. Consumers - the radar, the own-location layer, centring - depend on the source, not on how the position was obtained.

- Rationale: the radar must not know or care whether the position came from a long-press or a GPS fix; the location phase then adds providers without touching consumers.
- Alternatives: pass a coordinate straight from the map gesture to the radar (rejected: the radar, the marker, and centring would each need rework when device location arrives); read `CLLocationManager` now (rejected: needs permissions, which is the next phase's subject).
- Setting the location is a long-press on the map. This is our refinement: the reference sets it through preference fields. It suits a touch device and needs no settings screen, and the value is persisted the same way either way.
- The own-location marker is drawn by us rather than by MapKit's user-location dot, so a manual location shows without any location permission. MapKit's user-location display stays off until the location phase decides how device and manual locations combine.

### Decision: Port the radar aggregation as pure logic, with the reference's fixed geometry

A pure aggregation type takes the realtime strikes, a location, the data area, a reference time, and the alert interval, and returns rings and sectors with the closest strike per sector, plus the no-location, outside-data-area, no-data, and activity states. Rings end at 10, 25, 50, 100, 250, and 500 km; there are eight equally wide sectors; the alert interval is ten minutes.

- Rationale: this is the reference's own computation (`AlertDataHandler`, `Warning`, `AlertParameters`), and its constants are fixed rather than settings, so the port is self-contained. Keeping it pure makes the sector and window cases unit-testable exactly as the reference's tests do.
- Alternatives: aggregate the displayed tiles (rejected: the radar's window and granularity differ from the map's - it works on individual strikes over ten minutes, not on the displayed interval's cells); ship the radar with only its empty and error states (rejected: it would be rewritten in the alerts phase and verified by nothing).
- The aggregation is realtime-only, matching the reference: a history or animation result leaves it reporting no data. The radar therefore shows activity only while the map is in realtime mode.
- The alerts phase adds enable gating, limits, signalling, suppression, and state reporting on top; the geometry and window defined here are expected to stay unchanged.

### Decision: Quick settings edits the same store the map already observes

The dialog is a sheet over the map listing region, interval duration, historic timestep, data source, colour scheme, map mode, and base-map fade. Each entry reads and writes the settings store; the map is never left, and closing the dialog leaves the result of the changes visible.

- Rationale: the store already publishes changes and the pipeline already reacts to the data source, the scheme, and the map mode. Reusing it keeps one source of truth, so the quick dialog and the settings screen cannot diverge.
- Value sets follow the reference: region offers Local, Global, and the seven named regions (the current default is Europe); interval duration offers 30, 60, 90, 120, and 240 minutes; the historic timestep offers 15, 30, and 60 minutes.
- Alternatives: a separate quick-settings model (rejected: two sources of truth for the same keys); a full-screen settings entry point from the legend (rejected: the requirement is to apply changes without leaving the map).
- Cluster and show-grid toggles from the reference are omitted: the app draws neither clusters nor grid lines, so they would be controls with no effect. The query period and animation cadence stay with the preferences phase, which owns cadence settings.

### Decision: Retire the count threshold but keep its argument

The threshold requirement leaves `data-modes`, the in-memory placeholder and the settings-facing API go with it, and the grid request keeps sending the provider's positional threshold argument as a constant.

- Rationale: the reference's grid method is positional - Android calls it with five arguments ending in the threshold - so the argument cannot simply disappear from the request, while the feature that no user could reach can disappear from the contract.
- Alternatives: keep the requirement and add a control (rejected: it was never wanted); drop the argument from the request (rejected: the provider's method signature expects it, and mismatched arity would fail the call).

### Decision: The data-area overview is a viewport thumbnail

The overview draws the data area's extent and cell size as a box, the visible map rect as a smaller box inside it, and the zoom level as text. It shows nothing when the result carries no data area.

- Rationale: it is the reference's `RegionView`: text for extent and deltas, one inset rectangle for the viewport, one line for zoom. The visible rect is available from the map view, and the grid parameters arrive with the result.
- Alternatives: a real map thumbnail (rejected: a second map view for an informational panel is a large cost for no behavioural gain); folding it into the legend (rejected: the reference keeps them separate, and the legend is already the settings entry point).

## Risks / Trade-offs

- **Chrome over the map competes for space with the existing controls** -> Place the components in the reference's corners (legend top-left, radar bottom-left, overview above the histogram bottom-right, histogram above the time slider) and keep the status row and mode controls where they are; verify at the smallest supported screen size.
- **Long-press to set the location is our own addition, not the reference's mechanism** -> Cover it with a UI test and document it as the manual path, so a later phase can add the reference's coordinate fields without contradiction.
- **The radar's fixed 500 km outer ring exceeds a small data area** -> The outside-data-area state and an empty-radar state both exist; the aggregation reports what it finds rather than inventing activity.
- **Custom-drawn radar and histogram cost layout and redraw attention** -> Draw only in `draw(_:)` from a prebuilt content value, never from request state, and keep the geometry in the pure types so the views stay small.
- **New settings widen the request surface** -> Region, interval duration, and history step feed values the request already carries; the defaults keep today's behaviour (Europe, 60 minutes, and the current step) so an untouched install behaves as it does now.
- **Retiring the threshold touches a delivered spec** -> The removal rides in this change with a Reason and Migration note, and the argument stays on the wire, so no request or result changes.
- **The `data-modes` Purpose sentence still names threshold selection** -> The requirement is removed by this change's delta; the sentence is corrected when the change is archived, recorded as a task below rather than edited from here.

## Migration Plan

Deliver as one change:

1. The retired threshold: drop the placeholder and the settings-facing API, keep the request argument, and remove the requirement via this change's delta.
2. Location: the source protocol, the manual implementation, persisted coordinates, the own-location marker, and centring.
3. The aggregation: rings, sectors, window, states, and the summary.
4. The chrome: legend, data-area overview, histogram, radar, and quick settings, each with its content type.
5. Docs and the roadmap: the capability page, `docs/data-modes.md` losing its threshold section, and the roadmap recording the phase, the manual-location slice, and the location phase's reduced scope.

Rollback: each step is independently revertable; the settings added for region, interval duration, and history step are inert if reverted, and the retired threshold can be restored with its requirement.

## Open Questions

- Whether the enlarged radar should also surface the alert limits (notification and signalling distances) - the alerts phase decides this, and the enlarged view ships without them here.
- Whether the query period and animation cadence belong in the quick dialog after the preferences phase exists, or stay preferences-only - deferred with those settings.
