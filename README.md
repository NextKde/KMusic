# KMusic progress

Updated: 2026-10-21T23:31:09.546477+08:00

Runtime `a571da9c` · shared `96ff101` · native Qt/QML, local rendering

- Available: QR login UI/session lifecycle, real search/play/pause/next/seek and lyrics; human phone scan and authenticated persistence still require user acceptance.
- Current player fix: local metadata readability plate; optical background kept at panel sides. No second scene capture added.
- Implemented: expiry handling and a non-secret sign-out marker preventing unwanted restore if secure deletion fails; authenticated lifecycle still needs real user login validation.
- New candidate: real album detail browsing with independent track model and explicit play/queue actions. Browsing did not alter queue or start playback; real helper interruption showed an error, Retry restored 20 tracks; actual album/single enqueue kept playback paused; Play album and track-row playback advanced real audio. Search filtering and error Retry checked. Fixed toolbar samples the opaque real page scene.
- Design: immersive left playback/right real queue, plain content buttons, fixed liquid overlays. Final visual acceptance belongs to user.

![Current capture](screenshots/round-20261021-2329/current.png)

[Exact capture metadata](screenshots/round-20261021-2329/metadata.json)

![Current-track readability, light](screenshots/round-20261021-212941/panel-light.png)

![Current-track readability, dark](screenshots/round-20261021-212941/panel-dark.png)

- Real playlist/album search, detail, loaded-song enqueue/play and failure Retry checked locally on `7be9494`. Load-more now fetched all 836/836 tracks in real 200-ID batches; loading failure preserves the existing list and Retry resumes. Changing detail pages ignores the delayed old result. Queue/playback remain unchanged during loading.

- Artist search/detail now shows real popular songs separately from catalogue counts. Enqueue stays paused; actual playback returned a labelled 30-second preview. Artist albums now loaded 45/45; opening an album and Back preserves artist state. Tested album playback returned an anonymous account/rights error (no successful URL or engine load); this failure remains visible. Online save-to-local-playlist candidate: opening/cancelling picker did not write tracks; explicit selection saved metadata and playlist item without starting audio. Actual restart retained two saved songs, queue and preview position while staying paused with zero resolves/loads. Explicit Play freshly resolved the preview and advanced 1715→3161ms; database audit found no persisted NetEase stream URLs.

- Fixed in `6ea8f1c`: picker closes from the stable window before refreshing playlist delegates. Actual save/reopen/cancel and duplicate-save checks completed without residual modal or ReferenceError.

- Local favorites delivered: explicit favorite/unfavorite, restart persistence, and toggling during actual playback checked. Unfavorite keeps the song and playback context. These are local records, separate from NetEase account likes.

- Recently played candidate records only real engine Playing, keeps one entry per song and survives restart. Permission rejection did not enter history. Fixed in `00aff6d`: actual permission rejection followed by successful preview in the same process clears the earlier error; history keeps only the successful track.

- Fixed pending-resolve cancellation: after actual Pause, late successful URLs and interrupted-helper responses are ignored with zero engine loads. Explicit resume freshly resolves; changing tracks also ignores the old successful URL. Queue-end/EOS handling remains under review.
