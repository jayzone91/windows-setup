function Get-OneCommanderSettingsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Settings\OneCommanderV3.json"
}


function Get-OneCommanderExecutablePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $paths = @(
        "$env:ProgramFiles\OneCommander\OneCommander.exe"
        "${env:ProgramFiles(x86)}\OneCommander\OneCommander.exe"
    )

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    return $null
}


function Test-OneCommanderOobeCompleted {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $settingsPath = Get-OneCommanderSettingsPath

    if (-not (Test-Path $settingsPath)) {
        return $false
    }

    try {
        $settings = Get-Content `
            -Path $settingsPath `
            -Raw |
        ConvertFrom-Json
    }
    catch {
        return $false
    }

    $roaming =
    $settings.userSettings.roaming."Rapidrive.Properties.Settings"

    if (-not $roaming) {
        return $false
    }

    return $roaming.LicenseAccepted -eq "True"
}


function Get-OneCommanderSettings {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $settingsPath = Get-OneCommanderSettingsPath

    if (-not (Test-Path $settingsPath)) {
        throw (
            "OneCommander-Einstellungen wurden nicht gefunden: " +
            $settingsPath
        )
    }

    return Get-Content `
        -Path $settingsPath `
        -Raw |
    ConvertFrom-Json
}


function Save-OneCommanderSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Settings
    )

    $settingsPath = Get-OneCommanderSettingsPath

    $Settings |
    ConvertTo-Json -Depth 30 |
    Set-Content `
        -Path $settingsPath `
        -Encoding UTF8
}


function Get-OneCommanderMachineSettings {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object] $Settings
    )

    $machineName = $env:COMPUTERNAME

    $machineKey = @(
        $Settings.userSettings.PSObject.Properties.Name |
        Where-Object {
            $_ -eq $machineName -or
            $_ -eq "PC_$machineName" -or
            $_ -like "*$machineName"
        }
    ) |
    Select-Object -First 1

    if (-not $machineKey) {
        throw (
            "Maschinenspezifische OneCommander-Einstellungen " +
            "für '$machineName' wurden nicht gefunden."
        )
    }

    $machineSettings =
    $Settings.userSettings.$machineKey."Rapidrive.Properties.Settings"

    if (-not $machineSettings) {
        throw (
            "Maschinenspezifische OneCommander-Einstellungen " +
            "für '$machineKey' wurden nicht gefunden."
        )
    }

    return $machineSettings
}


