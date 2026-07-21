# CK免费工具箱一键发布方案

## 发布包结构

~~~text
dist/
  CK免费工具箱-v1.0.2/
    CK免费工具箱.exe
    CKFreeToolbox.ps1
    app/
    static/
    TestVeh/
    使用说明.txt
    package-manifest.json
  CK免费工具箱-v1.0.2.zip
~~~

发布包是纯客户端，不启动 HTTP 服务，不包含后端，也不预装 `vehicle_renderer`、`nui-wallfix`、`rpf_to_fivem`、`ck_anti_john` 和 `xiaoha_cleaner`。用户必须解压完整 ZIP，不能只复制 EXE。

## 运行时 Release 组件

工具箱启动后根据 app/config/tools.json 检测当前页面的组件：

- 模型自动截图对应 [ch-jack/CK-model_renderer](https://github.com/ch-jack/CK-model_renderer)。
- NUI 自动去墙对应 [ch-jack/nui-wallfix](https://github.com/ch-jack/nui-wallfix)。
- RPF 转 FiveM 对应 [ch-jack/rpf2fivem](https://github.com/ch-jack/rpf2fivem)。
- 扫描移除后门对应 [ch-jack/ck_anti_john](https://github.com/ch-jack/ck_anti_john)。
- 一键清理小哈对应 [ch-jack/xiaoha_cleaner](https://github.com/ch-jack/xiaoha_cleaner)。
- 启动后后台依次检查所有登记组件的最新稳定 Release，缓存每个组件的最新版本或检查错误，不阻塞主窗口。
- 组件缺失时显示“安装组件”，用户确认后才访问公开 releases/latest 跳转。
- 只下载配置匹配的 Release ZIP，不使用 codeload、分支源码 ZIP 或 Git clone。
- 下载进入隔离 staging，限制大小并拒绝 ZIP 路径穿越。
- 检查和安装过程输出确定进度；组件下载按 Content-Length 显示实际百分比、已下载大小和实时下载速度。
- 配置了校验附件的组件会校验 Release 发布的 .sha256；所有组件都计算并记录实际 ZIP SHA-256。
- 必需文件校验通过后才替换组件；更新前保留备份，失败时自动回滚。
- 安装完成后写入 schema 2 .ck-component.json，记录 releaseTag、附件名和 SHA-256。

模型 Release 已内置 Sollumz v2.8.3，工具箱通过 Blender 自带 Python 配置带哈希校验的依赖。NUI、RPF、扫描移除后门与一键清理小哈组件的 Python 入口只使用标准库；RPF Release 另内置提取器、CodeWalker DLL 和 7-Zip。旧版 commit 清单会在下一次更新时迁移。

## 工具箱自更新

发布版启动后会异步检查 [ch-jack/ck_free_toolbox](https://github.com/ch-jack/ck_free_toolbox) 最新稳定 Release：

1. 比较 package-manifest.json 中的本地版本和最新 vX.Y.Z 标签。
2. 用户点击“立即更新”后下载 CK-Free-Toolbox-vX.Y.Z.zip，并显示实际下载进度和实时下载速度。
3. 优先校验同名 .sha256 附件，再校验包内版本、核心文件和 package-manifest.json 哈希。
4. 将验证后的核心文件暂存到安装目录内的 .ck-self-update。
5. 关闭当前工具箱后，由临时更新器替换 EXE、主脚本、app、static 和清单，并自动重启。
6. `config.json`、vehicle_renderer、nui-wallfix、rpf_to_fivem、ck_anti_john、xiaoha_cleaner、TestVeh 和其他用户文件不参与替换。
7. 替换失败会恢复旧核心文件，并写入 %LOCALAPPDATA%\CKFreeToolbox\update.log。

## Blender 和 Python 不进入发布包

发布包不复制 Blender，也不包含独立 Python。

- Blender 提供官网和 `blender.exe` 文件选择；Python 缺失时提供官网和 `python.exe` 文件选择。
- Python 候选必须真实执行版本命令并满足 3.7+，0 字节 WindowsApps 商店别名不会被接受。
- .NET Framework 4.8 使用 Windows 系统安装，只检测注册表并提供官网，不允许手动指定目录。
- YtdTools.exe 与 RpfTools.exe 由模型组件 Release 自带。
- Sollumz 由模型组件 Release 自带并通过隔离 Blender 配置加载，用户不需要在 Blender 中单独安装或选择插件目录。
- Blender 仍使用其自带 Python，最低支持版本为 4.2；选择 4.1 或更早版本会明确标记为不支持。
- Blender/Python 选择结果统一保存在工具箱根目录 `config.json` 的 `dependencies` 节点。
- 首次启动会迁移旧 `%LOCALAPPDATA%\CKFreeToolbox\settings.json`；之后不再从旧文件运行时读写。
- 发布 ZIP 不包含根目录 `config.json`，自更新核心文件列表也不包含它，因此不会覆盖用户选择。
- 模型组件把 RPF/YTD 临时文件放在本次输出目录的 `_temp`，正常结束自动清理，不使用系统 `%TEMP%`。
## 本地一键打包

双击：

~~~text
一键打包发布包.cmd
~~~

或执行：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-ReleasePackage.ps1
~~~

参数：

- `-OutputDirectory "D:\release"`：指定输出目录。
- `-SkipArchive`：只生成发布目录。
- `-OpenOutput`：完成后打开输出目录。

打包只依赖本仓库和 Windows PowerShell/.NET Framework，不需要同级组件仓库、Git、Python 或 Blender。ZIP 使用 PowerShell `Compress-Archive` 生成。

## GitHub Actions

`.github/workflows/build-release.yml` 在 `windows-2022` Runner 上执行：

1. 只检出 `ck_free_toolbox` 仓库。
2. 检查全部 `.ps1` 和 `.psm1` 的 PowerShell 语法。
3. 编译轻量 WinExe 并生成便携 ZIP。
4. 验证核心源码、组件工作器和五个页面存在。
5. 验证发布包不含功能组件目录和 Blender。
6. 上传 Actions Artifact。
7. 正式 Release 同时发布 ZIP 和同名 .sha256，供客户端自更新校验。

推送 `main` 会按 Actions 运行序号生成 `v1.0.<run>`，自动构建并创建正式 GitHub Release。Pull Request 只验证构建；手动推送 `v*` 标签仍可发布指定版本。

## NUI 自动去墙安全流程

1. “安全扫描”只读取文件，不访问网络，也不写入目标目录。
2. “预览方案”解析替换结果，但不修改文件。
3. “正式写入”需要二次确认，并在目标目录外创建带 Run ID 的备份。
4. “恢复备份”按 Run ID 还原，冲突时默认拒绝覆盖。

## RPF 转 FiveM 运行流程

1. 组件缺失时，从 `ch-jack/rpf2fivem` 最新稳定 Release 下载 ZIP 和 SHA-256。
2. 页面实际执行并校验 Python 3.7+，同时校验 .NET Framework 4.8、RPF 提取器和 7-Zip；Python 缺失时显示官网和选择按钮。
3. 用户选择目录、RPF 或压缩包以及独立输出目录，并设置资源限制。
4. 客户端直接执行 `rpf_to_fivem.py ... --json`，不启动服务器或后台服务。
5. 页面解析 `_rpf_to_fivem_report.json`，显示资源结果、警告和输出路径。

## 扫描移除后门安全流程

1. 组件缺失时，从 `ch-jack/ck_anti_john` 最新稳定 Release 下载 ZIP 和 SHA-256。
2. “扫描后门”只读、不联网、不提取目标 ZIP，也不执行被扫描代码。
3. “移除预览”只返回动作；“确认移除”二次确认后才写入。
4. 目录目标先在外部创建 Run ID 备份；ZIP 默认保留原包并生成 `*.cleaned.zip`。
5. 修复后自动复扫；仍有可自动修复高危项时拒绝交付结果或回滚目录，人工项单独提示。

## 一键清理小哈安全流程

1. 组件缺失时，从 `ch-jack/xiaoha_cleaner` 最新稳定 Release 下载 ZIP 和 SHA-256。
2. “只读扫描”只识别小哈资源、代码注入及 SQL 证据，不修改目标文件或数据库。
3. 文件清理把命中文件移动到目标目录外的隔离区，并生成可用于恢复的 `run-report.json`。
4. MySQL 信息从 `server.cfg` 和 `exec` 配置链自动读取，敏感值不会写入界面、日志或报告。
5. 数据库清理默认关闭；执行前必须停止服务器、完成数据库备份、勾选确认并选择可用 MySQL 客户端。
6. 数据库改动不能通过文件报告恢复，只能从执行前备份恢复。

## 发布前验证

- ZIP 中存在 EXE、主脚本、`app/`、`static/` 和 `package-manifest.json`。
- ZIP 中不存在根目录 `config.json`、`vehicle_renderer/`、`nui-wallfix/`、`rpf_to_fivem/`、`ck_anti_john/`、`xiaoha_cleaner/`、`runtime/blender/`、`blender.exe` 和 `python.exe`。
- 首次启动时五个页面显示组件缺失，并提供“安装组件”操作。
- 模型组件安装后可扫描并渲染 `.yft`、`.ydr`、`.ydd` 或 `.ymap`。
- NUI 组件安装后可执行安全扫描、写入和按 Run ID 恢复。
- RPF 组件安装后可把目录、单个 RPF 或压缩包转换为独立 FiveM resource，并生成 JSON 报告。
- 扫描移除后门组件安装后可扫描目录/ZIP、预览移除、确认写入并按 Run ID 恢复。
- 一键清理小哈组件安装后可扫描 server-data/resources、隔离命中文件、按报告恢复，并在备份确认后选择性清理关联 SQL。
- Blender 可打开官网并选择 `blender.exe`；4.1 会显示不支持，4.2+ 检测通过。
- Python 缺失时 NUI/RPF/扫描移除后门/一键清理小哈页面显示官网和选择按钮；真实 Python 3.7+ 通过，WindowsApps 占位程序失败。
- Blender/Python 路径写入同一个根目录 `config.json`，旧设置迁移且自更新后仍保留。
- .NET 可打开官网；内置转换工具和 Sollumz 随模型组件完成安装。
- 模型截图运行时的 `_temp` 位于输出目录，任务完成后已自动删除。
- 关闭主窗口后没有残留工具箱、Python 或 Blender 进程。
- 自更新成功后版本清单更新且组件/用户目录保留；模拟替换失败时旧核心文件恢复。

## 正式分发

- 发送完整 ZIP，不要只发送 EXE。
- 面向大量用户前，为 EXE 和 ZIP 配置代码签名。
- main 自动发布时，工作流会同步 EXE、界面和包清单版本，并发布 ZIP 与 SHA-256；指定版本仍可手动推送 `v*` 标签。
