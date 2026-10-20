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

还原项1：共享按钮 iconOnly 模式修复紧凑播放器图标裁切，原文字按钮默认行为保持。待运行回归。滑块差异：Forma 轨道4px/拇指22×16px，共享默认6px/32×16px；仅记录，先实图比较，不直接修改全局默认。

材质轮次fd51df7：共享表面从闭合双边框改为基于法线的方向性正光，按钮/输入实际复用；
输入语义色、焦点和选择文字一起修复，GLSL/QSB配对提交。待实际视觉回归。
Select、GlassSwitch、NavBar、Segmented独立旧渐变/边缘仍pending，Material分支保持。

App独立可选KF6适配器仅向半透明侧栏区域请求原生BlurBehind；effectAvailable与blurRequested
分开报告，不可用回退不透明侧栏。客户端alpha截图只能表明App表面，不能证明桌面合成模糊。

选择器视觉轮：闭合场/弹层共享LiquidSurface，去亮暗浮雕，Material与activated/宿主确认保持，键盘焦点独立。待运行验收；Gallery条纹源已裁切。GlassSwitch/NavBar/Segmented仍pending。
