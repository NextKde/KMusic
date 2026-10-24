# Qt network compatibility containment

[简体中文](NetworkCompatibility.zh-CN.md)

A reported KMusic crash on Qt 6.12.0-3 was traced, with matching debug symbols,
to an invalid access through a Qt network-reply private pointer while HTTP/2
HEADERS were being handled (`QHttpHeaderParser::setStatusCode` ←
`QHttpNetworkReply::setStatusCode` ← `QHttp2ProtocolHandler::handleHeadersReceived`).
The origin of that invalid pointer has **not** been established. This is not proof
that a particular Qt CVE caused the crash, nor proof of an application lifetime bug.
No core dump, cookies or account credentials are committed or uploaded.

KMusic now routes its Qt network requests through `MusicProviders::NetworkAccessManager`.
It copies each request and disables `Http2AllowedAttribute` and `Http2DirectAttribute`
before Qt creates the reply. This avoids the observed HTTP/2 failure path using
HTTP/1.1; it does not repair or establish the underlying invalid-pointer cause.
Coverage includes provider HTTP, Bilibili account/API traffic, direct lyrics,
Subsonic requests, the legacy source transport, and QML artwork/avatar downloads
through a dedicated QML network factory. The QML manager remains separate from
native account cookie jars. TLS verification, cookies, request headers, redirects,
timeouts and cancellation rules are not weakened. No system Qt packages, desktop
settings or process-wide network environment switches are changed. Node/GStreamer
transports are outside Qt's QNetworkAccessManager and are unchanged.

Qt recommends this per-request HTTP/2 disable mechanism for
[CVE-2026-95620](https://www.qt.io/blog/security-advisory-cve-2026-95620) and
[CVE-2026-96432](https://www.qt.io/blog/security-advisory-cve-2026-96432). Their affected
version lists differ from the reported host's Qt 6.12.0; these advisories support
the containment mechanism, not a confirmed attribution of this crash. The policy
is applied consistently across supported Qt versions pending a root-cause finding.
HTTP/2 multiplexing is unavailable, so some image-heavy pages may use more connections.

## Validation boundary

All build/runtime checks take place in the development VM (Qt 6.10.2); the host
instance is left untouched. Six cold-cache baseline load/switch/exit cycles did not
reproduce the host crash. Consequently, passing the checks below does **not** prove
the original fault was reproduced or its cause fixed.

The provider suite adds native/QML factory request-policy checks, unchanged caller
request/TLS configuration and headers, redirects, cancellation and context destruction.
Live API and real cover requests report HTTP 200 with `Http2WasUsedAttribute=false`
and the policy applied; no URL, response body, QR or cookie is logged. These are
protocol/functional checks, not authenticated-account or visual acceptance.
The full app also undergoes the same bounded cold-cache loading/exit exercise.
