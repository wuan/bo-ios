# iOS foundation

Phase 0 of the [Android feature-parity roadmap](../openspec/changes/android-feature-parity/proposal.md) establishes a shared foundation for later phases. It is delivered by the [`ios-foundation`](../openspec/changes/ios-foundation/proposal.md) change.

## Module layout

| Path | Responsibility |
| --- | --- |
| `monitor/settings/` | `SettingsKey` (typed keys + registered defaults) and `SettingsStore` (typed access, persistence, reset, change observation). |
| `monitor/data/` | Shared domain model: `Result`, `Strike`/`RasterElement`, `GridParameters`, `Parameters`, `DataArea`, `TimeIntervalSelection`, `History`, `Location`, `Event`, and `StrikeDataParser`. |
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
let provider = JsonRpcDataProvider(serviceEndpoint: ViewController.defaultServiceEndpoint)
let handler = DataHandler(provider: provider)

let task = Task {
    for await event in handler.events() {
        switch event {
        case .requestStarted:        break
        case .dataReceived(let result): /* render result */
        case .failed(let error):        /* report error, keep prior data */
        }
    }
}

handler.requestData(parameters: Parameters())
// ...
task.cancel()   // unsubscribes
```

`DataHandler.latest` holds the most recent successful `Result`, which is retained after a failed request.

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
