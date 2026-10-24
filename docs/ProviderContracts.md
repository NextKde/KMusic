# Provider contracts

See the maintained [Chinese architecture and lifecycle contract](ProviderContracts.zh-CN.md).

Providers use separate interfaces for search, detail, playback resolution, accounts
and personal libraries. Stable identities include provider, instance, account,
item and part. Callers receive typed results or sanitized structured errors.
Requests are scoped to a caller-owned QObject; cancellation completes at most
once, while destruction suppresses callbacks. Providers must outlive requests.

The first implementation includes native Qt HTTP transport and independently
implemented Bilibili video-detail/part decoding. Separate search, WBI signing and playback resolver modules now connect public video
search, BV links and part playback to the UI. Login and personal libraries remain unimplemented. The current NetEase implementation remains
unchanged; future adapters must not add endpoint logic to MusicController.

Temporary playback descriptors stay native and never persist URLs or account
cookies. HTTP API sessions and CDN playback headers must be isolated. Biu source
must not be copied, translated or ported.

Run the standalone fixture tests in a VM only; see [tests](../tests/providers/README.md).
Fixture success does not establish live API availability or visual acceptance.
