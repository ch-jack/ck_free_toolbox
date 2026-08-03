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
            if ($legacy.PSObject.Properties['JavaPath']) {
                $config.dependencies.javaPath = [string]$legacy.JavaPath
            }
            if ($legacy.PSObject.Properties['NodePath']) {
                $config.dependencies.nodePath = [string]$legacy.NodePath
            }
        } catch { }
    }
    Save-CkToolboxConfig -Config $config
    return $script:CkToolboxConfigPath
}

function New-CkToolboxConfig {
    return [pscustomobject][ordered]@{
        schemaVersion = 2
        dependencies = [pscustomobject][ordered]@{
            blenderPath = ''
            pythonPath = ''
            javaPath = ''
            nodePath = ''
        }
        agreements = [pscustomobject][ordered]@{
            disclaimerAccepted = $false
            disclaimerVersion = 0
            disclaimerAcceptedAt = ''
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
        $config | Add-Member -NotePropertyName schemaVersion -NotePropertyValue 2
    } else {
        $config.schemaVersion = [Math]::Max(2, [int]$config.schemaVersion)
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
    if (-not $config.dependencies.PSObject.Properties['javaPath']) {
        $config.dependencies | Add-Member -NotePropertyName javaPath -NotePropertyValue ''
    }
    if (-not $config.dependencies.PSObject.Properties['nodePath']) {
        $config.dependencies | Add-Member -NotePropertyName nodePath -NotePropertyValue ''
    }
    if (-not $config.PSObject.Properties['agreements'] -or -not $config.agreements) {
        $config | Add-Member -NotePropertyName agreements -NotePropertyValue ([pscustomobject][ordered]@{}) -Force
    }
    if (-not $config.agreements.PSObject.Properties['disclaimerAccepted']) {
        $config.agreements | Add-Member -NotePropertyName disclaimerAccepted -NotePropertyValue $false
    }
    if (-not $config.agreements.PSObject.Properties['disclaimerVersion']) {
        $config.agreements | Add-Member -NotePropertyName disclaimerVersion -NotePropertyValue 0
    }
    if (-not $config.agreements.PSObject.Properties['disclaimerAcceptedAt']) {
        $config.agreements | Add-Member -NotePropertyName disclaimerAcceptedAt -NotePropertyValue ''
    }

    $accepted = $false
    try { $accepted = [Convert]::ToBoolean($config.agreements.disclaimerAccepted) } catch { }
    $acceptedVersion = 0
    try { $acceptedVersion = [Math]::Max(0, [int]$config.agreements.disclaimerVersion) } catch { }
    $config.agreements.disclaimerAccepted = $accepted
    $config.agreements.disclaimerVersion = $acceptedVersion
    $config.agreements.disclaimerAcceptedAt = [string]$config.agreements.disclaimerAcceptedAt
    if ($config.PSObject.Properties['BlenderPath'] -and -not $config.dependencies.blenderPath) {
        $config.dependencies.blenderPath = [string]$config.BlenderPath
    }
    if ($config.PSObject.Properties['PythonPath'] -and -not $config.dependencies.pythonPath) {
        $config.dependencies.pythonPath = [string]$config.PythonPath
    }
    if ($config.PSObject.Properties['JavaPath'] -and -not $config.dependencies.javaPath) {
        $config.dependencies.javaPath = [string]$config.JavaPath
    }
    if ($config.PSObject.Properties['NodePath'] -and -not $config.dependencies.nodePath) {
        $config.dependencies.nodePath = [string]$config.NodePath
    }
    if ($config.PSObject.Properties['BlenderPath']) { $config.PSObject.Properties.Remove('BlenderPath') }
    if ($config.PSObject.Properties['PythonPath']) { $config.PSObject.Properties.Remove('PythonPath') }
    if ($config.PSObject.Properties['JavaPath']) { $config.PSObject.Properties.Remove('JavaPath') }
    if ($config.PSObject.Properties['NodePath']) { $config.PSObject.Properties.Remove('NodePath') }
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
        JavaPath = [string]$config.dependencies.javaPath
        NodePath = [string]$config.dependencies.nodePath
    }
}

function Set-CkToolboxDependencyPath {
    param(
        [Parameter(Mandatory)][ValidateSet('Blender', 'Python', 'Java', 'Node')][string]$Dependency,
        [Parameter(Mandatory)][string]$Path
    )

    $config = Get-CkToolboxConfig
    $fullPath = [IO.Path]::GetFullPath($Path)
    if ($Dependency -eq 'Blender') {
        $config.dependencies.blenderPath = $fullPath
    } elseif ($Dependency -eq 'Python') {
        $config.dependencies.pythonPath = $fullPath
    } elseif ($Dependency -eq 'Java') {
        $config.dependencies.javaPath = $fullPath
    } else {
        $config.dependencies.nodePath = $fullPath
    }
    Save-CkToolboxConfig -Config $config
    return $fullPath
}

function Test-CkToolboxDisclaimerAccepted {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 2147483647)]
        [int]$Version
    )

    $config = Get-CkToolboxConfig
    return (($config.agreements.disclaimerAccepted -eq $true) -and
        ([int]$config.agreements.disclaimerVersion -ge $Version))
}

function Set-CkToolboxDisclaimerAccepted {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 2147483647)]
        [int]$Version
    )

    $config = Get-CkToolboxConfig
    $config.agreements.disclaimerAccepted = $true
    $config.agreements.disclaimerVersion = $Version
    $config.agreements.disclaimerAcceptedAt = [DateTimeOffset]::Now.ToString('o')
    Save-CkToolboxConfig -Config $config
}

Export-ModuleMember -Function Initialize-CkToolboxConfig, Get-CkToolboxConfigPath, Get-CkToolboxConfig, Save-CkToolboxConfig, Get-CkDependencySettings, Set-CkToolboxDependencyPath, Test-CkToolboxDisclaimerAccepted, Set-CkToolboxDisclaimerAccepted
