param(
    [switch]$ForceIcon
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$SourcePath = Join-Path $Root 'launcher\CKFreeToolboxLauncher.cs'
$OutputPath = Join-Path $Root 'CK免费工具箱.exe'
$IconPath = Join-Path $Root 'static\cklogo.ico'
$CscPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$PowerShellAssemblyCandidates = @(
    (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\System.Management.Automation.dll'),
    (Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\System.Management.Automation\v4.0_3.0.0.0__31bf3856ad364e35\System.Management.Automation.dll')
)
$PowerShellAssembly = @($PowerShellAssemblyCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)[0]
if (-not $PowerShellAssembly) {
    $PowerShellAssembly = @(Get-ChildItem -LiteralPath (Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL') -Recurse -Filter System.Management.Automation.dll -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)[0]
}

function New-CkLogoBitmap {
    param([int]$Size)

    Add-Type -AssemblyName System.Drawing

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 128.0
    $radius = [Math]::Max(3.0, 24.0 * $scale)
    $rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $path.AddArc($rect.Left, $rect.Top, $diameter, $diameter, 180, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Top, $diameter, $diameter, 270, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($rect.Left, $rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $backgroundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 11, 11, 13))
    $graphics.FillPath($backgroundBrush, $path)

    $fontName = 'Arial Black'
    $fontSize = [Math]::Max(8.0, 49.0 * $scale)
    $whiteFont = New-Object System.Drawing.Font($fontName, $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $blueFont = New-Object System.Drawing.Font($fontName, $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 84, 166, 255))
    $greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 49, 224, 162))

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Near
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $graphics.DrawString('C', $whiteFont, $whiteBrush, [float](17 * $scale), [float](34 * $scale), $format)
    $graphics.DrawString('K', $blueFont, $blueBrush, [float](56 * $scale), [float](34 * $scale), $format)
    $graphics.FillRectangle($greenBrush, [float](98 * $scale), [float](30 * $scale), [float](8 * $scale), [float](16 * $scale))
    $graphics.FillRectangle($greenBrush, [float](98 * $scale), [float](82 * $scale), [float](8 * $scale), [float](16 * $scale))

    $graphics.Dispose()
    $path.Dispose()
    $backgroundBrush.Dispose()
    $whiteFont.Dispose()
    $blueFont.Dispose()
    $whiteBrush.Dispose()
    $blueBrush.Dispose()
    $greenBrush.Dispose()
    $format.Dispose()

    return $bitmap
}

function New-CkIco {
    param([string]$Path)

    Add-Type -AssemblyName System.Drawing
    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $images = New-Object System.Collections.Generic.List[object]

    foreach ($size in $sizes) {
        $bitmap = New-CkLogoBitmap -Size $size
        $stream = New-Object System.IO.MemoryStream
        try {
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $images.Add([pscustomobject]@{
                Size = $size
                Bytes = $stream.ToArray()
            })
        }
        finally {
            $stream.Dispose()
            $bitmap.Dispose()
        }
    }

    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    $writer = New-Object System.IO.BinaryWriter($fs)
    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]$images.Count)

        $offset = 6 + (16 * $images.Count)
        foreach ($image in $images) {
            $width = if ($image.Size -eq 256) { 0 } else { $image.Size }
            $writer.Write([byte]$width)
            $writer.Write([byte]$width)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$image.Bytes.Length)
            $writer.Write([UInt32]$offset)
            $offset += $image.Bytes.Length
        }

        foreach ($image in $images) {
            $writer.Write([byte[]]$image.Bytes)
        }
    }
    finally {
        $writer.Dispose()
        $fs.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $CscPath)) {
    throw "找不到 C# 编译器: $CscPath"
}
if (-not $PowerShellAssembly -or -not (Test-Path -LiteralPath $PowerShellAssembly)) {
    throw "找不到 PowerShell 宿主程序集: $PowerShellAssembly"
}
if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "找不到启动器源码: $SourcePath"
}

if ($ForceIcon -or -not (Test-Path -LiteralPath $IconPath)) {
    New-CkIco -Path $IconPath
}

$compilerArgs = @(
    '/nologo',
    '/target:winexe',
    '/platform:anycpu',
    '/optimize+',
    "/win32icon:$IconPath",
    "/reference:System.dll",
    "/reference:System.Core.dll",
    "/reference:System.Windows.Forms.dll",
    "/reference:$PowerShellAssembly",
    "/out:$OutputPath",
    $SourcePath
)

& $CscPath @compilerArgs
if ($LASTEXITCODE -ne 0) {
    throw "EXE 编译失败，退出码: $LASTEXITCODE"
}

$item = Get-Item -LiteralPath $OutputPath
Write-Host "Built: $($item.FullName)"
Write-Host "Size : $($item.Length) bytes"