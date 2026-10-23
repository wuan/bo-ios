# Tasks

## 1. Source-scoped region selection

- [x] 1.1 Add `DataProviderType.selectsRegion` (`rpc` false, `http` true) and verify it with a unit test asserting the mapping for every case
- [x] 1.2 Add a `SelectableSettings.namedRegions` view (`value > 0`) and a default HTTP region constant of Europe (`1`); verify the named values and names with a unit test
- [x] 1.3 In `ViewController.baseParameters()`, choose the region from the active source resolved from `settings`: the stored region when the source selects regions, otherwise `Parameters.globalRegion`; verify with `ViewControllerSettingsTests` that an RPC request carries `globalRegion` and an HTTP request carries the stored named region
- [x] 1.4 Resolve a stored value that is not a named region to Europe for the HTTP source, without writing; verify with a test that an unset (`0`) region yields Europe for HTTP and leaves the stored value unchanged
- [x] 1.5 Update the region rules in `docs/data-modes.md` (the source-scoped table) and verify the documented behavior matches the tests

## 2. Legend follows the resolved request

- [x] 2.1 Derive the legend region name from the resolved `parameters.region` in `refreshLegend()` instead of the stored setting; verify with a test that an auto-local RPC request reads "Local" and shows the local region size
- [x] 2.2 Verify an HTTP request shows its named region in the legend with a test over `LegendContentBuilder` / `ViewControllerChromeTests`

## 3. Quick-settings region control

- [x] 3.1 Offer the region row only while the active source selects regions, listing `SelectableSettings.namedRegions`; verify the row is absent for RPC and present with named values for HTTP
- [x] 3.2 Toggle the region row live when the data source changes inside the open dialog; verify with a `monitorUITests` case that switching to HTTP reveals the region picker without closing the sheet
- [x] 3.3 Update the existing `monitorUITests` region case and `SelectableSettingsTests` region expectations to the named-only, source-scoped behavior, and verify `xcodebuild test` passes with them
- [x] 3.4 Update `docs/map-ui-overlays.md` (legend row and quick-settings table) and verify it matches the implemented behavior

## 4. Apply a source change immediately

- [x] 4.1 Observe `.dataSource` in `ViewController` and re-request, refreshing the legend, so a source switch takes effect without waiting for the next tick; verify with a test that changing the source updates the region on the next received request

## 5. Remove the named JSON-RPC grid branch

- [x] 5.1 Remove the named case from `JsonRpcDataProvider.gridRequest`, leaving the local and global cases and a `default` that falls back to the global method; verify with a test that an unexpected region selects the global method
- [x] 5.2 Update `JsonRpcGridRequestTests` (drop the named case, add the fallback) and `GridGatingTests` (its `region: 1` case now takes the four-argument global shape); verify both suites pass
- [x] 5.3 Update the arity note in `JsonRpcClient.swift` and the grid-methods section of `docs/data-providers.md`, and verify the docs list only the global and local methods

## 6. Integration verification

- [x] 6.1 Run `xcodebuild test -project monitor.xcodeproj -scheme monitor -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO` and verify the full unit and UI suites pass
- [x] 6.2 Manually verify in the simulator that the region picker is absent on RPC, present with named regions on HTTP, and that the legend names the resolved region in both modes

## Workflow follow-up

- Archive the change after review requirements are satisfied.
- Verify the archived result and the updated main specs.
