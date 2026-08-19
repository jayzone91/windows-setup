function New-WindowsSetupRestorePoint {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Windows PowerShell 5.1 wird als externer Prozess mit regulären CLI-Argumenten aufgerufen."
    )]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Systemwiederherstellungspunkt"
    Write-Host "========================================"

    $windowsPowerShell = Join-Path `
        $env:SystemRoot `
        "System32\WindowsPowerShell\v1.0\powershell.exe"

    if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
        throw "Windows PowerShell 5.1 für System Restore wurde nicht gefunden."
    }

    $latestRestorePointTime = $null

    $restorePointCommand = (
        '$ErrorActionPreference = "Stop"; ' +
        '$restorePoint = Get-ComputerRestorePoint | ' +
        'Sort-Object SequenceNumber -Descending | ' +
        'Select-Object -First 1; ' +
        'if ($restorePoint) { ' +
        '[Management.ManagementDateTimeConverter]::ToDateTime(' +
        '$restorePoint.CreationTime).ToString("o") }'
    )

    $restorePointOutput = @(
        & $windowsPowerShell `
            -NoProfile `
            -NonInteractive `
            -Command $restorePointCommand `
            2>&1
    )

    if ($LASTEXITCODE -eq 0) {
        $latestRestorePointValue = (
            $restorePointOutput |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Last 1
        )

        if ($latestRestorePointValue) {
            $parsedRestorePointTime = [datetime]::MinValue

            if (
                [datetime]::TryParse(
                    $latestRestorePointValue,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::RoundtripKind,
                    [ref]$parsedRestorePointTime
                )
            ) {
                $latestRestorePointTime = $parsedRestorePointTime
            }
            else {
                Write-Host (
                    "[INFO] Zeitstempel des letzten Wiederherstellungspunkts " +
                    "konnte nicht ausgewertet werden: {0}" -f
                    $latestRestorePointValue
                )
            }
        }
    }
    else {
        $message = (
            $restorePointOutput |
            ForEach-Object { [string]$_ }
        ) -join " "

        Write-Host (
            "[INFO] Vorhandene Wiederherstellungspunkte konnten nicht " +
            "vorab ermittelt werden: {0}" -f $message
        )
    }

    if (
        $latestRestorePointTime -and
        $latestRestorePointTime -ge (Get-Date).AddHours(-24)
    ) {
        Write-Host (
            "[OK] Frischer Wiederherstellungspunkt vorhanden: {0}" `
                -f $latestRestorePointTime
        ) -ForegroundColor Green

        return
    }

    Write-Host "[CREATE] Wiederherstellungspunkt 'Windows Setup Bootstrap'"

    $command = (
        "Checkpoint-Computer " +
        "-Description 'Windows Setup Bootstrap' " +
        "-RestorePointType MODIFY_SETTINGS " +
        "-ErrorAction Stop"
    )

    $output = @(
        & $windowsPowerShell `
            -NoProfile `
            -NonInteractive `
            -Command $command `
            2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        $message = (
            $output |
            ForEach-Object { [string]$_ }
        ) -join " "

        throw (
            "Wiederherstellungspunkt konnte nicht erstellt werden. " +
            "Setup wird aus Sicherheitsgründen abgebrochen. " +
            $message
        )
    }

    Write-Host "[OK] Wiederherstellungspunkt erstellt." `
        -ForegroundColor Green
}

function Get-WindowsSetupBitLockerStatus {
    $systemDrive = [string]$env:SystemDrive

    try {
        $volume = Get-BitLockerVolume `
            -MountPoint $systemDrive `
            -ErrorAction Stop

        return [pscustomobject]@{
            Available        = $true
            MountPoint       = $systemDrive
            VolumeStatus     = [string]$volume.VolumeStatus
            ProtectionStatus = [string]$volume.ProtectionStatus
            EncryptionMethod = [string]$volume.EncryptionMethod
        }
    }
    catch {
        return [pscustomobject]@{
            Available        = $false
            MountPoint       = $systemDrive
            VolumeStatus     = $null
            ProtectionStatus = $null
            EncryptionMethod = $null
            Error            = $_.Exception.Message
        }
    }
}


function Show-WindowsSetupBitLockerStatus {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " BitLocker"
    Write-Host "========================================"

    $status = Get-WindowsSetupBitLockerStatus

    if (-not $status.Available) {
        Write-Warning (
            "BitLocker-Status für {0} konnte nicht ermittelt werden: {1}" -f
            $status.MountPoint,
            $status.Error
        )

        return $status
    }

    Write-Host (
        "[INFO] Systemlaufwerk: {0}" -f
        $status.MountPoint
    )
    Write-Host (
        "[INFO] VolumeStatus: {0}" -f
        $status.VolumeStatus
    )
    Write-Host (
        "[INFO] ProtectionStatus: {0}" -f
        $status.ProtectionStatus
    )
    Write-Host (
        "[INFO] EncryptionMethod: {0}" -f
        $status.EncryptionMethod
    )

    if ($status.ProtectionStatus -eq "On") {
        Write-Host "[OK] BitLocker-Schutz ist aktiv." `
            -ForegroundColor Green
    }
    else {
        Write-Warning "BitLocker-Schutz ist nicht aktiv."
    }

    return $status
}


function Get-WindowsSetupSecureBootStatus {
    try {
        $enabled = Confirm-SecureBootUEFI -ErrorAction Stop

        return [pscustomobject]@{
            Available = $true
            Enabled   = [bool]$enabled
            Error     = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            Enabled   = $null
            Error     = $_.Exception.Message
        }
    }
}


function Show-WindowsSetupSecureBootStatus {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Secure Boot"
    Write-Host "========================================"

    $status = Get-WindowsSetupSecureBootStatus

    if (-not $status.Available) {
        Write-Warning (
            "Secure-Boot-Status konnte nicht ermittelt werden: {0}" -f
            $status.Error
        )

        return $status
    }

    if ($status.Enabled) {
        Write-Host "[OK] Secure Boot ist aktiv." `
            -ForegroundColor Green
    }
    else {
        Write-Warning "Secure Boot ist nicht aktiv."
    }

    return $status
}


function Get-WindowsSetupFirewallStatus {
    try {
        $profiles = @(
            Get-NetFirewallProfile -ErrorAction Stop
        )

        return [pscustomobject]@{
            Available = $true
            Profiles  = $profiles
            Error     = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            Profiles  = @()
            Error     = $_.Exception.Message
        }
    }
}


function Show-WindowsSetupFirewallStatus {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Firewall"
    Write-Host "========================================"

    $status = Get-WindowsSetupFirewallStatus

    if (-not $status.Available) {
        Write-Warning (
            "Firewall-Status konnte nicht ermittelt werden: {0}" -f
            $status.Error
        )

        return $status
    }

    foreach ($firewallProfile in $status.Profiles) {
        $state = if ($firewallProfile.Enabled) { "On" } else { "Off" }

        Write-Host (
            "[INFO] {0}: {1}" -f
            $firewallProfile.Name,
            $state
        )
    }

    $disabledProfiles = @(
        $status.Profiles |
        Where-Object { -not $_.Enabled }
    )

    if ($disabledProfiles.Count -eq 0) {
        Write-Host "[OK] Windows Firewall ist für alle Profile aktiv." `
            -ForegroundColor Green
    }
    else {
        Write-Warning (
            "Windows Firewall ist für folgende Profile nicht aktiv: {0}" -f
            (($disabledProfiles | ForEach-Object { $_.Name }) -join ", ")
        )
    }

    return $status
}


function Test-ApplePasswordRequirements {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Apple Passwords Voraussetzungen"
    Write-Host "========================================"


    #
    # Benutzerpasswort prüfen
    #

    Write-Host "[CHECK] Windows Benutzerpasswort"


    $user = Get-LocalUser -Name $env:USERNAME


    if ($user.PasswordLastSet) {

        Write-Host (
            "[OK] Benutzerpasswort gesetzt. " +
            "Zuletzt geändert: $($user.PasswordLastSet)"
        )

    }
    else {

        Write-Warning `
            "Benutzer besitzt kein gesetztes Passwort."

    }


    #
    # Windows Hello prüfen
    #

    Write-Host "[CHECK] Windows Hello"


    $helloStatus = dsregcmd /status

    $azureAdJoined = $helloStatus |
    Select-String "AzureAdJoined"

    $domainJoined = $helloStatus |
    Select-String "DomainJoined"

    $isJoinedAccount = (
        $azureAdJoined -match "YES" -or
        $domainJoined -match "YES"
    )

    if (-not $isJoinedAccount) {

        Write-Host (
            "[OK] Lokales Windows-Konto erkannt. " +
            "Windows Hello wird nicht über dsregcmd bewertet."
        )

        Write-Host (
            "[INFO] Die Windows-Hello-Einrichtung kann für lokale Konten " +
            "nicht zuverlässig nicht-interaktiv geprüft werden."
        )
    }
    else {

        $ngcSet = $helloStatus |
        Select-String "NgcSet"

        if ($ngcSet -match "YES") {

            Write-Host "[OK] Windows Hello ist eingerichtet."

        }
        else {

            Write-Warning `
                "Windows Hello ist nicht eingerichtet."

        }

    }

}
