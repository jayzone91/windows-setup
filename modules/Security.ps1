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

    $latestRestorePointTime = $null

    try {
        $restorePoints = @(
            Get-CimInstance `
                -Namespace "root/default" `
                -ClassName "SystemRestore" `
                -ErrorAction Stop
        )

        $latestRestorePoint = $restorePoints |
            Sort-Object {
                [Management.ManagementDateTimeConverter]::ToDateTime(
                    $_.CreationTime
                )
            } -Descending |
            Select-Object -First 1

        if ($latestRestorePoint) {
            $latestRestorePointTime = (
                [Management.ManagementDateTimeConverter]::ToDateTime(
                    $latestRestorePoint.CreationTime
                )
            )
        }
    }
    catch {
        Write-Host (
            "[INFO] Vorhandene Wiederherstellungspunkte konnten nicht " +
            "vorab ermittelt werden: {0}" -f $_.Exception.Message
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

    $windowsPowerShell = Join-Path `
        $env:SystemRoot `
        "System32\WindowsPowerShell\v1.0\powershell.exe"

    if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
        throw "Windows PowerShell 5.1 für Checkpoint-Computer wurde nicht gefunden."
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
