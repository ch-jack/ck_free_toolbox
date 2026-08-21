function Get-CkCleanModelName {
    param([Parameter(Mandatory)][string]$Name)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    $lower = $stem.ToLowerInvariant()
    if ($lower.EndsWith('_hi') -or $lower.EndsWith('+hi')) {
        return $stem.Substring(0, $stem.Length - 3)
    }
    return $stem
}

function Test-CkGeneratedPath {
    param([Parameter(Mandatory)][string]$PathText)
    foreach ($part in ($PathText -split '[\\/]')) {
        if (@('_vehicle_renders', '_temp', '_work', '_archive_unpacked', '_rpf_unpacked') -contains $part.ToLowerInvariant()) {
            return $true
        }
    }
    return $false
}

function Get-CkScannableFiles {
    param([Parameter(Mandatory)][string]$Root)

    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push([IO.Path]::GetFullPath($Root))
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($file in [IO.Directory]::EnumerateFiles($current)) { $file }
        foreach ($directory in [IO.Directory]::EnumerateDirectories($current)) {
            $name = [IO.Path]::GetFileName($directory).ToLowerInvariant()
            if (@('_vehicle_renders', '_temp', '_work', '_archive_unpacked', '_rpf_unpacked') -contains $name) { continue }
            $attributes = [IO.File]::GetAttributes($directory)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
            $pending.Push($directory)
        }
    }
}

