# NetEase Personal backend

[简体中文](PersonalBackend.zh-CN.md)

Implemented read-only account-library adapter; actual authenticated calls remain
unverified. It requires this app's confirmed NetEase session. Local favorites and
local recently played remain separate. No account like/follow/playlist mutation
or cloud-to-local synchronization is added.

`MusicController.personalFeed` is a `QVariantMap` notifying `personalChanged`.
Each section has `items`, `loading`, `error`, `more`, `nextOffset`, `scopeLabel`
and cumulative `omittedCount`. Successful responses also provide `loaded` and
`total` (`-1` means unknown/not a category total). Item fields are
`providerId/title/artist/artwork/kind/source`; songs add `album/durationMs`, and
recent events add `playedAt` (service milliseconds) and unique `entryId`.

| Section | Real source and paging |
| --- | --- |
| createdPlaylists | `user_playlist`, 50 raw account entries/page; creator ID equals the private current user ID. |
| savedPlaylists | Same mixed list/cursor, creator ID differs. An empty category page can still have `more=true`; no mixed total is presented as its category total. |
| likedSongs | `likelist` ID snapshot in memory, then `song_detail` batches of 100, in source ID order. Missing/nameless metadata is omitted and counted. |
| recentSongs | `/api/play-record/song/list`, latest up to 100 service records, no offset API; `more=false`, explicit bounded scope. Original event order/repeated songs retained; not a play-count ranking or local history. |
| savedAlbums | `album_sublist`, 50/page, offset and provider count/hasMore. |
| savedArtists | `artist_sublist`, 50/page, offset and provider count/hasMore. |

`reloadPersonal()` resets/loads all six sections, guarded against duplicate
in-flight reloads. `loadMorePersonal(section)` appends deduplicated entries.
A failed page sets `loading=false`/`error` and retains loaded rows, cursor, `more`
and omission count; retry the page or refresh. A liked-ID snapshot lost when the
helper restarts requires Refresh. Lists may change remotely between offset pages;
this is not an atomic server-library snapshot.

`openPersonalItem(section,row)` reuses playlist/album/artist details and emits
`personalCollectionOpened()`. `playPersonalSong(section,row)` accepts liked/recent
songs; only this explicit action stores selected metadata and starts fresh URL
resolution using existing preview/permission handling. Browsing never writes
account content to SQLite or changes playback/queue.

Account IDs have a C++-only getter, not a QML property. Login/restore/logout/expiry
clear lists and opened Personal details. Provider session/request epochs and helper
auth epochs reject old responses; ID snapshots are memory-only and cleared on
session replacement/logout. UI defers refresh until ready/session reset completes.

Primary source: [pinned SPlayer modules](https://github.com/SPlayer-Dev/SPlayer-Next/tree/05a4e5929030df21a8448ddb24c77dbd353f974e/electron/main/apis/netease/modules).
The chronological-history module originally requires Electron's web client; KMusic
explicitly adapts the same endpoint to native weapi, matching the
[API-enhanced module](https://github.com/neteasecloudmusicapienhanced/api-enhanced/blob/main/module/record_recent_song.js).
Failures remain errors, with no fallback to `user_record` rankings. Attribution and
transport differences are in `providers/netease/NOTICE.md`.

No functional tests, sign-in simulation, screenshots or GUI verification were run
for this implementation. The coordinator owns the unified build/open; user scanning
and actual account pagination/rights/history validation remain required.
