# KMusic

Native NextKde music application. Development is in progress.

<!-- progress-links:start -->
[Latest progress and screenshots](https://github.com/NextKde/KMusic/blob/ui-evidence/README.md) · [Current source](https://github.com/NextKde/KMusic/tree/codex/music-development) · [Component Gallery progress](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->

The approved project plan is in [docs/ProjectPlan.zh-CN.md](docs/ProjectPlan.zh-CN.md).

## Development milestone

Native Qt Quick music player consuming the pinned `Kos.Ui` module from
[nextkdeAppDemo](https://github.com/NextKde/nextkdeAppDemo). The first UI milestone
uses original, explicitly labelled offline editorial art and the existing NextKde
local library/playback backend. The NetEase page now uses the attributed SPlayer
Next request/crypto modules through a plain Node helper: search, song details,
lyrics and playable URL resolution feed the real GStreamer player. Preview-only,
unavailable, account and network states are explicit. Login and broader catalogue
flows remain in progress; this is not final feature or UI acceptance.

### Build and run

Qt 6.8+ (Core, Gui, Qml, Quick, QuickControls2, QuickDialogs2, Concurrent, DBus,
Network and Sql), Qt5Compat.GraphicalEffects, Qt SVG support, GStreamer development
packages (core/audio/pbutils) and TagLib 1.12+ are required. Audio decoding also
needs the corresponding GStreamer codec plugins and a working audio sink.
Online NetEase requests require Node.js 22.19+; no npm install or Electron is needed.

```sh
git clone --recursive https://github.com/NextKde/KMusic.git
cd KMusic
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j4
./build/kmusic
```

Import a local folder from the sidebar or Ctrl+O. Select a song to play; + adds it
to the queue and ··· adds it to an existing playlist. Ctrl+F focuses library search.
The bottom player provides transport, seek, volume, shuffle, repeat, queue and
now-playing views. Light/dark/system appearance is in the sidebar.

Data defaults to `~/.local/share/kmusic`, cache to `~/.cache/kmusic`, isolated from
KOS Music. `KOS_MUSIC_DATA_DIR` and `KOS_MUSIC_CACHE_DIR` override these for review.
Online music is under **Online · NetEase**. Enter a query, search, then click a
result to play; + enqueues it and ··· opens fetched song details. The status strip
identifies preview-only playback. Availability depends on the source's response;
no URL, authentication and network errors are shown explicitly. Inherited LX
adapters are not the default source and are not wired into the app. Playback URLs
are transient and are not stored as song identity. Login is not implemented yet.

### Live review hook

Opt in with `KMUSIC_REVIEW_DIR=/absolute/private/review-directory`. Atomically
write `request.json` there with one of:

```json
{"action":"capture","path":"/absolute/output.png"}
```

Other actions are `theme` (`theme`: `light`, `dark`, `system`), `page` (`page`: `new`,
`songs`, `queue`, `now`) and `resize` (`width`, `height`). Capture grabs the live
window content using its actual renderer and DPR, then writes `response.json`
with `ok` and `path`. It is not an offscreen rendering or a visual acceptance test.

See [design](docs/Design.md), [confirmed plan](docs/ProjectPlan.zh-CN.md),
[component inventory](docs/ComponentInventory.md) and [source provenance](NOTICE.md).

### Sidebar material

If KF6WindowSystem is available at build time, KMusic can request the compositor's
existing BlurBehind support for its sidebar only. Text stays opaque. Runtime
support is detected; the fallback sidebar is opaque. This does not install or
change KWin effects. Raw client-content screenshots retain sidebar alpha and do
not include the compositor's desktop blur. Live review status distinguishes
`effectAvailable`, `blurRequested`, the logical region and fallback reason.
