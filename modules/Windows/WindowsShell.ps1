function Set-TaskbarPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Taskleiste"
    Write-Host "========================================"

    $changed = $false
    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

    foreach ($path in @($advancedPath, $searchPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop |
            Out-Null

            $changed = $true
        }
    }

    if (
        Set-RegistryDword `
            -Path $searchPath `
            -Name "SearchboxTaskbarMode" `
            -Value 0
    ) {
        Write-Host "[CONFIG] Suche ausgeblendet."
        $changed = $true
    }

    if (
        Set-RegistryDword `
            -Path $advancedPath `
            -Name "ShowTaskViewButton" `
            -Value 0
    ) {
        Write-Host "[CONFIG] Aktive Anwendungen ausgeblendet."
        $changed = $true
    }

    if (
        Set-RegistryDword `
            -Path $advancedPath `
            -Name "TaskbarResume" `
            -Value 0
    ) {
        Write-Host "[CONFIG] Fortsetzen ausgeblendet."
        $changed = $true
    }

    $stuckRectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

    if (-not (Test-Path -LiteralPath $stuckRectsPath)) {
        throw "StuckRects3 wurde nicht gefunden: $stuckRectsPath"
    }

    $stuckRects = Get-ItemProperty `
        -Path $stuckRectsPath `
        -Name "Settings" `
        -ErrorAction Stop

    [byte[]] $taskbarSettings = $stuckRects.Settings

    if ($taskbarSettings.Length -le 8) {
        throw "StuckRects3\Settings hat ein unerwartetes Format."
    }

    $currentAutoHide = ($taskbarSettings[8] -band 0x01) -eq 0x01
    $desiredAutoHide = [bool] $Config.Taskbar.AutoHide

    if ($currentAutoHide -ne $desiredAutoHide) {
        if ($desiredAutoHide) {
            $taskbarSettings[8] = $taskbarSettings[8] -bor 0x01
        }
        else {
            $taskbarSettings[8] = $taskbarSettings[8] -band 0xFE
        }

        Set-ItemProperty `
            -Path $stuckRectsPath `
            -Name "Settings" `
            -Value $taskbarSettings `
            -ErrorAction Stop

        Write-Host "[CONFIG] Taskleisten-Autohide aktualisiert."
        $changed = $true
    }

    if ($changed) {
        Write-Host "[OK] Taskleisten-Einstellungen aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Taskleisten-Einstellungen unverändert." `
            -ForegroundColor Green
    }

    return $changed
}

function Set-StartMenuPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Startmenü & Suche"
    Write-Host "========================================"

    $changed = $false
    $explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"

    if (-not (Test-Path -LiteralPath $explorerPolicyPath)) {
        New-Item `
            -Path $explorerPolicyPath `
            -Force `
            -ErrorAction Stop |
        Out-Null

        $changed = $true
    }

    if (
        Set-RegistryDword `
            -Path $explorerPolicyPath `
            -Name "DisableSearchBoxSuggestions" `
            -Value 1
    ) {
        $changed = $true
    }

    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $startPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"

    $desiredValues = @(
        @{
            Path  = $advancedPath
            Name  = "Start_TrackDocs"
            Value = [int] [bool] $Config.StartMenu.ShowRecentlyAddedApps
        },
        @{
            Path  = $startPath
            Name  = "ShowRecentList"
            Value = [int] [bool] $Config.StartMenu.ShowRecentItems
        },
        @{
            Path  = $advancedPath
            Name  = "Start_IrisRecommendations"
            Value = [int] [bool] $Config.StartMenu.ShowRecommendations
        },
        @{
            Path  = $startPath
            Name  = "ShowFrequentList"
            Value = [int] [bool] $Config.StartMenu.ShowMostUsedApps
        }
    )

    foreach ($entry in $desiredValues) {
        if (
            Set-RegistryDword `
                -Path $entry.Path `
                -Name $entry.Name `
                -Value $entry.Value
        ) {
            $changed = $true
        }
    }

    if ($changed) {
        Write-Host "[OK] Startmenü-Einstellungen aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Startmenü-Einstellungen unverändert." `
            -ForegroundColor Green
    }

    return $changed
}

function Set-WindowsTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Design"
    Write-Host "========================================"

    $accentColor = [string] $Config.Theme.AccentColor

    if ($accentColor -notmatch '^#(?<R>[0-9A-Fa-f]{2})(?<G>[0-9A-Fa-f]{2})(?<B>[0-9A-Fa-f]{2})$') {
        throw "Ungültige Windows-Akzentfarbe: $accentColor"
    }

    [byte] $red = [Convert]::ToByte($Matches.R, 16)
    [byte] $green = [Convert]::ToByte($Matches.G, 16)
    [byte] $blue = [Convert]::ToByte($Matches.B, 16)

    $argb = [BitConverter]::ToInt32(
        [byte[]] @($blue, $green, $red, 0xFF),
        0
    )

    $abgr = [BitConverter]::ToInt32(
        [byte[]] @($red, $green, $blue, 0xFF),
        0
    )

    $changed = $false
    $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $dwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
    $explorerAccentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"

    foreach ($path in @(
            $personalizePath,
            $desktopPath,
            $dwmPath,
            $explorerAccentPath
        )) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop |
            Out-Null

            $changed = $true
        }
    }

    foreach ($entry in @(
            @{
                Path  = $personalizePath
                Name  = "AppsUseLightTheme"
                Value = 0
            },
            @{
                Path  = $personalizePath
                Name  = "SystemUsesLightTheme"
                Value = 0
            },
            @{
                Path  = $desktopPath
                Name  = "AutoColorization"
                Value = 0
            },
            @{
                Path  = $dwmPath
                Name  = "AccentColor"
                Value = $abgr
            },
            @{
                Path  = $dwmPath
                Name  = "ColorizationColor"
                Value = $argb
            },
            @{
                Path  = $explorerAccentPath
                Name  = "AccentColorMenu"
                Value = $abgr
            }
        )) {
        if (
            Set-RegistryDword `
                -Path $entry.Path `
                -Name $entry.Name `
                -Value $entry.Value
        ) {
            $changed = $true
        }
    }

    if ($changed) {
        Write-Host (
            "[OK] Windows Design aktualisiert. Akzentfarbe: " +
            $accentColor
        ) -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Windows Design unverändert." `
            -ForegroundColor Green
    }

    return $changed
}

