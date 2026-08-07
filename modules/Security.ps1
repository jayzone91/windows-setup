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
