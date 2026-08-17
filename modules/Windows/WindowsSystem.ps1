function Set-WindowsComputerName {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Computername"
    Write-Host "========================================"

    if (-not $Config.ContainsKey("ComputerName")) {
        throw "ComputerName fehlt in config/windows.psd1."
    }

    $desiredName = [string] $Config.ComputerName

    if ([string]::IsNullOrWhiteSpace($desiredName)) {
        throw "ComputerName in config/windows.psd1 darf nicht leer sein."
    }

    if ($desiredName.Length -gt 15) {
        throw "ComputerName darf maximal 15 Zeichen lang sein: '$desiredName'."
    }

    if ($desiredName -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$' -and $desiredName.Length -gt 1) {
        throw (
            "ComputerName enthält ungültige Zeichen oder endet mit einem Bindestrich: " +
            "'$desiredName'. Erlaubt sind Buchstaben, Ziffern und Bindestriche."
        )
    }

    if ($desiredName.Length -eq 1 -and $desiredName -notmatch '^[A-Za-z0-9]$') {
        throw "ComputerName enthält ein ungültiges Zeichen: '$desiredName'."
    }

    if ($desiredName -match '^\d+$') {
        throw "ComputerName darf nicht ausschließlich aus Ziffern bestehen: '$desiredName'."
    }

    $currentName = [System.Net.Dns]::GetHostName()

    if ($currentName.Equals($desiredName, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "[SKIP] Computername bereits im Desired State: $currentName." `
            -ForegroundColor Green
        return $false
    }

    Rename-Computer `
        -NewName $desiredName `
        -Force `
        -ErrorAction Stop

    $message = (
        "[OK] Computername von '{0}' auf '{1}' geändert. " +
        "Die Änderung wird nach dem nächsten Neustart vollständig wirksam."
    ) -f $currentName, $desiredName

    Write-Host $message -ForegroundColor Green

    return $true
}
function Set-WindowsDeveloperPreferences {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Entwickler-Grundzustand"
    Write-Host "========================================"

    if (-not $Config.ContainsKey("System")) {
        throw "System fehlt in config/windows.psd1."
    }

    $changed = $false
    $systemConfig = $Config.System

    if (
        -not $systemConfig.ContainsKey("Sudo") -or
        -not $systemConfig.Sudo.ContainsKey("Enabled") -or
        -not $systemConfig.Sudo.ContainsKey("Mode")
    ) {
        throw "System.Sudo.Enabled oder System.Sudo.Mode fehlt in config/windows.psd1."
    }

    $sudoModeValues = @{
        forceNewWindow = 1
        disableInput   = 2
        normal         = 3
    }

    $sudoEnabled = [bool] $systemConfig.Sudo.Enabled
    $sudoMode = [string] $systemConfig.Sudo.Mode

    if ($sudoEnabled -and -not $sudoModeValues.ContainsKey($sudoMode)) {
        throw "Ungültiger Windows-Sudo-Modus: '$sudoMode'."
    }

    $windowsBuild = [Environment]::OSVersion.Version.Build

    if ($sudoEnabled -and $windowsBuild -lt 26100) {
        Write-Warning (
            "Windows Sudo benötigt Windows 11 24H2 / Build 26100 oder neuer. " +
            "Aktueller Build: $windowsBuild."
        )
    }
    else {
        $sudoPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sudo"
        $sudoPolicyValue = if ($sudoEnabled) {
            [int] $sudoModeValues[$sudoMode]
        }
        else {
            0
        }

        if (
            Set-RegistryDword `
                -Path $sudoPolicyPath `
                -Name "EnableSudo" `
                -Value $sudoPolicyValue
        ) {
            $changed = $true
            Write-Host "[CONFIG] Windows Sudo: Enabled=$sudoEnabled, Mode=$sudoMode."
        }
    }

    if (-not $systemConfig.ContainsKey("DeveloperMode")) {
        throw "System.DeveloperMode fehlt in config/windows.psd1."
    }

    $developerModeValue = if ([bool] $systemConfig.DeveloperMode) { 1 } else { 0 }

    if (
        Set-RegistryDword `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
            -Name "AllowDevelopmentWithoutDevLicense" `
            -Value $developerModeValue
    ) {
        $changed = $true
        Write-Host "[CONFIG] Windows Entwicklermodus: $([bool] $systemConfig.DeveloperMode)."
    }

    if (-not $systemConfig.ContainsKey("LongPaths")) {
        throw "System.LongPaths fehlt in config/windows.psd1."
    }

    $longPathsValue = if ([bool] $systemConfig.LongPaths) { 1 } else { 0 }

    if (
        Set-RegistryDword `
            -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            -Name "LongPathsEnabled" `
            -Value $longPathsValue
    ) {
        $changed = $true
        Write-Host "[CONFIG] Lange Win32-Pfade: $([bool] $systemConfig.LongPaths)."
    }

    if ($changed) {
        Write-Host "[OK] Windows Entwickler-Grundzustand aktualisiert." -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Windows Entwickler-Grundzustand bereits aktuell." -ForegroundColor Green
    }

    return $changed
}

function Set-WindowsPowerPreferences {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "powercfg ist ein natives Windows-Programm und verwendet die dokumentierte positionsbasierte CLI-Syntax."
    )]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Energieoptionen"
    Write-Host "========================================"

    function Get-PowerSettingIndexes {
        param(
            [Parameter(Mandatory)]
            [string] $SubGroup,

            [Parameter(Mandatory)]
            [string] $Setting
        )

        $output = @(
            & powercfg /query SCHEME_CURRENT $SubGroup $Setting 2>&1
        )

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Powercfg-Setting konnte nicht gelesen werden: {0}/{1}. {2}" -f
                $SubGroup,
                $Setting,
                ($output -join " ")
            )
        }

        $hexMatches = [regex]::Matches(
            ($output -join "`n"),
            '0x(?<value>[0-9a-fA-F]+)'
        )

        if ($hexMatches.Count -lt 2) {
            throw (
                "Powercfg-Ausgabe für {0}/{1} konnte nicht ausgewertet werden." -f
                $SubGroup,
                $Setting
            )
        }

        return [pscustomobject]@{
            AC = [Convert]::ToUInt32(
                $hexMatches[$hexMatches.Count - 2].Groups["value"].Value,
                16
            )
            DC = [Convert]::ToUInt32(
                $hexMatches[$hexMatches.Count - 1].Groups["value"].Value,
                16
            )
        }
    }

    $changed = $false

    $monitor = Get-PowerSettingIndexes `
        -SubGroup "SUB_VIDEO" `
        -Setting "VIDEOIDLE"

    if ($monitor.AC -ne 0) {
        & powercfg /change monitor-timeout-ac 0

        if ($LASTEXITCODE -ne 0) {
            throw "AC-Monitor-Timeout konnte nicht deaktiviert werden."
        }

        $changed = $true
    }

    if ($monitor.DC -ne 0) {
        & powercfg /change monitor-timeout-dc 0

        if ($LASTEXITCODE -ne 0) {
            throw "DC-Monitor-Timeout konnte nicht deaktiviert werden."
        }

        $changed = $true
    }

    $standby = Get-PowerSettingIndexes `
        -SubGroup "SUB_SLEEP" `
        -Setting "STANDBYIDLE"

    if ($standby.AC -ne 0) {
        & powercfg /change standby-timeout-ac 0

        if ($LASTEXITCODE -ne 0) {
            throw "AC-Standby-Timeout konnte nicht deaktiviert werden."
        }

        $changed = $true
    }

    if ($standby.DC -ne 0) {
        & powercfg /change standby-timeout-dc 0

        if ($LASTEXITCODE -ne 0) {
            throw "DC-Standby-Timeout konnte nicht deaktiviert werden."
        }

        $changed = $true
    }

    $hibernateEnabled = Get-ItemPropertyValue `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" `
        -Name "HibernateEnabled" `
        -ErrorAction SilentlyContinue

    if ($null -eq $hibernateEnabled -or [int]$hibernateEnabled -ne 0) {
        & powercfg /hibernate off

        if ($LASTEXITCODE -ne 0) {
            throw "Ruhezustand konnte nicht deaktiviert werden."
        }

        $changed = $true
    }

    if ($changed) {
        Write-Host "[OK] Energieoptionen aktualisiert." -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Energieoptionen unverändert." -ForegroundColor Green
    }

    return $changed
}

function Set-WindowsHDR {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " HDR"
    Write-Host "========================================"

    Write-Warning (
        "HDR kann auf diesem System aktuell nicht zuverlässig " +
        "über die Windows DisplayConfig API automatisiert werden."
    )

    Write-Host (
        "[INFO] HDR bitte einmalig über " +
        "'Einstellungen > System > Anzeige > HDR' aktivieren."
    )
}

function Set-WindowsSnap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Snap"
    Write-Host "========================================"

    if (
        -not $Config.Contains("WindowManagement") -or
        -not $Config.WindowManagement.Contains("Snap") -or
        -not $Config.WindowManagement.Snap.Contains("Enabled")
    ) {
        throw "WindowManagement.Snap.Enabled fehlt in config/windows.psd1."
    }

    $enabled = [bool] $Config.WindowManagement.Snap.Enabled
    $desiredDword = if ($enabled) { 1 } else { 0 }
    $desiredString = if ($enabled) { "1" } else { "0" }
    $changed = $false
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $explorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    $currentArrangement = Get-ItemPropertyValue `
        -Path $desktopPath `
        -Name "WindowArrangementActive" `
        -ErrorAction SilentlyContinue

    if ([string] $currentArrangement -ne $desiredString) {
        Set-ItemProperty `
            -Path $desktopPath `
            -Name "WindowArrangementActive" `
            -Value $desiredString `
            -ErrorAction Stop

        $changed = $true
    }

    foreach ($name in @(
            "EnableSnapAssistFlyout",
            "EnableSnapBar"
        )) {
        if (
            Set-RegistryDword `
                -Path $explorerAdvancedPath `
                -Name $name `
                -Value $desiredDword
        ) {
            $changed = $true
        }
    }

    if ($changed) {
        Write-Host "[OK] Windows Snap aktualisiert. Enabled=$enabled." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Windows Snap bereits im Desired State." `
            -ForegroundColor Green
    }

    return $changed
}