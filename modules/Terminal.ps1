function Get-WindowsTerminalSettingsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    if (
        -not $Config.Contains("SettingsPath") -or
        [string]::IsNullOrWhiteSpace([string] $Config.SettingsPath)
    ) {
        throw "Terminal-Konfiguration enthält keinen SettingsPath."
    }

    return [Environment]::ExpandEnvironmentVariables(
        [string] $Config.SettingsPath
    )
}


function Get-WindowsTerminalRepositorySettingsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    if (
        -not $Config.Contains("RepositorySettingsPath") -or
        [string]::IsNullOrWhiteSpace([string] $Config.RepositorySettingsPath)
    ) {
        throw "Terminal-Konfiguration enthält keinen RepositorySettingsPath."
    }

    return Join-Path `
        $RepositoryPath `
        ([string] $Config.RepositorySettingsPath)
}


function Get-WindowsTerminalStateMarkerPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    if (
        -not $Config.Contains("StateMarkerPath") -or
        [string]::IsNullOrWhiteSpace([string] $Config.StateMarkerPath)
    ) {
        throw "Terminal-Konfiguration enthält keinen StateMarkerPath."
    }

    return Join-Path `
        $RepositoryPath `
        ([string] $Config.StateMarkerPath)
}


function Test-WindowsTerminalSettingsJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Windows Terminal settings.json nicht gefunden: $Path"
    }

    try {
        Get-Content `
            -LiteralPath $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json `
            -ErrorAction Stop |
        Out-Null
    }
    catch {
        throw (
            "Windows Terminal settings.json ist kein gültiges JSON: " +
            "$Path`n$($_.Exception.Message)"
        )
    }
}


function New-WindowsTerminalInitialSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Theme,

        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not $Config.Contains("Initial")) {
        throw "Terminal-Konfiguration enthält keinen Initial-Bereich."
    }

    if (-not $Config.Contains("ColorSchemeName")) {
        throw "Terminal-Konfiguration enthält keinen ColorSchemeName."
    }

    $initial = $Config.Initial
    $profileDefaults = $initial.ProfileDefaults
    $tabs = $initial.Tabs
    $schemeName = [string] $Config.ColorSchemeName

    $settings = [ordered]@{
        '$schema' = "https://aka.ms/terminal-profiles-schema"

        defaultProfile = [string] $initial.DefaultProfile

        alwaysShowTabs     = [bool] $tabs.AlwaysShow
        showTabsInTitlebar = [bool] $tabs.ShowInTitlebar
        tabWidthMode       = [string] $tabs.WidthMode
        useAcrylicInTabRow = [bool] $tabs.UseAcrylicInRow

        profiles = [ordered]@{
            defaults = [ordered]@{
                font = [ordered]@{
                    face = [string] $profileDefaults.FontFace
                    size = [int] $profileDefaults.FontSize
                }

                colorScheme = [string] $profileDefaults.ColorScheme
                cursorShape = [string] $profileDefaults.CursorShape
                useAcrylic  = [bool] $profileDefaults.UseAcrylic
                opacity     = [int] $profileDefaults.Opacity
                padding     = [string] $profileDefaults.Padding
            }

            list = @(
                foreach ($profileName in @($initial.HiddenProfiles)) {
                    [ordered]@{
                        name   = [string] $profileName
                        hidden = $true
                    }
                }
            )
        }

        schemes = @(
            [ordered]@{
                name                = $schemeName
                foreground          = $Theme.Colors.Text
                background          = $Theme.Colors.Base
                cursorColor         = $Theme.Colors.Rosewater
                selectionBackground = $Theme.Colors.Surface2

                black        = $Theme.Colors.Surface1
                red          = $Theme.Colors.Red
                green        = $Theme.Colors.Green
                yellow       = $Theme.Colors.Yellow
                blue         = $Theme.Colors.Blue
                purple       = $Theme.Colors.Pink
                cyan         = $Theme.Colors.Teal
                white        = $Theme.Colors.Subtext1

                brightBlack  = $Theme.Colors.Surface2
                brightRed    = $Theme.Colors.Red
                brightGreen  = $Theme.Colors.Green
                brightYellow = $Theme.Colors.Yellow
                brightBlue   = $Theme.Colors.Blue
                brightPurple = $Theme.Colors.Pink
                brightCyan   = $Theme.Colors.Teal
                brightWhite  = $Theme.Colors.Subtext0
            }
        )
    }

    $parent = Split-Path -Path $Path -Parent

    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
        Out-Null
    }

    $json = $settings |
    ConvertTo-Json `
        -Depth 20

    [System.IO.File]::WriteAllText(
        $Path,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    Test-WindowsTerminalSettingsJson -Path $Path

    Write-Host "[INIT] Windows Terminal settings.json erzeugt: $Path"
}


function Backup-WindowsTerminalSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SettingsPath,

        [Parameter(Mandatory)]
        [string] $RepositorySettingsPath
    )

    $existingItem = Get-Item `
        -LiteralPath $SettingsPath `
        -Force `
        -ErrorAction SilentlyContinue

    if (-not $existingItem) {
        return
    }

    if ($existingItem.LinkType -eq "HardLink") {
        return
    }

    if ($existingItem.LinkType -eq "SymbolicLink") {
        return
    }

    if (-not (Test-Path -LiteralPath $RepositorySettingsPath -PathType Leaf)) {
        return
    }

    $backupPath = "$SettingsPath.backup-before-windows-setup"

    if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
        return
    }

    Write-Host "[BACKUP] $SettingsPath -> $backupPath"

    Copy-Item `
        -LiteralPath $SettingsPath `
        -Destination $backupPath
}


