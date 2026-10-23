# Source provenance

The native KMusic application is distributed under GNU GPL version 3; see LICENSE.
The extracted SPlayer Next provider code is under AGPL-3.0; see
providers/netease/LICENSE and providers/netease/NOTICE.md. Preserve both notices
when distributing the combined application and helper.

- `src/` music backend and `qml/Artwork.qml`, `data/kmusic.svg` originate from
  [NextKde/NextKde](https://github.com/NextKde/NextKde), revision
  `38f3fb88e1ed6c0a44ca4188b694859aca29381c`, `apps/music/`. Existing source comments
  are retained. KMusic replaces the application entry and UI, isolates data/cache
  defaults and MPRIS identity, and adapts provider integration.
- `vendor/nextkdeAppDemo` is a pinned Git submodule, preserving its LICENSE and
  NOTICE. Portable controls are linked from that source, not copied privately.
- Apple Music supplies layout inspiration. Discovery metadata/artwork are fetched
  from NetEase's anonymous new-album API; they are source-provided catalogue data,
  not original art, personalized recommendations or a playback entitlement.
- Forma source-5bdb550 is a visual reference; its source is not copied here.
- `providers/netease/{core,modules}` is extracted from SPlayer Next revision
  `05a4e5929030df21a8448ddb24c77dbd353f974e` (imsyy and contributors), AGPL-3.0.
  Relative import suffixes and native host transport are adapted; unsupported
  Electron web-client mode is explicit. Request/crypto/xeapi and selected NetEase
  modules are retained. See its NOTICE for exact paths and modifications.
- `providers/helper.ts` and the Qt QProcess protocol are KMusic glue. No Electron
  UI, account cookie from another player, or third-party source fallback is used.

- Convex button/input material is implemented by the pinned Kos.Ui submodule.
  Its native QML/GLSL derivation references mkj0kjay/vue-web-liquid-glass revision
  `934404c05167417945e73a36388c20cc201b5a55`; see the component NOTICE. No Vue UI,
  displacement-map code, website image or external desktop pixels are imported.

The plain-JavaScript files under `providers/runtime/` are generated from the
corresponding TypeScript sources using `tools/build-provider-runtime.mjs`. Their
original source comments and AGPL license/NOTICE are preserved; generation does
not change provider request/crypto behavior. Source/artifact hashes are recorded
in `providers/runtime/manifest.json`.
