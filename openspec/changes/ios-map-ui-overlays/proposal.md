# Proposal

## Why

Phase 2 gave the iOS app a correct lightning rendering but almost no chrome around it: the map is a full-bleed view with a status line, a settings button, a time slider, and an animation toggle. Android frames the same map with a legend, quick settings, a strike-rate histogram, a distance radar, and a data-area overview, and the user cannot currently adjust what they are looking at without leaving the map.

The radar also needs a position, and the app has no way to get one without location permission. Android solves this with a manual location mode; delivering that here turns the radar into a verifiable, device-independent feature instead of one blocked on Phase 4, and gives manual-location users a usable app.

## What Changes

- Add a **legend** at the top-left showing the active colour scale with its age ranges, the region name, the grid baseline, and the local region size.
- Add a **quick-settings dialog** opened by tapping the legend, applying without leaving the map: region, interval duration, historic timestep, data source, colour scheme, map mode, and map fade. Region, interval duration, and historic timestep become persisted settings; today region is an in-memory placeholder and the interval/step live in type defaults.
- Add a **strike-rate histogram** for the displayed period, fed by the histogram the grid response already carries, with tap-to-zoom-out to the data area.
- Add an **alarm radar** showing activity by distance and direction from the current location, in realtime mode, with the enlarged view on long-press and tap-to-centre, including its no-location, no-data, and outside-data-area states.
- Add a **data-area overview** showing the data-area extent, its deltas, the current viewport within it, and the zoom level.
- Add **manual location** as a user feature: long-press the map to set the position, persistence across launches, propagation to interested components, an own-location marker, and centering from the radar. This introduces `location-handling` early; device providers and permission flows stay in their own phase.
- Add the **sector/range aggregation** the radar renders: distance rings, direction sectors, and closest-strike age per sector over the alert interval, ported as pure logic. Alerting behaviour (enable gating, notification and signalling limits, sound and vibration, suppression, alert-state reporting) stays in its own phase.
- **Modify** `data-providers` to parse the response's histogram array into the result, and send the region and interval selections the new controls produce.
- **Remove** the count-threshold filtering requirement from `data-modes`: the app never had a control for it and always sent zero, so the requirement described unused behaviour. A count threshold that no user can set is dead weight in the contract, and the new legend would otherwise have to display it.

## Capabilities

### New Capabilities

- `map-ui-overlays`: The on-map informational and control components framing the lightning display - legend, quick settings, histogram, alarm radar, data-area overview - and the content each derives from the current data, region, and settings.
- `location-handling`: Determining and exposing the user's location. This change introduces the manual path (set by long-press, persisted, published to consumers, shown on the map, used for centering); device-based modes and permission flows arrive in a later phase.
- `proximity-alerts`: Aggregating activity relative to the current location - distance rings, direction sectors, and closest-strike age within the alert interval - for the radar to display. Notification, signalling, and suppression behaviour arrive in a later phase.

### Modified Capabilities

- `data-providers`: The grid response's histogram array becomes part of the parsed result, so the histogram overlay can be fed without extra requests.
- `data-modes`: The count-threshold filtering requirement is removed; the request continues to carry the argument the provider protocol defines, as a constant.

## Impact

- **Code**: `ViewController` gains chrome and layout beyond its current status row and mode controls; new view components under `monitor/mapview/view/`; a pure aggregation type and manual-location source; `SettingsStore` gains region, interval duration, and historic timestep keys; `Parameters`/`JsonRpcDataProvider` gain the histogram and the new selections; the count-threshold plumbing is retired.
- **Docs**: `docs/` gains a page for the new capability; `docs/data-modes.md` loses its count-threshold section; the parity roadmap records the phase, the manual-location slice, and the shrunk location phase.
- **APIs/backends**: no backend change. The grid method keeps its existing argument list, including the threshold slot, which now carries a constant.
- **Users**: no visible behaviour is lost - the retired threshold was never settable and always inactive. Users gain the chrome, and manual-location users gain a working radar without granting location permission.
