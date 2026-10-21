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
unavailable, account and network states are explicit. QR sign-in and song/album/playlist/artist browsing are implemented. Actual phone
confirmation, authenticated permissions and final UI acceptance remain pending.
See the [current delivery boundary](docs/DeliveryStatus.md).

### Build and run

Build dependencies: Git, CMake 3.21+, a C++20 compiler, pkg-config, Qt 6.8+
(Core, Gui, Qml, Quick, QuickControls2, QuickDialogs2, Concurrent, DBus, Network,
Sql), Qt6Keychain, libqrencode, GStreamer core/audio/pbutils development libraries,
and TagLib 1.12+. Runtime QML needs QtQuick.Effects and Qt5Compat.GraphicalEffects;
SVG images need Qt SVG support. Audio requires a working GStreamer sink and codec
plugins for your files (the checked host has base/good/libav).

NetEase needs Node.js 22.19+ on the **application process PATH**; the checked
runtime uses 22.23.1. No npm install, Electron or complete NextKde desktop is needed.
QtKeychain uses the desktop credential store; there is no plaintext cookie fallback.
The component submodule includes matching baked shaders; rebuilding their GLSL is
not a prerequisite for this application build.

```sh
git clone --branch codex/music-development --recurse-submodules https://github.com/NextKde/KMusic.git
cd KMusic
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j4
./build/kmusic
```

For an existing checkout, run `git submodule update --init --recursive` before
configuring. The build copies the plain Node provider beside `build/kmusic`.
An optional user-prefix installation is:

```sh
cmake --install build --prefix "$HOME/.local"
"$HOME/.local/bin/kmusic"
```

The install rules place the provider in `share/kmusic/providers`, plus the desktop
entry/icon in the standard data directories. A clean-machine installed-app smoke
is still pending; this is a developer candidate, not a packaged release. Ensure
Node is available in the GUI launch environment too, especially when using nvm.

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
The current candidate uses shared LiquidBackdrop/LiquidSurface inside QML:
cover/content sources for fixed overlays and a single real page source for the
52px floating capsule player. Ordinary content actions use the plain material
branch. The shell has 30px square-window chrome and a 236px sidebar. Sidebar
transparency samples only real app content extending beneath it; external desktop
pixels are not captured or blurred. There is no native compositor effects dependency.
Whole-app visual acceptance is pending.

### Restoring online playback

The library keeps a song's catalogue duration separately from the last decoded
stream duration. For NetEase, a saved preview restores its actual last stream
length and position with a concise NetEase/preview status. Historical availability
is not current playback permission, and no loaded URL is restored.
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

Actual QR scanning/confirmation, secure-store restore and authenticated expiry
remain user validation gates; anonymous browsing does not require a scan.

Online search offers Songs, Playlists, Albums and Artists. Collection results open the
same detail browser without changing playback or the queue. Playlist details
follow the provider's track-ID order, remove duplicate IDs, and retrieve missing
song metadata in batches of up to 200 entries with **Load more**. When more songs exist, the loaded/total counts and partial
status are explicit, and actions say **Play loaded songs / Queue loaded songs**.
Only that loaded subset is played or enqueued; the app does not claim the full
playlist is available. Individual playback still resolves current permissions.

Playlist **Load more** appends unique songs in source order without playback or queue changes. A failed batch keeps the loaded list and offers Retry more; loaded/total counts remain independent of the local filter.

Artist search opens the real NetEase popular-song list using the same collection browser. The loaded popular count is separate from the provider catalogue count; it is not all works. Play/queue popular songs are explicit, and browsing does not change playback. The Albums entry opens the real artist album list in 30-result batches with loaded/total/more status. Album results use the existing detail browser; Back restores the artist and its cached album list.

Online song rows and collection-detail songs offer **Save to local playlist**. Opening the picker does not save; choosing a playlist atomically stores catalogue metadata and the local association. You can create a playlist inside the picker. Restart restores local playlists, queue identities, position and historical preview facts without autoplay. Explicit resumed NetEase playback resolves a fresh URL and current permissions; playable URLs and account cookies are not stored in the music SQLite database.

**Local favorites** are stored only in the local music database (schema 3). Heart actions on song rows and Now Playing explicitly add/remove a local favorite; online metadata is stored only when adding. Removing a favorite keeps the song, playlists and playback queue. The sidebar shows actual local favorites after restart. This does not read or synchronize the NetEase account liked-song list.

**Recently played** is local history recorded only after the audio engine enters Playing, once per loaded playback attempt. Source URL resolution/loading, browsing and permission failures do not add history. Each song has one entry ordered by its last successful start; it survives restart and explicit online replay resolves current permissions again. Schema 4 starts a confirmed history table rather than reclassifying older load-time timestamps as verified playback.

Pausing while a playback URL is still resolving invalidates that attempt. Late URL/error responses cannot start playback or replace the paused state; an explicit resumed play resolves again.

At the repeat-none queue boundary, playback fully stops and cancels pending preparation/recovery. Natural EOS carries its posting-time engine epoch and is accepted only for the current loaded track and active play intent; pause/stop/track replacement invalidates prior EOS.

Shuffle tracks queue occurrences separately, including duplicate songs. Repeat-none consumes each occurrence once, then stops. Explicit selection/restart, queue edits and playback-mode changes start a new pass; pause/resume preserves a running pass. Repeat-all begins a new pass, while repeat-one repeats the current occurrence on natural completion. Failed song IDs remain excluded throughout a recovery chain, including repeat-all.

Previous uses the restored logical position: above 3 seconds it restarts the current track, otherwise it selects the preceding queue occurrence. It preserves paused playback. A restored, unloaded online track resolves again before being prepared at zero; no saved stream URL is reused.
