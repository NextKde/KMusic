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
There is one CTest executable containing these assertions. This is not a live API
smoke test, a full player build, or UI/playback acceptance.
