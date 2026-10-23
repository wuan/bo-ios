# Data providers

How the iOS app fetches lightning data, and how that behaviour is configured.
This documents the `data-providers` capability delivered by the
[`ios-data-providers`](../openspec/changes/archive/2026-10-22-ios-data-providers/proposal.md) change.

## Selecting the source

The source is the `dataSource` setting. Recognised values are the raw values of
`DataProviderType`:

| `dataSource` | Provider | Serves |
| --- | --- | --- |
| `rpc` (default) | `JsonRpcDataProvider` | grid-aggregated data and clusters |
| `http` | `BlitzortungHttpDataProvider` | strike lists only |

An unrecognised value falls back to `rpc`. The selection is persisted in
`UserDefaults` through `SettingsStore`, so it survives relaunch.

In the app, tap **Data source** on the map screen, choose the source, and tap
**Save**. The full preferences screen arrives in a later phase; this screen
exists so the behaviour can be exercised.

## Endpoint override

The `serviceEndpoint` setting overrides the base URL of the active source. An
empty or whitespace-only value falls back to the source's built-in default
(`DataProviderDefaults`):

| Source | Default endpoint |
| --- | --- |
| `rpc` | `http://bo-test.tryb.de` |
| `http` | `http://data.blitzortung.org/Data/Protected` |

Both defaults are plain HTTP, so `monitor/Info.plist` carries App Transport
Security exceptions for `tryb.de` and `data.blitzortung.org`.

## Credentials

The Blitzortung.org HTTP source requires authentication; the JSON-RPC source has
none. Credentials are stored by a `CredentialStore`; the app uses
`KeychainCredentialStore`, which keeps the username and password in the Keychain
rather than in the settings store, so they never appear in `UserDefaults` or in a
future preferences export. Tests use `InMemoryCredentialStore`.

Credentials are attached as an HTTP Basic `Authorization` header by
`URLSessionHttpTransport`, and only for sources that pass them — the JSON-RPC
provider has no credential store and sends none. The data-source screen follows
the same split: it offers the username and password fields only while the HTTP
source is selected.

## Client identification

Every request carries `User-Agent: bo-ios-<CFBundleVersion>`, built once by
`UserAgent`. The value is derived from the app bundle, so it follows the build
number with no code change. This mirrors the Android client, which sends
`bo-android-<version code>`.

## The Blitzortung HTTP source

The HTTP source is not interchangeable with JSON-RPC. It reads line-oriented
strike logs, one per minute:

```
<base>/Strikes_<region>/yyyy/MM/dd/HH/mm.log
```

Each line looks like:

```
2019-02-13 06:07:24.748241830 pos;37.714012;26.801138;0 str;0 dev;7013 sta;18;85;...
```

`StrikeLogParser` reads the position and timestamp; malformed lines are skipped
without failing the batch.

A fetch covers the interval by reading one log every 10 minutes
(`defaultChunkMinutes`), starting from the later of the interval start and the
last minute fetched, and ending at the interval end. Strikes seen are
accumulated, those that fall outside the current window are dropped, and
duplicates caused by the one-minute rewind are suppressed. Changing any request
parameter resets the accumulation.

Capability limits, declared through `DataProviderCapabilities`:

| Source | `supportsGrid` | `supportsClusters` |
| --- | --- | --- |
| `rpc` | `true` | `true` |
| `http` | `false` | `false` |

So the HTTP source serves strike lists only; it cannot serve grid-aggregated
data or clusters, and consumers must not request them.

### Grid methods

The JSON-RPC backend serves grid data through a separate method per region kind,
and the provider selects one from the request's region:

| Region | Method | Positional arguments |
| --- | --- | --- |
| Global (`0`) | `get_global_strikes_grid` | duration, grid size, offset, threshold |
| Local (`-1`, with a data area) | `get_local_strikes_grid` | x, y, grid size, duration, offset, threshold, data-area scale |
| Named (`1`..`7`) | `get_strikes_grid` | duration, grid size, offset, region, threshold |

This mirrors the Android client and matters because `get_strikes_grid` clamps its
region into the named range server-side: sending a global request (`0`) through
it is served as the first named region (Europe), not the whole globe. A local
request without a data area cannot be bounded, so it falls back to the global
method.

### Grid geometry

