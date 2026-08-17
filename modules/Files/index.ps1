function Get-FilesPackage {
    [CmdletBinding()]
    param()

    return Get-AppxPackage `
        -Name "Files" `
        -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1
}


function Install-Files {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Files"
    Write-Host "========================================"
    Write-Host ""

    $package = Get-FilesPackage

    if ($package) {
        if ($package.PackageFamilyName -ne $Config.PackageFamilyName) {
            throw (
                "Unerwartete Files-PackageFamilyName: {0}" `
                    -f $package.PackageFamilyName
            )
        }

        Write-Host (
            "[CURRENT] Files {0} ist installiert." `
                -f $package.Version
        ) -ForegroundColor Green

        return
    }

    $windowsPowerShell = Join-Path `
        $env:SystemRoot `
        "System32\WindowsPowerShell\v1.0\powershell.exe"

    if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
        throw "Windows PowerShell 5.1 wurde nicht gefunden."
    }

    $escapedUrl = $Config.AppInstallerUrl.Replace("'", "''")

    $command = (
        "Add-AppxPackage -AppInstallerFile '{0}'" `
            -f $escapedUrl
    )

    $encodedCommand = [Convert]::ToBase64String(
        [Text.Encoding]::Unicode.GetBytes($command)
    )

    Write-Host "[INSTALL] Files über offiziellen AppInstaller."

    & $windowsPowerShell `
        -NoProfile `
        -NonInteractive `
        -ExecutionPolicy Bypass `
        -EncodedCommand $encodedCommand

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Files-AppInstaller fehlgeschlagen. Exitcode: {0}" `
                -f $LASTEXITCODE
        )
    }

    $package = Get-FilesPackage

    if (-not $package) {
        throw "Files wurde nach dem AppInstaller-Lauf nicht gefunden."
    }

    if ($package.PackageFamilyName -ne $Config.PackageFamilyName) {
        throw (
            "Unerwartete Files-PackageFamilyName nach Installation: {0}" `
                -f $package.PackageFamilyName
        )
    }

    Write-Host (
        "[OK] Files {0} installiert." `
            -f $package.Version
    ) -ForegroundColor Green
}


function Get-FilesSettingsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $package = Get-FilesPackage

    if (-not $package) {
        return $null
    }

    if ($package.PackageFamilyName -ne $Config.PackageFamilyName) {
        throw (
            "Unerwartete Files-PackageFamilyName: {0}" `
                -f $package.PackageFamilyName
        )
    }

    return Join-Path `
        $env:LOCALAPPDATA `
        (
            "Packages\{0}\LocalState\settings\user_settings.json" `
                -f $package.PackageFamilyName
        )
}


function Test-FilesSettingsCurrent {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $settingsPath = Get-FilesSettingsPath -Config $Config

    if (
        -not $settingsPath -or
        -not (Test-Path -LiteralPath $settingsPath -PathType Leaf)
    ) {
        return $false
    }

    try {
        $settings = Get-Content `
            -LiteralPath $settingsPath `
            -Raw `
            -ErrorAction Stop |
        ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $false
    }

    foreach ($name in $Config.DesiredSettings.Keys) {
        $property = $settings.PSObject.Properties[$name]

        if (-not $property) {
            return $false
        }

        if (
            [string]$property.Value -ne
            [string]$Config.DesiredSettings[$name]
        ) {
            return $false
        }
    }

    return $true
}


function Test-FilesDefaultFileManager {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $launcherPath = Join-Path `
        $env:LOCALAPPDATA `
        "Files\Files.App.Launcher.exe"

    if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
        return $false
    }

    $expectedCommand = "`"$launcherPath`" `"%1`""

    foreach ($path in @(
            "HKCU:\Software\Classes\Folder\shell\open\command",
            "HKCU:\Software\Classes\Folder\shell\explore\command"
        )) {
        if (-not (Test-Path -LiteralPath $path)) {
            return $false
        }

        $key = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue

        if (-not $key) {
            return $false
        }

        if ([string]$key.GetValue("") -ne $expectedCommand) {
            return $false
        }

        if ([string]$key.GetValue("DelegateExecute") -ne "") {
            return $false
        }
    }

    return $true
}


function Stop-FilesForConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $processes = @(
        Get-Process `
            -Name "Files" `
            -ErrorAction SilentlyContinue
    )

    if ($processes.Count -eq 0) {
        return $false
    }

    Write-Host "[INFO] Beende Files für die Konfiguration."

    $processes |
    Stop-Process `
        -Force `
        -ErrorAction Stop

    $processes |
    Wait-Process `
        -ErrorAction SilentlyContinue

    return $true
}


function Start-Files {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    Start-Process `
        -FilePath "$env:WINDIR\explorer.exe" `
        -ArgumentList (
            "shell:AppsFolder\{0}" `
                -f $Config.AppId
        )
}


