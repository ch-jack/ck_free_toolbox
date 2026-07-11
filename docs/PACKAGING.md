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

发布包是纯客户端，不启动 HTTP 服务，不包含后端，也不预装 `vehicle_renderer` 和 `nui-wallfix`。用户必须解压完整 ZIP，不能只复制 EXE。

## 运行时 Release 组件

工具箱启动后根据 app/config/tools.json 检测当前页面的组件：

- 模型自动截图对应 [ch-jack/CK-model_renderer](https://github.com/ch-jack/CK-model_renderer)。
- NUI 自动去墙对应 [ch-jack/nui-wallfix](https://github.com/ch-jack/nui-wallfix)。
- 组件缺失时显示“安装组件”，用户确认后才访问公开 releases/latest 跳转。
- 只下载配置匹配的 Release ZIP，不使用 codeload、分支源码 ZIP 或 Git clone。
- 下载进入隔离 staging，限制大小并拒绝 ZIP 路径穿越。
- 模型包校验 Release 发布的 .sha256 附件；所有组件都计算并记录实际 ZIP SHA-256。
- 必需文件校验通过后才替换组件；更新前保留备份，失败时自动回滚。
- 安装完成后写入 schema 2 .ck-component.json，记录 releaseTag、附件名和 SHA-256。

模型 Release 已内置 Sollumz v2.8.3，工具箱通过 Blender 自带 Python 配置带哈希校验的依赖。NUI 组件只使用 Python 标准库。旧版 commit 清单会在下一次更新时迁移。

## Blender 不进入发布包

发布包不复制 Blender，也不包含独立 Python。用户需要安装 Blender 4.2 或更高版本。工具箱会检测环境变量、PATH 和 Blender 默认安装目录，并使用 Blender 自带 Python。

未检测到 Blender 时，界面中的 Blender 环境依赖显示“官网下载”，点击后打开：

~~~text
https://www.blender.org/download/
~~~

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
4. 验证核心源码、组件工作器和两个页面存在。
5. 验证发布包不含功能组件目录和 Blender。
6. 上传 Actions Artifact。

推送 `main`、创建 Pull Request 或手动运行会自动构建。推送与程序版本一致的 `v*` 标签会自动创建 GitHub Release 并上传 ZIP。当前版本标签为 `v1.0.2`。

## NUI 自动去墙安全流程

1. “安全扫描”只读取文件，不访问网络，也不写入目标目录。
2. “预览方案”解析替换结果，但不修改文件。
3. “正式写入”需要二次确认，并在目标目录外创建带 Run ID 的备份。
4. “恢复备份”按 Run ID 还原，冲突时默认拒绝覆盖。

## 发布前验证

- ZIP 中存在 EXE、主脚本、`app/`、`static/` 和 `package-manifest.json`。
- ZIP 中不存在 `vehicle_renderer/`、`nui-wallfix/`、`runtime/blender/` 和 `blender.exe`。
- 首次启动时两个页面显示组件缺失，并提供“安装组件”操作。
- 模型组件安装后可扫描并渲染 `.yft`、`.ydr`、`.ydd` 或 `.ymap`。
- NUI 组件安装后可执行安全扫描、写入和按 Run ID 恢复。
- 未安装 Blender 时可以打开 Blender 官方下载页。
- 关闭主窗口后没有残留工具箱、Python 或 Blender 进程。

## 正式分发

- 发送完整 ZIP，不要只发送 EXE。
- 面向大量用户前，为 EXE 和 ZIP 配置代码签名。
- 新版本先更新启动器和界面版本号，再创建对应 `v*` 标签。