function Set-OneCommanderSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host "[INFO] Konfiguriere OneCommander."

    if (-not (Test-OneCommanderOobeCompleted)) {
        throw (
            "OneCommander-OOBE wurde noch nicht abgeschlossen. " +
            "OneCommander einmal starten und die Ersteinrichtung abschließen."
        )
    }

    $settings = Get-OneCommanderSettings
    $machineSettings = Get-OneCommanderMachineSettings -Settings $settings

    $roamingSettings =
    $settings.userSettings.roaming."Rapidrive.Properties.Settings"

    if (-not $roamingSettings) {
        throw "Roaming-Einstellungen von OneCommander wurden nicht gefunden."
    }

    #
    # Win + E
    #
    $machineSettings.UseWinEHotkey = "True"

    $roamingSettings.HotkeyChar = "E"
    $roamingSettings.HotkeySwitchesToWindow = "True"

    #
    # Explorer-Ersatz
    #
    $roamingSettings.OpenFilesThroughExplorer = "False"
    $roamingSettings.OpenRecycleBinInExplorer = "False"

    #
    # Catppuccin Mocha Theme
    #
    $roamingSettings.ThemeName = "CatppuccinMocha"
    $roamingSettings.UseSystemTheme = "False"
    $roamingSettings.UseSystemAccentColor = "False"
    $roamingSettings.AccentColor = "#FFCBA6F7"

    #
    # Folder Icons
    #
    # OneCommander zeigt im Auswahlfeld den Dateinamen ohne .png an.
    # Das PNG selbst liegt unter Resources\MainFolderIcon\CatppuccinMocha.png.
    #
    $mainFolderIconSource = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons\MainFolderIcon\CatppuccinMocha.png"

    if (Test-Path $mainFolderIconSource) {
        $roamingSettings.MainFolderIcon = "CatppuccinMocha"
    }

    $folderIconsSource = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons\FolderIcons\CatppuccinMocha"

    if (Test-Path $folderIconsSource) {
        $roamingSettings.FolderIconsTheme = "CatppuccinMocha"
    }

    #
    # File Icons erst aktivieren, wenn das Pack wirklich existiert.
    #
    $fileIconsSource = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons\FileIcons\CatppuccinMocha"

    if (Test-Path $fileIconsSource) {
        $roamingSettings.FileIconsTheme = "CatppuccinMocha"
    }

    #
    # Datei-Alter-Farben
    #
    $roamingSettings.UseFileAgeColor = "True"
    $roamingSettings.FileAgeType = "var"
    $roamingSettings.FileAgeLuma = "105"
    $roamingSettings.FileAgeSaturation = "80"

    Save-OneCommanderSettings `
        -Settings $settings

    Write-Host (
        "[OK] OneCommander-Einstellungen aktualisiert."
    ) -ForegroundColor Green
}


function Set-OneCommanderDefaultFileManager {
    [CmdletBinding()]
    param()

    $exe = Get-OneCommanderExecutablePath

    if (-not $exe) {
        throw "OneCommander.exe wurde nicht gefunden."
    }

    Write-Host "[INFO] Registriere OneCommander als Standard-Dateimanager."

    #
    # Directory
    #
    $directoryShell =
    "HKCU:\Software\Classes\Directory\shell"

    $directoryEntry =
    Join-Path `
        $directoryShell `
        "OpenInOneCommander"

    $directoryCommand =
    Join-Path `
        $directoryEntry `
        "command"

    New-Item `
        -Path $directoryEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $directoryCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $directoryEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $directoryEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $directoryCommand `
        -Value "`"$exe`" -`"%1`""

    Set-Item `
        -Path $directoryShell `
        -Value "OpenInOneCommander"

    #
    # Directory Background
    #
    $directoryBackgroundEntry =
    "HKCU:\Software\Classes\Directory\Background\shell\OpenInOneCommander"

    $directoryBackgroundCommand =
    Join-Path `
        $directoryBackgroundEntry `
        "command"

    New-Item `
        -Path $directoryBackgroundEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $directoryBackgroundCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $directoryBackgroundEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $directoryBackgroundEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $directoryBackgroundCommand `
        -Value "`"$exe`" -`"%W`""

    #
    # Drive
    #
    $driveShell =
    "HKCU:\Software\Classes\Drive\shell"

    $driveEntry =
    Join-Path `
        $driveShell `
        "OpenInOneCommander"

    $driveCommand =
    Join-Path `
        $driveEntry `
        "command"

    New-Item `
        -Path $driveEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $driveCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $driveEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $driveEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $driveCommand `
        -Value "`"$exe`" -`"%1`""

    Set-Item `
        -Path $driveShell `
        -Value "OpenInOneCommander"

    #
    # Drive Background
    #
    $driveBackgroundEntry =
    "HKCU:\Software\Classes\Drive\background\shell\OpenInOneCommander"

    $driveBackgroundCommand =
    Join-Path `
        $driveBackgroundEntry `
        "command"

    New-Item `
        -Path $driveBackgroundEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $driveBackgroundCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $driveBackgroundEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $driveBackgroundEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $driveBackgroundCommand `
        -Value "`"$exe`" -`"%W`""

    #
    # Explorer OpenNewWindow / Win + E
    #
    $clsidCommand =
    "HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command"

    New-Item `
        -Path $clsidCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $clsidCommand `
        -Value $exe

    New-ItemProperty `
        -Path $clsidCommand `
        -Name "DelegateExecute" `
        -PropertyType String `
        -Value "" `
        -Force |
    Out-Null

    Write-Host (
        "[OK] OneCommander als Standard-Dateimanager registriert."
    ) -ForegroundColor Green
}


function Set-DirectoryJunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-Path $Target)) {
        throw "Junction-Ziel existiert nicht: $Target"
    }

    $parent = Split-Path `
        -Path $Path `
        -Parent

    if (-not (Test-Path $parent)) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
        Out-Null
    }

    if (Test-Path $Path) {
        $item = Get-Item `
            -Path $Path `
            -Force

        if (
            $item.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) {
            $currentTarget = [string] $item.Target

            if ($currentTarget -eq $Target) {
                Write-Host "[OK] Junction bereits korrekt: $Path"
                return
            }

            Remove-Item `
                -Path $Path `
                -Force
        }
        else {
            throw (
                "Pfad existiert bereits und ist keine Junction: " +
                $Path
            )
        }
    }

    New-Item `
        -ItemType Junction `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[OK] Junction erstellt: " +
        "$Path -> $Target"
    ) -ForegroundColor Green
}


function Install-OneCommanderTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $source = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Themes\CatppuccinMocha"

    $destination = Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Themes\CatppuccinMocha"

    Set-DirectoryJunction `
        -Path $destination `
        -Target $source
}


function Remove-OneCommanderGeneratedIconCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        return
    }

    Get-ChildItem `
        -Path $Path `
        -Directory `
        -Force `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^\d+$'
    } |
    ForEach-Object {
        Write-Host (
            "[INFO] Entferne generierten OneCommander-Icon-Cache: " +
            $_.FullName
        )

        Remove-Item `
            -Path $_.FullName `
            -Recurse `
            -Force
    }
}


