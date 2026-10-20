# NextKde Music design contract

> Paused for user review on 2026-10-20. The proposed revised contract is
> [ProjectPlan.zh-CN.md](ProjectPlan.zh-CN.md). It supersedes this initial document
> on local testing, source integration, evidence publication and repository naming.

[简体中文](Design.zh-CN.md)

## Reference ownership

| Reference | Owns |
| --- | --- |
| https://music.apple.com/cn/new | Music navigation, editorial discovery, album shelves, song lists and persistent playback |
| Local Forma source-5bdb550 | Fine control shape, colour, spacing, typography, material and interaction states |
| https://github.com/NextKde/nextkdeAppDemo | Actual reusable Qt Quick components; canonical location for portable fixes |
| NextKde apps/settings/main.qml | Frameless square outer window, top drag strip and right-side window controls |

The coordinator designs and reviews. One implementation agent develops the app
and sends general component improvements back to nextkdeAppDemo. Each round
handles a small explicit set of differences, then receives independent review.

## Desktop composition

Start at 1280×800 logical pixels; support 1024×640 without clipped controls and
1440×900 without wasteful stretching. Use a zero-radius outer window, a 30px top
drag strip inspired by kos-settings, and minimize/maximize/close on the right.
Support move, resize, maximize/restore, keyboard focus and visible focus feedback.
Do not make the whole UI square: Forma governs individual control geometry.

A roughly 240px sidebar groups Search, New, Library (songs/albums/artists), and
playlists. The content area has a clear page title and editorial hierarchy:
featured releases, new albums, recommended playlists and compact song rows.
Use a persistent player with artwork, metadata, transport, seek and volume.
Provide album/playlist details, queue and now-playing/lyrics views. Library
import, search, empty states and failures must have working actions.

The first milestone is a functional local music player with original offline
editorial fixture data for UI review. Fixture shelves must be labelled and must
not pretend to stream commercial music. Existing NextKde playback code may be
extracted with provenance; avoid rebuilding mature playback logic unnecessarily.
Account-based Apple Music playback is not part of the current contract.

## Components and fidelity

Use Kos.Ui LiquidTextField, LiquidActionButton, LiquidNavigationButton,
LiquidSlider, LiquidSelect, LiquidDialog and semantic theme primitives where
applicable. Missing reusable patterns are contributed upstream. Maintain an
inventory linking each app use to its upstream QML file and Forma reference.
For each difference record expected/actual behaviour, source, proposed fix,
revision and visual review status. Review default/hover/pressed/focus/disabled,
open popup, scrolling and reduced-motion states in light and dark appearances.

Keep foreground text opaque when the material is translucent. Any sampled
glass must sample eligible sibling content in the same window. Do not claim
desktop blur or refraction from alpha transparency. Do not modify KWin for this app.

## Acceptance evidence

Build and run only in the VM. Review actual screenshots personally; animated
behaviour needs sequences and interaction observations. Record VM OS/Qt/backend,
app SHA, component SHA, window size, scale, theme, commands and known gaps in
ignored .task/acceptance/. A successful build is separate from UI sign-off.

Before delivery cover discovery, search, detail navigation, local import,
play/pause/previous/next/seek/volume, queue, playlist persistence, keyboard flow,
empty/error states, window controls and light/dark/resized layouts. Component
changes also need regression of their nextkdeAppDemo consumers in the VM.
