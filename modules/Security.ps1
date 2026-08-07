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


    if ($user.PasswordRequired) {

        Write-Host "[OK] Benutzerpasswort aktiviert."

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
