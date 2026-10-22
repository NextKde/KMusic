# Material corrections: sidebar and highlights

[简体中文](MaterialReview.zh-CN.md)

User feedback on 2026-10-20 adds subtle sidebar translucency/blur and removes the
outline/embossed look of liquid controls, especially buttons and text inputs.

References: [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/),
[Materials](https://developer.apple.com/design/human-interface-guidelines/materials),
and [official Music image](https://www.apple.com/newsroom/2025/06/macos-tahoe-26-makes-the-mac-more-capable-productive-and-intelligent-than-ever/).
The coordinator viewed the official image and read the geometry-dependent lighting,
sidebar and layering guidance. Keep the square app frame and right-side controls.

The two full-perimeter strokes and fixed sheen in LiquidSurface explain the current
bevel effect. Replace them with restrained, directional highlights that fade locally.
Retain separate accessible focus rings. Check both sampled and fallback rendering,
light/dark, neutral/textured backgrounds and all interaction states. Audit independent
select/switch/segmented materials too; one repaired surface is not whole-library acceptance.

Sidebar text/icons stay opaque over a mildly translucent material. An optional app-only
KF6WindowSystem adapter may request the existing compositor's blur for the sidebar region;
no KWin settings/plugins change and no KF dependency in portable Kos.Ui. Remove opaque
paint underneath the sidebar; keep the rest of the window opaque. Use an opaque fallback
if the capability is unavailable, without claiming native blur. No wallpaper replicas.

Preserve before/after evidence and the existing publication cadence. Client item captures
show application drawing only; compositor blur needs composed-scene evidence. Until then
report the native request separately from successful visual acceptance.
