# Proposal

## Why

The region setting is applied to every data source, but it only makes sense for
the Blitzortung HTTP source, whose strike logs are per-named-region files
(`Strikes_<region>/...`). The JSON-RPC source resolves the region itself from
the visible extent and ignores an explicit selection (the reference Android
client forces it to global), so offering the picker for it lets users choose a
value that does nothing and lets the legend report a region that is not the one
being requested.

## What Changes

- Apply the stored region only when the active source is the Blitzortung HTTP
  source. The JSON-RPC source always requests the automatic extent-derived
  local/global selection and never a named region.
- Offer the region control only for the HTTP source: hidden while JSON-RPC is
  active, and restricted to named regions (Europe, N./C./S. America, Oceania,
  Asia, Africa).
- Resolve a stored value that is not a named region (including the `0` default)
  to Europe for the HTTP source, without writing to the settings store.
- Drive the legend's region name from the resolved request rather than the
  stored setting, so an automatically-local JSON-RPC request reads "Local" and
  shows the local region size, while an HTTP request shows its named region.
- Re-request and refresh the display when the data source changes, so switching
  to or from the HTTP source takes effect immediately.
- Remove the now-unreachable `get_strikes_grid` named branch from the JSON-RPC
  provider; an unexpected region falls back to the global method, matching the
  existing "local without a data area falls back to global" rule.

## Capabilities

### New Capabilities
<!-- None: the change adjusts existing behavior. -->

### Modified Capabilities

- `data-modes`: region selection becomes source-scoped - automatic local/global
  selection for the JSON-RPC source, and a named-region selection that applies
  only to the Blitzortung HTTP source - instead of one setting applied to every
  source.
- `map-ui-overlays`: the quick-settings region entry is offered only while the
  HTTP source is active and lists named regions; the legend's region name
  follows the resolved request rather than the stored setting.

## Impact

- `monitor/ViewController.swift`: region selection by source, legend region
  name from resolved parameters, `.dataSource` change handling.
- `monitor/Parameters.swift`: a region-gating counterpart to `gatingGrid`.
- `monitor/pipeline/JsonRpcDataProvider.swift`: remove the named branch;
  `monitor/pipeline/DataProvider.swift` and the providers carry the
  region-applies trait; `monitor/client/jsonrpc/JsonRpcClient.swift` doc.
- `monitor/settings/SelectableSettings.swift`, `SettingsKey.swift`: split named
  regions from sentinel values; default stays `0`.
- `monitor/mapview/view/QuickSettingsViewController.swift`: source-dependent
  region row.
- Tests: `ViewControllerSettingsTests`, `SelectableSettingsTests`,
  `JsonRpcGridRequestTests`, `GridGatingTests`, `DataSourceAuthTests`,
  `LegendContentTests`, and `monitorUITests`.
- Docs: `data-modes.md`, `map-ui-overlays.md`, `data-providers.md`.
