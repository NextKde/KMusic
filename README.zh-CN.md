# KMusic

[English](README.md)

采用 Qt Quick 的原生音乐应用，实际链接固定版本的 nextkdeAppDemo / Kos.Ui。
当前整体候选采用方角自绘窗体、右侧窗控、真实当前曲目与来源搜索入口、专辑架及常驻播放器。
已移除重复抽象离线封面；没有资料时显示真实空态，不将搜索结果冒充推荐。
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

在线入口为 **Online search**，输入关键词搜索、点击结果播放、+入队、···查看实际获取的详情。
最近选择区与播放页会显示试听限制；无播放地址、账号和网络错误会明确呈现。临时播放URL不作为持久歌曲身份，
不从其他播放器读取账号Cookie，尚无登录流程。原LX适配器不是默认来源。

[整体设计校正](docs/DesignReset.zh-CN.md)定义下一轮完整外壳和音乐内容验收。
透明模糊使用纯QML采样真实应用页面、封面及背景underlay，保留清晰文字和液态光学。
当前候选使用真实当前封面预模糊underlay及共享LiquidBackdrop/LiquidSurface，均在QML内完成。
外壳为30px自绘窗饰、236px侧栏与84px播放器，不依赖原生合成器特效。整体视觉验收仍待完成。

在线恢复会区分曲库整曲时长与上次实际解码流的长度。试听会话重启后保留真实流时长与位置，
明确显示“上次试听，播放前必须重新检查”，不会恢复旧URL或当前播放权限。重启后点击播放
会先重新解析地址再加载引擎。旧会话没有流元数据时显示未知播放时长，避免将整曲长度当作试听长度。
会话仅保存曲目ID、位置、上次可用性分类、流时长与音质，不保存播放URL、Cookie、请求头或Token。
本机review状态提供不含敏感信息的解析/加载计数与确认状态，供重启/恢复专项核对。

发现页沿固定版本SPlayer网易云album_new接口加载8张公开新碟，有明确加载、错误和重试。
这不是个性化推荐，不自动播放。点击封面进入真实专辑资料与曲目列表，浏览不会改动播放或保存歌曲。
可明确选择整张播放、单曲或加入队列；固定顶栏在真实滚动内容上方，“Find in album”筛选已载入曲目。
封面上的小播放按钮可直接播放整张。每次播放仍重新解析地址，账号/版权限制可能使曲目仅可试听或不可播。

### 网易云登录

从侧栏“Sign in to NetEase”生成二维码，在网易云音乐官方手机端扫码并确认。
二维码在本机生成；会话通过 QtKeychain 保存到系统凭据库，不允许明文回退。
保存失败会明确提示仅本次会话有效。退出会清除本机凭据并请求服务端退出；
会话过期需要重新扫码。账户变化后旧播放地址失效，下次播放重新解析。
登录不改变会员和曲目版权限制。专用截图接口在显示二维码或账户身份时拒绝截图。
构建额外依赖 Qt6Keychain 和 libqrencode。实际扫码登录需用户完成。

在线搜索支持歌曲、歌单和专辑；点击集合结果进入同一个详情页，不改变播放或队列。
歌单按来源 trackIds 顺序与 ID 去重，逐批补齐曲目元数据，每批最多 200 项。若还有更多内容，页面明确显示
已载入/总数与部分载入状态，按钮使用“播放/入队已载入曲目”，只操作这一部分，
不宣称完整歌单可用。每首歌仍通过真实地址解析确认当前播放权限。

歌单详情可通过“加载更多”逐批获取，每批最多 200 首，按源曲目顺序及 ID 去重追加。失败保留已加载列表并可重试；本地筛选不改变已载／总数，继续加载不播放或改队列。

歌手搜索复用同一详情页展示网易云真实热门歌曲，已加载热门数量与来源作品总数分开显示，不宣称全部作品。“播放／入队热门歌曲”需明确操作，浏览不改变播放。本批尚不包含歌手专辑浏览。
