# KMusic

[English](README.md)

采用 Qt Quick 的原生音乐应用，实际链接固定版本的 nextkdeAppDemo / Kos.Ui。
首轮已有方角窗体、右侧窗控、双精选卡/专辑架、侧栏与常驻播放器；推荐艺术为明确标注的原创离线样例。
本地导入、搜索、播放、队列和歌单使用现有 NextKde 后端。SPlayer Next 网易云请求/加密模块
已通过纯 Node 辅助进程接入搜索、详情、歌词与播放地址，并交给真实 GStreamer 播放器。
试听、不可播、网络和账号失效有明确状态。账号登录及更广的目录流程仍待完善，不代表最终验收通过。

依赖 Qt6 6.8+ Core/Gui/Qml/Quick/QuickControls2/QuickDialogs2/Concurrent/DBus/Network/Sql、
在线请求另需 Node.js>=22.19，无需 npm 安装或 Electron。
Qt5Compat.GraphicalEffects、SVG、GStreamer core/audio/pbutils 开发包、TagLib>=1.12及相应解码插件。

```sh
git clone --recursive https://github.com/NextKde/KMusic.git
cd KMusic
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j4
./build/kmusic
```

通过侧栏或 Ctrl+O 导入本地音乐文件夹。点击歌曲播放，+ 加入队列，··· 加入已建歌单。
Ctrl+F 搜索本地资料库；底栏提供播放、进度、音量、随机、循环和队列/正在播放入口。
侧栏可切换浅色/深色/系统外观。
默认数据目录 `~/.local/share/kmusic`，缓存 `~/.cache/kmusic`，与 KOS Music 隔离；
可通过 `KOS_MUSIC_DATA_DIR` / `KOS_MUSIC_CACHE_DIR` 指定独立验收目录。

设置 `KMUSIC_REVIEW_DIR` 可开启仅用于本机验收的文件请求接口：原子写入 `request.json`，
`{"action":"capture","path":"/absolute/out.png"}` 抓取实际窗口内容并写出 response.json。
亦支持 theme（theme=light/dark/system）、page（page=new/songs/queue/now）和 resize（width/height）。
截图来自实际窗口渲染，不是离屏模拟，截图成功本身不等于视觉验收通过。

详见[确认计划](docs/ProjectPlan.zh-CN.md)、[组件对应](docs/ComponentInventory.zh-CN.md)与[来源](NOTICE.md)。

在线入口为 **Online · NetEase**，输入关键词搜索、点击结果播放、+入队、···查看实际获取的详情。
状态栏会显示试听限制；无播放地址、账号和网络错误会明确呈现。临时播放URL不作为持久歌曲身份，
不从其他播放器读取账号Cookie，尚无登录流程。原LX适配器不是默认来源。

侧栏可选材质：构建时有KF6WindowSystem且运行合成器提供BlurBehind时，仅侧栏区域使用
半透明材质并请求现有模糊协议，文字保持不透明；运行能力不可用时回退实心侧栏。
不会安装/修改KWin效果。客户端截图保留侧栏alpha，不包含桌面合成模糊；
review状态分别记录effectAvailable、blurRequested、逻辑区域与fallback原因。

在线恢复会区分曲库整曲时长与上次实际解码流的长度。试听会话重启后保留真实流时长与位置，
明确显示“上次试听，播放前必须重新检查”，不会恢复旧URL或当前播放权限。重启后点击播放
会先重新解析地址再加载引擎。旧会话没有流元数据时显示未知播放时长，避免将整曲长度当作试听长度。
会话仅保存曲目ID、位置、上次可用性分类、流时长与音质，不保存播放URL、Cookie、请求头或Token。
本机review状态提供不含敏感信息的解析/加载计数与确认状态，供重启/恢复专项核对。

### 原生侧栏对照（Linux/KDE，可选开启）

生产侧栏模糊可选依赖KF6WindowSystem。KWaylandClient仅供review适配器按本进程PID
读取真实窗口UUID/几何；缺少时原生捕获守卫拒绝实验。普通启动不创建测试窗口，也不
订阅窗口管理信息。WindowMaterial修改模糊请求后安排窗口帧，保证空闲Wayland表面
也提交协议状态。
开启KMUSIC_REVIEW_DIR后，nativeBackground（visible=true/false）创建原创条纹的
独立原生背景窗口，尺寸仅为App加16px边界；nativeBlur（enabled=true/false）仅切换
本App请求。nativeSidebar（path=绝对PNG路径）调用现有KWin CaptureArea，只抓侧栏内部，
包含调用者窗口。前后验证runtime PID、真实合成器几何、UUID/PID、激活窗口、背景覆盖
与父子关系；失败则丢弃像素，sidecar记录原始格式/stride/DPR及身份。不修改合成器配置
或服务权限。实验后关闭测试背景并恢复nativeBlur.enabled=true。普通客户端capture
仍不能证明桌面模糊，真实原生RGB on/off结果仍需独立看图验收。
