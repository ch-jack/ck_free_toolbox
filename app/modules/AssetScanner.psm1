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
        if (@('_vehicle_renders', '_work', '_archive_unpacked', '_rpf_unpacked') -contains $part.ToLowerInvariant()) {
            return $true
        }
    }
    return $false
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
        [Parameter(Mandatory)][string]$PathText
    )

    if (Test-CkGeneratedPath $PathText) { return }
    $ext = [System.IO.Path]::GetExtension($PathText).ToLowerInvariant()
    if (@('.yft', '.ydr', '.ydd', '.ymap') -notcontains $ext) { return }

    $info = Get-CkAssetInfo -PathText $PathText -Extension $ext
    if (-not $info) { return }

    $model = Get-CkCleanModelName $PathText
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
        [System.IO.Directory]::EnumerateFiles($item.FullName, '*.*', [System.IO.SearchOption]::AllDirectories) | ForEach-Object {
            $relative = $_.Substring($item.FullName.TrimEnd('\').Length).TrimStart('\')
            Add-CkAssetByName -Map $map -PathText $relative
        }
    } elseif ($item.Extension.ToLowerInvariant() -eq '.zip') {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($item.FullName)
        try {
            foreach ($entry in $zip.Entries) {
                Add-CkAssetByName -Map $map -PathText $entry.FullName
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
