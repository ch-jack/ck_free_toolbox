[CmdletBinding()]
param(
    [Parameter(Mandatory)][int]$ParentPid,
    [Parameter(Mandatory)][string]$SourceRoot,
    [Parameter(Mandatory)][string]$TargetRoot,
    [Parameter(Mandatory)][string]$ExpectedVersion,
    [string]$StateRoot = '',
    [switch]$SkipRestart,
    [switch]$TestFailAfterInstall
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$UpdateStateRoot = if ([string]::IsNullOrWhiteSpace($StateRoot)) {
    Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox'
} else {
    [IO.Path]::GetFullPath($StateRoot)
}

function Assert-CkChildPath {
    param([string]$Path, [string]$Parent)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $fullParent = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $fullPath.StartsWith($fullParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "更新路径越界: $fullPath"
    }
    return $fullPath
}

function Remove-CkPath {
    param([string]$Path, [string]$Parent)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    $safePath = Assert-CkChildPath -Path $Path -Parent $Parent
    $item = Get-Item -LiteralPath $safePath -Force
    if ($item.PSIsContainer) {
        [IO.Directory]::Delete($safePath, $true)
    } else {
        [IO.File]::Delete($safePath)
    }
}

function Write-CkUpdateLog {
    param([string]$Message)

    try {
        $logRoot = $script:UpdateStateRoot
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
        $line = '{0} {1}' -f (Get-Date).ToString('o'), $Message
        Add-Content -LiteralPath (Join-Path $logRoot 'update.log') -Value $line -Encoding UTF8
    } catch { }
}

$target = [IO.Path]::GetFullPath($TargetRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
$updateRoot = Join-Path $target '.ck-self-update'
$source = Assert-CkChildPath -Path $SourceRoot -Parent $updateRoot
$launcher = Join-Path $target 'CK免费工具箱.exe'
$coreItems = @(
    'CK免费工具箱.exe',
    'CKFreeToolbox.ps1',
    'app',
    'static',
    'package-manifest.json',
    '使用说明.txt'
)
$backupRoot = ''
$backedUp = New-Object System.Collections.Generic.List[string]
$installed = New-Object System.Collections.Generic.List[string]

try {
    if ($ExpectedVersion -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
        throw "目标版本无效: $ExpectedVersion"
    }
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "工具箱目录不存在: $target"
    }

    $manifestPath = Join-Path $source 'package-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw '暂存更新缺少 package-manifest.json。'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$manifest.version -ne $ExpectedVersion) {
        throw "暂存更新版本不匹配: $($manifest.version)"
    }
    foreach ($name in $coreItems) {
        if (-not (Test-Path -LiteralPath (Join-Path $source $name))) {
            throw "暂存更新缺少核心项目: $name"
        }
    }

    if ($ParentPid -gt 0) {
        $parent = Get-Process -Id $ParentPid -ErrorAction SilentlyContinue
        if ($parent) {
            Write-CkUpdateLog "等待工具箱进程退出: PID=$ParentPid"
            if (-not $parent.WaitForExit(120000)) {
                throw "等待工具箱退出超时: PID=$ParentPid"
            }
        }
    }

    New-Item -ItemType Directory -Path $updateRoot -Force | Out-Null
    $backupRoot = Assert-CkChildPath -Path (Join-Path $updateRoot ('backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))) -Parent $updateRoot
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    Write-CkUpdateLog "开始更新到 $ExpectedVersion"
    foreach ($name in $coreItems) {
        $current = Join-Path $target $name
        if (Test-Path -LiteralPath $current) {
            Move-Item -LiteralPath $current -Destination (Join-Path $backupRoot $name)
            $backedUp.Add($name)
        }
    }

    foreach ($name in $coreItems) {
        $incoming = Join-Path $source $name
        if (Test-Path -LiteralPath $incoming) {
            Move-Item -LiteralPath $incoming -Destination (Join-Path $target $name)
            $installed.Add($name)
        }
    }

    $installedManifest = Get-Content -LiteralPath (Join-Path $target 'package-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$installedManifest.version -ne $ExpectedVersion) {
        throw '更新后的版本清单验证失败。'
    }
    if ($TestFailAfterInstall) {
        throw '测试触发：安装后模拟失败。'
    }

    $stageRoot = Split-Path -Parent $source
    if (Test-Path -LiteralPath $stageRoot -PathType Container) {
        Remove-CkPath -Path $stageRoot -Parent $updateRoot
    }

    if (-not $SkipRestart) {
        if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
            throw "更新后找不到启动器: $launcher"
        }
        Start-Process -FilePath $launcher -WorkingDirectory $target
    }
    try {
        $resultRoot = $UpdateStateRoot
        New-Item -ItemType Directory -Path $resultRoot -Force | Out-Null
        $result = [ordered]@{
            status = 'success'
            version = $ExpectedVersion
            updatedAt = (Get-Date).ToString('o')
            backup = $backupRoot
        } | ConvertTo-Json -Depth 3
        [IO.File]::WriteAllText((Join-Path $resultRoot 'last-update.json'), $result, (New-Object Text.UTF8Encoding($false)))
    } catch { }
    Write-CkUpdateLog "更新完成: $ExpectedVersion"
    exit 0
} catch {
    $message = $_.Exception.Message
    Write-CkUpdateLog "更新失败: $message"

    try {
        foreach ($name in @($installed)) {
            $newPath = Join-Path $target $name
            if (Test-Path -LiteralPath $newPath) {
                Remove-CkPath -Path $newPath -Parent $target
            }
        }
        if ($backupRoot -and (Test-Path -LiteralPath $backupRoot -PathType Container)) {
            foreach ($name in @($backedUp)) {
                $backupPath = Join-Path $backupRoot $name
                if (Test-Path -LiteralPath $backupPath) {
                    Move-Item -LiteralPath $backupPath -Destination (Join-Path $target $name)
                }
            }
        }
        Write-CkUpdateLog '旧版本已回滚。'
    } catch {
        $rollbackMessage = $_.Exception.Message
        $message = $message + [Environment]::NewLine + "回滚失败: $rollbackMessage"
        Write-CkUpdateLog "回滚失败: $rollbackMessage"
    }

    try {
        New-Item -ItemType Directory -Path $UpdateStateRoot -Force | Out-Null
        $failureResult = [ordered]@{
            status = 'error'
            version = $ExpectedVersion
            failedAt = (Get-Date).ToString('o')
            error = $message
        } | ConvertTo-Json -Depth 3
        [IO.File]::WriteAllText((Join-Path $UpdateStateRoot 'last-update.json'), $failureResult, (New-Object Text.UTF8Encoding($false)))
    } catch { }

    if (-not $SkipRestart -and (Test-Path -LiteralPath $launcher -PathType Leaf)) {
        try { Start-Process -FilePath $launcher -WorkingDirectory $target } catch { }
    }

    if (-not $SkipRestart) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $detail = '工具箱自动更新失败。' + [Environment]::NewLine + [Environment]::NewLine +
                $message + [Environment]::NewLine + [Environment]::NewLine +
                '日志: ' + (Join-Path $UpdateStateRoot 'update.log')
            [System.Windows.Forms.MessageBox]::Show(
                $detail,
                'CK免费工具箱 - 自动更新',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        } catch { }
    }
    exit 1
}
