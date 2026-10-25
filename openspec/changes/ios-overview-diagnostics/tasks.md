# Tasks

## 1. Gate the overview on diagnostics

- [x] 1.1 Make `DataAreaOverviewContentBuilder.make` take the diagnostics flag and return no content while it is off; verify unit tests that no content is produced with the flag off (even with a data area) and content with it on
- [x] 1.2 Pass `settings.bool(for: .diagnosticsEnabled)` from `ViewController.refreshOverview` and observe `SettingsKey.diagnosticsEnabled` so a change refreshes the overview; verify a controller test that the overview is nil by default, appears when the setting is turned on, and disappears when it is turned off
- [x] 1.3 Turn the diagnostics setting on in `ViewControllerChromeTests`'s setup for its existing overview cases, and verify those tests pass unchanged

## 2. Size the box from the visible extent

- [x] 2.1 Add the box's height-over-width ratio to `DataAreaOverviewContent`, built from the visible extent's spans (falling back to the current ratio before the map reports one); verify unit tests for a wide extent, a tall extent, and the fallback
- [x] 2.2 Size `DataAreaOverviewView` from the content's ratio, clamped to a usable range, invalidating the intrinsic size on configure; verify unit tests that a wide extent draws a flatter box than a tall one and that the extremes clamp

## 3. Documentation and verification

- [x] 3.1 Update `docs/map-ui-overlays.md`: the overview is gated on the diagnostics setting and its box follows the visible extent's ratio; verify the documented test command runs green
- [x] 3.2 Run `openspec validate ios-overview-diagnostics --strict` and the unit and UI suites on the simulator, and verify they pass with no warnings introduced. Validation passes and the unit suite is green (636 tests, 0 failures); the UI suite is green except the same pre-existing live check that fails with this change stashed (`testLiveHttpSourceAuthenticatesAgainstRealBackend` gets 0 strikes) and five tests that skip for want of a stub server, a fresh install, or a device; the overview-dependent live checks (`testHistogramTapZoomsOutToTheDataArea`, `testCentringFollowsTheKeepZoomChoice`) pass with diagnostics on
- [x] 3.3 Observed on the simulator: the overview is absent by default; turning Diagnostics on shows it (Europe: 130×177.7 pt); panning to the Arctic flattens it (130×72 pt, the minimum); turning Diagnostics off removes it again

## Workflow follow-up

- Archive the change (which syncs the `map-ui-overlays` requirement into `openspec/specs/`).
