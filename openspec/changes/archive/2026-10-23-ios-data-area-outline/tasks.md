# Tasks

## 1. Draw the boundary as a replaced overlay

- [x] 1.1 Add an `ActivityDataAreaPolygon` overlay type and an `ActivityOverlayBuilder` builder that turns a grid's four corner coordinates into it; verify with a `MapRenderingTests` case that the built polygon has four points spanning the grid's longitude and latitude bounds
- [x] 1.2 Give `ActivityDataAreaPolygon` its own `mapView(_:rendererFor:)` case that strokes it white at 1 pt with no fill, keeping the appearance the default case gave it; verify with a `MapRenderingTests` case that the boundary's renderer is a `MKPolygonRenderer` with a white stroke and a clear fill
- [x] 1.3 In `render(result:)`, remove the map's existing data-area outline and add the current result's only when it carries grid parameters; verify with `MapRenderingTests` cases that two renders one after another leave exactly one outline and that a result without grid parameters leaves none
- [x] 1.4 Update `docs/map-rendering.md` so the data-area boundary is part of the drawing it documents rather than an aside, and says it is replaced for each displayed result; verify the described behaviour matches the tests from tasks 1.1 to 1.3

## 2. Integration verification

- [x] 2.1 Run `xcodebuild test -project monitor.xcodeproj -scheme monitor -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO` and verify the full unit and UI suites pass, allowing for the live credential checks that the docs record as failing rather than skipping without code signing
- [x] 2.2 In the simulator against the live JSON-RPC backend, zoom in and out repeatedly and verify that a single white boundary follows the displayed data area, with no stale rectangles left on the map

## Workflow follow-up

- Archive the change after review requirements are satisfied.
- Verify the archived result and the updated main spec.
