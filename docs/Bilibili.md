# Bilibili search and playback

Select Bilibili using the platform button, then search videos or paste an official
BV link. Public search, pagination, video parts and ordinary AAC audio use
separate native Qt modules. Playback shares KMusic's queue, pause and seek controls.
Account QR login, read-only favorites folders and account video history are available; see [account setup and limitations](BilibiliAccount.md). Lyrics and cloud write operations are not integrated.

Temporary playback URLs never persist. The GStreamer HTTP identity is scoped to
one load and carries no account cookies. No Biu code was copied or ported.

Tests and actual playback were run only on the selected VM, 172.20.23.3. AAC requires
a GStreamer decoder, such as gstreamer1.0-libav on Debian/Ubuntu. The VM used an
isolated plugin directory rather than system package installation.

See [usage, modules and test commands in Chinese](Bilibili.zh-CN.md) and
[provider contracts](ProviderContracts.md).

Long-audio buffering has a 30-second no-progress deadline and a 120-second
absolute limit per loading episode. Only new buffering/download progress extends
the stall deadline. Once Bilibili resolution finishes, the engine owns this deadline;
the preparation timer no longer interrupts it. Download caching and MP4 seeking
remain enabled. `playback_loading_tests` covers progress, stalls, oscillation,
the absolute limit and reset using monotonic time inputs.

Resolution prefers an API-provided `upos-*.bilivideo.com` direct CDN candidate
over an edge relay. Signed URLs are never rewritten; the original is retained
as a candidate, and remains primary when no direct CDN is supplied.

VM retesting passed for a short video and twice for the previously failing
43-minute BV1toJR6HEn7, including pause and seeking to 20 minutes followed by
advancing playback. This was not a full 43-minute endurance run.

Bilibili now opens [Discover](BilibiliDiscovery.md): new music, music-region picks, popular videos and signed-in following updates.
