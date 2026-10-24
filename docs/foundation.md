# iOS foundation

Phase 0 of the [Android feature-parity roadmap](parity-roadmap.md) establishes a shared foundation for later phases. It is delivered by the [`ios-foundation`](../openspec/changes/archive/2026-10-22-ios-foundation/proposal.md) change.

## Module layout

| Path | Responsibility |
| --- | --- |
| `monitor/settings/` | `SettingsKey` (typed keys + registered defaults) and `SettingsStore` (typed access, persistence, reset, change observation). `SettingsViewController` is the minimal source/endpoint/credential surface. |
| `monitor/client/` | `UserAgent` (client identification), `CredentialStore` (Keychain + in-memory), `HttpTransport` (URLSession transport), and the JSON-RPC client. |
| `monitor/data/` | Shared domain model: `Result`, `Strike`/`RasterElement`, `GridParameters`, `Parameters`, `DataArea`, `TimeIntervalSelection`, `History`, `Location`, `Event`, and `StrikeDataParser`. |
| `monitor/modes/` | Realtime/history/animation selection: `DataMode`, `TimeModel`, `LocalData` (region and data-area/grid selection), `ViewExtent`, and `ModeRefreshScheduler`. |
| `monitor/pipeline/` | Data pipeline: `DataProvider`, `DataEvent`, `DataHandler`, `JsonRpcDataProvider`. |
| `monitor/Resources/Localizable.xcstrings` | Base String Catalog for all user-facing text. |
| `monitorTests/` | Unit tests and `Fixtures`. |

## Settings

```swift
let store = SettingsStore()
store.set("satellite", for: .mapMode)
let mode = store.string(for: .mapMode)

let token = store.observe(.mapMode) { /* react to a change */ }
store.removeObserver(token)
```

Every case in `SettingsKey` must have an entry in `SettingsKey.defaultValues`; `SettingsStoreTests.testEveryKeyHasDefault` enforces this.

## Data pipeline

```swift
let settings = SettingsStore()
let credentialStore = KeychainCredentialStore()
let factory = DataProviderFactory(credentialStore: credentialStore)
let coordinator = DataProviderCoordinator(settings: settings, factory: factory)

let task = Task {
    for await event in coordinator.events() {
        switch event {
        case .requestStarted:        break
        case .dataReceived(let result): /* render result */
        case .failed(let error):        /* report error, keep prior data */
        }
    }
}

coordinator.requestData(parameters: Parameters())
// ...
task.cancel()   // unsubscribes
```

`DataHandler.latest` holds the most recent successful `Result`, which is retained after a failed request.

## Data providers

The active source is selected with the `dataSource` setting (`rpc` or `http`) and an optional
`serviceEndpoint` override; an empty override falls back to the provider default. Credentials
are stored in the Keychain, every request identifies the client as `bo-ios-<CFBundleVersion>`,
results are cached for five minutes per parameter set, and a result that is not newer than the
last accepted one is discarded.

See [data-providers.md](data-providers.md) for the full reference.

## Data modes

The display runs in realtime, history, or animation mode over a 24-hour range,
selects a region and local data area from the visible extent, and sizes the grid
to that extent. See [data-modes.md](data-modes.md) for the full reference.

## Building and testing

```bash
# Compile for a device (no simulator required)
xcodebuild -project monitor.xcodeproj -scheme monitor -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

# Run unit and UI tests in the simulator
xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

## Adding files to the targets

`monitor.xcodeproj` uses explicit file references (no synchronized groups), so every new source file must be added to the project: a `PBXBuildFile` entry, a `PBXFileReference` entry, membership in the relevant group, and membership in the target's `Sources` (or `Resources`) build phase. After adding files, run the build and test commands above to confirm the project file is valid.