function Get-CkAssetSourceKey {
    param([Parameter(Mandatory)][string]$PathText)

    $normalized = $PathText.Replace('\', '/').TrimStart('/')
    $separator = $normalized.LastIndexOf('/')
    if ($separator -lt 0) { return '.' }
    return $normalized.Substring(0, $separator).TrimEnd('/')
}

function Get-CkVehicleSourceKeysForMetadata {
    param([Parameter(Mandatory)][string]$MetadataPath)

    $normalized = $MetadataPath.Replace('\', '/').TrimStart('/')
    $metadataParent = Get-CkAssetSourceKey -PathText $normalized
    $keys = @{}
    $keys[$metadataParent] = $true
    $keys[$(if ($metadataParent -eq '.') { 'stream' } else { "$metadataParent/stream" })] = $true

    $parts = @($normalized -split '/')
    $dataIndex = -1
    for ($index = 0; $index -lt ($parts.Count - 1); $index++) {
        if ($parts[$index] -ieq 'data') {
            $dataIndex = $index
            break
        }
    }
    if ($dataIndex -ge 0) {
        $resourceKey = if ($dataIndex -eq 0) { '.' } else { ($parts[0..($dataIndex - 1)] -join '/') }
        $streamKey = if ($resourceKey -eq '.') { 'stream' } else { "$resourceKey/stream" }
        $keys[$streamKey] = $true
        $suffixCount = $parts.Count - $dataIndex - 2
        if ($suffixCount -gt 0) {
            $suffix = $parts[($dataIndex + 1)..($parts.Count - 2)] -join '/'
            $keys["$streamKey/$suffix"] = $true
        }
    }
    return @($keys.Keys)
}

function Remove-CkXmlComments {
    param([Parameter(Mandatory)][string]$XmlText)
    return [regex]::Replace($XmlText, '<!--[\s\S]*?-->', '')
}

function Add-CkVehicleMetadataModels {
    param(
        [Parameter(Mandatory)][hashtable]$Index,
        [Parameter(Mandatory)][string]$MetadataPath,
        [Parameter(Mandatory)][string]$XmlText
    )

    $name = [IO.Path]::GetFileName($MetadataPath).ToLowerInvariant()
    if (@('vehicles.meta', 'carvariations.meta') -notcontains $name) { return }

    $originalError = $null
    try {
        $document = New-Object Xml.XmlDocument
        $document.PreserveWhitespace = $false
        $document.LoadXml($XmlText)
    } catch {
        $originalError = $_.Exception.Message
        try {
            $document = New-Object Xml.XmlDocument
            $document.PreserveWhitespace = $false
            $document.LoadXml((Remove-CkXmlComments -XmlText $XmlText))
        } catch {
            throw "车辆元数据 XML 无效: $MetadataPath。$originalError；移除注释后仍无法解析: $($_.Exception.Message)"
        }
    }

    $models = @(
        $document.SelectNodes('//InitDatas/Item/modelName | //variationData/Item/modelName') |
            ForEach-Object { ([string]$_.InnerText).Trim() } |
            Where-Object { $_ }
    )
    if (-not $models.Count) { return }

    foreach ($sourceKey in @(Get-CkVehicleSourceKeysForMetadata -MetadataPath $MetadataPath)) {
        if (-not $Index.ContainsKey($sourceKey)) { $Index[$sourceKey] = @{} }
        foreach ($model in $models) { $Index[$sourceKey][$model] = $true }
    }
}

function Get-CkAssetInfo {
    param(
        [Parameter(Mandatory)][string]$PathText,
        [Parameter(Mandatory)][string]$Extension
    )

    $lower = $PathText.Replace('\', '/').ToLowerInvariant()
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($PathText).ToLowerInvariant()
    switch ($Extension.ToLowerInvariant()) {
        '.yft' { return [pscustomobject]@{ Kind = 'vehicle'; Label = '载具'; Icon = '▱' } }
        '.ydd' { return [pscustomobject]@{ Kind = 'drawable-dict'; Label = '字典'; Icon = '▣' } }
        '.ymap' { return [pscustomobject]@{ Kind = 'map'; Label = '地图'; Icon = '▦' } }
        '.ydr' {
            if ($stem.StartsWith('w_') -or $stem.StartsWith('weapon_') -or $lower.Contains('weapon') -or $lower.Contains('/wea')) {
                return [pscustomobject]@{ Kind = 'weapon'; Label = '武器'; Icon = '⌁' }
            }
            if ($lower.Contains('accessory') -or $lower.Contains('accessories') -or $lower.Contains('shipin') -or $lower.Contains('labubu') -or $lower.Contains('backpack') -or $lower.Contains('bag')) {
                return [pscustomobject]@{ Kind = 'accessory'; Label = '饰品'; Icon = '◇' }
            }
            if ($lower.Contains('prop')) {
                return [pscustomobject]@{ Kind = 'prop'; Label = '道具'; Icon = '□' }
            }
            return [pscustomobject]@{ Kind = 'drawable'; Label = '模型'; Icon = '□' }
        }
    }
    return $null
}

function New-CkAssetRow {
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$KindLabel,
        [Parameter(Mandatory)][string]$Icon,
        [Parameter(Mandatory)][string]$Source
    )

    [pscustomobject]@{
        Selected = $true
        Icon = $Icon
        Model = $Model
        Kind = $Kind
        KindLabel = $KindLabel
        Source = $Source
        Status = '待渲染'
    }
}

function Add-CkAssetByName {
    param(
        [Parameter(Mandatory)]$Map,
        [Parameter(Mandatory)][string]$PathText,
        [hashtable]$VehicleBaseModelsBySource
    )

    if (Test-CkGeneratedPath $PathText) { return }
    $ext = [System.IO.Path]::GetExtension($PathText).ToLowerInvariant()
    if (@('.yft', '.ydr', '.ydd', '.ymap') -notcontains $ext) { return }

    $info = Get-CkAssetInfo -PathText $PathText -Extension $ext
    if (-not $info) { return }

    $model = Get-CkCleanModelName $PathText
    if ($ext -eq '.yft' -and $VehicleBaseModelsBySource) {
        $sourceKey = Get-CkAssetSourceKey -PathText $PathText
        if ($VehicleBaseModelsBySource.ContainsKey($sourceKey)) {
            $baseModels = $VehicleBaseModelsBySource[$sourceKey]
            if ($baseModels.Count -gt 0 -and -not $baseModels.ContainsKey($model)) { return }
        }
    }
    $key = "$($info.Kind)|$($model.ToLowerInvariant())"
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($PathText).ToLowerInvariant()
    $score = if ($stem.EndsWith('_hi') -or $stem.EndsWith('+hi')) { 2 } else { 1 }

    if (-not $Map.ContainsKey($key) -or $Map[$key].Score -le $score) {
        $Map[$key] = [pscustomobject]@{
            Score = $score
            Row = New-CkAssetRow -Model $model -Kind $info.Kind -KindLabel $info.Label -Icon $info.Icon -Source $PathText
        }
    }
}

function Get-CkRenderableAssets {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "路径不存在: $Path"
    }

    $map = @{}
    $item = Get-Item -LiteralPath $Path
    if ($item.PSIsContainer) {
        $files = @(Get-CkScannableFiles -Root $item.FullName)
        $rootLength = $item.FullName.TrimEnd('\').Length
        $vehicleBaseModelsBySource = @{}
        foreach ($file in $files) {
            $name = [IO.Path]::GetFileName($file).ToLowerInvariant()
            if (@('vehicles.meta', 'carvariations.meta') -notcontains $name) { continue }
            $relative = $file.Substring($rootLength).TrimStart('\')
            Add-CkVehicleMetadataModels -Index $vehicleBaseModelsBySource -MetadataPath $relative -XmlText ([IO.File]::ReadAllText($file))
        }
        foreach ($file in $files) {
            $relative = $file.Substring($rootLength).TrimStart('\')
            Add-CkAssetByName -Map $map -PathText $relative -VehicleBaseModelsBySource $vehicleBaseModelsBySource
        }
    } elseif ($item.Extension.ToLowerInvariant() -eq '.zip') {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($item.FullName)
        try {
            $vehicleBaseModelsBySource = @{}
            foreach ($entry in $zip.Entries) {
                $name = [IO.Path]::GetFileName($entry.FullName).ToLowerInvariant()
                if (@('vehicles.meta', 'carvariations.meta') -notcontains $name) { continue }
                $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8, $true)
                try { $xmlText = $reader.ReadToEnd() } finally { $reader.Dispose() }
                Add-CkVehicleMetadataModels -Index $vehicleBaseModelsBySource -MetadataPath $entry.FullName -XmlText $xmlText
            }
            foreach ($entry in $zip.Entries) {
                Add-CkAssetByName -Map $map -PathText $entry.FullName -VehicleBaseModelsBySource $vehicleBaseModelsBySource
            }
        } finally {
            $zip.Dispose()
        }
    } elseif (@('.rar', '.7z') -contains $item.Extension.ToLowerInvariant()) {
        $map[$item.BaseName] = [pscustomobject]@{
            Score = 1
            Row = New-CkAssetRow -Model $item.BaseName -Kind 'archive' -KindLabel '资源包' -Icon '▱' -Source $item.FullName
        }
    }

    return @($map.Values | ForEach-Object { $_.Row } | Sort-Object KindLabel, Model)
}

Export-ModuleMember -Function Get-CkRenderableAssets, Get-CkCleanModelName, Get-CkAssetInfo
