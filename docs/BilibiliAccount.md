# Bilibili account and library

[简体中文](BilibiliAccount.zh-CN.md)

The Bilibili avatar and Personal page open a separate Bilibili account dialog.
Generate a code, scan with the official Bilibili app and confirm on your phone.
KMusic accepts the session only after `/x/web-interface/nav` verifies its identity.
No password entry, imported browser cookie, or automatic scan confirmation is used.
QR URL validation accepts only the exact HTTPS entry pairs `passport.bilibili.com/h5-app/passport/login/scan` (legacy) and `account.bilibili.com/h5/account-h5/auth/scan-web` (observed current service), with a matching challenge key. QR challenges expire after 180 seconds. Cancel aborts polling and clears unverified
cookies. Returned cross-domain login URLs are never followed.

Personal is read-only: favorites folders, videos within a folder (20 per page),
and account video history (cursor pages, 20 per request). Non-video/deleted entries
may be omitted. History is service-provided account history, separate from KMusic's
local recently played; it does not imply KMusic uploads play records. Browse does
not write a local track or change the queue. Explicit Play selects a public BV/cid
identity and reuses the current session for Bilibili API resolution. Existing
ordinary AAC and permission restrictions still apply; no entitlement bypass.

API/passport traffic shares a native provider-local cookie jar. Fixed HTTPS origins,
manual redirects, 4 MiB responses and a 15-second deadline bound it. Cookie identity
is never included in the CDN playback descriptor or local media identity. Account
scope is retained by library entries, verified on reads/actions, and deliberately
removed only at explicit public playback selection. Session changes cancel old
requests and clear the library/search/pending playback. Network/verification errors
do not erase credentials; a confirmed unauthenticated account expires the session.

Credentials use the separate QtKeychain key `NextKde.KMusic/bilibili.session`, with
insecure fallback disabled. A non-secret restoration gate is cleared and synced
immediately on device sign-out, even if credential deletion fails. Storage is
serialized: pending writes/reads finish before removal, and new login/restore is
blocked until cleanup completes. Failed secure storage leaves the current login
session-only; the UI offers cleanup retry. Sign-out is local to this device, not a
server-wide revoke operation. There is no token-refresh or cloud write API here.

Modules: `BilibiliSession` transport, `BilibiliAccount` AccountProvider,
`BilibiliLibrary` LibraryProvider, separate account/library controllers, and
`BilibiliPersonalPage`/generic account dialog. The NetEase path remains independent.
The opt-in review capture gate excludes visible QR/account identity for both sources.

Protocol references (community documentation of actual Bilibili endpoints, not an
official stable API guarantee): [QR flow](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/login/login_action/QR.md),
[favorites folders](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/fav/info.md),
[folder items](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/fav/list.md),
[history](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/historytoview/history.md).
Implementation is independent; no Biu code was copied, translated or ported.

Validation is VM-only. Parser/session fixtures cover status codes, QR origin/path,
nav authentication vs verification, missing data, synthetic cookie restoration /
clear / expiry, account scope, cancellation and history cursor progression. They
are not proof of authenticated sign-in, actual keyring race execution, or private
account-data availability. Those still require a user-authorized phone scan and
interactive account validation; no real account credentials are in fixtures/logs.

VM validation for this delivery: full native app build and four provider fixture
executables passed. A real anonymous request generated a challenge, polled the
waiting-for-scan status, cancelled it, and verified anonymous nav returned signed
out. Only status categories were recorded; no QR URL/key or account scan was used.
The isolated VM app opened the Bilibili Personal sign-in page without QML errors.
