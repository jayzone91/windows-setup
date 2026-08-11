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

function Disable-WindowsSnap {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Snap"
    Write-Host "========================================"

    $changed = $false
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $explorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    $currentArrangement = Get-ItemPropertyValue `
        -Path $desktopPath `
        -Name "WindowArrangementActive" `
        -ErrorAction SilentlyContinue

    if ([string] $currentArrangement -ne "0") {
        Set-ItemProperty `
            -Path $desktopPath `
            -Name "WindowArrangementActive" `
            -Value "0" `
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
                -Value 0
        ) {
            $changed = $true
        }
    }

    if ($changed) {
        Write-Host "[OK] Windows Snap deaktiviert/aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Windows Snap bereits im Desired State." `
            -ForegroundColor Green
    }

    return $changed
}
