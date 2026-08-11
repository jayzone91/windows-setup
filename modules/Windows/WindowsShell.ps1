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
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Design"
    Write-Host "========================================"

    $changed = $false
    $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $desktopPath = "HKCU:\Control Panel\Desktop"

    foreach ($path in @($personalizePath, $desktopPath)) {
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
                Value = 1
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
        Write-Host "[OK] Windows Design aktualisiert." `
            -ForegroundColor Green
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

    $currentValue = Get-ItemPropertyValue `
        -Path $Path `
        -Name $Name `
        -ErrorAction SilentlyContinue

    if (
        $null -ne $currentValue -and
        [int] $currentValue -eq $Value
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
