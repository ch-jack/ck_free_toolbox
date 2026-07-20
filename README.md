# CK免费工具箱

CK免费工具箱 v1.0.2 是纯本机客户端工具，不需要服务端文件、HTTP API 或后台服务。推荐通过 CK免费工具箱.exe 启动，窗口和任务栏使用 static/cklogo.ico。

本仓库不是空外壳。`CKFreeToolbox.ps1` 和 `app/` 包含窗口、环境检测、任务进程、日志、组件安装更新及五个功能页的客户端实现。模型渲染、NUI 重写、RPF 转 FiveM、扫描移除后门和一键清理小哈引擎分别在 [CK-model_renderer](https://github.com/ch-jack/CK-model_renderer)、[nui-wallfix](https://github.com/ch-jack/nui-wallfix)、[rpf2fivem](https://github.com/ch-jack/rpf2fivem)、[ck_anti_john](https://github.com/ch-jack/ck_anti_john) 和 [xiaoha_cleaner](https://github.com/ch-jack/xiaoha_cleaner) 维护，工具箱运行后按需下载。

## 界面预览

### 模型自动截图

![CK免费工具箱 - 模型自动截图](homepage-preview.png)

### NUI 自动去墙

![CK免费工具箱 - NUI 自动去墙](nui-wallfix-preview.png)

### RPF 转 FiveM

![CK免费工具箱 - RPF 转 FiveM](rpf-to-fivem-preview.png)

## 启动

双击：

~~~text
D:\fivem\ck_free_toolbox\CK免费工具箱.exe
~~~

start_toolbox.cmd 仅用于开发排错。不要只复制 EXE；主脚本、app/ 和 static/ 必须与 EXE 保持原目录结构。

## 一键打包

开发者双击 `一键打包发布包.cmd`，脚本会自动：

- 重新构建 `CK免费工具箱.exe`。
- 不预先下载或打包 `vehicle_renderer`、`nui-wallfix`、`rpf_to_fivem`、`ck_anti_john` 和 `xiaoha_cleaner`。
- 保留组件检测、GitHub 安装、校验、更新、备份和失败回滚代码。
- 不复制 Blender 或 Python；依赖由用户安装，工具箱只负责真实检测、官网跳转和路径选择。
- 生成可以直接发给用户的轻量客户端目录和 ZIP。
- 写入使用说明、版本、运行时组件策略和 SHA-256 清单。

默认产物位于 `dist/CK免费工具箱-v1.0.2/` 和同名 ZIP。用户解压后直接双击最外层 `CK免费工具箱.exe`。页面检测到组件缺失时，点击“安装组件”才会从对应 GitHub 仓库下载。Blender 仍需用户独立安装。

命令行用法：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-ReleasePackage.ps1
~~~

可用 `-SkipArchive` 只生成发布目录。

## GitHub 自动构建与发布

`.github/workflows/build-release.yml` 只检出并构建本仓库，不拉取五个功能组件：

- 推送到 `main` 时，自动生成 `v1.0.<run>` 版本，构建 EXE/ZIP、上传 Artifact 并创建正式 GitHub Release。
- Pull Request 只执行构建验证，不发布 Release。
- 手动推送 `v*` 标签时仍按指定标签发布；自动版本会同步写入 EXE、界面和包清单。
- 自动构建和发布都不会下载或打包 Blender。

发布命令：

~~~powershell
git tag v1.0.2
git push origin v1.0.2
~~~

## 功能

### 模型自动截图

- 扫描目录中的 .yft、.ydr、.ydd 和 .ymap。
- 支持载具、武器、饰品、道具、普通 Drawable、Drawable Dictionary 和地图。
- 支持按载具、武器、饰品分类筛选，并保留实时搜索、全选、取消、打开输出目录和批量渲染。
- 分类筛选会传给 `--asset-types`；角度预设提供当前左侧、标准正面和反向正面，兼容本地前向轴相反的模型。
- 使用已安装 Blender 自带 Python；玩家只需选择安装目录中的 `blender.exe`，最低支持 Blender 4.2（推荐 5.1），CodeWalker 转换工具与 Sollumz 使用模型组件内置路径。
- RPF 解包和 YTD 纹理中间文件统一写入本次输出目录的 `_temp`，不占用系统临时目录，任务结束自动清理。
- 每次渲染都会生成带模型名和对应图片的 HTML 表格，以及独立 Markdown/JSON 执行报告；页面确认报告属于本轮任务后启用“打开图片表格”。

### NUI 自动去墙

- 支持选择单个 FiveM resource 或整个 `resources` 目录，扫描 HTML、CSS、JavaScript 和资源清单中的外链。
- “安全扫描”只读且不访问网络；“预览方案”会解析替换结果，但不修改目标文件。
- 必须选择具体 resource 或 resources 目录；工具箱会阻止扫描磁盘根目录和自身工作区，长任务可随时停止。
- 正式写入支持自动、完全本地化和国内 CDN 三种方案，并可限制超时与单文件大小。
- 每次正式写入都在目标目录外创建备份，结果提供 Run ID，可从工具箱直接恢复。
- 支持自定义 `providers.json`、未验证镜像、内网地址和冲突时强制恢复等高级选项。
- 直接调用随包发布的 `nui-wallfix.py`，不需要后端服务；Python 必须实际运行并满足 3.7+，不会把 WindowsApps 商店占位程序误判为已安装。
- Python 缺失时显示官网下载按钮，安装后可选择安装目录中的 `python.exe`。
- 扫描、预览、正式写入、恢复及可捕获失败分别生成专属执行报告；页面可打开本次报告或报告历史。

### RPF 转 FiveM

- 支持输入目录、单个 `.rpf`，以及 ZIP、RAR、7Z、TAR 和嵌套压缩包。
- 每个 RPF 自动生成一个独立 FiveM resource，并写入 `fxmanifest.lua` 和可识别的 `data_file`。
- 支持载具、武器、饰品、地图、碰撞、导航、动画、粒子、声音及其他 GTA V/FiveM stream 文件。
- 提供覆盖、保留临时目录、超时、嵌套深度、压缩包数量、文件数和解压大小限制。
- 长任务可停止；完成后显示成功、失败、输出文件、警告和逐资源明细，并只允许打开本轮转换生成的 JSON 报告。
- 直接调用 Release 内的 `rpf_to_fivem.py`、`CkRpfExtractor.exe` 和 `7z.exe`，不需要后端或源码仓库。
- Python 缺失时提供官网和选择按钮，选择结果与 Blender 路径共用根目录 `config.json`。

### 扫描移除后门

- 支持选择单个 FiveM resource、整个 `resources` 目录或 ZIP。
- “扫描后门”只读、不联网、不提取 ZIP，也不会执行目标中的 Lua、JavaScript 或 HTML。
- 大目录默认使用最多 8 个线程；页面实时显示统计文件、完成数/总数、百分比、当前文件和线程数，不再长时间无反馈。
- 覆盖 GP212887 精确链、Lua 远程执行、XOR/Base64/LZString/Node VM JavaScript 投递器、manifest 注入、Blum/Warden/Cipher IOC 和 txAdmin 篡改。
- “移除预览”只生成动作；“确认移除”会先备份目录目标并在写入后自动复检。
- ZIP 默认保留原包并生成 `*.cleaned.zip`；目录修复返回 Run ID，可在页面直接恢复。
- 组件从 [ch-jack/ck_anti_john](https://github.com/ch-jack/ck_anti_john) 的稳定 Release 安装并校验 SHA-256。
- 页面提供“打开本次报告”：优先打开组件原生清理报告；扫描、预览和恢复则保存并打开本次原生 JSON 结果。

### 一键清理小哈

- 支持选择 FiveM `server-data`、`resources` 或单个资源目录，先执行只读扫描并列出小哈资源、代码注入和关联 SQL。
- 自动读取 `server.cfg` 以及 `exec` 配置链中的 MySQL 连接信息；密码不会显示在界面、日志或报告中。
- 资源和代码清理会把文件移动到目标目录外的隔离区，并生成 `run-report.json`，可在工具箱内恢复文件修改。
- 数据库清理默认关闭；只有显式启用、选择 MySQL 客户端并确认已停止服务器和完成备份后才会执行。
- 数据库会删除样本内建表、品牌表、资源源码实际解析出的 `CREATE TABLE` 以及确认新增的列；文件报告不能恢复这些操作，必须从执行前备份恢复。
- 组件从 [ch-jack/xiaoha_cleaner](https://github.com/ch-jack/xiaoha_cleaner) 的稳定 Release 安装并校验 SHA-256。
- “打开本次报告”直接打开本轮扫描、清理或恢复生成的文件，不会误用恢复输入框中的旧报告。

### 统一依赖配置

- 首次启动在工具箱根目录生成 `config.json`，统一保存 `dependencies.blenderPath` 和 `dependencies.pythonPath`。
- 自动迁移旧 `%LOCALAPPDATA%\CKFreeToolbox\settings.json` 中的 Blender/Python 路径；迁移后运行时只读写根目录配置。
- 工具箱自更新不会替换或删除 `config.json`，发布 ZIP 也不包含默认配置，避免覆盖用户选择。
- Python 候选必须通过真实版本命令并满足 3.7+；支持用户选择、系统 Python、`py.exe` 和有效的 Blender Python。

### GitHub Release 组件管理

- 当前工具页右上角显示对应项目的 GitHub 开源地址，使用系统默认浏览器打开。
- 工具箱启动后会在后台依次检查所有登记组件的最新稳定 Release；检查不阻塞页面，结果会保留在对应工具页。
- 组件缺失时显示“安装组件”，只下载 tools.json 登记的最新稳定 GitHub Release ZIP，不再下载分支源码。
- 点击“检查更新”通过公开 releases/latest 跳转比较本地 releaseTag 与最新稳定 Release 标签，不占用 GitHub API 配额。
- 检查、下载、校验、解压、依赖配置和版本切换均通过顶部进度条显示；下载阶段显示实际字节进度。
- 下载先进入隔离 staging，限制大小并防止 ZIP 路径穿越；模型包校验随 Release 发布的 SHA-256，所有组件记录实际下载哈希。
- 更新前保留 .ck-component-backups 备份，安装失败会回滚，避免破坏当前可用版本。
- 模型 Release 已内置 Sollumz v2.8.3；工具箱只使用 Blender Python 配置带哈希校验的运行依赖。
- 旧版 commit 清单不会继续拉取源码，首次检查会提示更新，安装后迁移为 Release 版本清单。

### 工具箱自更新

- 启动后异步检查 [ck_free_toolbox Releases](https://github.com/ch-jack/ck_free_toolbox/releases)，不阻塞页面加载。
- 发现新版本时顶部显示“立即更新”，下载阶段显示实际进度。
- 更新 ZIP 会校验 Release SHA-256、包版本、核心文件和清单哈希。
- 主程序退出后由临时更新器替换 EXE、主脚本、app 和 static，并自动重启。
- 已安装的 vehicle_renderer、nui-wallfix、rpf_to_fivem、ck_anti_john、xiaoha_cleaner、TestVeh、模型和输出不会被删除。
- 替换失败会自动恢复旧核心文件，日志位于 %LOCALAPPDATA%\CKFreeToolbox\update.log。

## 交互可靠性

- 所有按钮通过持久闭包绑定，不依赖页面创建完成后会失效的局部函数。
- 按钮异常统一显示在页面状态、日志和错误弹窗中，不再静默无响应。
- 子进程输出先进入线程安全队列，再由 WPF Dispatcher 定时读取，避免后台线程直接操作 UI。
- 每个页面使用独立的 AutomationId，隐藏页面不会与当前页面的同名按钮冲突。
- 主窗口按屏幕工作区自适应，默认上限 1180×740，并允许缩小到紧凑布局。
- 标题、正文、按钮、日志和步骤组件使用紧凑字号与间距，减少首屏拥挤。
- 滚动条使用窄版深色轨道、圆角滑块以及悬停和拖动高亮。
- 模型列表启用 WPF 虚拟化，日志限制最大字符数，长任务不会无限占用界面内存。
- Blender 提供“官网”和“选择”按钮并校验 `blender.exe` 及 4.2 最低版本；NUI/RPF/扫描移除后门/一键清理小哈页面为 Python 提供“官网”和“选择”按钮并校验 3.7+；.NET 4.8 使用系统安装并只提供官网。

## 已验证

2026-07-17 已完成以下验证：

- PowerShell 语法检查：主脚本及全部 .ps1/.psm1 文件通过。
- Python 探测：真实 Python 3.7.0/3.13.9 通过，0 字节 WindowsApps 商店占位程序被拒绝。
- 统一配置：旧设置迁移、Blender/Python 双路径保存及根目录 `config.json` 结构通过。
- 缺失环境 UI：NUI/RPF/扫描移除后门/一键清理小哈页面均提供 Python 官网和选择按钮。
- 按钮烟测：扫描、搜索、全选、取消和模型渲染通过。
- 扫描 D:\fivem\TestVeh：识别 47 个可处理模型。
- 饰品实渲染：jr_labubu2 成功生成 D:\fivem\TestVeh\_vehicle_renders\jr_labubu2.png。
- 最终 EXE 自动化：模型页操作、渲染按钮恢复及退出码 0 全部通过。
- Blender 外置运行：自动使用 Blender 5.1.2 自带 Python 3.13.9，UI 实渲染 jr_labubu2 通过。
- 中文总进度：真实渲染期间未出现英文阶段文本，英文原始输出仅保留在日志。
- 原完整 ZIP 已验证不含 blender.exe 和 runtime\blender；当前自动构建进一步改为不预装功能组件的轻量包。
- NUI 自动去墙：安全扫描、完全本地化写入和按 Run ID 恢复通过。
- RPF 转 FiveM：组件注册、参数校验、JSON 报告解析和真实 RPF 转换通过。
- Release 组件安装：CK-model_renderer v1.0.0、nui-wallfix v0.1.0、rpf2fivem v1.0.1 与 ck_anti_john v0.2.3 真实下载、SHA-256 校验和安装通过。
- 启动组件检查：模型截图、NUI 去墙、RPF 转 FiveM、扫描移除后门和一键清理小哈按队列自动完成检查，页面分别显示最新 Release 或更新提示。
- 扫描移除后门页面：XAML 实例化、核心控件、Python 3.7 环境识别及“扫描后门”按钮端到端调用通过；实时消费 `CK_PROGRESS` 并显示多线程完成数、百分比和当前文件，最终 JSON 仍独立解析。
- 扫描移除后门组件：v0.2.3 的 27 项测试通过；客户 chat.zip 从 4 项普通 node_modules 弱组合误报降为 clean/0 项，已知 C2、隐藏 .cache 和 GP212887 强信号保持命中，全程未执行 ZIP 内代码。
- 一键清理小哈页面：组件注册、XAML 实例化、Python 环境识别、只读扫描/清理参数和报告恢复入口通过。
- 一键清理小哈组件：v1.0.0 Release ZIP 与 SHA-256 附件可解析，组件文件清单与工具箱登记一致。
- Release 更新链路不调用 GitHub API，不使用 codeload、分支源码 ZIP 或 Git clone。
- 工具箱自更新：联网版本检查、成功替换、组件/用户目录保留和模拟失败回滚通过。

## 可扩展架构

~~~text
ck_free_toolbox/
  CK免费工具箱.exe
  CKFreeToolbox.ps1
  config.json                    # 首次运行生成，统一用户配置
  app/config/tools.json          # 静态工具注册表
  app/modules/
    ToolboxConfig.psm1
  app/pages/
  static/
~~~

当前工具注册表启用模型自动截图、NUI 自动去墙、RPF 转 FiveM、扫描移除后门和一键清理小哈。新增功能时，新建一个 app/pages/*.ps1 页面工厂，并在 app/config/tools.json 注册 id/title/icon/page/factory。主窗口只负责加载、导航和公共运行时，不需要把所有功能继续堆进一个脚本。

每个工具还可注册 sourceUrl、component.repo 和 releaseAssetPattern。主窗口据此显示开源链接、检测必需文件、查询最新稳定 Release 并调用隔离组件工作器。

## 开发与发布目录

工具箱源码仓库可以独立构建，不再要求同级存在功能组件仓库。开发模式下如果同级已有 `vehicle_renderer`、`nui-wallfix`、`rpf_to_fivem`、`ck_anti_john` 或 `xiaoha_cleaner`，页面会直接检测并使用；轻量发布包则在自身目录内按需安装组件。

GitHub Actions 与本地一键打包都只依赖本仓库源码，详见 `docs/PACKAGING.md`。

## 重新构建 EXE

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\fivem\ck_free_toolbox\tools\Build-CkToolboxExe.ps1
~~~

该命令只重建轻量 WinExe 入口，不会提交代码。
