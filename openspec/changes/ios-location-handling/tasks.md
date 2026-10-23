# Tasks

> Prerequisite: this change builds on the location seam and the map chrome delivered by `ios-map-ui-overlays` (`LocationSource`/`SettableLocationSource`, `ManualLocationSource`, the own-location marker, centring, and the persisted `locationMode`) and on the radar geometry in `AlertGeometry`. The manual path stays as it is; this change adds the device path beside it.

## 1. Settings and the mode value set

- [x] 1.1 Add `showOwnLocation` (default `true`), `ownLocationSize` (default `100`), `keepZoomOnCenter` (default `false`), and `backgroundLocationDisclosureShown` (default `false`) to `SettingsKey` with their registered defaults and checked accessors; verified by the existing every-key-has-a-default unit test and by unit tests reading each value and its default from a fresh store.
- [x] 1.2 Add `network`, `gps`, and `passive` to `LocationMode` beside `manual`, leaving `manual` the registered default and an unrecognised stored value falling back to manual; verified by unit tests for the default, for each case's stored round trip, and for the fallback.

## 2. Device location sources

- [x] 2.1 Implement the mode-to-configuration mapping as a pure function: `network` at kilometre accuracy, `gps` at best accuracy, and `passive` at three-kilometre accuracy with significant-change monitoring instead of continuous updates; verified by unit tests asserting each mode's accuracy and update style.
- [x] 2.2 Implement `DeviceLocationSource` against the existing `LocationSource` protocol, with no position until the device reports one and one published change per accepted position; verified by unit tests with a stubbed location manager that a reported position becomes the current location and notifies observers exactly once, that an unchanged position notifies nothing, and that no report leaves the location unknown.
- [x] 2.3 Implement `LocationSourceFactory` returning the device source for the three device modes and `ManualLocationSource` for manual, keeping the device source out of `SettableLocationSource`; verified by unit tests that each mode yields the expected source and that a long press in a device mode sets nothing.

## 3. Permissions and the background disclosure

- [x] 3.1 Add `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` to `monitor/Info.plist` and their localised strings; verified by a unit test reading the built bundle's plist for both keys and by the simulator showing the prompt when a device mode is selected.
- [x] 3.2 Request when-in-use authorisation when a device mode needs it and leave the manual path untouched when it is refused or not yet decided; verified by unit tests over stubbed authorisation states (granted, refused, not determined) and a test that manual mode requests nothing.
- [x] 3.3 Implement the background-location disclosure with its persisted acknowledgement, ahead of the request path that the background phase will use, and request no background authorisation in this change; verified by unit tests that the disclosure is due until acknowledged and not due afterwards, and that no background (always) authorisation is requested.
- [x] 3.4 Document the permission and disclosure rules in `docs/location-handling.md` with the authorisation states and the disclosure flag; verified by reading the page against the code for every state and flag it names.

## 4. Own-location display and size

- [x] 4.1 Hide the marker while own-location display is off and draw it at the configured size, scaling the existing 14-point diameter by the percentage so 100 percent reproduces today's marker; verified by unit tests on `OwnLocationMarker.make` for the disabled case and for several sizes, and by a visual check of two sizes in the simulator.
- [x] 4.2 Redraw the marker when the display or size setting changes without a location change; verified by a unit test that a setting change refreshes the drawn marker's diameter and visibility.

## 5. Centring with keep-zoom

- [x] 5.1 Honour the keep-zoom choice in `ViewController.centerOnLocation()`: preserve the current span when it is on and set the span showing the radar's outer range (`AlertGeometry.rangeSteps.last`) when it is off, leaving the map unchanged when no location is known; verified by unit tests for both choices and for the no-location case.
- [x] 5.2 Confirm the radar's tap still routes through centring and now follows the keep-zoom choice; verified by a chrome integration test that a radar tap centres with the stored choice in effect.

## 6. Wiring the mode into the app

- [x] 6.1 Build the active source through the factory in `ViewController` and replace it when the stored `locationMode` changes, re-registering observation on the new source only; verified by unit tests that each mode yields the expected source type, that a mid-session change swaps the source, and that the replaced source no longer delivers updates.
- [x] 6.2 Confirm a device position reaches every consumer without further wiring: the marker, the radar's state, and centring; verified by a `ViewController` test that a stubbed source's position updates the marker and the radar, and by a simulator pass with a simulated device location.

## 7. Documentation and the Phase 3 leftovers

- [x] 7.1 Add `docs/location-handling.md` as the capability page: the four modes with their device mapping, the permission and disclosure rules, the own-location display and size, keep-zoom centring, and the settings the change introduces, each with its value; verified by reading the page against the code for every mode, threshold, and value it states.
- [x] 7.2 Update `docs/map-ui-overlays.md`: the manual-location section hands device modes to the new page and loses its "arrives with the location phase" note, and the settings table gains the three new map settings; verified by a search showing no stale claim that device modes are still to come.
- [x] 7.3 Update `docs/parity-roadmap.md`: record Phase 3 as delivered with its archive link (replacing the "in flight" wording and the moved change path), record this phase as the change delivering the device path, and delete the consumed sketches `docs/parity-capabilities/map-ui-overlays.md` and `docs/parity-capabilities/location-handling.md`, whose requirements now live in the main specs; verified by reading the roadmap against the change's capabilities and by every relative link in the document resolving to a file that exists.

## 8. Verification

- [x] 8.1 Run the full suite and `openspec validate ios-location-handling --strict`; verified by both passing with no new warnings.
- [x] 8.2 Run the app in the simulator with a simulated device location in each device mode: confirm the permission prompt, the device position reaching the marker and the radar, and the refusal path continuing with a manual location; verified by a screenshot of each.
- [x] 8.3 Confirm the two map choices: keep-zoom on and off when centring from the radar, and own-location display off followed by a size change, each without leaving the map and surviving a relaunch; verified by a screenshot and a relaunch.

## Workflow follow-up

- On archive, move this change's roadmap row to its archive link and drop any "in flight" wording; the previous phase's identical step was noted in its tasks and missed, which is why step 7.3 corrects it in the same pass.
- On archive, the `location-handling` main spec gains this change's deltas; the sketch it replaced is already deleted by step 7.3.
