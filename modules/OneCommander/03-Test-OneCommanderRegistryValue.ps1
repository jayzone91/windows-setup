function Test-OneCommanderRegistryValue {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $ExpectedValue,

        [string] $Name = "(default)"
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    try {
        if ($Name -eq "(default)") {
            $actualValue = (Get-Item -Path $Path -ErrorAction Stop).GetValue("")
        }
        else {
            $actualValue = Get-ItemPropertyValue `
                -Path $Path `
                -Name $Name `
                -ErrorAction Stop
        }
    }
    catch {
        return $false
    }

    return [string]$actualValue -eq $ExpectedValue
}


function Test-OneCommanderConfigurationCurrent {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    try {
        $settings = Get-OneCommanderSettings
        $machineSettings = Get-OneCommanderMachineSettings `
            -Settings $settings

        $roamingSettings =
        $settings.userSettings.roaming."Rapidrive.Properties.Settings"

        if (-not $roamingSettings) {
            return $false
        }

        $desiredMachineSettings = @{
            UseWinEHotkey = "True"
        }

        $desiredRoamingSettings = @{
            HotkeyChar               = "E"
            HotkeySwitchesToWindow   = "True"
            OpenFilesThroughExplorer = "False"
            OpenRecycleBinInExplorer = "False"
            ThemeName                = "CatppuccinMocha"
            UseSystemTheme           = "False"
            UseSystemAccentColor     = "False"
            AccentColor              = "#FFCBA6F7"
            MainFolderIcon           = "CatppuccinMocha"
            FolderIconsTheme         = "CatppuccinMocha"
            FileIconsTheme           = "CatppuccinMocha"
            UseFileAgeColor          = "True"
            FileAgeType              = "var"
            FileAgeLuma              = "105"
            FileAgeSaturation        = "80"
        }

        foreach ($name in $desiredMachineSettings.Keys) {
            if (
                [string]$machineSettings.$name -ne
                [string]$desiredMachineSettings[$name]
            ) {
                return $false
            }
        }

        foreach ($name in $desiredRoamingSettings.Keys) {
            if (
                [string]$roamingSettings.$name -ne
                [string]$desiredRoamingSettings[$name]
            ) {
                return $false
            }
        }

        $themeSource = Join-Path `
            $RepositoryPath `
            "dotfiles\onecommander\Themes\CatppuccinMocha"

        $themeDestination = Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Themes\CatppuccinMocha"

        if (
            -not (
                Test-OneCommanderJunction `
                    -Path $themeDestination `
                    -Target $themeSource
            )
        ) {
            return $false
        }

        $iconsRoot = Join-Path `
            $RepositoryPath `
            "dotfiles\onecommander\Icons"

        $mainFolderIconSource = Join-Path `
            $iconsRoot `
            "MainFolderIcon\CatppuccinMocha.png"

        $mainFolderIconDestination = Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Resources\MainFolderIcon\CatppuccinMocha.png"

        if (
            -not (Test-Path $mainFolderIconSource) -or
            -not (Test-Path $mainFolderIconDestination)
        ) {
            return $false
        }

        $sourceHash = (
            Get-FileHash `
                -Path $mainFolderIconSource `
                -Algorithm SHA256
        ).Hash

        $destinationHash = (
            Get-FileHash `
                -Path $mainFolderIconDestination `
                -Algorithm SHA256
        ).Hash

        if ($sourceHash -ne $destinationHash) {
            return $false
        }

        $folderIconsSource = Join-Path `
            $iconsRoot `
            "FolderIcons\CatppuccinMocha"

        $folderIconsDestination = Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Resources\FolderIcons\CatppuccinMocha"

        if (
            -not (
                Test-OneCommanderJunction `
                    -Path $folderIconsDestination `
                    -Target $folderIconsSource
            )
        ) {
            return $false
        }

        $fileIconsSource = Join-Path `
            $RepositoryPath `
            ".generated\onecommander\FileIcons\CatppuccinMocha"

        $fileIconsManifest = Join-Path `
            $fileIconsSource `
            "_manifest.json"

        $fileIconsDestination = Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Resources\FileIcons\CatppuccinMocha"

        if (
            -not (Test-Path $fileIconsManifest) -or
            -not (
                Test-OneCommanderJunction `
                    -Path $fileIconsDestination `
                    -Target $fileIconsSource
            )
        ) {
            return $false
        }

        $exe = Get-OneCommanderExecutablePath

        if (-not $exe) {
            return $false
        }

        $registryChecks = @(
            @{
                Path  = "HKCU:\Software\Classes\Directory\shell"
                Value = "OpenInOneCommander"
            },
            @{
                Path  = "HKCU:\Software\Classes\Directory\shell\OpenInOneCommander\command"
                Value = "`"$exe`" -`"%1`""
            },
            @{
                Path  = "HKCU:\Software\Classes\Drive\shell"
                Value = "OpenInOneCommander"
            },
            @{
                Path  = "HKCU:\Software\Classes\Drive\shell\OpenInOneCommander\command"
                Value = "`"$exe`" -`"%1`""
            },
            @{
                Path  = "HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command"
                Value = $exe
            }
        )

        foreach ($check in $registryChecks) {
            if (
                -not (
                    Test-OneCommanderRegistryValue `
                        -Path $check.Path `
                        -ExpectedValue $check.Value
                )
            ) {
                return $false
            }
        }

        $clsidCommand =
        "HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command"

        if (
            -not (
                Test-OneCommanderRegistryValue `
                    -Path $clsidCommand `
                    -Name "DelegateExecute" `
                    -ExpectedValue ""
            )
        ) {
            return $false
        }

        return $true
    }
    catch {
        Write-Host (
            "[INFO] OneCommander-Precheck konnte nicht vollständig " +
            "ausgeführt werden: {0}" `
                -f $_.Exception.Message
        )

        return $false
    }
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


    if (
        Test-OneCommanderConfigurationCurrent `
            -RepositoryPath $RepositoryPath
    ) {
        Write-Host (
            "[CURRENT] OneCommander-Konfiguration ist bereits aktuell."
        ) -ForegroundColor Green

        Write-Host "[SKIP] OneCommander bleibt geöffnet."

        return
    }

    Write-Host (
        "[CHANGE] OneCommander-Konfiguration muss aktualisiert werden."
    )

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

