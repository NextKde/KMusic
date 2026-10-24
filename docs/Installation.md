# Install KMusic

[简体中文](Installation.zh-CN.md) · [Back to KMusic](../README.en.md)

## Supported environments

The source installer recognizes Arch Linux, Ubuntu and Debian, on x86_64 or aarch64. Recognition is not a claim that every release ships suitable dependencies. Only x86_64 was tested.

[The completed matrix](https://github.com/NextKde/KMusic/actions/runs/39783294345) tested revision `49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0` in distro containers on hosted VMs: Arch Linux, Ubuntu 26.04 and Debian 13 passed successful installation and failure paths. Ubuntu 24.04 with its default Qt 6.4.2 correctly failed the Qt 6.8 requirement. Debian's successful fixture explicitly supplied Node 22.19; its default Node 20 is insufficient. Startup coverage was offscreen, not desktop visual acceptance.

## Prepare dependencies

Install requirements yourself using your distribution's supported tooling. KMusic never invokes a package manager, installs dependencies or uses sudo. The application does not require the complete NextKDE desktop or a KWin plugin.

| Requirement | Minimum / modules |
| :--- | :--- |
| Tools | Python 3.9+, CMake 3.21+, C++20 compiler, make, Git, pkg-config |
| Node.js | 22.19+, available on the application's PATH |
| Qt | 6.8+: Core, Gui, Qml, Quick, QuickControls2, QuickDialogs2, Concurrent, DBus, Network, Sql, Svg, ShaderTools, Core5Compat |
| Libraries | Qt6Keychain, TagLib 1.12+, libqrencode, GStreamer core/audio/pbutils development libraries |
| QML | QtQuick, Effects, Controls, Dialogs, Layouts, Window, Templates, QtQml.WorkerScript, QtCore, Qt5Compat.GraphicalEffects |
| Qt plugins | SQLite, SVG, and Wayland or XCB platform support |
| GStreamer elements | playbin, autoaudiosink, audioconvert, audioresample, vorbisdec, flacdec, mpg123audiodec |

The exact checks are in [packaging/installer.py](../packaging/installer.py). `check` includes a small C++20 compiler probe. Missing or too-old dependencies produce exit 11 with `details.dependencies`; resolve those entries before retrying. GUI launches must also see Node, especially when it is installed through a shell-only version manager.

The bundled provider runs as ordinary JavaScript, including on distro Node builds without TypeScript support. TypeScript is needed only by developers regenerating provider artifacts; see [provider development](../providers/README.md).

## Install from an existing clone (no source download)

Use the complete source on main; shared component submodule initialization is not required.

```sh
cd /your/path/KMusic
./install.sh install --source-dir .
./install.sh status
# Only when removing the installation:
./install.sh uninstall
```

The directory must be a Git repository root; relative paths and paths containing spaces are supported.
This mode builds directly from that directory into installer-owned temporary directories. It never runs
clone, fetch, checkout or submodule update, and never installs dependencies. Commit or discard tracked
source changes first. The pinned shared component source is already bundled; no submodule initialization is needed. Untracked files are not version identifiers; commit new source files before installing.
Missing files, mismatched component manifests or tracked changes return `INTEGRITY_FAILED` (21);
invalid paths or conflicting options return `INVALID_ARGUMENT` (2). Missing dependencies still return
`DEPENDENCY_UNSATISFIED` (11). An ordinary clone includes the shared UI source; see [component provenance and sync](SharedUi.md).

Local and remote installations share the same manifest, atomic activation, launcher, icon and uninstall.
The version is the full local HEAD SHA; the manifest records `sourceType: local`. Repeating that revision
returns `ALREADY_INSTALLED`. Commit changes and rerun to update. A failed build preserves the previous
installation. Uninstall preserves library/settings/user data and does not delete the source checkout.
`--source-dir` and `--version` are mutually exclusive. Prior manual `cmake --install` deployments are not
managed by this manifest. See [local installer tests](../tests/installer/README.md).

## Install and launch

```sh
git clone --branch main https://github.com/NextKde/KMusic.git
cd KMusic
```

Run as a regular user, not root. Keep `install.sh` and `packaging/installer.py` together; this is not a standalone curl-to-shell installer.

```sh
./install.sh check
./install.sh install --version 49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0
./install.sh status
```

Run `check`, then `install`. The latter fetches the pinned official source and builds it; current revisions include the shared components; it is not a prebuilt binary download. `status` reports installation state; run `uninstall` only to remove it. There is no stable release yet. For another reviewed revision, replace the version with a full 40-character Git SHA, not a branch or tag.

After success, open **KMusic** from your application launcher. Installation does not automatically launch it or create a `~/.local/bin/kmusic` command.

## Files, upgrades and removal

Remove the managed installation only when needed:

```sh
./install.sh uninstall
```

- Versions: `${XDG_DATA_HOME:-$HOME/.local/share}/kmusic-app/versions/`; `current` points to the published version.
- Desktop entry and icon: user XDG application and icon directories.
- Installer logs and lock: `${XDG_STATE_HOME:-$HOME/.local/state}/kmusic-installer`.
- Installing a different SHA stages a new build before switching `current`; a controlled publish failure restores previous links. It does not terminate the running player.
- Existing unmanaged desktop/icon entries are not overwritten. Same-version installation reports `ALREADY_INSTALLED` after checking requirements.
- Uninstall removes installer-owned files and links. It preserves music files, app data, settings, caches and credentials, and does not remove a separate manual/system installation.

## Failures and App Store integration

Stdout is JSONL: progress records followed by a final result for normal completion or handled errors. Use `success`, `code`, `stage` and `details`, not translated `message`, for decisions. Diagnostics belong on stderr or in the log. Hard kills and power loss cannot guarantee a final result.

| Exit | Code |
| :--- | :--- |
| 0 | Success |
| 2 | Invalid arguments |
| 10 | Unsupported platform |
| 11 | DEPENDENCY_UNSATISFIED |
| 12 / 13 | Permission / concurrent installer |
| 20 / 21 | Download / source integrity |
| 30 / 31 / 32 | Build / installation / uninstall |
| 99 / 130 | Internal error / cancellation |

The [App Store contract and automated tests](https://github.com/NextKde/NextKde/blob/codex/settings-extension-store/docs/app-store/KMusicInstallation.zh-CN.md) live in the main NextKDE repository as requested. The store must pin a trusted installer and source revision; a SHA identity check is not a publisher signature. The provisioning scripts there are test fixtures, not automatic dependency installation by KMusic.

## Build for development

This is separate from the managed installer and uses the same prerequisites:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
./build/kmusic
```

Shared controls come from the pinned `vendor/nextkdeAppDemo` bundled snapshot. Source attribution is in [NOTICE.md](../NOTICE.md). No npm installation is required for the bundled Node provider.
