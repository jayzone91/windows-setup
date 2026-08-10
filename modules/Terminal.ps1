function Set-WindowsTerminalPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Theme
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Terminal"
    Write-Host "========================================"

    $settingsPath = Join-Path `
        $env:LOCALAPPDATA `
        "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $settingsPath)) {
        throw "Windows Terminal settings.json nicht gefunden: $settingsPath"
    }

    Write-Host "[CONFIG] Windows Terminal konfigurieren"

    $settings = Get-Content `
        -Path $settingsPath `
        -Raw `
        -Encoding UTF8 |
    ConvertFrom-Json

    # ------------------------------------------------------------
    # PowerShell 7 als Standardprofil
    # ------------------------------------------------------------

    $settings.defaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"

    # ------------------------------------------------------------
    # Globale Profil-Einstellungen
    # ------------------------------------------------------------

    if (-not $settings.profiles.defaults) {
        $settings.profiles.defaults = [PSCustomObject]@{}
    }

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "font" `
        -NotePropertyValue ([PSCustomObject]@{
            face = "JetBrainsMono Nerd Font"
            size = 11
        }) `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "colorScheme" `
        -NotePropertyValue "Catppuccin Mocha" `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "padding" `
        -NotePropertyValue "10" `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "cursorShape" `
        -NotePropertyValue "bar" `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "useAcrylic" `
        -NotePropertyValue $false `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "opacity" `
        -NotePropertyValue 100 `
        -Force

    $settings.profiles.defaults | Add-Member `
        -NotePropertyName "padding" `
        -NotePropertyValue "12, 10, 12, 10" `
        -Force

    $settings | Add-Member `
        -NotePropertyName "alwaysShowTabs" `
        -NotePropertyValue $true `
        -Force

    $settings | Add-Member `
        -NotePropertyName "showTabsInTitlebar" `
        -NotePropertyValue $false `
        -Force

    $settings | Add-Member `
        -NotePropertyName "tabWidthMode" `
        -NotePropertyValue "compact" `
        -Force

    $settings | Add-Member `
        -NotePropertyName "useAcrylicInTabRow" `
        -NotePropertyValue $false `
        -Force

    # ------------------------------------------------------------
    # Catppuccin Mocha Scheme
    # ------------------------------------------------------------

    $catppuccin = [PSCustomObject]@{
        name                = "Catppuccin Mocha"

        foreground          = $Theme.Colors.Text
        background          = $Theme.Colors.Base

        cursorColor         = $Theme.Colors.Rosewater
        selectionBackground = $Theme.Colors.Surface2

        black               = "#45475A"
        red                 = "#F38BA8"
        green               = "#A6E3A1"
        yellow              = "#F9E2AF"
        blue                = "#89B4FA"
        purple              = "#F5C2E7"
        cyan                = "#94E2D5"
        white               = "#BAC2DE"

        brightBlack         = "#585B70"
        brightRed           = "#F38BA8"
        brightGreen         = "#A6E3A1"
        brightYellow        = "#F9E2AF"
        brightBlue          = "#89B4FA"
        brightPurple        = "#F5C2E7"
        brightCyan          = "#94E2D5"
        brightWhite         = "#A6ADC8"
    }

    $existingSchemes = @($settings.schemes)

    $existingSchemes = @(
        $existingSchemes |
        Where-Object {
            $_.name -ne "Catppuccin Mocha"
        }
    )

    $settings.schemes = @(
        $existingSchemes
        $catppuccin
    )

    # ------------------------------------------------------------
    # Alte Windows PowerShell / CMD Profile ausblenden
    # ------------------------------------------------------------

    foreach ($terminalProfile in $settings.profiles.list) {
        if (
            $terminalProfile.name -eq "Windows PowerShell" -or
            $terminalProfile.name -eq "Eingabeaufforderung"
        ) {
            $terminalProfile.hidden = $true
        }
    }

    # ------------------------------------------------------------
    # Speichern
    # ------------------------------------------------------------

    $json = $settings |
    ConvertTo-Json `
        -Depth 20

    [System.IO.File]::WriteAllText(
        $settingsPath,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host "[OK] Windows Terminal konfiguriert." `
        -ForegroundColor Green
}
