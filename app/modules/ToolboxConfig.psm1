function Initialize-CkToolboxConfig {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$LegacyPath = ''
    )

    $script:CkToolboxConfigPath = [IO.Path]::GetFullPath($Path)
    if (Test-Path -LiteralPath $script:CkToolboxConfigPath -PathType Leaf) {
        $existing = Get-CkToolboxConfig
        Save-CkToolboxConfig -Config $existing
        return $script:CkToolboxConfigPath
    }

    $config = New-CkToolboxConfig
    if ($LegacyPath -and (Test-Path -LiteralPath $LegacyPath -PathType Leaf)) {
        try {
            $legacy = Get-Content -LiteralPath $LegacyPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($legacy.PSObject.Properties['BlenderPath']) {
                $config.dependencies.blenderPath = [string]$legacy.BlenderPath
            }
            if ($legacy.PSObject.Properties['PythonPath']) {
                $config.dependencies.pythonPath = [string]$legacy.PythonPath
            }
        } catch { }
    }
    Save-CkToolboxConfig -Config $config
    return $script:CkToolboxConfigPath
}

function New-CkToolboxConfig {
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        dependencies = [pscustomobject][ordered]@{
            blenderPath = ''
            pythonPath = ''
        }
    }
}

function Get-CkToolboxConfigPath {
    if ([string]::IsNullOrWhiteSpace($script:CkToolboxConfigPath)) {
        throw '工具箱配置尚未初始化。'
    }
    return $script:CkToolboxConfigPath
}

function ConvertTo-CkToolboxConfig {
    param($Value)

    if (-not $Value) { return New-CkToolboxConfig }
    $config = $Value
    if (-not $config.PSObject.Properties['schemaVersion']) {
        $config | Add-Member -NotePropertyName schemaVersion -NotePropertyValue 1
    } else {
        $config.schemaVersion = [Math]::Max(1, [int]$config.schemaVersion)
    }
    if (-not $config.PSObject.Properties['dependencies'] -or -not $config.dependencies) {
        $config | Add-Member -NotePropertyName dependencies -NotePropertyValue ([pscustomobject][ordered]@{}) -Force
    }
    if (-not $config.dependencies.PSObject.Properties['blenderPath']) {
        $config.dependencies | Add-Member -NotePropertyName blenderPath -NotePropertyValue ''
    }
    if (-not $config.dependencies.PSObject.Properties['pythonPath']) {
        $config.dependencies | Add-Member -NotePropertyName pythonPath -NotePropertyValue ''
    }
    if ($config.PSObject.Properties['BlenderPath'] -and -not $config.dependencies.blenderPath) {
        $config.dependencies.blenderPath = [string]$config.BlenderPath
    }
    if ($config.PSObject.Properties['PythonPath'] -and -not $config.dependencies.pythonPath) {
        $config.dependencies.pythonPath = [string]$config.PythonPath
    }
    if ($config.PSObject.Properties['BlenderPath']) { $config.PSObject.Properties.Remove('BlenderPath') }
    if ($config.PSObject.Properties['PythonPath']) { $config.PSObject.Properties.Remove('PythonPath') }
    return $config
}

function Get-CkToolboxConfig {
    $path = Get-CkToolboxConfigPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return New-CkToolboxConfig
    }
    try {
        $value = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        return ConvertTo-CkToolboxConfig -Value $value
    } catch {
        throw "工具箱配置无法读取: $path。$($_.Exception.Message)"
    }
}

function Save-CkToolboxConfig {
    param([Parameter(Mandatory)]$Config)

    $path = Get-CkToolboxConfigPath
    $parent = Split-Path -Parent $path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $normalized = ConvertTo-CkToolboxConfig -Value $Config
    $temporary = "$path.tmp-$([Guid]::NewGuid().ToString('N'))"
    try {
        [IO.File]::WriteAllText(
            $temporary,
            ($normalized | ConvertTo-Json -Depth 5),
            (New-Object Text.UTF8Encoding($false))
        )
        Move-Item -LiteralPath $temporary -Destination $path -Force
    } finally {
        if (Test-Path -LiteralPath $temporary -PathType Leaf) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

function Get-CkDependencySettings {
    $config = Get-CkToolboxConfig
    return [pscustomobject]@{
        BlenderPath = [string]$config.dependencies.blenderPath
        PythonPath = [string]$config.dependencies.pythonPath
    }
}

function Set-CkToolboxDependencyPath {
    param(
        [Parameter(Mandatory)][ValidateSet('Blender', 'Python')][string]$Dependency,
        [Parameter(Mandatory)][string]$Path
    )

    $config = Get-CkToolboxConfig
    $fullPath = [IO.Path]::GetFullPath($Path)
    if ($Dependency -eq 'Blender') {
        $config.dependencies.blenderPath = $fullPath
    } else {
        $config.dependencies.pythonPath = $fullPath
    }
    Save-CkToolboxConfig -Config $config
    return $fullPath
}

Export-ModuleMember -Function Initialize-CkToolboxConfig, Get-CkToolboxConfigPath, Get-CkToolboxConfig, Save-CkToolboxConfig, Get-CkDependencySettings, Set-CkToolboxDependencyPath
