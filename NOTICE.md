# Source provenance

KMusic is distributed under GNU GPL version 3; see LICENSE.

- `src/` music backend and `qml/Artwork.qml`, `data/kmusic.svg` originate from
  [NextKde/NextKde](https://github.com/NextKde/NextKde), revision
  `38f3fb88e1ed6c0a44ca4188b694859aca29381c`, `apps/music/`. Existing source comments
  are retained. KMusic replaces the application entry and UI, isolates data/cache
  defaults and MPRIS identity, and adapts provider integration.
- `vendor/nextkdeAppDemo` is a pinned Git submodule, preserving its LICENSE and
  NOTICE. Portable controls are linked from that source, not copied privately.
- New discovery artwork is original QML geometry. Offline collections contain
  no commercial album images or audio. Apple Music supplies layout inspiration.
- Forma source-5bdb550 is a visual reference; its source is not copied here.
- SPlayer Next provider integration is planned against revision
  `05a4e5929030df21a8448ddb24c77dbd353f974e`; no SPlayer code is included yet.
  Any extraction must preserve its applicable license and authorship.
