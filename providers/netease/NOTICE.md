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
