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

# ------------------------------------------------------------
# Strikter Code-Preflight
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " PowerShell Preflight"
Write-Host "========================================"

$powerShellModulePath = Join-Path $Root "modules\PowerShell.ps1"

if (-not (Test-Path -LiteralPath $powerShellModulePath -PathType Leaf)) {
    throw "PowerShell-Modul nicht gefunden: $powerShellModulePath"
}

. $powerShellModulePath

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "[PREREQUISITE] PSScriptAnalyzer installieren"

    Install-Module `
        -Name "PSScriptAnalyzer" `
        -Scope CurrentUser `
        -Repository "PSGallery" `
        -Force `
        -AllowClobber `
        -ErrorAction Stop
}

Test-PowerShellCode `
    -Path $Root `
    -FailOnAnyIssue

Write-Host "[OK] Strikter Code-Preflight bestanden." `
    -ForegroundColor Green

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
$PowerToys = Import-PowerShellDataFile "$Root\config\powertoys.psd1"
$Raycast = Import-PowerShellDataFile "$Root\config\raycast.psd1"
$Theme = Import-PowerShellDataFile "$Root\config\theme.psd1"
$Windhawk = Import-PowerShellDataFile "$Root\config\windhawk.psd1"
$Windows = Import-PowerShellDataFile "$Root\config\windows.psd1"
$Debloat = Import-PowerShellDataFile "$Root\config\debloat.psd1"
$Storage = Import-PowerShellDataFile `
    "$Root\config\storage.psd1"


# ------------------------------------------------------------
# Paketmanager
# ------------------------------------------------------------

Initialize-PackageManagers `
    -Packages $Packages
# ------------------------------------------------------------
# Software
# ------------------------------------------------------------


try {
    Install-PackageGroup -Packages $Packages.Base -GroupName "Basissoftware"

    Install-PackageGroup `
        -Packages $Packages.Drivers `
        -GroupName "Treiber-Tools"

    Install-PackageGroup -Packages $Packages.Tools -GroupName "System-Tools"

    Install-PackageGroup `
        -Packages $Packages.HomeOffice `
        -GroupName "Home Office"

    Install-PackageGroup -Packages $Packages.Development -GroupName "Dev-Tools"

    Install-PackageGroup -Packages $Packages.Browser -GroupName "Browser"
}
finally {
    Clear-PackageManagerCaches
}
Install-PcVisitSupporterModule

Install-Windhawk

# Pfade neu einlesen
Update-SessionPath

Set-PowerToysConfiguration `
    -Config $PowerToys `
    -RepositoryPath $Root
Initialize-RaycastConfiguration `
    -Config $Raycast `
    -RepositoryPath $Root
Set-WindhawkConfiguration `
    -Config $Windhawk

Set-KomorebiConfiguration `
    -RepositoryPath $Root

Set-ZebarConfiguration `
    -RepositoryPath $Root

Set-OneCommanderConfiguration `
    -RepositoryPath $Root

Initialize-NanaZipFileAssociations `
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
Set-TaskbarPreferences `
    -Config $Windows
Set-StartMenuPreferences `
    -Config $Windows
Disable-WindowsSnap
Set-WindowsTheme
Set-WindowsPowerPreferences
Set-WindowsHDR
Set-WindowsWallpaperSlideshow

# ------------------------------------------------------------
# Entwicklung
# ------------------------------------------------------------

Set-GitPreferences

Update-NeovimConfiguration `
    -RepositoryPath $Root

Set-NeovimCompilerEnvironment

Test-NeovimRequirements
Set-WindowsTerminalPreferences `
    -Theme $Theme

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

Initialize-LogitechGHubConfiguration `
    -RepositoryPath "$Root\config\lghub"

# ------------------------------------------------------------
# Windows Updates
# ------------------------------------------------------------

$windowsUpdateStatus =
Install-WindowsUpdates

# ------------------------------------------------------------
# Scheduled Tasks
# ------------------------------------------------------------


Register-KomorebiStartupTask

Register-ZebarStartupTask

Restart-WindowsDesktopEnvironment

Register-WindowsSetupScheduledTask `
    -BootstrapPath "$Root\bootstrap.ps1"

# ------------------------------------------------------------
# Abschließende Tests
# ------------------------------------------------------------

Test-ApplePasswordRequirements

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

$rebootStatus =
Get-PendingRebootStatus

$rebootRequired =
$rebootStatus.RebootRequired

if ($rebootStatus.RebootRequired) {

    Write-Host ""
    Write-Host "[INFO] Neustartstatus:"

    foreach ($reason in $rebootStatus.Reasons) {
        Write-Host "  - $reason"
    }

    if ($rebootStatus.PendingFileRenames.Count -gt 0) {

        Write-Host ""
        Write-Host "[INFO] PendingFileRenameOperations:"

        foreach ($entry in $rebootStatus.PendingFileRenames) {
            Write-Host "  - $entry"
        }
    }
}

$repositoryStatus =
Get-WindowsSetupRepositoryStatus `
    -RepositoryPath $Root

if ($repositoryStatus.HasChanges) {

    Write-Host ""
    Write-Host "[INFO] Lokale Repository-Änderungen:"

    foreach ($file in $repositoryStatus.ChangedFiles) {
        Write-Host "  - $file"
    }
}

if ($repositoryStatus.UnpushedCommits -gt 0) {
    Write-Host (
        "[INFO] Ungepushte Commits: {0}" `
            -f $repositoryStatus.UnpushedCommits
    )
}

Show-NeovimMaintenanceStatus

Send-WindowsSetupNotifications `
    -WindowsUpdateRebootRequired $windowsUpdateStatus.RebootRequired `
    -DriverRebootRequired $script:DriverRebootRequired `
    -PendingReboot $rebootRequired `
    -RepositoryStatus $repositoryStatus `
    -RepositoryPath $Root
