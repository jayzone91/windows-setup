function ConvertTo-PowerToysHotkeyObject {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Hotkey
    )

    return [pscustomobject]@{
        win   = [bool]$Hotkey.win
        ctrl  = [bool]$Hotkey.ctrl
        alt   = [bool]$Hotkey.alt
        shift = [bool]$Hotkey.shift
        code  = [int]$Hotkey.code
        key   = [string]$Hotkey.key
    }
}

function Test-PowerToysJsonEqual {
    param(
        [AllowNull()]
        [object]$Current,

        [AllowNull()]
        [object]$Desired
    )

    $currentJson = $Current | ConvertTo-Json -Depth 100 -Compress
    $desiredJson = $Desired | ConvertTo-Json -Depth 100 -Compress

    return $currentJson -eq $desiredJson
}

function Backup-UnmanagedPowerToysFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $backupRoot = Join-Path `
        $RepositoryPath `
        ".generated\backups\powertoys\before-managed-state"

    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    $safeName = $Path `
        -replace [regex]::Escape($env:LOCALAPPDATA), "LOCALAPPDATA" `
        -replace '[:\\\/]', '_'

    $backupPath = Join-Path $backupRoot $safeName

    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        Copy-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "[OK] Ausgangskonfiguration gesichert: $Path"
    }
}

function Write-PowerToysJson {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Object
    )

    $json = $Object | ConvertTo-Json -Depth 100

    [System.IO.File]::WriteAllText(
        $Path,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    $null = Get-Content -LiteralPath $Path -Raw |
        ConvertFrom-Json -Depth 100
}

function Get-CommandPaletteSettingsPath {
    $package = Get-AppxPackage `
        -Name "Microsoft.CommandPalette" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $package) {
        return $null
    }

    return Join-Path `
        $env:LOCALAPPDATA `
        ("Packages\{0}\LocalState\settings.json" -f $package.PackageFamilyName)
}