# Native provider contract tests

Run **inside the development VM only**, with Qt >= 6.8 Core, Network and Test:

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