function Initialize-WindowsTerminalConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Theme,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Terminal"
    Write-Host "========================================"

    $settingsPath = Get-WindowsTerminalSettingsPath `
        -Config $Config

    $repositorySettingsPath = Get-WindowsTerminalRepositorySettingsPath `
        -Config $Config `
        -RepositoryPath $RepositoryPath

    $stateMarkerPath = Get-WindowsTerminalStateMarkerPath `
        -Config $Config `
        -RepositoryPath $RepositoryPath

    $initialized = Test-Path `
        -LiteralPath $stateMarkerPath `
        -PathType Leaf

    if ($initialized) {
        if (-not (Test-Path -LiteralPath $repositorySettingsPath -PathType Leaf)) {
            throw (
                "Windows Terminal ist als initialisiert markiert, aber die " +
                "versionierte settings.json fehlt: $repositorySettingsPath"
            )
        }

        Test-WindowsTerminalSettingsJson `
            -Path $repositorySettingsPath

        Set-FileSymbolicLink `
            -Path $settingsPath `
            -Target $repositorySettingsPath `
            -ReplaceExistingFile

        Write-Host "[OK] Windows Terminal bereits initialisiert." `
            -ForegroundColor Green

        return
    }

    if (Test-Path -LiteralPath $repositorySettingsPath -PathType Leaf) {
        Write-Host (
            "[INIT] Versionierte Windows-Terminal-settings.json bereits vorhanden; " +
            "sie wird unverändert übernommen."
        )

        Test-WindowsTerminalSettingsJson `
            -Path $repositorySettingsPath
    }
    else {
        New-WindowsTerminalInitialSettings `
            -Config $Config `
            -Theme $Theme `
            -Path $repositorySettingsPath
    }

    Backup-WindowsTerminalSettings `
        -SettingsPath $settingsPath `
        -RepositorySettingsPath $repositorySettingsPath

    Set-FileSymbolicLink `
        -Path $settingsPath `
        -Target $repositorySettingsPath `
        -ReplaceExistingFile

    $stateMarkerDirectory = Split-Path `
        -Path $stateMarkerPath `
        -Parent

    if (-not (Test-Path -LiteralPath $stateMarkerDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $stateMarkerDirectory `
            -Force |
        Out-Null
    }

    [System.IO.File]::WriteAllText(
        $stateMarkerPath,
        "initialized",
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host "[OK] Windows Terminal initialisiert." `
        -ForegroundColor Green
}


function Set-WindowsTerminalPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Theme,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Initialize-WindowsTerminalConfiguration `
        -Config $Config `
        -Theme $Theme `
        -RepositoryPath $RepositoryPath
}