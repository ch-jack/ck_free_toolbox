# CK免费工具箱

CK免费工具箱 v1.0.2 是纯本机客户端工具，不需要服务端文件、HTTP API 或后台服务。推荐通过 CK免费工具箱.exe 启动，窗口和任务栏使用 static/cklogo.ico。

本仓库不是空外壳。`CKFreeToolbox.ps1` 和 `app/` 包含窗口、模型扫描、环境检测、任务进程、日志、组件安装更新及两个功能页的客户端实现。模型渲染引擎与 NUI 重写引擎分别在 [CK-model_renderer](https://github.com/ch-jack/CK-model_renderer) 和 [nui-wallfix](https://github.com/ch-jack/nui-wallfix) 维护，工具箱运行后按需下载。

## 启动

双击：

~~~text
D:\fivem\ck_free_toolbox\CK免费工具箱.exe
~~~

start_toolbox.cmd 仅用于开发排错。不要只复制 EXE；主脚本、app/ 和 static/ 必须与 EXE 保持原目录结构。

## 一键打包

开发者双击 `一键打包发布包.cmd`，脚本会自动：

- 重新构建 `CK免费工具箱.exe`。
- 不预先下载或打包 `vehicle_renderer` 和 `nui-wallfix`。
- 保留组件检测、GitHub 安装、校验、更新、备份和失败回滚代码。
- 不复制 Blender；模型组件使用用户已安装 Blender 自带的 Python。
- 生成可以直接发给用户的轻量客户端目录和 ZIP。
- 写入使用说明、版本、运行时组件策略和 SHA-256 清单。

默认产物位于 `dist/CK免费工具箱-v1.0.2/` 和同名 ZIP。用户解压后直接双击最外层 `CK免费工具箱.exe`。页面检测到组件缺失时，点击“安装组件”才会从对应 GitHub 仓库下载。Blender 仍需用户独立安装。

命令行用法：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-ReleasePackage.ps1
~~~

可用 `-SkipArchive` 只生成发布目录。

## GitHub 自动构建与发布

`.github/workflows/build-release.yml` 只检出并构建本仓库，不拉取两个功能组件：

- 推送到 `main`、创建面向 `main` 的 Pull Request 或手动运行时，自动检查 PowerShell 语法、构建 EXE、验证轻量包并上传 Actions Artifact。
- 推送 `v*` 标签时，在构建通过后自动创建同名 GitHub Release 并上传 ZIP。
- Release 标签必须和启动器中的版本一致。例如当前版本使用 `v1.0.2`。
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
- 支持实时搜索、全选、取消、打开输出目录和批量渲染。
- 调用 vehicle_renderer/render_all_vehicles.py --asset-types all。
- 使用已安装 Blender 自带 Python；日志和退出码实时回到 UI，总进度使用中文阶段提示。

### NUI 自动去墙

- 支持选择单个 FiveM resource 或整个 `resources` 目录，扫描 HTML、CSS、JavaScript 和资源清单中的外链。
- “安全扫描”只读且不访问网络；“预览方案”会解析替换结果，但不修改目标文件。
- 必须选择具体 resource 或 resources 目录；工具箱会阻止扫描磁盘根目录和自身工作区，长任务可随时停止。
- 正式写入支持自动、完全本地化和国内 CDN 三种方案，并可限制超时与单文件大小。
- 每次正式写入都在目标目录外创建备份，结果提供 Run ID，可从工具箱直接恢复。
- 支持自定义 `providers.json`、未验证镜像、内网地址和冲突时强制恢复等高级选项。
- 直接调用随包发布的 `nui-wallfix.py`，不需要后端服务；优先使用系统 Python，未安装时使用 Blender 自带 Python。

### GitHub Release 组件管理

- 当前工具页右上角显示对应项目的 GitHub 开源地址，使用系统默认浏览器打开。
- 组件缺失时显示“安装组件”，只下载 tools.json 登记的最新稳定 GitHub Release ZIP，不再下载分支源码。
- 点击“检查更新”通过公开 releases/latest 跳转比较本地 releaseTag 与最新稳定 Release 标签，不占用 GitHub API 配额。
- 下载先进入隔离 staging，限制大小并防止 ZIP 路径穿越；模型包校验随 Release 发布的 SHA-256，所有组件记录实际下载哈希。
- 更新前保留 .ck-component-backups 备份，安装失败会回滚，避免破坏当前可用版本。
- 模型 Release 已内置 Sollumz v2.8.3；工具箱只使用 Blender Python 配置带哈希校验的运行依赖。
- 旧版 commit 清单不会继续拉取源码，首次检查会提示更新，安装后迁移为 Release 版本清单。

## 交互可靠性

- 所有按钮通过持久闭包绑定，不依赖页面创建完成后会失效的局部函数。
- 按钮异常统一显示在页面状态、日志和错误弹窗中，不再静默无响应。
- 子进程输出先进入线程安全队列，再由 WPF Dispatcher 定时读取，避免后台线程直接操作 UI。
- 每个页面使用独立的 AutomationId，隐藏页面不会与当前页面的同名按钮冲突。
- 主窗口按屏幕工作区自适应，默认上限 1180×740，并允许缩小到紧凑布局。
- 标题、正文、按钮、日志和步骤组件使用紧凑字号与间距，减少首屏拥挤。
- 滚动条使用窄版深色轨道、圆角滑块以及悬停和拖动高亮。
- 模型列表启用 WPF 虚拟化，日志限制最大字符数，长任务不会无限占用界面内存。
- Blender 未安装时，依赖卡显示“官网下载”，点击后打开 Blender 官方下载页。

## 已验证

2026-07-11 已完成以下验证：

- PowerShell 语法检查：10 个 .ps1/.psm1 文件通过。
- 按钮烟测：扫描、搜索、全选、取消和模型渲染通过。
- 扫描 D:\fivem\TestVeh：识别 47 个可处理模型。
- 饰品实渲染：jr_labubu2 成功生成 D:\fivem\TestVeh\_vehicle_renders\jr_labubu2.png。
- 最终 EXE 自动化：模型页操作、渲染按钮恢复及退出码 0 全部通过。
- Blender 外置运行：自动使用 Blender 5.1.2 自带 Python 3.13.9，UI 实渲染 jr_labubu2 通过。
- 中文总进度：真实渲染期间未出现英文阶段文本，英文原始输出仅保留在日志。
- 原完整 ZIP 已验证不含 blender.exe 和 runtime\blender；当前自动构建进一步改为不预装功能组件的轻量包。
- NUI 自动去墙：安全扫描、完全本地化写入和按 Run ID 恢复通过。
- Release 组件安装：CK-model_renderer v1.0.0 与 nui-wallfix v0.1.0 真实下载、安装和同版本检查通过。
- Release 更新链路不调用 GitHub API，不使用 codeload、分支源码 ZIP 或 Git clone。

## 可扩展架构

~~~text
ck_free_toolbox/
  CK免费工具箱.exe
  CKFreeToolbox.ps1
  app/config/tools.json
  app/modules/
  app/pages/
  static/
~~~

当前工具注册表启用模型自动截图和 NUI 自动去墙。新增功能时，新建一个 app/pages/*.ps1 页面工厂，并在 app/config/tools.json 注册 id/title/icon/page/factory。主窗口只负责加载、导航和公共运行时，不需要把所有功能继续堆进一个脚本。

每个工具还可注册 sourceUrl、component.repo 和 releaseAssetPattern。主窗口据此显示开源链接、检测必需文件、查询最新稳定 Release 并调用隔离组件工作器。

## 开发与发布目录

工具箱源码仓库可以独立构建，不再要求同级存在功能组件仓库。开发模式下如果同级已有 `vehicle_renderer` 或 `nui-wallfix`，页面会直接检测并使用；轻量发布包则在自身目录内按需安装组件。

GitHub Actions 与本地一键打包都只依赖本仓库源码，详见 `docs/PACKAGING.md`。

## 重新构建 EXE

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\fivem\ck_free_toolbox\tools\Build-CkToolboxExe.ps1
~~~

该命令只重建轻量 WinExe 入口，不会提交代码。
