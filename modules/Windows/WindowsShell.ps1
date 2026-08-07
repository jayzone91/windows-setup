function Set-TaskbarPreferences {
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

    Set-ItemProperty `
        -Path $searchPath `
        -Name "SearchboxTaskbarMode" `
        -Value 0 `
        -ErrorAction Stop

    # Taskansicht / Aktive Anwendungen
    Write-Host "[CONFIG] Aktive Anwendungen ausblenden"

    Set-ItemProperty `
        -Path $advancedPath `
        -Name "ShowTaskViewButton" `
        -Value 0 `
        -ErrorAction Stop

    # Widgets
    Write-Host "[CONFIG] Widgets deaktivieren"

    $widgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"

    if (-not (Test-Path $widgetsPolicyPath)) {
        New-Item `
            -Path $widgetsPolicyPath `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    New-ItemProperty `
        -Path $widgetsPolicyPath `
        -Name "AllowNewsAndInterests" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    # Fortsetzen
    Write-Host "[CONFIG] Fortsetzen ausblenden"

    Set-ItemProperty `
        -Path $advancedPath `
        -Name "TaskbarResume" `
        -Value 0 `
        -ErrorAction Stop

    Write-Host "[OK] Taskleisten-Einstellungen gesetzt." `
        -ForegroundColor Green
}

function Set-StartMenuPreferences {
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
