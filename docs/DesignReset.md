# Whole-app design correction — 2026-10-21

[简体中文](DesignReset.zh-CN.md)

## Current bounded correction: color and floating playback

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
- Review light/dark appearances at 1280×800 and 1024×640, including spacing,
  readability, final-item reachability, playback, seeking and volume. Regress any
  compatible shared-control interfaces in Gallery.

The user's latest instructions supersede the earlier native-blur approach.
Previous component checks do not establish whole-app design acceptance.

1. Apple Music defines the music content architecture and hierarchy.
2. kos-settings defines the application exterior and client-drawn window decoration, beyond the three window controls. Keep the outer frame square.
3. Forma defines component shadows, interactions, corner radii, typography and other fine details. Kos.Ui remains the actual implementation.
4. Liquid rendering is essential: preserve real in-app backdrop sampling, refraction, soft directional reflections, press expansion and motion. Removing harsh outlines must not flatten the controls.
5. Transparency and blur are implemented entirely in QML against actual application scene content. Retire KWin liquid glass, KF6 native blur requests, KWayland geometry inspection and NativeReview capture tooling from production builds/startup. Do not reproduce desktop wallpaper inside the client.

The next gate is one coherent, running 1280×800 main window, with a 1024×640 layout check: kos-settings exterior, music sidebar/content/player proportions, consistent vector icons and Forma details. Use genuine source-backed music/artwork or honest empty states. Remove repetitive abstract fixture covers and ad hoc text-symbol icons. Preserve the existing source, playback, preview and lyrics work. General visual fixes still belong in the shared library and require Gallery regression.

Continue local dedicated-window checks and the existing screenshot/source publication schedule. Do not claim the rejected exterior is accepted while the correction is in progress.