A JSON-RPC grid result carries its own raster geometry: `x0`/`xd`/`xc` for
longitude and `y1`/`yd`/`yc` for latitude, where the column count `xc` starts at
`x0` and the row count `yc` starts at `y1` and runs southwards. The strike arrays
are `[x, y, count, age]`, with **zero-based** offsets into that raster.

`GridParameters.getCenterLongitude(offset:)` and `getCenterLatitude(offset:)`
turn an offset into the cell's centre, as `x0 + xd * (offset + 0.5)` and
`y1 - yd * (offset + 0.5)`: the first cell's centre lies half a cell inside the
north-western corner of the grid, and the last half a cell inside the
south-eastern. Both axes use the same half-cell inset, as the reference client
does; a centre placed on the wrong side of an edge shifts every drawn cell by one
whole cell in that direction.

## Caching and freshness

`DataCache` stores results keyed by the full `Parameters` value, with a
five-minute time-to-live (`DataCache.defaultTimeToLive = 300`), matching the
Android client. A request within that window for the same parameters is served
from the cache and does not contact the provider.

`FreshnessValidator` keeps the reference timestamp most recently accepted for
each parameter set and rejects a result that is not newer than the last accepted
result **for the same parameters**, so an out-of-order response cannot replace
fresher data for a selection. The first result for a selection is always
accepted, and a result for a different selection is always accepted — which is
what lets historical intervals, whose timestamps are older than realtime, still
be displayed.

`DataProviderCoordinator` wires both together: subscribe once with `events()`,
call `requestData(parameters:)`, and it clears the cache and rebuilds the
handler whenever `dataSource` or `serviceEndpoint` changes — so a result from
the previous source is never served.

An endpoint override is only used when it is an absolute URL with a scheme and a
host; anything else falls back to the default rather than reaching a provider.

## Verifying against a live backend

The UI suite carries three end-to-end checks. Each skips when its prerequisite is
missing, so an ordinary `xcodebuild test` stays green offline:

| Check | Requires |
| --- | --- |
| `testLiveRpcSourceRendersStrikes` | the public JSON-RPC backend returning strike data |
| `testLiveHttpSourceUsesCustomEndpointAndCredentials` | a stub server on `127.0.0.1:8099` demanding HTTP Basic `test:test` for strike logs |
| `testLiveRpcSourceIgnoresStoredCredentials` | the same stub server |
| `testLiveHttpSourceAuthenticatesAgainstRealBackend` | Blitzortung credentials |

### Running the credential check

`testLiveHttpSourceAuthenticatesAgainstRealBackend` points the HTTP source at its
built-in endpoint and enters real credentials. It skips unless credentials are
supplied out of band; they are never stored in the repository.

Environment variables do not reach the UI test process, so pass them as build
settings via an `.xcconfig` kept outside the repository:

```bash
cat > /tmp/bo_secrets.xcconfig <<EOF
BO_DATA_USERNAME = your-username
BO_DATA_PASSWORD = your-password
EOF

xcodebuild test -project monitor.xcodeproj -scheme monitor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -xcconfig /tmp/bo_secrets.xcconfig \
  -only-testing:monitorUITests/monitorUITests/testLiveHttpSourceAuthenticatesAgainstRealBackend
```

The test bundle's `Info.plist` carries the `BOTestDataUsername` /
`BOTestDataPassword` placeholders that substitute those build settings, so the
check skips when no configuration is supplied. Run it with code signing enabled:
the Keychain is required to store the credentials.

The stub must answer `GET /Strikes_<region>/<yyyy>/<MM>/<dd>/<HH>/<mm>.log` with a
strike log when the `Authorization` header is `Basic test:test`, and `401`
otherwise. A minimal `http.server` handler is enough; it does not need to serve
JSON-RPC for these checks.

The public backend answers with data only for a `User-Agent` of
`bo-ios-<build>`: a plain `bo-ios` or a missing header returns an empty result.
Because each check asserts a non-zero strike count in the status line, they also
cover the user-agent requirement, and the HTTP checks cover the credential path.

Two caveats:

- The credential check needs Keychain access, which requires code signing. Run it
  with signing enabled; a `CODE_SIGNING_ALLOWED=NO` build cannot store
  credentials, so that check fails rather than skips. The hermetic tests run
  unsigned.
- Plain-HTTP loopback (`127.0.0.1`) was permitted by App Transport Security in
  the simulator without an extra exception. A device may differ.
