function Set-LanguageEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "npm ist ein externes CLI-Programm und verwendet Positionsargumente als Teil seiner regulären CLI-Syntax."
    )]
    param()


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

        $fnmEnvironment = fnm env `
            --shell powershell |
        Out-String


        $fnmScript = [scriptblock]::Create(
            $fnmEnvironment
        )


        & $fnmScript

        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw "npm ist nach der fnm-Konfiguration nicht verfügbar."
        }

        Write-Host "[OK] Node LTS konfiguriert."

        Write-Host "[UPDATE] npm"

        npm install --global npm@latest

        if ($LASTEXITCODE -ne 0) {
            throw "npm konnte nicht aktualisiert werden."
        }

        Write-Host "[OK] npm $(& npm --version)"

        Write-Host "[UPDATE] pnpm"

        npm install `
            --global `
            pnpm@latest

        if ($LASTEXITCODE -ne 0) {
            throw "pnpm konnte nicht installiert oder aktualisiert werden."
        }

        Write-Host (
            "[OK] pnpm {0}" `
                -f (& pnpm --version)
        ) `
            -ForegroundColor Green


        Write-Host "[UPDATE] Yarn"

        npm install `
            --global `
            yarn@latest

        if ($LASTEXITCODE -ne 0) {
            throw "Yarn konnte nicht installiert oder aktualisiert werden."
        }

        Write-Host (
            "[OK] Yarn {0}" `
                -f (& yarn --version)
        ) `
            -ForegroundColor Green

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


