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

Switch/Segmented候选（4c0f08b）：轨道、静止拇指及展开开关透镜共享方向性
LiquidSurface；展开透镜采样同级真实轨道。分段透镜移除全周亮边/浮雕/阴影，
可采样显式backdrop。Material分支和宿主状态所有权保留。Gallery含禁用/Material
对照，分段页使用裁切的真实彩条源。浅深色展开/移动验收待完成，静止图不代表
展开结果通过；NavBar独立材质仍待处理。
实际播放页使用两种共享控件：Lyrics控制已有持久化设置；选择歌词视图会启用
歌词，关闭歌词回到Overview并明确显示关闭。重新启用网易歌词发起新歌词请求。
视图模式不持久化。审阅接口新增固定materialReview(state,index)与
materialSequence(control,directory,index)，连续帧调用真实共享按下/释放状态入口，
不注入指针/键盘事件；frames.json记录实际请求时间及状态。

NavBar候选（ae9d83e）：共享轨道/静止拇指/活动透镜使用方向性Surface，移除
RGB/白色闭合边、固定高光斑和深度渐变。保留原可变currentIndex/selectionChanged
导航契约及点击/弹簧/超时行为。Gallery作为直接消费方提供真实纹理、禁用/Material
对照。KMusic当前不使用NavBar，仅固定共享版本并回归现有页面，不额外塞入新导航。
动态/焦点/无障碍验收需独立完成，未宣称所有材质均已验收。
