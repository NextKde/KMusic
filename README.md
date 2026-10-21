# KMusic

Native NextKde music application. Development is in progress.

<!-- progress-links:start -->
[Latest progress and screenshots](https://github.com/NextKde/KMusic/blob/ui-evidence/README.md) · [Current source](https://github.com/NextKde/KMusic/tree/codex/music-development) · [Component Gallery progress](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->

The approved project plan is in [docs/ProjectPlan.zh-CN.md](docs/ProjectPlan.zh-CN.md).

## Development milestone

Native Qt Quick music player consuming the pinned `Kos.Ui` module from
[nextkdeAppDemo](https://github.com/NextKde/nextkdeAppDemo). The current whole-home candidate
uses actual current-track artwork and library albums with an honest empty state,
a settings-style square shell, and a compact persistent player. The existing
NextKde local library/playback backend is retained. The NetEase page now uses the attributed SPlayer
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
are transient and are not stored as song identity. QR sign-in and secure session storage are implemented; actual phone confirmation
and an authenticated session still require user validation.

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

### Material direction

The [design reset](docs/DesignReset.zh-CN.md) defines the next complete shell and
music-page review. Transparency and blur use pure QML sampling of real app page,
artwork and background underlay, with clear text and retained liquid optics.
The current candidate uses a preblurred real current-cover underlay and shared
LiquidBackdrop/LiquidSurface inside QML. It has a 30px square-window chrome,
236px sidebar and 84px player. There is no native compositor effects dependency.
Whole-app visual acceptance is pending.

### Restoring online playback

The library keeps a song's catalogue duration separately from the last decoded
stream duration. For NetEase, a saved preview restores its actual last stream
length and position with an explicit “previous preview; playback must be checked
again” status. It does not restore a loaded URL or current playback permission.
Pressing play after restart resolves a fresh address before loading the engine.
Older sessions without stream metadata show an unknown playback length until a
new stream is decoded, rather than displaying the full catalogue length.

The saved session contains only track ID, position, last availability category,
last stream duration and quality. Playback URLs, cookies, headers and tokens are
not included. Live review status includes non-sensitive resolve/load counters and
session confirmation facts for targeted restart/resume checks.

### Public discovery feed

Discover loads eight public new albums from the pinned SPlayer NetEase
`album_new` adapter. Loading, provider failure and Retry are explicit; the list
is not personalized and never starts audio automatically. Clicking an album cover
opens its actual metadata and song list without changing playback or saving songs.
Use Play album, an individual row, or Add to queue to act explicitly. The toolbar
stays above the real scrolling content; Find in album filters the loaded songs.
The small play action on a cover is a direct album-play shortcut. Actual playback
always resolves a fresh address; account/rights restrictions may still limit it
to a preview or prevent playback.

### NetEase sign-in

Open **Sign in to NetEase** in the sidebar and generate a code, then scan and
confirm with the official mobile app. Codes are generated locally. Sessions are
stored via QtKeychain in the system credential store; plaintext fallback is
disabled. If storage fails, the app reports a session-only sign-in. Sign-out
clears the local session and requests remote logout; expired sessions need a new
scan. Account changes invalidate previously resolved playback URLs. Subscription
and track permissions still apply. The review capture hook refuses images while
a sign-in code or account identity is visible.

Build dependencies additionally include Qt6Keychain and libqrencode.

Online search offers Songs, Playlists and Albums. Collection results open the
same detail browser without changing playback or the queue. Playlist details
follow the provider's track-ID order and retrieve missing song metadata for the
first 200 entries. When more songs exist, the loaded/total counts and partial
status are explicit, and actions say **Play loaded songs / Queue loaded songs**.
Only that loaded subset is played or enqueued; the app does not claim the full
playlist is available. Individual playback still resolves current permissions.
