# Bilibili discovery

[简体中文](BilibiliDiscovery.zh-CN.md)

Selecting Bilibili opens Discover. Search remains a separate page with a Discover
return action. The ordinary-content shelves provide **New music**, **Music picks**
and **Popular music videos**. **Following updates** appears only after Bilibili
sign-in and includes followed creators' video posts across categories, not just
music. No feed claims personalized music recommendations or a complete catalogue.
Opening the page fetches metadata only. Clicking a video explicitly selects its
BV/cid and uses the existing detail/AAC resolver; browsing never changes playback.

## Modules and service endpoints

- `BilibiliDiscovery`: public transport with no account cookie jar; new music
  `/x/centralization/interface/new/music`, popular music
  `/x/centralization/interface/music/comprehensive/web/rank`, WBI-signed music-region
  `/x/web-interface/region/feed/rcmd` (`from_region=1003`, `device=web`, `plat=30`,
  `request_cnt=15`, incrementing `display_id`). These endpoints were inspected from
  real anonymous service JSON in the VM. Rank maps `related_archive` rather than
  mixing a music identity with a different video's cid. Missing new-music cid is
  resolved through the existing BV detail flow.
- `BilibiliFollowing`: separate private read-only transport for
  `/x/polymer/web-dynamic/v1/feed/all?type=video&platform=web`, with opaque `offset`
  cursor. Protocol reference: [community dynamic-feed documentation](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/dynamic/all.md).
  Account identity and session epoch gate every result; session changes cancel and
  clear private results. Only explicit Play converts account-scoped membership to
  the public playback identity. No follow, like, or history-write API is called.
- `BilibiliDiscoveryController`: section-specific requests, loading/error/retry,
  cursor progression and BV/cid deduplication. `BilibiliFeedState` has deterministic
  stale-response/duplicate/cursor-cycle fixtures. Teardown invalidates generations
  and destroys pending handles before providers/state.
- `BilibiliDiscoveryPage` and `BilibiliFeedSection`: ordinary content with existing
  controls and a shared fixed page header; no shared material changes.

`music.bilibili.discovery.sections` exposes `newSongs`, `recommendations`, `popular`,
`following`, each `{items:[{providerId,title,artist,artwork}], loading, error, more,
loaded}`. Actions: `ensureLoaded`, `reload(section)`, `retry(section)`,
`loadMore(section)`, `play(section,row)`. Failures retain already-loaded entries and
retry the failed cursor. Repeated/cyclic cursors are rejected. New-music/rank are
single service snapshots; music picks request up to 100 batches and stop if a batch
contains no new distinct video. Following filters to supported direct video posts;
unsupported/deleted/non-video entries may be omitted. None of these counts is
presented as a catalogue total.

## Validation boundary

VM-only full build, provider fixtures and live anonymous endpoints are checked.
Fixture coverage includes normal/empty/error shapes, correct related-video mapping,
cancellation, synthetic-session wrong-account denial, account-generation clearing,
cursor progression/cycles, duplicate batches and provider teardown. Live probes
log counts/status only, not account identity, cookies, QR data or stream URLs.
The signed-in following endpoint still requires the user's own scan; unsigned
`-101` is an authentication error, not an empty successful feed. Fixtures are not
proof of real authenticated following data or visual acceptance. No Biu code or
web assets were copied, translated or ported. Host builds/runtime are untouched.
