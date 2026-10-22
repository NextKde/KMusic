# Source-aware navigation research

2026-10-22: user authorized ten bounded menu/demo iterations over about one hour.
No screenshots or automatic visual acceptance. Preserve shared Gallery materials.

Sources are selected before browsing: online providers (NetEase/Bilibili), local
files, and individual media servers. Search stays scoped to the selected source.
Device-managed playlists/favorites/history remain distinct from provider accounts.

NetEase third-party modules expose daily recommendations, user playlists, liked
song IDs and recent plays. user_record is a listening chart, not recent history.
Current KMusic helper does not yet expose those account collection endpoints.
Evidence: https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/tree/main/module
and attributed local SPlayer-Next reference at05a4e592.

Bilibili API-collect and Nemo2011/bilibili-api repositories are currently archived
and their maintained interfaces are unavailable. Old cached documentation does
not establish current support. Prototype navigation uses video/uploader/collection
semantics and must not claim music albums, integration or playback.
https://github.com/SocialSisterYi/bilibili-API-collect
https://github.com/Nemo2011/bilibili-api

OpenSubsonic defines music/search/starred/playlist capabilities; individual server
support determines menus. Navidrome directory APIs may be virtual. WebDAV starts
as folders/files, not an album catalogue. Local files may include metadata/art.
https://opensubsonic.netlify.app/docs/endpoints/
https://github.com/navidrome/website/blob/master/content/en/docs/developers/subsonic-api.md
https://jellyfin.org/docs/general/server/media/music.html/

Round plan and source-level capability matrix are in the Chinese companion.

Round4 isolates search drafts for the two integrated providers. NetEase navigation
search submits on Enter; local input filters imported files. Unsupported source
search is disabled, not routed to another backend. Ctrl+F respects source scope;
Ctrl+O/import switches to local. Multiple account/server search is not integrated.

Round5 separates anonymous browsing from account menus, including daily picks,
likes, created/collected playlists, collected albums, followed artists and recent
plays. Real sign-in remains available; signed-in collection pages explicitly stay
unintegrated. Session changes clear NetEase drafts without clearing local drafts.
No account collections were fetched or fabricated, and no user scan was performed.

Round6 adds Bilibili-specific descriptions and scoped video/uploader/collection
search preview without network requests or fake results. Its footer entry remains
Bilibili-only and never opens NetEase login or shows a NetEase avatar. Local/media
sources hide the online account entry. No Bilibili adapter or credentials added.

Round7 adds a media connection preview. Music servers expose server libraries;
WebDAV exposes folders/files, not an album API. The dialog accepts only a session
example label and shows a read-only .invalid address. No server requests, saved
credentials or fabricated library. Real multi-instance adapters remain absent.