function Set-FilesSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $settingsPath = Get-FilesSettingsPath -Config $Config

    if (
        -not $settingsPath -or
        -not (Test-Path -LiteralPath $settingsPath -PathType Leaf)
    ) {
        throw (
            "Files user_settings.json fehlt. " +
            "Files einmal manuell starten und wieder schließen."
        )
    }

    $settings = Get-Content `
        -LiteralPath $settingsPath `
        -Raw |
    ConvertFrom-Json

    foreach ($name in $Config.DesiredSettings.Keys) {
        $property = $settings.PSObject.Properties[$name]
        $value = $Config.DesiredSettings[$name]

        if ($property) {
            $property.Value = $value
        }
        else {
            $settings |
            Add-Member `
                -MemberType NoteProperty `
                -Name $name `
                -Value $value
        }
    }

    $json = $settings |
    ConvertTo-Json `
        -Depth 100

    [IO.File]::WriteAllText(
        $settingsPath,
        $json + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )
}


function Set-FilesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $package = Get-FilesPackage

    if (-not $package) {
        throw "Files ist nicht installiert."
    }

    $settingsPath = Get-FilesSettingsPath -Config $Config

    if (
        -not $settingsPath -or
        -not (Test-Path -LiteralPath $settingsPath -PathType Leaf)
    ) {
        Write-Warning (
            "Files ist installiert, aber user_settings.json fehlt."
        )

        Write-Host (
            "[INFO] Files einmal manuell starten und wieder schließen; " +
            "danach den Bootstrap erneut ausführen."
        )

        return
    }

    $settingsCurrent = Test-FilesSettingsCurrent -Config $Config
    $defaultFileManagerCurrent = Test-FilesDefaultFileManager

    if ($settingsCurrent -and $defaultFileManagerCurrent) {
        Write-Host (
            "[CURRENT] Files-Konfiguration ist bereits aktuell."
        ) -ForegroundColor Green

        Write-Host "[SKIP] Files bleibt geöffnet."

        return
    }

    if (-not $settingsCurrent) {
        Write-Host "[CHANGE] Files-Settings müssen aktualisiert werden."

        $wasRunning = Stop-FilesForConfiguration

        try {
            Set-FilesSettings -Config $Config
        }
        finally {
            if ($wasRunning) {
                Write-Host "[INFO] Starte Files neu."
                Start-Files -Config $Config
            }
        }

        if (-not (Test-FilesSettingsCurrent -Config $Config)) {
            throw "Files-Settings sind nach dem Schreiben nicht aktuell."
        }

        Write-Host "[OK] Files-Settings aktualisiert." -ForegroundColor Green
    }

    if (-not $defaultFileManagerCurrent) {
        Write-Warning (
            "Files ist noch nicht als Standard-Dateimanager für Win+E " +
            "registriert."
        )

        Write-Host (
            "[INFO] In Files die native Standard-Dateimanager-/Win+E-" +
            "Integration aktivieren. Registry-Sonderlösungen werden " +
            "vorerst bewusst nicht erzwungen."
        )

        return
    }

    Write-Host "[OK] Files-Default-File-Manager erkannt." -ForegroundColor Green
}
