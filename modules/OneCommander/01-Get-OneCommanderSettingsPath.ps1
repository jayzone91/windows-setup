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
        $machineCandidates = @(
            $Settings.userSettings.PSObject.Properties |
            Where-Object {
                $_.Name -ne "roaming" -and
                $null -ne $_.Value."Rapidrive.Properties.Settings"
            }
        )

        if ($machineCandidates.Count -ne 1) {
            throw (
                "Maschinenspezifische OneCommander-Einstellungen " +
                "für '$machineName' wurden nicht gefunden. " +
                "Als Fallback wurde kein eindeutiger vorhandener Maschinenblock " +
                "ermittelt; Kandidaten: $($machineCandidates.Count)."
            )
        }

        $machineKey = $machineCandidates[0].Name

        Write-Host (
            "[INFO] OneCommander verwendet den eindeutigen vorhandenen " +
            "Maschinenblock '$machineKey' für '$machineName'."
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
    # Catppuccin File Icons
    #
    $fileIconsSource = Join-Path `
        $RepositoryPath `
        ".generated\onecommander\FileIcons\CatppuccinMocha"

    $fileIconsManifest = Join-Path `
        $fileIconsSource `
        "_manifest.json"

    if (-not (Test-Path $fileIconsManifest)) {
        throw (
            "Catppuccin File-Icon-Pack wurde nicht gefunden: " +
            $fileIconsSource
        )
    }

    $roamingSettings.FileIconsTheme = "CatppuccinMocha"

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