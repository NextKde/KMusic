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
