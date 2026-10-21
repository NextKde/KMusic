# Whole-app design correction — 2026-10-21

[简体中文](DesignReset.zh-CN.md)

## Current bounded correction: color and floating playback

Latest bounded request: sidebar opacity is **98%**. External desktop visibility
uses window alpha only, without KWin/native blur. Actual horizontally scrolling
in-app artwork and text extend beneath the sidebar and receive continuous QML
blur plus one refraction pass. Exclude the sidebar, its foreground and the player
from the sidebar capture source to prevent feedback and duplicated contours.

Buttons and inputs now directly reference the user-supplied
[Liquid Glass Vue](https://vue-web-liquid-glass.netlify.app/searchbox): visible
convex-edge bending of real background detail, a continuous center and directional
highlights, without thick closed outlines, embossing or opaque flat substitutes.
Shared fixes belong in Kos.Ui and require Gallery regression. Study source:
[mkj0kjay/vue-web-liquid-glass](https://github.com/mkj0kjay/vue-web-liquid-glass);
preserve attribution/licensing for any adapted code.

Keep the 1100×680 default, the 52px player and its supplied internal order. Follow
the newly attached user AGENTS VM-only preference for runtime tests/screenshots
this round. Automatic polling stays paused; no catalogue or backend expansion.

After pausing the long-running work, the user authorized these two corrections
only. Keep scheduled polling paused; this does not resume the full project or
establish whole-app acceptance.

- Remove the forced purple accent. Use neutral ordinary controls and media
  tracks; distinguish hover, pressed, selected and keyboard-focus states. Reserve
  system accent for meaningful emphasis and keyboard focus, rather than replacing
  every purple surface with another accent color.
- Present playback as a width-limited floating glass panel centered above the
  content area, with side/bottom clearance, internal rounded geometry and a subtle
  shadow. Sample actual page content for the whole panel's blur/refraction. A
  full-width solid footer or glass buttons alone do not meet this requirement.
- Extend content behind the panel and add enough scroll-end space to bring the
  final item fully above it. The square outer window does not prohibit rounded
  floating playback controls.
- The user's subsequent screenshot directly defines the internal order: shuffle,
  previous, play/pause, next and repeat on the left; artwork and two metadata lines
  in the middle, with a thin seek track along that region's lower edge; actual
  preview status, queue list and a volume entry on the right. Open volume on demand,
  omit a separate Now Playing button, and do not move transport to the middle.
  Use a capsule outline and eliminate discrete blur replicas and repeated
  refraction; inspect actual motion frames.
- The user requires at least a 30% height reduction: reduce the 76px candidate to
  52px (about 31.6%), scaling artwork, icons, type and padding together while
  preserving the supplied internal order and thin middle-region seek track.
- The user clarified shell colors and transparency: the light content pane is
  white, while the sidebar must actually reveal the desktop through window alpha.
  Remove opaque ancestors and cover imagery behind the sidebar; keep text opaque.
  Do not request native/KWin blur. QML shadows soften boundaries, not external
  desktop pixels. Playback glass continues sampling actual in-window page content.
- Review light/dark appearances at 1280×800 and 1024×640, including spacing,
  readability, final-item reachability, playback, seeking and volume. Regress any
  compatible shared-control interfaces in Gallery.

The user's latest instructions supersede the earlier native-blur approach.
Previous component checks do not establish whole-app design acceptance.

1. Apple Music defines the music content architecture and hierarchy.
2. kos-settings defines the application exterior and client-drawn window decoration, beyond the three window controls. Keep the outer frame square.
3. Forma defines component shadows, interactions, corner radii, typography and other fine details. Kos.Ui remains the actual implementation.
4. Liquid rendering is essential: preserve real in-app backdrop sampling, refraction, soft directional reflections, press expansion and motion. Removing harsh outlines must not flatten the controls.
5. The sidebar reveals the desktop through actual window alpha; QML provides tint, shadows and soft edges, not external-desktop blur. Internal playback glass still samples actual in-window page content. Retire KWin liquid glass, KF6 native blur requests, KWayland geometry inspection and NativeReview capture tooling from production builds/startup. Do not reproduce desktop wallpaper inside the client.

The next gate is one coherent, running 1280×800 main window, with a 1024×640 layout check: kos-settings exterior, music sidebar/content/player proportions, consistent vector icons and Forma details. Use genuine source-backed music/artwork or honest empty states. Remove repetitive abstract fixture covers and ad hoc text-symbol icons. Preserve the existing source, playback, preview and lyrics work. General visual fixes still belong in the shared library and require Gallery regression.

Automatic polling remains paused. Run the bounded runtime review only in the VM, following the latest user instructions. Publish only genuine evidence with its actual source/runtime identity; do not claim whole-app acceptance.
