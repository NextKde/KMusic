# 材质修正：侧栏与高光

2026-10-20 用户反馈，纳入当前开发与共享组件验收，不改变方角窗口骨架。

## 参考与判断

- [Apple：Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)，
  约 8 分钟侧栏环境色、约 11 分钟形状/光线决定高光、约 13 分钟减少玻璃叠玻璃。
- [Apple HIG：Materials](https://developer.apple.com/design/human-interface-guidelines/materials)：
  侧栏以可读性为先，采用柔化背景内容的常规材质。
- [Apple 官方 Music 实图](https://www.apple.com/newsroom/2025/06/macos-tahoe-26-makes-the-mac-more-capable-productive-and-intelligent-than-ever/)：
  个人已查看官方配图；侧栏轻微透色、背景细节散开，普通控件没有沉重的常驻亮边。

当前源码中 LiquidSurface 的全周 1px 亮边、内圈 1px 亮边和固定面内渐变叠加，
是目前按钮/input 呈现描边与浮雕感的可定位原因。此项属于共享材质修正。

## 侧栏

侧栏底材轻微透明并有实际背景模糊，前景文字与图标保持不透明。
KMusic 的可选平台适配层可通过 KF6WindowSystem 请求已有合成器对侧栏区域 blur；
共享 Kos.Ui 不加入 KWin/KF6 依赖。只请求现有能力，不修改 KWin 配置或插件。
只对侧栏区域生效，主内容、顶栏与播放器保持实心。缺少能力时使用明确的实心退化路径。
不得在透明侧栏下面保留全窗实心背景，也不得拿墙纸副本或装饰渐变冒充真实桌面模糊。

## 液态高光

优先修 LiquidSurface 及实际消费它的按钮、input，再逐项检查 Select、Switch、Segmented、
Dialog、Card、导航和滑块各自的独立材质。保留清单，不以修一处代表全库已通过。

- 消除常态双圈亮边；高光沿局部光弧自然衰减，方向与形状相关。
- 面内反光宽而弱，避免顶部白带、底部黑带形成金属/浮雕。
- 普通状态安静，悬停/按下适度增强，减少动态效果时平滑退化。
- 无 backdrop 与有真实采样的路径均检查，不能只在彩色背景上好看。
- 键盘焦点提示独立保留；不将功能性的 focus ring 与常态装饰描边混淆。

## 验收与证据

每项检查浅/深色、普通/悬停/按下/焦点/禁用、纯色/有纹理背景与边缘裁切；
按钮和搜索框优先。动态需要连续帧。侧栏需检查移动/缩放和透明区域边界。
保留本轮改前/改后的真实版本截图，按既定五分钟双库截图与十五分钟源码推送执行。

客户端 Item.grabToImage 只能证明应用内部绘制，不能证明桌面合成器的 blur 已正确呈现；
原生模糊需要合成画面的额外证据，未取得前如实记录“请求已发送，视觉效果待验收”。
