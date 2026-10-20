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
No account cookie is read from another player or logged. Login is not yet exposed.
