# Bilibili search and playback

Select Bilibili using the platform button, then search videos or paste an official
BV link. Public search, pagination, video parts and ordinary AAC audio use
separate native Qt modules. Playback shares KMusic's queue, pause and seek controls.
Account login, favorites, recommendations and lyrics are not integrated yet.

Temporary playback URLs never persist. The GStreamer HTTP identity is scoped to
one load and carries no account cookies. No Biu code was copied or ported.

Tests and actual playback were run only on the selected VM, 172.20.23.3. AAC requires
a GStreamer decoder, such as gstreamer1.0-libav on Debian/Ubuntu. The VM used an
isolated plugin directory rather than system package installation.

See [usage, modules and test commands in Chinese](Bilibili.zh-CN.md) and
[provider contracts](ProviderContracts.md).
