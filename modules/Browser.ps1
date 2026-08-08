function Set-BrowserConfiguration {

    param(
        [Parameter(Mandatory)]
        $Config
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Browser"
    Write-Host "========================================"


    if ($Config.ChromeBeta) {

        Set-ChromiumExtensions `
            -Extensions $Config.ChromeBeta.Extensions `
            -PolicyPath $Config.ChromeBeta.PolicyPath
    }


    if ($Config.Zen) {

        Set-ZenExtensions `
            -Extensions $Config.Zen
    }


    Write-Host ""
    Write-Host "[OK] Browser Konfiguration abgeschlossen." `
        -ForegroundColor Green
}



function Set-ChromiumExtensions {

    param(
        [Parameter(Mandatory)]
        $Extensions,

        [Parameter(Mandatory)]
        $PolicyPath
    )


    Write-Host ""
    Write-Host "[CONFIG] Chromium Extensions"


    $extensionPath = Join-Path `
        $PolicyPath `
        "ExtensionInstallForcelist"


    # alten Key entfernen
    if (Test-Path $extensionPath) {
        Remove-Item `
            -Path $extensionPath `
            -Recurse `
            -Force
    }


    # neuen Key erstellen
    New-Item `
        -Path $extensionPath `
        -Force |
    Out-Null


    $index = 1


    foreach ($extension in $Extensions) {

        $value =
        "$($extension.Id);https://clients2.google.com/service/update2/crx"


        New-ItemProperty `
            -Path $extensionPath `
            -Name $index `
            -PropertyType String `
            -Value $value `
            -Force |
        Out-Null


        Write-Host (
            "[ADD] {0}" -f $extension.Name
        )


        $index++
    }


    Write-Host "[OK] Chromium Extensions gesetzt."
}
