# Tasks

## 1. Anchor cell centres by grid kind

- [x] 1.1 Derive `GridParameters.getCenterLongitude`/`getCenterLatitude` from the anchor the grid uses: a world-spanning grid (`isGlobal`) numbers its offsets from the origin, a bounded grid from its reported north-western corner; verify with `GridParametersTests` that the existing bounded grid (`-10..10`, `35..55`) keeps every centre it has today
- [x] 1.2 Add a `GridParametersTests` case built on the live global geometry (`x0 = -180`, `xd = 0.318399`, `xc = 1130`, `y1 = 90.0263`, `yd = 0.235637`, `yc = 763`) verifying that cell `[455, 99]` decodes to about `145.0, -23.4` and that every offset decodes to a centre inside valid latitude and longitude
- [x] 1.3 Verify with a `GridParametersTests` case that a world-spanning grid still reports its bounds as the geographic extent (`longitudeStart`/`longitudeEnd` and `latitudeStart`/`latitudeEnd` unchanged) and that `contains` keeps its current result

## 2. Decode global strikes through the parser

- [x] 2.1 Add a global grid fixture (spanning grid with a southern-hemisphere cell) to `monitorTests/Fixtures.swift` and verify with `StrikeDataParserTests` that the parsed strike carries the anchored coordinate and the cell's deltas as its extent
- [x] 2.2 Verify with a `JsonRpcGridRequestTests` case that a `get_global_strikes_grid` response decodes each raster entry to the coordinate its offsets name
- [x] 2.3 Update the grid-geometry section of `docs/data-providers.md` to state both anchorings, replacing the single corner rule, and verify the formulas there match the tests from tasks 1.2 and 2.1

## 3. Integration verification

- [x] 3.1 Run `xcodebuild test -project monitor.xcodeproj -scheme monitor -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO` and verify the full unit and UI suites pass
- [x] 3.2 In the simulator against the live JSON-RPC backend, verify that global strikes render where the offsets place them — activity in the Americas, Australia and the Pacific — and that no strike appears in Greenland

## Workflow follow-up

- Archive the change after review requirements are satisfied.
- Verify the archived result and the updated main spec.
