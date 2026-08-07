#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = $PSScriptRoot

Write-Host ""
Write-Host "========================================"
Write-Host " Windows Setup"
Write-Host "========================================"
Write-Host ""

# ------------------------------------------------------------
# Module
# ------------------------------------------------------------

. "$Root\modules\index.ps1"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

Clear-WindowsSetupTemp


# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------

$Packages = Import-PowerShellDataFile "$Root\config\packages.psd1"
$VSCode = Import-PowerShellDataFile "$Root\config\vscode.psd1"

# ------------------------------------------------------------
# Software
# ------------------------------------------------------------

Install-PackageGroup `
    -Packages $Packages.Drivers `
    -GroupName "Treiber-Tools"

Install-PackageGroup -Packages $Packages.Base -GroupName "Basissoftware"

Install-VSCodeExtensions -Extensions $VSCode.Extensions

Set-VSCodeSettings `
    -Source "$Root\dotfiles\vscode\settings.json"

Install-PackageGroup -Packages $Packages.Tools -GroupName "System-Tools"

Install-PackageGroup -Packages $Packages.Development -GroupName "Dev-Tools"

Install-PackageGroup -Packages $Packages.Browser -GroupName "Browser"


# Pfade neu einlesen
Update-SessionPath

# ------------------------------------------------------------
# Treiber
# ------------------------------------------------------------

Install-Drivers

if ($script:DriverRebootRequired) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Neustart erforderlich"
    Write-Host "========================================"
    Write-Host ""

    Write-Host (
        "Mindestens ein Treiber benötigt einen Neustart. " +
        "Der Computer wurde NICHT automatisch neu gestartet."
    ) -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Windows
# ------------------------------------------------------------

Set-TaskbarPreferences
Set-StartMenuPreferences
Set-WindowsTheme
Set-WindowsPowerPreferences
Set-WindowsHDR
Set-WindowsWallpaperSlideshow

Restart-WindowsExplorer

# ------------------------------------------------------------
# Entwicklung
# ------------------------------------------------------------

Set-GitPreferences

Set-WindowsTerminalPreferences
Set-PowerShellPreferences
Set-NushellPreferences

Set-LanguageEnvironment

Install-CodexCli

# ------------------------------------------------------------
# Abschließende Tests
# ------------------------------------------------------------

Test-ApplePasswordRequirements

# ------------------------------------------------------------
# Browser Config
# ------------------------------------------------------------

Set-BrowserConfiguration

# ------------------------------------------------------------
# Fertig
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Setup-Durchlauf abgeschlossen"
Write-Host "========================================"
Write-Host ""
