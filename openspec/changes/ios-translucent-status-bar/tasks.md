# Tasks

## 1. Status row as a material overlay

- [x] 1.1 Wrap `statusText` and `settingsButton` in a single container view backed by a `UIVisualEffectView` with `UIBlurEffect(style: .systemThinMaterial)`, and add that container to the view instead of the two subviews; verify the project builds (`xcodebuild ... build`) and the `status.text` and `settings.open` accessibility identifiers still resolve.
- [x] 1.2 Constrain the container to fill the view's width and top edge while pinning its content to `view.safeAreaLayoutGuide.topAnchor`; verify with a unit test in `ViewControllerChromeTests` that after `layoutIfNeeded()` the status text's `frame.minY` equals `view.safeAreaInsets.top`.

## 2. Full-bleed map and re-anchored chrome

- [x] 2.1 Change `mapView.topAnchor` from `statusText.bottomAnchor` to `view.topAnchor`; verify with a unit test that after `layoutIfNeeded()` the map's `frame.minY` equals the view's `bounds.minY`.
- [x] 2.2 Bring the status container in front of the map after the chrome is built; verify with a unit test that a hit test at the status text's centre resolves to the status bar rather than the map, so the map never covers the row. (The map is deliberately full-bleed, so the row necessarily overlays the map's frame; front-most z-order, not geometric separation, is the property under test.)
- [x] 2.3 Re-anchor `legendView.topAnchor` from `mapView.topAnchor + 8` to the status container's `bottomAnchor + 8`; verify with a unit test that the legend's `frame.minY` is greater than the status text's `frame.maxY`.
- [x] 2.4 Update the status-row layout note in `docs/map-ui-overlays.md` to describe the row sitting below the top safe area over a full-bleed map; verify the prose matches the new constraints.

## 3. System status bar

- [x] 3.1 Change `prefersStatusBarHidden` to `false`; verify a unit test asserts `controller.prefersStatusBarHidden == false`, and confirm in the simulator that the system clock/battery and the app's own status row are both visible.

## 4. Bottom controls bar

- [x] 4.1 Wrap the mode controls (`modeControls`) in a material-backed container (`UIVisualEffectView`, `UIBlurEffect(style: .systemThinMaterial)`) floating at the bottom safe area, mirroring the top status bar; verify the build and that the `mode.controls`, `mode.indicator`, `time.slider`, `time.range.start`, and `time.range.end` identifiers still resolve.
- [x] 4.2 Compact the controls to two rows - range labels on the slider row, vertical stack spacing 8 to 4, and a footnote-sized mode indicator; verify with a unit test that the range labels share the slider's superview and that the controls stack has two arranged subviews.
- [x] 4.3 Make the map full-bleed to the bottom (`mapView.bottomAnchor` to `view.bottomAnchor`); verify with a unit test that the map reaches the view's bottom and with a simulator screenshot that MapKit's legal attribution is not covered by the bar. (No explicit lift is applied: `MKMapView` ignores `layoutMargins` for its attribution, and the screenshot confirmed the attribution already sits well above the bar.)
- [x] 4.4 Extend the `docs/map-ui-overlays.md` note to the bottom controls bar; verify the prose matches the two-row arrangement and the full-bleed map.

## 5. Integration verification

- [x] 5.1 Run the unit and UI suites on a cutout simulator (`xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`) and verify they pass, updating any UI-test normalized map coordinates or screenshots whose frames shifted. (Unit suite: 516 tests, 0 failures. UI suite: all layout-dependent tests pass after moving the normalized tap in `testRadarTapCentresTheMapOnTheLocation` clear of the bottom-left radar, which the full-bleed map brought under its old coordinate. Three failures were environmental, not regressions, and each passes on its own: `testLiveHttpSourceAuthenticatesAgainstRealBackend` (live window returned 0 strikes), `testLongPressSetsAndMovesTheOwnLocationMarker` (stale persisted marker), and `testDeviceModePromptsForPermissionAndShowsThePosition` (no simulated location set - passes after `xcrun simctl location booted set 50.5,10.5`).)
- [x] 5.2 On a cutout device in portrait and landscape, and on the 375 x 667 class, verify the status row and the bottom controls bar are fully visible, the map shows behind both, and the text, settings control, mode indicator, slider, and range labels stay legible over the `hybrid`, `satellite`, and `standard` map modes in both light and dark appearance. (Verified by the user visually in the simulator on a cutout device - reported looking good. Automated cover here was portrait light/dark only, since this environment has no 375 x 667 simulator and no scriptable rotation.)

## Workflow follow-up

- Archive the change once implementation and review are complete, and sync the `map-ui-overlays` delta into the main spec.
