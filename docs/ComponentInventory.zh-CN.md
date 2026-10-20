# 组件对应清单

[English](ComponentInventory.md)

真正源码位于固定子模块 `vendor/nextkdeAppDemo/shared/qml`，页面导入 Kos.Ui。
目前全项待独立浅深色、交互状态验收，源码对应不代表还原度通过。

| App 使用点 | 共享控件 | Forma 参考 | 待检查 |
| --- | --- | --- | --- |
| 侧栏导航 | LiquidNavigationButton | src/widgets/sidebar.cpp | 选中态、间距、焦点 |
| 搜索/歌单名称 | LiquidTextField | src/widgets/text_field.cpp | 内边距、高光、占位文案 |
| 播放/导入/队列按钮 | LiquidActionButton | src/widgets/button.cpp | 悬停、按下、材质 |
| 进度/音量 | LiquidSlider | src/widgets/slider.cpp | 拇指、轨道、键盘 |
| 外观选择 | LiquidSelect | button.cpp / theme.cpp | 弹层、尺寸、焦点 |
| 歌单/反馈弹窗 | LiquidDialog | Forma应用弹窗 | 可读性与背景 |
| 右侧窗控 | KosWindowControls | kos-settings/main.qml | 2c98a5e兼容属性改进，需回归 |
| 窗口缩放 | KosWindowResizeHandles | kos-settings骨架 | 四边与四角 |

外框半径为0，窗控使用14px绿黄红圆点与最大化/还原，组件原默认行为保持。
资料库、队列、持久化等业务不进入组件库。
