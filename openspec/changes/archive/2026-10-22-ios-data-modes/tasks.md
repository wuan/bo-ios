# Tasks

> Prerequisite: this change consumes the selectable source, settings keys, and provider capability descriptor delivered by `ios-data-providers`; that change should land first.

## 1. Time model and slider

- [x] 1.1 Add the time-stepping operations (rewind, fast-forward, animation step, return to realtime) to the time model, clamping to the history lower limit and aligning offsets to the history increment; verified by unit tests ported from the Android time-interval cases.
- [x] 1.2 Add the position/offset mapping used by the slider, so a position converts to an offset and back and the rightmost position yields a zero offset; verified by unit tests for round-tripping and for the realtime boundary.
- [x] 1.3 Implement the 24-hour time-slider control over the history range; verified by a UI test or manual check that the rightmost position activates realtime and any other position selects that interval.
- [x] 1.4 Implement the realtime, history, and animation mode state, including starting and stopping animation and holding the interval it stopped on; verified by unit tests for the mode transitions and a manual animation run.

## 2. Region, data area, and grid size

- [x] 2.1 Add a `ViewExtent` value type and an adapter that produces it from the map view; verified by unit tests constructing extents from fixed center/span values.
- [x] 2.2 Implement region/data-area/grid selection, including the local-without-area fallback to global and the global-to-local switch when the grid size is below the local threshold; verified by unit tests covering each transition.
- [x] 2.3 Implement grid-size derivation from the extent, clamped to the supported range; verified by unit tests at several extents, including one too large for a local area.
- [x] 2.4 Gate grid requests on the active provider's capability descriptor; verified by a test showing the non-grid source issues no grid request while the grid-capable source carries the grid size.

## 3. Count threshold

- [x] 3.1 Carry the count threshold into request parameters, treating zero as inactive; verified by unit tests that a zero threshold leaves parameters unchanged and a non-zero threshold appears in the issued request.

## 4. Mode-driven refresh, documentation, and integration

- [x] 4.1 Replace the fixed realtime poll with mode-driven refresh (periodic in realtime, on change in history, per step in animation); verified by a scheduler unit test and by manual observation in each mode.
- [x] 4.2 Document the mode controls, the region and data-area rules, the threshold, and the defaults, and verify the documented defaults and rules match the code.
- [x] 4.3 Run the app in realtime, history, and animation modes against a live backend and confirm the `data-modes` scenarios hold for time selection, region switching, and grid gating.
- [x] 4.4 Run `xcodebuild test` and `openspec validate ios-data-modes --strict` and resolve all failures and warnings.

## 5. Follow-ups from manual verification

- [x] 5.1 Scope stale-result rejection to a single request selection so a historical interval is displayed instead of discarded as out-of-order (also a `data-providers` delta).
- [x] 5.2 Show the start of the selected interval as a wall-clock time in the status line in history and animation mode, keeping the realtime countdown (also a `data-modes` delta).

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied; its `data-modes` capability is copied to the main specs.
- Verify the archived result with `openspec list --specs` and `openspec validate`.
