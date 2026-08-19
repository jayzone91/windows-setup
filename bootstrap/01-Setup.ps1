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
# Fingerprint-gesteuerter Code-Preflight
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Source Code Preflight"
Write-Host "========================================"

$helpersModulePath = Join-Path $Root "modules\Helpers\index.ps1"
$powerShellModulePath = Join-Path $Root "modules\PowerShell\index.ps1"

foreach ($modulePath in @(
        $helpersModulePath,
        $powerShellModulePath
    )) {
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw "Preflight-Modul nicht gefunden: $modulePath"
    }

    . $modulePath
}

if (Test-PowerShellCodeFingerprint -Path $Root) {
    Write-Host "[SKIP] Source-Code seit letztem erfolgreichen Check unverändert." `
        -ForegroundColor Green
}
else {
    Write-Host "[CHECK] Source-Code-Fingerprint geändert."

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
        -FailOnAnyIssue `
        -UpdateFingerprint

    Write-Host "[OK] Strikter Code-Preflight bestanden." `
        -ForegroundColor Green
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
# Wiederherstellungspunkt
# ------------------------------------------------------------

New-WindowsSetupRestorePoint

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

Clear-WindowsSetupTemp


# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------

$Packages = & "$Root\config\packages\index.ps1"
$VSCode = Import-PowerShellDataFile "$Root\config\vscode.psd1"
$Browsers = Import-PowerShellDataFile "$Root\config\browsers.psd1"
$PowerShell = Import-PowerShellDataFile "$Root\config\powershell.psd1"
$PowerToys = Import-PowerShellDataFile "$Root\config\powertoys.psd1"
$Raycast = Import-PowerShellDataFile "$Root\config\raycast.psd1"
$Theme = Import-PowerShellDataFile "$Root\config\theme.psd1"
$Terminal = Import-PowerShellDataFile "$Root\config\terminal.psd1"
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

    Install-PackageGroup `
        -Packages $Packages.Gaming `
        -GroupName "Gaming"
    Install-PackageGroup -Packages $Packages.Browser -GroupName "Browser"

    Invoke-WingetQueuedChanges

    Update-MicrosoftStoreApps
}
finally {
    Clear-PackageManagerCaches
}
Install-PcVisitSupporterModule

Protect-EMClientSettings `
    -RepositoryPath $Root

Restore-EMClientSettings `
    -RepositoryPath $Root



# Pfade neu einlesen
Update-SessionPath

Initialize-WindowsSetupAgeIdentity `
    -RepositoryPath $Root

Set-PowerToysConfiguration `
    -Config $PowerToys `
    -RepositoryPath $Root
Initialize-RaycastConfiguration `
    -Config $Raycast `
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

$null = Set-WindowsComputerName `
    -Config $Windows

$taskbarChanged = Set-TaskbarPreferences `
    -Config $Windows

$startMenuChanged = Set-StartMenuPreferences `
    -Config $Windows

$windowsSnapChanged = Set-WindowsSnap `
    -Config $Windows
$windowsThemeChanged = Set-WindowsTheme `
    -Config $Windows
$null = Set-WindowsDeveloperPreferences `
    -Config $Windows
$null = Set-WindowsPowerPreferences

Set-WindowsHDR

$null = Set-WindowsWallpaperSlideshow

$windowsExplorerRestartRequired = (
    $taskbarChanged -or
    $startMenuChanged -or
    $windowsSnapChanged -or
    $windowsThemeChanged
)

# ------------------------------------------------------------
# Entwicklung
# ------------------------------------------------------------

Set-GitPreferences

Update-NeovimConfiguration `
    -RepositoryPath $Root

Set-NeovimCompilerEnvironment

Test-NeovimRequirements
Set-WindowsTerminalPreferences `
    -Config $Terminal `
    -Theme $Theme `
    -RepositoryPath $Root

Install-PowerShellModules `
    -Modules $PowerShell.Modules

Set-PowerShellPreferences

Set-LanguageEnvironment

Initialize-DevelopmentStorage `
    -Config $Storage `
    -RepositoryPath $Root

Initialize-GamesDriveDirectories `
    -Config $Storage

Initialize-GamingLauncherInstallPaths `
    -Packages $Packages.Gaming `
    -StorageConfig $Storage `
    -RepositoryPath $Root

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

$null = Set-BrowserConfiguration `
    -Config $Browsers

if ($windowsExplorerRestartRequired) {
    Restart-WindowsExplorer
}
else {
    Write-Host ""
    Write-Host "[SKIP] Windows Explorer bleibt geöffnet; kein Shell-Drift."
}

# ------------------------------------------------------------
# Peripherie
# ------------------------------------------------------------

Initialize-LogitechGHubConfiguration `
    -RepositoryPath "$Root\config\lghub"

# ------------------------------------------------------------
# Windows Updates
# ------------------------------------------------------------

$script:windowsUpdateStatus =
Install-WindowsUpdates

# ------------------------------------------------------------
# Scheduled Tasks
# ------------------------------------------------------------



$null = Register-WindowsSetupScheduledTask `
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

$script:rebootRequired =
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
