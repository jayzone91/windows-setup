function Set-BrowserConfiguration {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Browser"
    Write-Host "========================================"


    Set-ChromiumExtensions

    Set-ZenBrowserConfiguration


    Write-Host ""
    Write-Host "[OK] Browser Konfiguration abgeschlossen." `
        -ForegroundColor Green
}



function Set-ChromiumExtensions {

    Write-Host ""
    Write-Host "[CONFIG] Chromium Extensions"


    $chromePolicyPath =
    "HKLM:\Software\Policies\Google\Chrome"


    if (-not (Test-Path $chromePolicyPath)) {

        New-Item `
            -Path $chromePolicyPath `
            -Force | Out-Null
    }


    Write-Host "[OK] Chromium Policy Pfad vorhanden."
}



function Set-ZenBrowserConfiguration {

    Write-Host ""
    Write-Host "[CONFIG] Zen Browser"


    $zenPath =
    "$env:APPDATA\zen"


    if (Test-Path $zenPath) {

        Write-Host "[OK] Zen Profil gefunden."

    }
    else {

        Write-Host "[INFO] Zen Profil wird nach dem ersten Start erstellt."

    }

}
