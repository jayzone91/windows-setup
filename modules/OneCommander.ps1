function Get-OneCommanderSettingsPath {
    [CmdletBinding()]
    param()

    return Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Settings\OneCommanderV3.json"
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

    $roaming = $settings.userSettings.roaming."Rapidrive.Properties.Settings"

    if (-not $roaming) {
        return $false
    }

    return $roaming.LicenseAccepted -eq "True"
}


function Get-OneCommanderSettings {
    [CmdletBinding()]
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


function Set-OneCommanderSettings {
    [CmdletBinding()]
    param()

    Write-Host "[INFO] Konfiguriere OneCommander."

    if (-not (Test-OneCommanderOobeCompleted)) {
        Write-Warning (
            "OneCommander-OOBE wurde noch nicht abgeschlossen. " +
            "OneCommander einmal starten und die Ersteinrichtung abschließen."
        )

        return
    }

    $settings = Get-OneCommanderSettings

    $machineName = $env:COMPUTERNAME

    $machineKey = @(
        $settings.userSettings.PSObject.Properties.Name |
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
    $settings.userSettings.$machineKey."Rapidrive.Properties.Settings"

    $roamingSettings =
    $settings.userSettings.roaming."Rapidrive.Properties.Settings"

    if (-not $machineSettings) {
        throw (
            "Maschinenspezifische OneCommander-Einstellungen " +
            "für '$machineKey' wurden nicht gefunden."
        )
    }

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
    # Theme-Grundlagen
    #
    $roamingSettings.UseSystemTheme = "False"
    $roamingSettings.UseSystemAccentColor = "False"

    #
    # Icon Pack
    #
    $roamingSettings.MainFolderIcon = "CatppuccinMocha.png"
    $roamingSettings.FolderIconsTheme = "CatppuccinMocha"
    $roamingSettings.FolderIconsTheme = "CatppuccinMocha"

    #
    # Catppuccin Mocha Accent
    #
    $roamingSettings.ThemeName = "CatppuccinMocha"
    $roamingSettings.UseSystemTheme = "False"
    $roamingSettings.UseSystemAccentColor = "False"
    $roamingSettings.AccentColor = "#FFCBA6F7"


    #
    # Datei Alter Farben
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


function Get-OneCommanderExecutablePath {
    [CmdletBinding()]
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

    Set-Item `
        -Path $directoryCommand `
        -Value "`"$exe`" -`"%1`""

    Set-ItemProperty `
        -Path $directoryShell `
        -Name "(default)" `
        -Value "OpenInOneCommander" `
        -ErrorAction SilentlyContinue

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

    Set-Item `
        -Path $driveCommand `
        -Value "`"$exe`" -`"%1`""

    Set-ItemProperty `
        -Path $driveShell `
        -Name "(default)" `
        -Value "OpenInOneCommander" `
        -ErrorAction SilentlyContinue

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

    Set-Item `
        -Path $driveBackgroundCommand `
        -Value "`"$exe`" -`"%W`""

    #
    # Explorer OpenNewWindow / Win+E
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

    Install-OneCommanderTheme `
        -RepositoryPath $RepositoryPath

    Install-OneCommanderIcons `
        -RepositoryPath $RepositoryPath

    Set-OneCommanderSettings
    Set-OneCommanderDefaultFileManager
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
            $currentTarget = $item.Target

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

function Set-FileSymbolicLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-Path $Target)) {
        throw "Symlink-Ziel existiert nicht: $Target"
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
            $currentTarget = $item.Target

            if ($currentTarget -eq $Target) {
                Write-Host "[OK] Symlink bereits korrekt: $Path"
                return
            }

            Remove-Item `
                -Path $Path `
                -Force
        }
        else {
            throw (
                "Pfad existiert bereits und ist kein Symlink: " +
                $Path
            )
        }
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[OK] Symlink erstellt: " +
        "$Path -> $Target"
    ) -ForegroundColor Green
}

function Install-OneCommanderIcons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $iconsRoot = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons"

    #
    # Main Folder Icon
    #
    $mainFolderIconSource = Join-Path `
        $iconsRoot `
        "MainFolderIcon\CatppuccinMocha.png"

    if (Test-Path $mainFolderIconSource) {
        Set-FileSymbolicLink `
            -Path (
            Join-Path `
                $env:LOCALAPPDATA `
                "OneCommander\Resources\MainFolderIcon\CatppuccinMocha.png"
        ) `
            -Target $mainFolderIconSource
    }
    else {
        Write-Warning (
            "Catppuccin Main Folder Icon noch nicht vorhanden: " +
            $mainFolderIconSource
        )
    }

    #
    # Folder Icon Theme
    #
    $folderIconsSource = Join-Path `
        $iconsRoot `
        "FolderIcons\CatppuccinMocha"

    if (Test-Path $folderIconsSource) {
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
        $iconsRoot `
        "FileIcons\CatppuccinMocha"

    if (Test-Path $fileIconsSource) {
        Set-DirectoryJunction `
            -Path (
            Join-Path `
                $env:LOCALAPPDATA `
                "OneCommander\Resources\FileIcons\CatppuccinMocha"
        ) `
            -Target $fileIconsSource
    }
    else {
        Write-Host (
            "[INFO] Catppuccin File-Icon-Theme noch nicht vorhanden."
        )
    }
}
