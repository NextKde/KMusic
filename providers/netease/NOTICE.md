# SPlayer Next NetEase extraction

Upstream: https://github.com/SPlayer-Dev/SPlayer-Next
Revision: 05a4e5929030df21a8448ddb24c77dbd353f974e
Original path: electron/main/apis/netease/{core,modules}
License: AGPL-3.0; see LICENSE. Authors: imsyy and SPlayer Next contributors.

Modified for KMusic on 2026-10-20: native Node TypeScript relative imports include
.ts suffixes; Electron proxy/logger replaced by transport.ts; Electron web-client
mode explicitly reports unsupported, without silently emulating its browser SDK.
The original request/crypto/xeapi and selected API modules otherwise remain intact.
Only the allowlisted desktop API calls exposed by helper.ts can be invoked.
No account cookie is read from another player or logged. Account credentials are passed only over the private helper pipe and saved by
KMusic through the system credential store (no insecure-file fallback).

Discovery adds modules/album_new.ts from the same fixed revision, adapting only
the .ts relative import suffixes. The anonymous new-album feed is not personalized.

Account integration adds login_qr_key, login_qr_check, login_status and logout
from the same pinned revision. The QR check catch now preserves actual
800/801/802/803 responses and propagates transport failures instead of an empty
success-shaped body. KMusic generates the QR locally with libqrencode. No web UI
or QR image service is used. Account/cookie state management is KMusic code.

Collection search reuses cloudsearch type1000/type10 and playlist_detail from the
same fixed revision. KMusic's helper follows trackIds and requests missing song
metadata for a bounded first200 entries; partial counts are reported explicitly.
No additional upstream code or web interface was imported for this adapter.

Playlist pagination uses the same attributed playlist_detail and song_detail modules. KMusic keeps a bounded in-memory track-ID snapshot and requests successive 200-ID batches; it does not impose a permanent 200-song cap. Session restore/logout clears snapshots.

Artist browsing adds modules/artists.ts from the same fixed SPlayer Next revision (05a4e5929030df21a8448ddb24c77dbd353f974e), adapting only relative .ts import suffixes; original AGPL-3.0 authorship/license retained. cloudsearch type100 searches artists. The artist response is labelled popular songs, not a complete discography.

Artist albums adds modules/artist_album.ts from the same fixed upstream revision, adapting only relative .ts imports and retaining its AGPL license/authorship. Actual hotAlbums/more/artist.albumSize supply list pagination and catalogue metadata; artist popular tracks and albums remain independent browsing models.

Discovery feed adds personalized, recommend_songs and recommend_resource from the
same pinned SPlayer Next revision, with only relative .ts import suffix changes.
They retain the original AGPL-3.0 authorship and license. The pinned revision does
not contain top_song/toplist modules. These two files are small KMusic adapters
using SPlayer's request/createOption stack, with endpoint/parameter shape checked
against NeteaseCloudMusicApiEnhanced/api-enhanced module/top_song.js and toplist.js;
no third-party implementation text is copied for those wrappers. Public discovery
requests explicitly omit the account cookie; daily requests require an authenticated
session. Feed lifecycle, normalization and old-account cancellation are KMusic code.
