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

Write-WindowsSetupPerformanceCheckpoint -Name "Repository Update"

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
Write-WindowsSetupPerformanceCheckpoint -Name "Source Code Preflight"

Write-Host ""
Write-Host "========================================"
Write-Host " Windows Setup"
Write-Host "========================================"
Write-Host ""

# ------------------------------------------------------------
# Module
# ------------------------------------------------------------

. "$Root\modules\index.ps1"

Write-WindowsSetupPerformanceCheckpoint -Name "Module laden"

# ------------------------------------------------------------
# Wiederherstellungspunkt
# ------------------------------------------------------------

New-WindowsSetupRestorePoint

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

Clear-WindowsSetupTemp

Write-WindowsSetupPerformanceCheckpoint -Name "Restore Point + Cleanup"


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


Write-WindowsSetupPerformanceCheckpoint -Name "Konfiguration laden"

# ------------------------------------------------------------
# Paketmanager
# ------------------------------------------------------------

Initialize-PackageManagers `
    -Packages $Packages

Write-WindowsSetupPerformanceCheckpoint -Name "Package Managers"
# ------------------------------------------------------------
# Software
# ------------------------------------------------------------


try {
    Install-PackageGroup -Packages $Packages.Base -GroupName "Basissoftware"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Base"

    Install-PackageGroup `
        -Packages $Packages.Drivers `
        -GroupName "Treiber-Tools"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Drivers"

    Install-PackageGroup -Packages $Packages.Tools -GroupName "System-Tools"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Tools"

    Install-PackageGroup `
        -Packages $Packages.HomeOffice `
        -GroupName "Home Office"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package HomeOffice"

    Install-PackageGroup -Packages $Packages.Development -GroupName "Dev-Tools"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Development"

    Install-PackageGroup `
        -Packages $Packages.Gaming `
        -GroupName "Gaming"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Gaming"
    Install-PackageGroup -Packages $Packages.Browser -GroupName "Browser"
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Browser"

    Invoke-WingetQueuedChanges
    Write-WindowsSetupPerformanceCheckpoint -Name "Winget Queue"

    Update-MicrosoftStoreApps
    Write-WindowsSetupPerformanceCheckpoint -Name "Microsoft Store Updates"
}
finally {
    Clear-PackageManagerCaches
    Write-WindowsSetupPerformanceCheckpoint -Name "Package Cache Cleanup"
}
Install-PcVisitSupporterModule
Write-WindowsSetupPerformanceCheckpoint -Name "PCVisit"

Protect-EMClientSettings `
    -RepositoryPath $Root

Write-WindowsSetupPerformanceCheckpoint -Name "eM Client Protect"

Restore-EMClientSettings `
    -RepositoryPath $Root

Write-WindowsSetupPerformanceCheckpoint -Name "eM Client Restore"
Write-WindowsSetupPerformanceCheckpoint -Name "Pakete + eM Client"



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


Write-WindowsSetupPerformanceCheckpoint -Name "App-Konfiguration"

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

Write-WindowsSetupPerformanceCheckpoint -Name "Treiber"

# ------------------------------------------------------------
# Windows
# ------------------------------------------------------------

Set-WindowsDebloat -Config $Debloat
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Debloat"

$null = Set-WindowsComputerName `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Computername"

$taskbarChanged = Set-TaskbarPreferences `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Taskbar"

$startMenuChanged = Set-StartMenuPreferences `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Start"

$windowsSnapChanged = Set-WindowsSnap `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Snap"
$windowsThemeChanged = Set-WindowsTheme `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Theme"
$null = Set-WindowsDeveloperPreferences `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Developer"
$null = Set-WindowsPowerPreferences
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Power"

$null = Set-WindowsGameMode `
    -Config $Windows
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Game Mode"

Set-WindowsHDR
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: HDR"

$null = Set-WindowsWallpaperSlideshow
Write-WindowsSetupPerformanceCheckpoint -Name "Windows: Wallpaper"

$windowsExplorerRestartRequired = (
    $taskbarChanged -or
    $startMenuChanged -or
    $windowsSnapChanged -or
    $windowsThemeChanged
)

Write-WindowsSetupPerformanceCheckpoint -Name "Windows-Konfiguration"

# ------------------------------------------------------------
# Entwicklung
# ------------------------------------------------------------

Set-GitPreferences
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Git"

Update-NeovimConfiguration `
    -RepositoryPath $Root
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Neovim Config"

Set-NeovimCompilerEnvironment
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Compiler"

Test-NeovimRequirements
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Requirements"
Set-WindowsTerminalPreferences `
    -Config $Terminal `
    -Theme $Theme `
    -RepositoryPath $Root
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Terminal"

Install-PowerShellModules `
    -Modules $PowerShell.Modules
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: PS Modules"

Set-PowerShellPreferences
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: PowerShell"

Set-LanguageEnvironment
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Languages"

Initialize-DevelopmentStorage `
    -Config $Storage `
    -RepositoryPath $Root
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Storage"

Initialize-GamesDriveDirectories `
    -Config $Storage
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Games dirs"

Initialize-GamingLauncherInstallPaths `
    -Packages $Packages.Gaming `
    -StorageConfig $Storage `
    -RepositoryPath $Root
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Launcher paths"

Install-CodexCli
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Codex"


# ------------------------------------------------------------
# VS Code
# ------------------------------------------------------------

Install-VSCodeExtensions -Extensions $VSCode.Extensions
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: VS Code Extensions"

Set-VSCodeSettings `
    -Source "$Root\dotfiles\vscode\settings.json"
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: VS Code Settings"

# ------------------------------------------------------------
# Browser Config
# ------------------------------------------------------------

$null = Set-BrowserConfiguration `
    -Config $Browsers
Write-WindowsSetupPerformanceCheckpoint -Name "Dev: Browser"

if ($windowsExplorerRestartRequired) {
    Restart-WindowsExplorer
}
else {
    Write-Host ""
    Write-Host "[SKIP] Windows Explorer bleibt geöffnet; kein Shell-Drift."
}

Write-WindowsSetupPerformanceCheckpoint -Name "Entwicklung + VS Code + Browser"

# ------------------------------------------------------------
# Peripherie
# ------------------------------------------------------------

Initialize-LogitechGHubConfiguration `
    -RepositoryPath "$Root\config\lghub"

Write-WindowsSetupPerformanceCheckpoint -Name "Peripherie"

# ------------------------------------------------------------
# Windows Updates
# ------------------------------------------------------------

$script:windowsUpdateStatus =
Install-WindowsUpdates

Write-WindowsSetupPerformanceCheckpoint -Name "Windows Updates"

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
Write-WindowsSetupPerformanceCheckpoint -Name "Scheduled Tasks + Abschlussprüfungen"
