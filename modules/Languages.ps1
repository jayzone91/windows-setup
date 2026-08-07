function Set-LanguageEnvironment {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Languages"
    Write-Host "========================================"


    #
    # fnm
    #

    Write-Host "[CONFIG] fnm"


    if (Get-Command fnm -ErrorAction SilentlyContinue) {

        fnm install --lts
        fnm default lts-latest

        Write-Host "[OK] Node LTS konfiguriert."

    }
    else {

        Write-Warning "fnm nicht gefunden."

    }



    #
    # Bun
    #

    Write-Host "[CHECK] Bun"

    if (Get-Command bun -ErrorAction SilentlyContinue) {
        bun upgrade

        Write-Host "[OK] $(bun --version)"

    }



    #
    # Go
    #

    Write-Host "[CHECK] Go"

    if (Get-Command go -ErrorAction SilentlyContinue) {

        Write-Host "[OK] $(go version)"

    }


}

function Set-NushellFnmIntegration {

    $nuConfig = "$env:APPDATA\nushell\config.nu"

    if (-not (Test-Path $nuConfig)) {
        return
    }


    $content = Get-Content $nuConfig -Raw


    if ($content -notmatch "fnm env") {

        Add-Content `
            $nuConfig `
            "`n# fnm Node Version Manager`nfnm env --shell nushell | save -f ~/.cache/fnm.nu`nsource ~/.cache/fnm.nu"

        Write-Host "[OK] fnm Nushell Integration gesetzt."

    }
}


