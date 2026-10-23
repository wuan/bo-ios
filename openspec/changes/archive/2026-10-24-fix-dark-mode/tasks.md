# Tasks

## 1. Follow the system appearance

- [x] 1.1 Replace the map screen's hardcoded root background (`view.backgroundColor = .white`) with `.systemBackground`; verify with a unit test that, under a dark trait collection, the resolved root background equals `UIColor.systemBackground` resolved for dark.
- [x] 1.2 Assert the app forces no appearance; verify with a unit test that the app's `Info.plist` has no `UIUserInterfaceStyle` key and the map screen leaves `overrideUserInterfaceStyle` unset (`.unspecified`).
- [x] 1.3 Audit the target for literal colours (e.g. `UIColor.white`, `UIColor(white:)`); verify each remaining literal colour belongs to an on-map overlay that stays appearance-independent by design, and record that boundary in `docs/appearance.md`.

## 2. Appearance-following launch

- [x] 2.1 Add a launch-screen configuration to `monitor/Info.plist`; verify with a unit test that the built app's `Info.plist` carries a launch configuration, and confirm on the simulator that launching in dark appearance shows no light background before the map (add a light/dark colour asset referenced by `UIColorName` only if the default does not adapt).

## 3. Verification

- [x] 3.1 Manual pass: open the map screen, settings, quick settings, and the enlarged radar with the device in light appearance and again in dark appearance; verify every background, label, and control stays legible in both.
- [x] 3.2 Run the unit and UI suites on the iPhone 17 simulator (`xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`) and verify they pass.

## Workflow follow-up

- Archive the change once implementation and review are complete, and sync the `appearance` delta into the main spec.