function Restart-WindowsExplorer {
    Write-Host ""
    Write-Host "[RESTART] Windows Explorer wird neu gestartet..."

    Stop-Process `
        -Name explorer `
        -Force `
        -ErrorAction SilentlyContinue


    Write-Host "[OK] Windows Explorer neu gestartet." `
        -ForegroundColor Green
}

function Set-RegistryDword {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [int] $Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item `
            -Path $Path `
            -Force `
            -ErrorAction Stop |
        Out-Null
    }

    $property = Get-ItemProperty `
        -Path $Path `
        -Name $Name `
        -ErrorAction SilentlyContinue

    $currentValue = if (
        $null -ne $property -and
        $property.PSObject.Properties.Name -contains $Name
    ) {
        $property.$Name
    }
    else {
        $null
    }

    $desiredDword = [uint64] (
        ([int64] $Value) -band [int64] 4294967295
    )

    $currentDword = if ($null -eq $currentValue) {
        $null
    }
    else {
        [uint64] (
            ([int64] $currentValue) -band [int64] 4294967295
        )
    }

    if (
        $null -ne $currentDword -and
        $currentDword -eq $desiredDword
    ) {
        return $false
    }

    if ($null -eq $currentValue) {
        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType DWord `
            -Value $Value `
            -Force `
            -ErrorAction Stop |
        Out-Null
    }
    else {
        Set-ItemProperty `
            -Path $Path `
            -Name $Name `
            -Value $Value `
            -ErrorAction Stop
    }

    return $true
}