function Install-OneCommanderIcons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $buildFileIconsScript = Join-Path `
    (Split-Path -Path $PSScriptRoot -Parent) `
        "scripts\Build-OneCommanderFileIcons.ps1"

    if (Test-Path $buildFileIconsScript) {
        . $buildFileIconsScript
    }

    $iconsRoot = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons"

    #
    # Main Folder Icon
    #
    # OneCommander erwartet diese Datei direkt im MainFolderIcon-Verzeichnis.
    # Einzeldateien werden deshalb bewusst kopiert; Theme-Packs bleiben Junctions.
    #
    $mainFolderIconSource = Join-Path `
        $iconsRoot `
        "MainFolderIcon\CatppuccinMocha.png"

    if (-not (Test-Path $mainFolderIconSource)) {
        throw (
            "Catppuccin Main Folder Icon nicht vorhanden: " +
            $mainFolderIconSource
        )
    }

    $mainFolderIconDirectory = Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Resources\MainFolderIcon"

    $mainFolderIconDestination = Join-Path `
        $mainFolderIconDirectory `
        "CatppuccinMocha.png"

    New-Item `
        -ItemType Directory `
        -Path $mainFolderIconDirectory `
        -Force |
    Out-Null

    if (Test-Path $mainFolderIconDestination) {
        $item = Get-Item `
            -Path $mainFolderIconDestination `
            -Force

        if (
            $item.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) {
            Remove-Item `
                -Path $mainFolderIconDestination `
                -Force
        }
    }

    Copy-Item `
        -Path $mainFolderIconSource `
        -Destination $mainFolderIconDestination `
        -Force

    Write-Host (
        "[OK] Catppuccin Main Folder Icon installiert."
    ) -ForegroundColor Green

    #
    # Folder Icon Theme
    #
    $folderIconsSource = Join-Path `
        $iconsRoot `
        "FolderIcons\CatppuccinMocha"

    if (Test-Path $folderIconsSource) {
        Remove-OneCommanderGeneratedIconCache `
            -Path $folderIconsSource

        Set-DirectoryJunction `
            -Path (
            Join-Path `
                $env:LOCALAPPDATA `
                "OneCommander\Resources\FolderIcons\CatppuccinMocha"
        ) `
            -Target $folderIconsSource
    }
    else {
        Write-Host (
            "[INFO] Catppuccin Folder-Icon-Theme noch nicht vorhanden."
        )
    }

    #
    # File Icon Theme
    #
    $fileIconsSource = Join-Path `
        $RepositoryPath `
        ".generated\onecommander\FileIcons\CatppuccinMocha"

    $fileIconsManifest = Join-Path `
        $fileIconsSource `
        "_manifest.json"

    if (-not (Test-Path $fileIconsManifest)) {
        Write-Host (
            "[INFO] Catppuccin File-Icons fehlen. " +
            "Erzeuge vollständiges Icon-Pack."
        )

        Build-OneCommanderFileIcons `
            -RepositoryPath $RepositoryPath
    }

    if (-not (Test-Path $fileIconsManifest)) {
        throw (
            "Catppuccin File-Icon-Pack konnte nicht erzeugt werden: " +
            $fileIconsSource
        )
    }

    Remove-OneCommanderGeneratedIconCache `
        -Path $fileIconsSource

    Set-DirectoryJunction `
        -Path (
        Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Resources\FileIcons\CatppuccinMocha"
    ) `
        -Target $fileIconsSource
}


function Stop-OneCommanderForConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $processes = @(
        Get-Process `
            -Name "OneCommander" `
            -ErrorAction SilentlyContinue
    )

    if ($processes.Count -eq 0) {
        return $false
    }

    Write-Host "[INFO] Beende OneCommander für die Konfiguration."

    $processes |
    Stop-Process `
        -Force `
        -ErrorAction Stop

    $processes |
    Wait-Process `
        -ErrorAction SilentlyContinue

    return $true
}


function Start-OneCommander {
    [CmdletBinding()]
    param()

    $exe = Get-OneCommanderExecutablePath

    if (-not $exe) {
        throw "OneCommander.exe wurde nicht gefunden."
    }

    Start-Process `
        -FilePath $exe
}


function Set-OneCommanderConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " OneCommander"
    Write-Host "========================================"
    Write-Host ""

    if (-not (Test-OneCommanderOobeCompleted)) {
        Write-Warning (
            "OneCommander ist installiert, aber die OOBE wurde noch nicht abgeschlossen."
        )

        Write-Host (
            "[INFO] OneCommander einmal manuell starten und " +
            "die Ersteinrichtung abschließen."
        )

        return
    }

    $wasRunning = Stop-OneCommanderForConfiguration

    try {
        Install-OneCommanderTheme `
            -RepositoryPath $RepositoryPath

        Install-OneCommanderIcons `
            -RepositoryPath $RepositoryPath

        Set-OneCommanderSettings `
            -RepositoryPath $RepositoryPath

        Set-OneCommanderDefaultFileManager
    }
    finally {
        if ($wasRunning) {
            Write-Host "[INFO] Starte OneCommander neu."
            Start-OneCommander
        }
    }
}

function Set-FileHardLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-Path $Target)) {
        throw "Hardlink-Ziel existiert nicht: $Target"
    }

    $parent = Split-Path `
        -Path $Path `
        -Parent

    if (-not (Test-Path $parent)) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
        Out-Null
    }

    if (Test-Path $Path) {
        Remove-Item `
            -Path $Path `
            -Force
    }

    New-Item `
        -ItemType HardLink `
        -Path $Path `
        -Target $Target |
    Out-Null
}
