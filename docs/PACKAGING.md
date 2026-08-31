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
SnowyMerger 同样不预装；其运行目录为 snowy-merger，由统一组件工作器按需创建。
Red40 Clothing Repacker 同样不预装；其运行目录为 red40-clothing-packer，发布包只保留中文 CLI 页面和组件登记。

## 运行时 Release 组件

工具箱启动后根据 app/config/tools.json 检测当前页面的组件：

- 模型自动截图对应 [ch-jack/CK-model_renderer](https://github.com/ch-jack/CK-model_renderer)。
- NUI 自动去墙对应 [ch-jack/nui-wallfix](https://github.com/ch-jack/nui-wallfix)。
- RPF 转 FiveM 对应 [ch-jack/rpf2fivem](https://github.com/ch-jack/rpf2fivem)。
- 扫描移除后门对应 [ch-jack/ck_anti_john](https://github.com/ch-jack/ck_anti_john)。
- 秒杀小哈对应 [ch-jack/xiaoha_cleaner](https://github.com/ch-jack/xiaoha_cleaner)。
- 地图冲突合并对应 [ch-jack/SnowyMerger](https://github.com/ch-jack/SnowyMerger)。
- 衣服资源打包对应 [ch-jack/red40_clothing_packer](https://github.com/ch-jack/red40_clothing_packer)。
- 启动后后台依次检查所有登记组件的最新稳定 Release，缓存每个组件的最新版本或检查错误，不阻塞主窗口。
- 组件缺失时显示“安装组件”，用户确认后才访问公开 releases/latest 跳转。
- 只下载配置匹配的 Release ZIP，不使用 codeload、分支源码 ZIP 或 Git clone。
- 下载进入隔离 staging，限制大小并拒绝 ZIP 路径穿越。
- 检查和安装过程输出确定进度；组件下载按 Content-Length 显示实际百分比、已下载大小和实时下载速度。
- 配置了校验附件的组件会校验 Release 发布的 .sha256；所有组件都计算并记录实际 ZIP SHA-256。
- 必需文件校验通过后才替换组件；更新前保留备份，失败时自动回滚。
- 安装完成后写入 schema 2 .ck-component.json，记录 releaseTag、附件名和 SHA-256。

模型 Release 已内置 Sollumz v2.8.3，工具箱通过 Blender 自带 Python 配置带哈希校验的依赖。NUI、RPF 与扫描移除后门组件的 Python 入口只使用标准库；秒杀小哈 v1.1.0 起优先使用独立 EXE 并保留 Python 回退。RPF Release 另内置提取器、CodeWalker DLL 和 7-Zip。旧版 commit 清单会在下一次更新时迁移。
SnowyMerger Release 自带 YmapMerger、MewUI、CodeWalker.Core 及运行清单；工具箱只依赖系统 .NET 8 Runtime 和用户本机 GTA V。
Red40 Release 提供自包含 Windows x64 `ClothingRepacker.Cli.exe`、README、GPL-3.0 许可证和 CodeWalker 第三方声明；工具箱不启动 GUI，也不要求另装 .NET。

FXAP 解密组件保持按需安装；其可选顶点修复由组件 Release 提供最小 CLI 文件，工具箱本体不内置 FXAP 组件或 .NET Runtime。启用后只处理本次完整解密成功资源的完整副本，并默认在完成后打开修复副本（未生成副本则打开原解密目录）。

## 工具箱自更新

发布版启动后会异步检查 [ch-jack/ck_free_toolbox](https://github.com/ch-jack/ck_free_toolbox) 最新稳定 Release：

1. 比较 package-manifest.json 中的本地版本和最新 vX.Y.Z 标签。
2. 用户点击“立即更新”后下载 CK-Free-Toolbox-vX.Y.Z.zip，并显示实际下载进度和实时下载速度。
3. 优先校验同名 .sha256 附件，再校验包内版本、核心文件和 package-manifest.json 哈希。
4. 将验证后的核心文件暂存到安装目录内的 .ck-self-update。
5. 关闭当前工具箱后，由临时更新器替换 EXE、主脚本、app、static 和清单，并自动重启。
6. `config.json`、vehicle_renderer、nui-wallfix、rpf_to_fivem、ck_anti_john、xiaoha_cleaner、TestVeh 和其他用户文件不参与替换。
7. snowy-merger、其 vanilla_cache 和 SnowyMergerOutput 也不参与工具箱核心替换。
8. red40-clothing-packer 和 ClothingRepackerWork 方案、备份、报告与输出也不参与工具箱核心替换。
9. 替换失败会恢复旧核心文件，并写入 %LOCALAPPDATA%\CKFreeToolbox\update.log。

## Blender 和 Python 不进入发布包

发布包不复制 Blender，也不包含独立 Python。

- Blender 提供官网和 `blender.exe` 文件选择；Python 缺失时提供官网和 `python.exe` 文件选择。
- Python 候选必须真实执行版本命令并满足 3.7+，0 字节 WindowsApps 商店别名不会被接受。
- .NET Framework 4.8 使用 Windows 系统安装，只检测注册表并提供官网，不允许手动指定目录。
- SnowyMerger v1.2+ 单独检测系统 .NET 8 Runtime，不复用 .NET Framework 4.8 的检测结果。
- YtdTools.exe 与 RpfTools.exe 由模型组件 Release 自带。
- Sollumz 由模型组件 Release 自带并通过隔离 Blender 配置加载，用户不需要在 Blender 中单独安装或选择插件目录。
- Blender 仍使用其自带 Python，最低支持版本为 4.2；选择 4.1 或更早版本会明确标记为不支持。
- Blender/Python 选择结果统一保存在工具箱根目录 `config.json` 的 `dependencies` 节点；首次启动的免责条款同意状态保存在 `agreements` 节点。
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
4. 验证核心源码、组件工作器和全部登记页面存在。
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

## 地图冲突合并运行流程

1. 组件缺失时，从 ch-jack/SnowyMerger 最新稳定 Release 下载 SnowyMerger-vX.Y.Z.zip 和同名 SHA-256。
2. 统一组件工作器执行下载限制、SHA-256 校验、安全解压、必需 DLL 检查、旧版本备份和失败回滚。
3. 页面校验 .NET 8 Runtime、YmapMerger、MewUI、CodeWalker.Core 及包含 GTA5.exe 的 GTA V 目录。
4. 客户端直接执行 YmapMerger.exe -g <gta> -i <mods> -o <output>，并实时消费标准输出。
5. 结果写入 <output>/snowy_merger，完整任务日志写入用户本地 CKFreeToolbox 报告目录。

## 衣服资源打包运行流程

1. 组件缺失时，从 `ch-jack/red40_clothing_packer` 最新稳定 Release 下载 `red40-clothing-packer-cli-win-x64-v*.zip` 和同名 SHA-256。
2. ZIP 只有一个 `red40-clothing-packer/` 顶层目录，包含自包含 `ClothingRepacker.Cli.exe`、`README.md`、`LICENSE` 和 `CodeWalker-Notice.txt`；统一组件工作器负责安全解压、必需文件校验、备份、切换与回滚。
3. 中文页面覆盖 CLI 的 analyze、build、apply、restore、validate 三种输入、report 和 export-xml；不加载上游 GUI。
4. analyze 和 build 用于先生成方案与预览；apply 默认传入 `--copy-resources-to-output`，复制目标必须不存在，避免上游递归替换无法恢复的旧目录；关闭复制模式时必须二次确认直接修改源 resource。
5. restore 与 `export-xml --overwrite` 同样需要中文确认；原始标准输出按行显示，并归档到用户本地 CKFreeToolbox 报告目录。
6. 工具箱默认传入 `--no-version-check`，避免 CLI 重复检查上游仓库；用户可以在页面关闭该选项。
7. analyze 成功后写入 `plan.json.ck-plan.json`，记录方案 SHA-256、resourceRoots、生成根目录、目标 resource 和规划所依赖的 YMT/XML/meta/manifest SHA-256；stream 改名源复核存在性与目标冲突，不同步重复哈希大型 YTD/YDD。build/apply 只接受路径范围与规划输入哈希仍一致的 CK 方案。
8. apply 每次使用唯一备份子目录，生成清单后写入 `backup-manifest.json.ck-restore.json`，并由工具箱独立记录实际备份文件哈希；restore 会校验清单/备份哈希、允许的生成目录、原始 resource 范围和 stream 路径，再显示删除、复制、移动数量并确认。

## 扫描移除后门安全流程

1. 组件缺失时，从 `ch-jack/ck_anti_john` 最新稳定 Release 下载 ZIP 和 SHA-256。
2. “扫描后门”只读、不联网、不提取目标 ZIP，也不执行被扫描代码。
3. “移除预览”只返回动作；“确认移除”二次确认后才写入。
4. 目录目标先在外部创建 Run ID 备份；ZIP 默认保留原包并生成 `*.cleaned.zip`。
5. 修复后自动复扫；仍有可自动修复高危项时拒绝交付结果或回滚目录，人工项单独提示。

## 秒杀小哈安全流程

1. 组件缺失时，从 `ch-jack/xiaoha_cleaner` 最新稳定 Release 下载 ZIP 和 SHA-256。
2. “只读扫描”只识别小哈资源、代码注入及 SQL 证据，不修改目标文件或数据库。
3. 文件清理把命中文件移动到目标目录外的隔离区，并生成可用于恢复的 `run-report.json`。
4. MySQL 信息从 `server.cfg` 和 `exec` 配置链自动读取，敏感值不会写入界面、日志或报告。
5. 数据库清理默认关闭；执行前必须停止服务器、完成数据库备份、勾选确认并选择可用 MySQL 客户端。
6. 数据库改动不能通过文件报告恢复，只能从执行前备份恢复。

## 发布前验证

- ZIP 中存在 EXE、主脚本、`app/`、`static/` 和 `package-manifest.json`。
- ZIP 中不存在根目录 `config.json`、`vehicle_renderer/`、`nui-wallfix/`、`rpf_to_fivem/`、`ck_anti_john/`、`xiaoha_cleaner/`、`runtime/blender/`、`blender.exe` 和 `python.exe`。
- ZIP 中不存在 snowy-merger/；SnowyMergerPage.ps1 和 tools.json 注册必须存在。
- ZIP 中不存在 red40-clothing-packer/；ClothingRepackerPage.ps1 和 tools.json 注册必须存在，清单中的 clothingRepacker 必须为 false。
- 全新配置首次启动显示免责条款；未勾选时同意按钮不可用，拒绝或关闭后不进入主界面，同意后再次启动不重复弹出同版本条款。条款版本 2 新增“允许二创、禁止收费”，已同意版本 1 的配置必须重新确认。
- 首次启动时各按需组件页面显示组件缺失，并提供“安装组件”操作。
- 模型组件安装后可扫描并渲染 `.yft`、`.ydr`、`.ydd` 或 `.ymap`。
- NUI 组件安装后可执行安全扫描、写入和按 Run ID 恢复。
- RPF 组件安装后可把目录、单个 RPF 或压缩包转换为独立 FiveM resource，并生成 JSON 报告。
- 扫描移除后门组件安装后可扫描目录/ZIP、预览移除、确认写入并按 Run ID 恢复。
- 秒杀小哈组件安装后可扫描 server-data/resources、隔离命中文件、按报告恢复，并在备份确认后选择性清理关联 SQL。
- SnowyMerger 组件安装后可捕获 CLI 日志、识别无冲突输入，并把结果写入 snowy_merger resource。
- Red40 组件安装后，页面可调用全部公开 CLI 命令；apply/restore/覆盖 XML 的确认与任务日志必须有效。
- Blender 可打开官网并选择 `blender.exe`；4.1 会显示不支持，4.2+ 检测通过。
- Python 缺失时 NUI/RPF/扫描移除后门页面显示官网和选择按钮；秒杀小哈独立 EXE 不依赖 Python，旧组件回退入口仍按 Python 3.7+ 检测。
- Blender/Python 路径写入同一个根目录 `config.json`，旧设置迁移且自更新后仍保留。
- .NET 可打开官网；内置转换工具和 Sollumz 随模型组件完成安装。
- 模型截图运行时的 `_temp` 位于输出目录，任务完成后已自动删除。
- 关闭主窗口后没有残留工具箱、Python 或 Blender 进程。
- 自更新成功后版本清单更新且组件/用户目录保留；模拟替换失败时旧核心文件恢复。

## 正式分发

- 发送完整 ZIP，不要只发送 EXE。
- 面向大量用户前，为 EXE 和 ZIP 配置代码签名。
- main 自动发布时，工作流会同步 EXE、界面和包清单版本，并发布 ZIP 与 SHA-256；指定版本仍可手动推送 `v*` 标签。
