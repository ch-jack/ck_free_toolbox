# 单一正式包的内置组件约定

CK 工具箱只发布一个 Windows ZIP：

- CK-Free-Toolbox-vX.Y.Z.zip

这个正式包直接内置“扫描移除后门”和“一键清理小哈”。联网和断网环境使用同一个包、同一个入口和同一套操作：

- 服务器能连接 GitHub 时，工具箱按原有逻辑检查组件版本并正常提供更新。
- 服务器无法连接 GitHub 时，界面按原有逻辑提示网络或检查失败，已内置的组件文件仍在本地。
- 模型、NUI 和 RPF 组件仍按现有方式按需安装。

正式包不包含 Python。两个内置组件只依赖 Python 3.7+ 和标准库，服务器需要事先安装 Python，或从其他机器离线复制可用的 Python 环境。

## GitHub Actions 构建

每次工具箱 Actions 构建都会重新解析以下仓库的最新正式 Release：

- ch-jack/ck_anti_john
- ch-jack/xiaoha_cleaner

构建器只使用 https://github.com/<repo>/releases/latest 的正式版跳转，不读取分支源码、codeload、Draft 或 Pre-release。组件版本不写死在工具箱源码中，而是记录在每次构建产物的 package-manifest.json。

每个组件必须同时具有：

1. 与 tools.json 中 releaseAssetPattern 匹配的 ZIP；
2. 与 releaseChecksumAssetPattern 匹配的 SHA-256 附件；
3. 只有一个顶层目录；
4. requiredFiles 中登记的全部必需文件。

缺少附件、SHA-256 不一致、校验文件未绑定 ZIP 文件名、重复或越界路径、符号链接、异常压缩比、展开内容超过 1 GB，或必需文件缺失，都会使整个工具箱构建失败。构建不会降级到分支源码或无校验打包。

## 产物清单

唯一正式包的 package-manifest.json 包含：

- flavor: standard
- bundled.antiJohn: true
- bundled.xiaohaCleaner: true
- bundledComponents.<toolId>.releaseTag
- bundledComponents.<toolId>.assetName
- bundledComponents.<toolId>.sha256
- bundledComponents.<toolId>.releaseUrl

每个内置组件目录还包含 .ck-component.json，其版本、仓库、附件名和 SHA-256 必须与工具箱清单一致。

## 运行行为

- 工具箱启动、检查和更新组件的运行时逻辑保持不变。
- 有网时照常检查最新版本并按原流程更新。
- 没网时照常显示原有的网络或检查失败提示，不增加离线版专用入口或状态。
- 正式包内置组件和在线更新后的组件使用相同目录、相同页面和相同操作流程。
- 在线安装或更新仍只允许来自登记仓库的最新正式 GitHub Release。

## 本地构建

先生成基础目录和 ZIP，再把最新正式组件嵌入同一个目录，并覆盖同名 ZIP：

    .\tools\Build-ReleasePackage.ps1
    $base = Get-ChildItem .\dist -Directory | Select-Object -First 1
    .\tools\Build-BundledComponents.ps1 -BasePackagePath $base.FullName

正式发布由 .github/workflows/build-release.yml 自动完成。Release 只发布一个正式 ZIP 和它对应的 .sha256 文件。

## 组件发布自动触发

ck_anti_john 或 xiaoha_cleaner 的正式标签 Release 在测试、打包和附件发布全部成功后，会调用 ck_free_toolbox 的 build-release.yml。工具箱随后重新解析两个组件的最新正式 Release、校验各自 SHA-256，并发布新的唯一正式包。

跨仓库触发需要在两个组件仓库分别配置 Actions Secret：

- 名称：CK_TOOLBOX_TRIGGER_TOKEN
- 推荐类型：Fine-grained personal access token
- 仓库范围：只选择 ch-jack/ck_free_toolbox
- Repository permissions：Actions: Read and write
- 有效期：按维护周期设置并在到期前轮换

未配置 Secret 时，组件 Release 仍会正常发布，但触发步骤只输出警告，不会启动工具箱构建。令牌不得写入仓库文件、日志、Release 附件或工具箱包内。
