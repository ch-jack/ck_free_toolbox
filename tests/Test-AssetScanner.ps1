[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-asset-scanner-' + [guid]::NewGuid().ToString('N'))
$utf8 = New-Object Text.UTF8Encoding($false)

function Write-TestFile {
    param([Parameter(Mandatory)][string]$Path, [string]$Content = '')
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [IO.File]::WriteAllText($Path, $Content, $utf8)
}

try {
    $resource = Join-Path $tempRoot 'unified_pack'
    Write-TestFile -Path (Join-Path $resource 'data\subpack\vehicles.meta') -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<CVehicleModelInfo__InitDataList>
  <!-- pack--vip -->
  <InitDatas>
    <Item><modelName>base_car</modelName></Item>
    <Item><modelName>second_car</modelName></Item>
    <Item><modelName>base_car_dryclutch_1</modelName></Item>
  </InitDatas>
</CVehicleModelInfo__InitDataList>
<?xml version="1.0" encoding="UTF-8"?>
<CVehicleModelInfo__InitDataList>
  <InitDatas><Item><modelName>base_car</modelName></Item></InitDatas>
</CVehicleModelInfo__InitDataList>
'@
    Write-TestFile -Path (Join-Path $resource 'data\subpack\handling.meta') -Content @'
<CHandlingDataMgr><HandlingData>
  <Item><handlingName>BASE_CAR</handlingName></Item>
  <Item><handlingName>SECOND_CAR</handlingName></Item>
</HandlingData></CHandlingDataMgr>
'@
    Write-TestFile -Path (Join-Path $resource 'data\subpack\carvariations.meta') -Content @'
<CVehicleModelInfoVariation>
  <variationData>
    <Item><modelName>second_car</modelName></Item>
    <Item><modelName>base_car_dryclutch_1</modelName></Item>
    <Item><modelName>base_car_bumper_2</modelName></Item>
  </variationData>
</CVehicleModelInfoVariation>
'@
    Write-TestFile -Path (Join-Path $resource 'data\flat\handling.meta') -Content '<CHandlingDataMgr><HandlingData><Item><handlingName>flat_car</handlingName></Item></HandlingData></CHandlingDataMgr>'
    Write-TestFile -Path (Join-Path $resource 'data\flat\carvariations.meta') -Content '<CVehicleModelInfoVariation><variationData><Item><modelName>flat_car_spoiler_1</modelName></Item></variationData></CVehicleModelInfoVariation>'
    Write-TestFile -Path (Join-Path $resource 'data\flat\vehicles.meta') -Content @'
<CVehicleModelInfo__InitDataList>
  <InitDatas>
    <Item><modelName>flat_car</modelName></Item>
  </InitDatas>
</CVehicleModelInfo__InitDataList>
'@
    foreach ($name in @('base_car.yft', 'base_car_hi.yft', 'second_car.yft', 'base_car_dryclutch_1.yft', 'base_car_bumper_2.yft')) {
        Write-TestFile -Path (Join-Path $resource "stream\subpack\$name")
    }
    Write-TestFile -Path (Join-Path $resource 'stream\subpack\display_prop.ydr')
    Write-TestFile -Path (Join-Path $resource 'stream\flat_car.yft')
    Write-TestFile -Path (Join-Path $resource 'stream\flat_car_spoiler_1.yft')
    Write-TestFile -Path (Join-Path $resource 'data\damaged\vehicles.meta') -Content 'garbage <broken <modelName>recovered_car</modelName>'
    Write-TestFile -Path (Join-Path $resource 'data\damaged\handling.meta') -Content '<CHandlingDataMgr><HandlingData><Item><handlingName>recovered_car</handlingName></Item></HandlingData></CHandlingDataMgr>'
    Write-TestFile -Path (Join-Path $resource 'data\damaged\carvariations.meta') -Content '<CVehicleModelInfoVariation><variationData><Item><modelName>recovered_car_part_1</modelName></Item></variationData></CVehicleModelInfoVariation>'
    Write-TestFile -Path (Join-Path $resource 'stream\damaged\recovered_car.yft')
    Write-TestFile -Path (Join-Path $resource 'stream\damaged\recovered_car_part_1.yft')
    Write-TestFile -Path (Join-Path $resource '_vehicle_renders\old_output.yft')
    Write-TestFile -Path (Join-Path $resource '_vehicle_renders\vehicles.meta') -Content '<invalid'
    Write-TestFile -Path (Join-Path $resource '_temp\temporary_part.yft')

    $globalMetadata = Join-Path $tempRoot 'metadata_registry\data\global'
    Write-TestFile -Path (Join-Path $globalMetadata 'vehicles.meta') -Content '<CVehicleModelInfo__InitDataList><InitDatas><Item><modelName>miniram2500lema</modelName></Item><Item><modelName>fmgt18</modelName></Item></InitDatas></CVehicleModelInfo__InitDataList>'
    Write-TestFile -Path (Join-Path $globalMetadata 'handling.meta') -Content '<CHandlingDataMgr><HandlingData><Item><handlingName>MINIRAM2500LEMA</handlingName></Item><Item><handlingName>FMGT18</handlingName></Item></HandlingData></CHandlingDataMgr>'

    $partsOnly = Join-Path $tempRoot 'parts_only_pack'
    Write-TestFile -Path (Join-Path $partsOnly 'data\kit\carvariations.meta') -Content @'
<CVehicleModelInfoVariation><variationData>
    <Item><modelName>miniram2500lema_grill_4a</modelName></Item>
    <Item><modelName>miniram2500lema_roof_1</modelName></Item>
    <Item><modelName>miniram2500lema_skirts</modelName></Item>
    <Item><modelName>miniram2500lema_tips</modelName></Item>
</variationData></CVehicleModelInfoVariation>
'@
    foreach ($name in @('miniram2500lema.yft', 'miniram2500lema_grill_4a.yft', 'miniram2500lema_roof_1.yft', 'miniram2500lema_skirts.yft', 'miniram2500lema_tips.yft')) {
        Write-TestFile -Path (Join-Path $partsOnly "stream\kit\$name")
    }

    $unifiedStream = Join-Path $tempRoot '804_Unified_Vehicle_Pack\stream'
    foreach ($name in @('fmgt18.yft', 'fmgt18_livery6.yft', 'fmgt18_livery7.yft', 'fmgt18_livery8.yft', 'fmgt18_livery9.yft')) {
        Write-TestFile -Path (Join-Path $unifiedStream $name)
    }

    $standalone = Join-Path $tempRoot 'standalone_pack\stream'
    Write-TestFile -Path (Join-Path $standalone 'standalone_car.yft')
    Write-TestFile -Path (Join-Path $standalone 'metadata_missing_part.yft')

    Import-Module (Join-Path $repoRoot 'app\modules\AssetScanner.psm1') -Force
    $assets = @(Get-CkRenderableAssets -Path $tempRoot)
    $vehicles = @($assets | Where-Object Kind -eq 'vehicle')
    $vehicleNames = @($vehicles.Model | Sort-Object)
    $expectedVehicles = @('base_car', 'flat_car', 'fmgt18', 'miniram2500lema', 'recovered_car', 'second_car')
    if (($vehicleNames -join '|') -cne ($expectedVehicles -join '|')) {
        throw "目录扫描车型过滤错误。实际: $($vehicleNames -join ', ')"
    }
    $baseRow = @($vehicles | Where-Object Model -ceq 'base_car')[0]
    if (-not $baseRow.Source.EndsWith('base_car_hi.yft', [StringComparison]::OrdinalIgnoreCase)) {
        throw "目录扫描未优先选择高模: $($baseRow.Source)"
    }
    if (@($assets | Where-Object Model -ceq 'display_prop').Count -ne 1) {
        throw '车辆元数据过滤误删了非车辆模型。'
    }

    $zipSource = Join-Path $tempRoot 'zip_source'
    Write-TestFile -Path (Join-Path $zipSource 'zip_resource\data\nested\vehicles.meta') -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<CVehicleModelInfo__InitDataList>
  <!-- invalid--comment -->
  <InitDatas>
    <Item><modelName>zip_car</modelName></Item>
  </InitDatas>
</CVehicleModelInfo__InitDataList>
'@
    Write-TestFile -Path (Join-Path $zipSource 'zip_resource\data\nested\handling.meta') -Content '<CHandlingDataMgr><HandlingData><Item><handlingName>ZIP_CAR</handlingName></Item></HandlingData></CHandlingDataMgr>'
    Write-TestFile -Path (Join-Path $zipSource 'zip_resource\data\nested\carvariations.meta') -Content '<CVehicleModelInfoVariation><variationData><Item><modelName>zip_car_spoiler_1</modelName></Item></variationData></CVehicleModelInfoVariation>'
    Write-TestFile -Path (Join-Path $zipSource 'zip_resource\stream\nested\zip_car.yft')
    Write-TestFile -Path (Join-Path $zipSource 'zip_resource\stream\nested\zip_car_spoiler_1.yft')
    $zipPath = Join-Path $tempRoot 'vehicle_pack.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($zipSource, $zipPath)
    $zipAssets = @(Get-CkRenderableAssets -Path $zipPath)
    $zipVehicles = @($zipAssets | Where-Object Kind -eq 'vehicle')
    if ($zipVehicles.Count -ne 1 -or [string]$zipVehicles[0].Model -cne 'zip_car') {
        throw "ZIP 扫描车型过滤错误。实际: $(@($zipVehicles.Model) -join ', ')"
    }

    Write-Host 'Asset scanner vehicle metadata filtering tests passed.'
} finally {
    $fullTemp = [IO.Path]::GetFullPath($tempRoot)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($fullTemp.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($fullTemp).StartsWith('ck-asset-scanner-', [StringComparison]::Ordinal)) {
        if ([IO.Directory]::Exists($fullTemp)) { [IO.Directory]::Delete($fullTemp, $true) }
    } else {
        throw "测试临时目录不安全，未清理: $fullTemp"
    }
}
