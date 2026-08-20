[CmdletBinding()]
param(
    [string]$WorkspaceRoot = 'D:\fivem',
    [string]$ComponentRoot = '',
    [string]$FFmpegPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Import-Module (Join-Path $repoRoot 'app\modules\UiKit.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\ToolboxConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\EnvironmentProbe.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\ProcessRunner.psm1') -Force

$tempConfig = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'ck-image-page-' + [Guid]::NewGuid().ToString('N') + '.json')
try {
    [void](Initialize-CkToolboxConfig -Path $tempConfig)
    if ($FFmpegPath) {
        [void](Set-CkDependencyPath -Dependency FFmpeg -Path $FFmpegPath)
    }
    if (-not $ComponentRoot) {
        $ComponentRoot = Join-Path $WorkspaceRoot 'fivem-compression-img'
    }
    $context = [pscustomobject]@{
        Paths = [pscustomobject]@{
            WorkspaceRoot = $WorkspaceRoot
            RuntimeRoot = Join-Path $WorkspaceRoot 'runtime'
            RendererDir = Join-Path $WorkspaceRoot 'vehicle_renderer'
            RenderScript = Join-Path $WorkspaceRoot 'vehicle_renderer\render_all_vehicles.py'
            ImageCompressorDir = $ComponentRoot
            ImageCompressorScript = Join-Path $ComponentRoot 'fivem-compression-img.py'
            DefaultImageCompressorInput = ''
            DefaultImageCompressorOutput = Join-Path $WorkspaceRoot 'ImageCompressionOutput'
        }
        Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    }

    . (Join-Path $repoRoot 'app\pages\ImageCompressorPage.ps1')
    $page = New-CkImageCompressorPage -Context $context
    if (-not $page -or -not ($page.Root -is [System.Windows.UIElement])) {
        throw 'Image compressor page returned an invalid root element.'
    }
    foreach ($controlName in @('InputBox', 'OutputBox', 'StartButton', 'FilesGrid', 'OpenCsvButton', 'OpenJsonButton')) {
        if (-not $page.Root.FindName($controlName)) {
            throw "Image compressor page is missing control: $controlName"
        }
    }
    if ([string]$page.Id -cne 'image-compressor' -or [string]$page.Title -cne '图片批量压缩') {
        throw 'Image compressor page metadata is invalid.'
    }
    if ($FFmpegPath -and (Test-Path -LiteralPath (Join-Path $ComponentRoot 'fivem-compression-img.py') -PathType Leaf)) {
        $environmentStatus = $page.Root.FindName('EnvironmentStatus')
        if (-not $environmentStatus -or [string]$environmentStatus.Text -cne '运行环境就绪') {
            throw "Image compressor environment was not ready: $([string]$environmentStatus.Text)"
        }
    }
    Write-Host 'Image compressor WPF page instantiation passed.'
} finally {
    if (Test-Path -LiteralPath $tempConfig -PathType Leaf) {
        [IO.File]::Delete($tempConfig)
    }
}
