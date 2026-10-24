# 固定版本的共享组件源码

KMusic 内置 Kos.Ui 的固定源码快照，不再通过 Git 子模块获取组件。
普通 `git clone` 即包含构建所需的组件、GLSL/QSB、翻译与许可证；不包含 Gallery、示例图片或上游 Git 历史。
初始版本仍为 `dfeddc18f5b1fe529383a7391c2fb52d54b6adee`，此次仅改变分发方式，不调整视觉效果。

来源：[NextKde/nextkdeAppDemo](https://github.com/NextKde/nextkdeAppDemo)。
`vendor/nextkdeAppDemo/vendor-manifest.json` 记录完整提交号、来源和每个文件的 SHA-256。
保留上游 LICENSE、NOTICE.md 以及源码中的版权声明。

## 开发与同步

共享组件只在上游修改，Music 的业务逻辑和专属封装仍留在 Music。
不要直接修改 `vendor/nextkdeAppDemo`；手工改动将导致清单检查失败，同步工具也会拒绝覆盖它。
先将通用修复合入上游，再明确选择一个完整提交 SHA：

```sh
python3 tools/vendor_components.py --upstream-dir /path/to/nextkdeAppDemo --revision <40位完整提交SHA>
```

同步只从本地 Git 对象读取该提交，不读取上游工作区的未提交修改，也不自行下载。
仅复制 `shared/qml/`、LICENSE、NOTICE.md 并生成清单。导入前检查现有快照，失败时不覆盖下游改动。
更新清单与组件作为同一个 PR 提交，运行清单检查、构建及安装测试，最终效果由用户验收。
版本回退通过还原整个同步提交完成，不能只还原清单。

校验、测试、构建在虚拟机或 CI 执行，不在维护者本机运行：

```sh
python3 tools/vendor_components.py --check
python3 -m unittest discover -s tests/installer -p 'test_*.py' -v
```

## GitHub Actions 同步入口

`Sync pinned Kos.Ui snapshot` 接受 `workflow_dispatch` 的 `revision`，也监听
`repository_dispatch` 的 `kos-ui-sync` 事件及 `client_payload.revision`。
来源固定为官方组件仓库，参数必须是完整 SHA，不接受分支、标签或 latest。
工作流更新唯一的 `codex/sync-kos-ui` 分支和同步 PR，不自动合并 main。
并发同步串行执行；相同快照无变更时不产生空提交。

工作流需先进入默认分支才能由 GitHub 手动触发。仓库需允许 Actions 创建 PR。
上游主动通知还需要为目标仓库授权的 GitHub App 或令牌，由维护者配置为 Secret；
本次未创建令牌或修改上游仓库，也未宣称跨仓库推送触发已经启用。
未配置时可以手动指定 SHA，同步工作流仍能独立使用。
机器人创建 PR 的检查可能需要 GitHub 审批；不能把 PR 已创建当作测试通过。

## 安装

`install --source-dir .` 检查内置源码清单，不执行子模块初始化或组件下载。
清单缺失、内容不匹配时返回 `INTEGRITY_FAILED`，不会隐式拉取另一个版本。
远程 `install --version <SHA>` 仍兼容明确指定的历史子模块版本；新版本直接使用随仓库内置的组件。
