<p align="center"><img src="data/kmusic.svg" width="80" height="80" alt="KMusic logo"></p>

<h1 align="center">KMusic</h1>

<p align="center"><strong>A native Qt music player for NextKDE.</strong><br>Online discovery, local music, and your own music server in one player.</p>

<p align="center">
  <a href="#get-started">Get started</a> ·
  <a href="docs/Installation.md">Installation</a> ·
  <a href="#disclaimer">Disclaimer</a> ·
  <a href="README.md">简体中文</a>
</p>

<p align="center"><code>Linux</code> &nbsp; <code>Qt 6.8+</code> &nbsp; <code>GStreamer</code></p>

![KMusic Discover — playlists, new songs and floating player](docs/images/kmusic-ipad.png)

Device-frame mockup · KMusic is a Linux application · [Original screenshot](docs/images/kmusic-discover.png)

Development preview; no stable release has been published. Functional and installer tests do not establish visual acceptance.

## Music and libraries

| Online music | Local music | Media sources |
| :--- | :--- | :--- |
| NetEase discovery, search, details, lyrics and QR sign-in. | Scan folders, read tags and embedded artwork, and manage device playlists. | Connect one Navidrome / OpenSubsonic server. |

- **Playback** — queue, seeking, volume, shuffle, repeat, and an immersive lyrics view.
- **Personal** — read-only NetEase playlists, liked songs, collections and listening history; real account authorization and permissions still require user validation.
- **Appearance** — light, dark, system and language preferences; shared QML liquid materials cover scrolling content.
- **Boundaries** — Bilibili is not connected. Jellyfin/WebDAV, multiple servers and remote playlist writes are not supported. Missing file artwork uses a placeholder, not generated artwork. NetEase previews and access depend on the service.

## Disclaimer

KMusic is an independent open-source music client. Online features obtain data through third-party service APIs. The project is not affiliated with, partnered with, or endorsed by NetEase Cloud Music or other platforms.

- **Content rights:** Music, recordings, lyrics, artwork and related materials belong to their respective rights holders. The applicable open-source licenses cover the software itself; they do not grant rights to music content or permission to use third-party APIs.
- **Authorized use:** Access only content, accounts and media sources you are entitled to use, and comply with applicable law and platform terms. Do not use the software to circumvent payment or access restrictions, copy or redistribute content without authorization, or abuse third-party APIs.
- **Service limitations:** APIs may change, be rate-limited or become unavailable. Playback, preview duration, quality and account features depend on actual platform permissions and responses. The project does not promise free access to paid content or uninterrupted service.
- **Accounts and privacy:** Sign-in and authorization are your choice. Protect your credentials; do not include cookies, tokens, QR codes or other sensitive information in public reports.
- **Use at your discretion:** To the extent permitted by applicable law, the software is provided as is, without guarantees regarding third-party service stability, accuracy or continued availability. This notice does not exclude liability that cannot lawfully be excluded.

Report copyright, API-use or other rights concerns through [Issues](https://github.com/NextKde/KMusic/issues), with relevant descriptions and links, for review by the maintainers. Please support licensed music and the original services.

<a id="get-started"></a>
## Get started

Prepare the dependencies in the [installation guide](docs/Installation.md), then run as a regular user:

```sh
git clone --branch main https://github.com/NextKde/KMusic.git
cd KMusic
./install.sh check
./install.sh install --source-dir .
```

This builds the already-cloned local source without downloading it again. Tracked source changes must be committed; the fixed shared UI snapshot is already included. Local installs support the same `status` and `uninstall` actions, preserving user data. Remote pinned installation remains available with `install --version <SHA>`. Missing dependencies return structured JSON errors; **it never installs dependencies or invokes sudo**. Open KMusic from the application launcher after installation.

The following records cover the earlier remote installation matrix; see the [installation guide](docs/Installation.md) for local-mode test scope.

| Distribution (x86_64) | Executed installer coverage |
| :--- | :--- |
| Arch Linux / Ubuntu 26.04 / Debian 13 | Install, upgrade, uninstall, failure paths and offscreen startup |
| Ubuntu 24.04 default dependencies | Expected dependency rejection, not successful installation certification |

[Test run and logs](https://github.com/NextKde/KMusic/actions/runs/39783294345) · [Installation, removal and troubleshooting](docs/Installation.md)

## Development and documentation

- [Local Music](docs/LocalMusic.md) · [Personal](docs/PersonalBackend.md) · [Media Sources](docs/MediaSources.md)
- [Design](docs/Design.md) · [Roadmap](docs/Roadmap.md) · [Source attribution](NOTICE.md)
- [App Store integration / 自动化测试](https://github.com/NextKde/NextKde/blob/codex/settings-extension-store/docs/app-store/KMusicInstallation.zh-CN.md)
- [Historical development notes](docs/DevelopmentNotes.md)

<!-- progress-links:start -->
[Interface preview](docs/images/kmusic-ipad.png) · [Component Gallery](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->

See [pinned component provenance and synchronization](docs/SharedUi.md).
