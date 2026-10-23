# Design

## Context

See `proposal.md` - Why.

Today one persisted `region` setting is applied to every request:
`ViewController.baseParameters()` copies it into `Parameters.region`, and
`LocalData.updateParameters` switches on it (local `-1`, global `0`, named
`1..7`). Only the JSON-RPC provider and the Blitzortung HTTP provider consume
that value, and they consume it differently: the RPC provider picks a JSON-RPC
method from it, while the HTTP provider drops it into a per-region log path
`Strikes_<region>/...`.

The reference Android client never applies the region setting to its JSON-RPC
source. `MainDataHandler.updateProviderSpecifics` maps the source to a
`DataMode(grid, region)`: RPC gets `region = false`, HTTP gets `region = true`,
and `activeParameters` forces `copy(region = 0)` when `region` is false. The
grid path then derives local/global from the map extent. So Android's region
preference is meaningful only for the HTTP source - the shape this change
adopts.

Two facts constrain the iOS work. There is no `.dataSource` observer in
`ViewController` (the coordinator rebuilds its provider, but the controller
re-requests only on its next tick), and the legend is fed from the stored
setting (`activeRegionName`) rather than from the request actually issued.

## Goals / Non-Goals

**Goals:**

- Region applies only to the Blitzortung HTTP source; the JSON-RPC source is
  always automatic (extent-derived local/global).
- The region control is offered only for HTTP and lists named regions only.
- A non-named stored region resolves to Europe for HTTP without being written.
- The legend names the region actually requested.
- A source change takes effect on the next request without a restart.
- Remove the now-unreachable named JSON-RPC grid branch.

**Non-Goals:**

- Changing how the local data area or grid size are derived from the extent.
- Adding or removing named regions, or changing their numeric values.
- Background monitoring, which already requests a local data area explicitly
  and reads no region setting.
- The full preferences screen; the region control stays in quick settings.

## Decisions

### Decision: The region-applies policy lives on `DataProviderType`

Add `DataProviderType.selectsRegion` (`http` is `true`, `rpc` is `false`) and
have both the request path and the quick-settings dialog resolve the active
source from `settings.string(for: .dataSource)`, which is exactly how
`DataProviderCoordinator.source(in:)` resolves the provider. One definition,
two consumers.

- Alternatives: a `selectsRegion` flag on `DataProviderCapabilities` (rejected:
  capabilities document what a provider *can* serve, and the RPC backend can
  serve named regions - the app simply chooses not to ask for them, so this is
  policy, not capability); a `source` member on `DataEventSource` (rejected:
  `DataHandler` wraps a provider without knowing its type, so it could not
  answer).

### Decision: Choose the region before `LocalData` runs, not after

`ViewController.baseParameters()` selects the region from the active source:
the stored region when the source selects regions, otherwise `globalRegion`.
`LocalData.updateParameters` then runs unchanged, so the RPC path keeps its
automatic local/global upgrade and the HTTP path keeps its named region. Gating
after `updateParameters` would undo that upgrade.

- Alternatives: a `gatingRegion(on:)` mirror on `Parameters` (rejected for now:
  it would have to run before `updateParameters`, which reads as two opposite
  orderings of similarly named calls; the source-driven choice is clearer in
  `baseParameters`).

### Decision: Named regions only, resolved to Europe when unset

`SelectableSettings` keeps its full value list for name lookup but gains a
`namedRegions` view (`value > 0`) that is what the HTTP picker offers. The
effective HTTP region is the stored value when it is named, otherwise Europe
(`Parameters.globalRegion + 1`). Nothing is written, so an existing install
whose stored region is the `0` default simply starts working.

- Alternatives: change the registered default to Europe (rejected as the sole
  mechanism: it does not help installs that already stored `0`); snap and
  persist on source switch (rejected: a surprising write triggered by an
  unrelated setting change).

### Decision: Legend follows the resolved request

`refreshLegend()` derives the name from `parameters.region` via
`SelectableSettings.name(for:value:)` instead of the stored setting, so an
auto-local RPC request reads "Local" and shows the local size, and an HTTP
request reads its named region. The legend already refreshes on each result
through `refreshChrome()`, so it needs no new scheduling.

- Alternatives: keep the stored setting as the source (rejected: it is the
  misreport this change exists to fix).

### Decision: Remove the named JSON-RPC branch

`JsonRpcDataProvider.gridRequest` keeps its local and global cases and drops the
named case; the `default` falls back to the global method, mirroring the
existing "local without a data area falls back to global" rule. The named method
becomes unreachable once RPC never sends a named region, so it is removed with
its test.

- Alternatives: keep the branch as defensive support (rejected: dead code with
  no caller, and keeping it implies the app can still select a joined region on
  RPC).

## Risks / Trade-offs

- [Legend lags one result behind an extent change] -> the region name updates
  on `render`, same as the grid baseline. Acceptable; the difference is at most
  one refresh interval.
- [Settings-derived source vs active provider could diverge] -> only if a
  caller injects a `DataHandler` decoupled from the settings store, which is a
  test-only path. Production uses the coordinator built from the same settings.
- [Removing the named branch changes direct-provider behavior] -> a caller
  passing `region >= 1` to `JsonRpcDataProvider` now gets the global method.
  Documented by a fallback test and in `data-providers.md`; the app never sends
  such a value.
- [Stored named region no longer affects RPC] -> a user who had picked "Asia"
  sees the RPC map go automatic. This is the intended behavior; the setting is
  retained and still applies when they switch to HTTP.

## Migration Plan

No data migration. The stored region is left untouched; `0` (the default) and
any named value are both valid under the new resolution. Rollback is reverting
the change, since no data was rewritten.

## Open Questions

None.
