# Component inventory

[简体中文](ComponentInventory.zh-CN.md)

Actual source: pinned `vendor/nextkdeAppDemo/shared/qml`, imported as `Kos.Ui`.
All rows await independent light/dark and state review. A source mapping is not
a fidelity or runtime acceptance claim.

| KMusic use | Kos.Ui source | Forma reference | Current gap |
| --- | --- | --- | --- |
| Sidebar navigation | controls/LiquidNavigationButton.qml | src/widgets/sidebar.cpp | Compare selected fill/spacing/focus |
| Search / playlist name | controls/LiquidTextField.qml | src/widgets/text_field.cpp | Compare insets, rim, placeholder |
| Player / import / queue | controls/LiquidActionButton.qml | src/widgets/button.cpp | Compare hover/pressed size and material |
| Seek / volume | controls/LiquidSlider.qml | src/widgets/slider.cpp | Compare thumb motion, track, keyboard |
| Appearance select | controls/LiquidSelect.qml | src/widgets/button.cpp + theme/theme.cpp | Popup sizing and focus review pending |
| Feedback / playlist dialog | controls/LiquidDialog.qml | Forma application dialogs | Backdrop/readability review pending |
| Right-side window controls | foundation/KosWindowControls.qml | kos-settings/main.qml | Additive geometry/maximize API in 2c98a5e; regression pending |
| Resize handles | foundation/KosWindowResizeHandles.qml | kos-settings window skeleton | Edges and corners review pending |

The outer window radius is zero. Window control defaults remain backward
compatible upstream; KMusic opts into 14px circles and maximize/restore. App
business logic (library, queue, persistence) stays outside shared controls.

Fidelity item 1: `LiquidActionButton.iconOnly` fixes clipped compact transport glyphs; upstream defaults remain unchanged. Runtime regression pending. Slider geometry difference recorded: Forma track 4px / knob 22×16px versus shared defaults 6px / 32×16px. No global slider defaults changed; visual comparison is required.

Material round (fd51df7): shared surface closed borders replaced by normal-based
positive light arcs; button/input share it. Input semantic colour/focus/selection
fix included. Exact shader sources and baked assets are committed together.
Runtime review pending. Independent Select, GlassSwitch, NavBar and Segmented
gradient/edge paths remain pending; Material branches are preserved.

The new design contract requires pure QML sampling of real application underlay.
The native platform blur adapter and capture experiment have been removed from
production. Complete shell/content/material review is pending under DesignReset.

Select visual round: closed field/popup now share LiquidSurface; bright/dark bevel removed; Material and activated/acknowledgement unchanged. Keyboard focus is separate. Runtime review pending. Gallery source stripes now clip at source bounds. GlassSwitch/NavBar/Segmented remain pending.

Switch/Segmented candidate (4c0f08b): track, resting handle and expanded switch
lens share directional LiquidSurface; the expanded lens samples the sibling
track. Segmented lens removes full rim/bevel/shadow and can sample an explicit
backdrop. Existing Material branches and host ownership remain. Gallery includes
disabled/Material controls and a clipped real striped source for the segmented
lens. Expanded/moving light/dark acceptance is pending; static rest frames alone
do not establish the expanded result. NavBar independent optics remain pending.

The actual Now Playing page now uses both shared controls: Lyrics toggles the
existing persisted setting; selecting Lyrics view enables it, and turning lyrics
off returns to Overview with an explicit off state. Re-enabling NetEase lyrics
issues a fresh lyric request. Presentation mode itself is transient. The review
API adds whitelisted materialReview(state,index) and materialSequence(control,
directory,index). Continuous frames use actual shared press/release state entry,
not injected pointer/keyboard events; frames.json records request timing/state.

NavBar candidate (ae9d83e): shared track/resting pill/active lens use directional
Surface; RGB/white closed rims, fixed glint and depth gradients are removed.
Its original mutable currentIndex/selectionChanged navigation contract and
click/spring/timeout behaviour remain. Gallery supplies the direct consumer and
real textured/disabled/Material comparisons. KMusic does not currently consume
NavBar, so it receives the pinned shared update and existing-page regression
without introducing an artificial new navigation UI. Dynamic/focus/accessibility
acceptance remains independent; this does not complete all material review.

Whole-home reset candidate: Inter 13px body/26px title follows Forma's type scale;
236px navigation uses the shared additive VectorIcon API (482f7ce) and compact
32px rows with 8px corners. Transport uses shared icon-only buttons, with
4px slider tracks/22×16px thumbs as explicit app settings, preserving library
defaults. Artwork underlay is the actual current cover, preblurred by Qt Quick
MultiEffect then sampled by LiquidSurface with directional reflections and
refraction. No desktop image or platform blur dependency. The square outer
window, 30px CSD, 14px right controls and low-contrast shell/content planes follow
kos-settings. Overall light/dark, narrow-window and pointer-state review pending.


Limited player/palette revision (long-term work remains paused): app-only semantic
bindings inherit Kos.Ui ActionButton/NavigationButton/Select, using neutral ordinary
icons, hover, selection and progress. System keyboard focus stays independent.
Shared defaults are unchanged. LiquidCard samples a separate real scrolling page
scene, with optional LiquidBackdrop continuous blur, one panel refraction pass,
capsule geometry and an outside-only analytic shadow. Child transport buttons do
not resample the page. Filled media paths and optional slider thumb remain shared
APIs. Player layout follows the supplied reference: transport left, artwork and
metadata/seek center, genuine preview badge/queue/volume popup right.

本轮仅修配色和悬浮播放器，长期任务仍暂停。App以语义属性继承Kos.Ui，普通
图标/悬停/选中/进度使用中性色，系统键盘焦点独立；共享默认值不变。播放器
只采独立的真实滚动页面一次，连续QML预模糊后保留折射/高光；内部按钮不重复
采页面，外投影不在玻璃内部垫黑底。实心媒体图标和可选隐藏滑块头均归共享库。
内部按用户图固定为左侧控制、中间封面/信息及细进度线、右侧真实试听标记/队列/
音量弹层。源码/正常构建完成不等于视觉或真实seek已通过；结果见developer检查点。

Ordinary MusicActionButton actions now opt into Kos.Ui LiquidActionButton.materialForm
(non-sampling), including discovery hero actions. Online's fixed search header
samples its sibling SongsPage, including the real scrolling result list; its
controls do not refract the same content again. The floating player remains the
existing 52px sampled panel. Shared defaults/optics remain unchanged.
