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

    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

    foreach ($path in @(
            $advancedPath,
            $searchPath
        )) {
        if (-not (Test-Path $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop | Out-Null
        }
    }

    # Suche
    Write-Host "[CONFIG] Suche ausblenden"

    Set-RegistryDword `
        -Path $searchPath `
        -Name "SearchboxTaskbarMode" `
        -Value 0


    # Taskansicht / Aktive Anwendungen
    Write-Host "[CONFIG] Aktive Anwendungen ausblenden"

    Set-RegistryDword `
        -Path $advancedPath `
        -Name "ShowTaskViewButton" `
        -Value 0

# Fortsetzen
    Write-Host "[CONFIG] Fortsetzen ausblenden"

    Set-RegistryDword `
        -Path $advancedPath `
        -Name "TaskbarResume" `
        -Value 0


    # Automatisches Ausblenden
    Write-Host "[CONFIG] Taskleiste automatisch ausblenden"

    $stuckRectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

    if (-not (Test-Path $stuckRectsPath)) {
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

    if ($currentAutoHide -eq $desiredAutoHide) {
        Write-Host "[OK] Taskleisten-Autohide bereits korrekt."
    }
    else {
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

        Write-Host "[OK] Taskleisten-Autohide aktualisiert."
    }
    Write-Host "[OK] Taskleisten-Einstellungen gesetzt." `
        -ForegroundColor Green
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

    $explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"

    if (-not (Test-Path $explorerPolicyPath)) {
        New-Item `
            -Path $explorerPolicyPath `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    Write-Host "[CONFIG] Internet-Suche im Startmenü deaktivieren"

    New-ItemProperty `
        -Path $explorerPolicyPath `
        -Name "DisableSearchBoxSuggestions" `
        -PropertyType DWord `
        -Value 1 `
        -Force `
        -ErrorAction Stop | Out-Null


    # ------------------------------------------------------------
    # Personalisierung > Start
    # ------------------------------------------------------------

    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $startPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"

    Write-Host "[CONFIG] Startmenü-Personalisierung setzen"

    Set-RegistryDword `
        -Path $advancedPath `
        -Name "Start_TrackDocs" `
        -Value ([int] [bool] $Config.StartMenu.ShowRecentlyAddedApps)

    Set-RegistryDword `
        -Path $startPath `
        -Name "ShowRecentList" `
        -Value ([int] [bool] $Config.StartMenu.ShowRecentItems)

    Set-RegistryDword `
        -Path $advancedPath `
        -Name "Start_IrisRecommendations" `
        -Value ([int] [bool] $Config.StartMenu.ShowRecommendations)

    Set-RegistryDword `
        -Path $startPath `
        -Name "ShowFrequentList" `
        -Value ([int] [bool] $Config.StartMenu.ShowMostUsedApps)
    Write-Host "[OK] Startmenü-Einstellungen gesetzt." `
        -ForegroundColor Green
}

function Set-WindowsTheme {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Design"
    Write-Host "========================================"

    $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $desktopPath = "HKCU:\Control Panel\Desktop"

    foreach ($path in @(
            $personalizePath,
            $desktopPath
        )) {
        if (-not (Test-Path $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop | Out-Null
        }
    }

    # ------------------------------------------------------------
    # Dark Mode
    # ------------------------------------------------------------

    Write-Host "[CONFIG] Dark Mode aktivieren"

    New-ItemProperty `
        -Path $personalizePath `
        -Name "AppsUseLightTheme" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    New-ItemProperty `
        -Path $personalizePath `
        -Name "SystemUsesLightTheme" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    # ------------------------------------------------------------
    # Akzentfarbe automatisch aus Hintergrundbild bestimmen
    # ------------------------------------------------------------

    Write-Host "[CONFIG] Akzentfarbe automatisch bestimmen"

    New-ItemProperty `
        -Path $desktopPath `
        -Name "AutoColorization" `
        -PropertyType DWord `
        -Value 1 `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "[OK] Windows Design konfiguriert." `
        -ForegroundColor Green
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

    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [int]$Value
    )


    if (-not (Test-Path $Path)) {
        New-Item `
            -Path $Path `
            -Force `
            -ErrorAction Stop |
        Out-Null
    }


    $property =
    Get-ItemProperty `
        -Path $Path `
        -Name $Name `
        -ErrorAction SilentlyContinue


    if ($null -eq $property) {

        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType DWord `
            -Value $Value `
            -ErrorAction Stop |
        Out-Null

        return
    }


    Set-ItemProperty `
        -Path $Path `
        -Name $Name `
        -Value $Value `
        -ErrorAction Stop
}
