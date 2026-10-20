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
