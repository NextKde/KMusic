# Whole-app design correction — 2026-10-21

[简体中文](DesignReset.zh-CN.md)

The user's latest instructions supersede the earlier native-blur approach.
Previous component checks do not establish whole-app design acceptance.

1. Apple Music defines the music content architecture and hierarchy.
2. kos-settings defines the application exterior and client-drawn window decoration, beyond the three window controls. Keep the outer frame square.
3. Forma defines component shadows, interactions, corner radii, typography and other fine details. Kos.Ui remains the actual implementation.
4. Liquid rendering is essential: preserve real in-app backdrop sampling, refraction, soft directional reflections, press expansion and motion. Removing harsh outlines must not flatten the controls.
5. Transparency and blur are implemented entirely in QML against actual application scene content. Retire KWin liquid glass, KF6 native blur requests, KWayland geometry inspection and NativeReview capture tooling from production builds/startup. Do not reproduce desktop wallpaper inside the client.

The next gate is one coherent, running 1280×800 main window, with a 1024×640 layout check: kos-settings exterior, music sidebar/content/player proportions, consistent vector icons and Forma details. Use genuine source-backed music/artwork or honest empty states. Remove repetitive abstract fixture covers and ad hoc text-symbol icons. Preserve the existing source, playback, preview and lyrics work. General visual fixes still belong in the shared library and require Gallery regression.

Continue local dedicated-window checks and the existing screenshot/source publication schedule. Do not claim the rejected exterior is accepted while the correction is in progress.
