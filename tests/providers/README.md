# Native provider contract tests

Run **inside the development VM only**, with Qt >= 6.8 Core, Network, Qml and Test:

```sh
cmake -S tests/providers -B build-provider-contracts -G Ninja
cmake --build build-provider-contracts --parallel 2
ctest --test-dir build-provider-contracts --output-on-failure
```

The executable checks provider-scoped BV/cid mapping, multiple parts, missing or
malformed data, authentication and verification errors, HTTP headers, 401/412/429/503,
redirect rejection, response size limits, cancellation and caller destruction.
HTTP fixtures listen on loopback; no external requests, accounts or cookies are used.
The base contract assertions run in provider_contract_tests; separate executables cover Bilibili and playback. This is not a live API
smoke test, a full player build, or UI/playback acceptance.

Bilibili coverage adds the published WBI vector, search identity/pagination, challenge responses, ordinary AAC selection and temporary URL descriptors. Enable `-DKMUSIC_TEST_PLAYBACK_HEADERS=ON` with GStreamer development files to exercise HTTP audio decoding, progress, pause and header isolation between loads.

On the VM, `bilibili_flow_tests --live` explicitly contacts Bilibili for public search and resolution. It logs counts and outcomes, never signed playback URLs. It is not run by CTest.

`playback_loading_tests` exercises the loading deadline with deterministic monotonic
time inputs: 30-second stalls, active slow downloads, repeated/regressing reports,
the 120-second overall limit and fresh loading episodes. It does not contact a CDN.

`bilibili_account_tests` covers QR origin/path matching, login/nav state parsing,
synthetic cookie restoration and expiry, cancellation, account isolation and
favorites/history pagination (including mixed-business history cursors).
`KMUSIC_BILI_LIVE_ANONYMOUS=1 ./build-provider-contracts/bilibili_account_tests`
opts into real anonymous generate/poll/cancel/nav checks, with status-only output.
It performs no account authorization and does not test real keyring job races or
private account-library access. Do not capture or log QR content or credentials.

`bilibili_discovery_tests` covers music/following response parsing, related-video
identity, empty/errors, cancellation, wrong-account gates with a synthetic cookie,
stale account generations, cursor cycles, deduplication and pending-handle teardown.
`./build-provider-contracts/bilibili_discovery_tests --live` opts into the three
public discovery endpoints, a recommendation continuation batch and first-new-song
AAC resolution. It reports counts/status only; any feed/resolve failure returns a
nonzero result. Authenticated following data still requires the user's phone scan.

`network_policy_tests` requires Qt Qml in addition to Core/Network/Test and runs
without a GUI. It checks HTTP/1 compatibility through native and QML factories,
caller request/header/TLS preservation, redirects, cancellation and context teardown.
`./build-provider-contracts/network_policy_tests --live` explicitly requests a real
public API and its returned cover using the QML factory, reporting HTTP status and
`Http2WasUsedAttribute` only. See [compatibility scope](../../docs/NetworkCompatibility.md);
passing these tests does not establish the host crash's root cause.
