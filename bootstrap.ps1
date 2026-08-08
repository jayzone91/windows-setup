#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = $PSScriptRoot

Write-Host ""
Write-Host "========================================"
Write-Host " Repository Update"
Write-Host "========================================"


if (Test-Path (Join-Path $Root ".git")) {

    git `
        -C $Root `
        fetch origin


    if ($LASTEXITCODE -ne 0) {
        Write-Warning "git fetch ist fehlgeschlagen."
    }
    else {

        $localChanges = @(
            git `
                -C $Root `
                status `
                --porcelain
        )


        if ($localChanges.Count -gt 0) {

            Write-Host (
                "[SKIP] Repository enthält lokale Änderungen. " +
                "Automatisches Pull wird übersprungen."
            )
        }
        else {

            git `
                -C $Root `
                pull `
                --ff-only


            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Repository aktualisiert."
            }
            else {
                Write-Warning "Repository konnte nicht aktualisiert werden."
            }
        }
    }
}

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
$Browsers = Import-PowerShellDataFile "$Root\config\browsers.psd1"
$PowerShell = Import-PowerShellDataFile "$Root\config\powershell.psd1"
$Debloat = Import-PowerShellDataFile "$Root\config\debloat.psd1"
$Storage = Import-PowerShellDataFile `
    "$Root\config\storage.psd1"

# ------------------------------------------------------------
# Software
# ------------------------------------------------------------

Install-PackageGroup -Packages $Packages.Base -GroupName "Basissoftware"

Install-PackageGroup -Packages $Packages.Tools -GroupName "System-Tools"

Install-PackageGroup -Packages $Packages.Development -GroupName "Dev-Tools"

Install-PackageGroup -Packages $Packages.Browser -GroupName "Browser"

Install-PackageGroup `
    -Packages $Packages.Drivers `
    -GroupName "Treiber-Tools"

# Pfade neu einlesen
Update-SessionPath

Set-KomorebiConfiguration `
    -RepositoryPath $Root

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

Set-WindowsDebloat -Config $Debloat
Set-TaskbarPreferences
Set-StartMenuPreferences
Set-WindowsTheme
Set-WindowsPowerPreferences
Set-WindowsHDR
Set-WindowsWallpaperSlideshow

# ------------------------------------------------------------
# Entwicklung
# ------------------------------------------------------------

Set-GitPreferences

Set-WindowsTerminalPreferences

Install-PowerShellModules `
    -Modules $PowerShell.Modules

Set-PowerShellPreferences

Set-NushellPreferences

Set-LanguageEnvironment

Initialize-DevelopmentStorage `
    -Config $Storage

Install-CodexCli


# ------------------------------------------------------------
# VS Code
# ------------------------------------------------------------

Install-VSCodeExtensions -Extensions $VSCode.Extensions

Set-VSCodeSettings `
    -Source "$Root\dotfiles\vscode\settings.json"

# ------------------------------------------------------------
# Browser Config
# ------------------------------------------------------------

Set-BrowserConfiguration `
    -Config $Browsers

Restart-WindowsExplorer

# ------------------------------------------------------------
# Peripherie
# ------------------------------------------------------------

Sync-LogitechGHubConfiguration `
    -RepositoryPath "$Root\config\lghub"

# ------------------------------------------------------------
# Windows Updates
# ------------------------------------------------------------

Install-WindowsUpdates

# ------------------------------------------------------------
# Scheduled Tasks
# ------------------------------------------------------------


Register-KomorebiStartupTask

Register-WindowsSetupScheduledTask `
    -BootstrapPath "$Root\bootstrap.ps1"

# ------------------------------------------------------------
# Abschließende Tests
# ------------------------------------------------------------

Test-ApplePasswordRequirements

Test-PowerShellCode `
    -Path $Root

# ------------------------------------------------------------
# Fertig
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Setup-Durchlauf abgeschlossen"
Write-Host "========================================"
Write-Host ""

# ------------------------------------------------------------
# Wartungsstatus
# ------------------------------------------------------------

$rebootRequired =
Test-PendingReboot


$repositoryStatus =
Get-WindowsSetupRepositoryStatus `
    -RepositoryPath $Root


Send-WindowsSetupNotifications `
    -RebootRequired $rebootRequired `
    -RepositoryStatus $repositoryStatus
