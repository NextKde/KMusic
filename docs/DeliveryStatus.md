# Current delivery status

[简体中文](DeliveryStatus.zh-CN.md) · 2026-10-22

This is a runnable developer candidate, **not a release or visual acceptance**.
The fixed native candidate checked here is
[`46f3286`](https://github.com/NextKde/KMusic/commit/46f3286fd217ca1d63f858080f75d8ed7e6bd5c2),
with Kos.Ui
[`96ff101`](https://github.com/NextKde/nextkdeAppDemo/commit/96ff101f18801594b87681a5f37e9a6131f9d144).
Later documentation-only commits do not change that tested binary.

| Scope | Actual result |
| --- | --- |
| Native startup | Arch Linux, Qt 6.12.0, Wayland/OpenGL, DPR 2; normal local data; no shell/compositor changes. |
| Size/appearance samples | 1100×680 and 1024×640, each light/dark; 24 original live-window captures with per-image revision/environment sidecars. Capture success does not establish visual quality. |
| Navigation | Discover, online album search, real album details, local favorites, recently played and immersive playback. Real search opened NetEase album 18909 with 13 songs. Browsing kept current track/queue and engine-load count unchanged. |
| Keyboard | Actual dedicated-window Qt key events: Ctrl+F focuses the library input; Space in that input does not resolve/load/start playback; Tab reaches sidebar navigation and player volume. Escape closes the volume popup and exits immersive playback with visible focus restored. |
| Focus fixes in this batch | Immersive playback previously had no Escape handler; the volume popup did not acquire keyboard focus. Both received narrow fixes, without material/layout changes. |
| Diagnostics | No new QML/Shader/source-feedback error observed in the checked log. Existing portal desktop-ID registration warning remains. |

The ordinary dataset contains local test favorites/recent/playlists and publicly
fetched song metadata; no sign-in code or account identity was captured. The local
review record is `.task/integration/` (ignored); selected evidence is published by
the coordinator through [latest progress](https://github.com/NextKde/KMusic/blob/ui-evidence/README.md).
The checked executable used Node 22.23.1, GStreamer 1.28.8, TagLib 2.3.2,
QtKeychain 0.17 and libqrencode 4.1.1. See [build/run instructions](../README.md#build-and-run).

Earlier targeted batches exercised real anonymous preview playback, save/favorite/
recent persistence, playlist batching, pause cancellation, natural EOS, finite
shuffle passes and restored-position Previous. They have separate exact revisions;
this integration check did **not** repeat a full playback/network matrix.

Still unverified or awaiting the user:

- Actual mobile QR confirmation, authenticated account permissions, credential-store
  restore, expired-session handling and authenticated sign-out. Implemented paths
  are not proof of a completed authenticated session.
- User visual acceptance, including liquid materials, player underlay readability,
  all page proportions and appearance. Content text remains visible through parts
  of the sampled player; these images are submitted for judgment, not labeled passed.
- Full keyboard/accessibility audit: this was a small shortcut/Tab check, not every
  control/dialog, screen reader or IME combination.
- Clean-machine installed-app/dependency smoke, other audio/platform setups, and
  broad network/rights/URL-expiry combinations. No release/package was published.

Development stops at this checkpoint pending coordinator/user acceptance. No new
business page or optical adjustment was selected as follow-up.
