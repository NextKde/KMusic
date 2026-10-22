<p align="center"><img src="data/kmusic.svg" width="80" height="80" alt="KMusic logo"></p>

<h1 align="center">KMusic</h1>

<p align="center"><strong>A native Qt music player for NextKDE.</strong><br>Online discovery, local music, and your own music server in one player.</p>

<p align="center">
  <a href="#get-started">Get started</a> ·
  <a href="docs/Installation.md">Installation</a> ·
  <a href="README.zh-CN.md">简体中文</a>
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

<a id="get-started"></a>
## Get started

Prepare the dependencies in the [installation guide](docs/Installation.md), then run as a regular user:

```sh
git clone --branch codex/music-development https://github.com/NextKde/KMusic.git
cd KMusic
./install.sh check
./install.sh install --version 49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0
```

This pins the revision that passed the installer matrix. The installer downloads and builds that source from the official repository. Missing dependencies return structured JSON errors; **it never installs dependencies or invokes sudo**. Open KMusic from the application launcher after installation.

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
[Latest progress and screenshots](https://github.com/NextKde/KMusic/blob/ui-evidence/README.md) · [Component Gallery](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->
