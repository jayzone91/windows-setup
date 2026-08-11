function Set-LanguageEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "fnm und npm sind externe CLI-Programme und verwenden Positionsargumente als Teil ihrer regulären CLI-Syntax."
    )]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Languages"
    Write-Host "========================================"

    Write-Host "[CHECK] Node.js LTS über fnm"

    $fnm = Get-Command `
        -Name "fnm" `
        -ErrorAction SilentlyContinue

    if ($fnm) {
        $latestLtsOutput = @(
            & $fnm.Source `
                list-remote `
                --lts `
                --latest `
                2>&1
        )

        if ($LASTEXITCODE -ne 0) {
            throw "Aktuelle Node-LTS-Version konnte über fnm nicht ermittelt werden."
        }

        $latestLtsVersion = $null

        foreach ($line in $latestLtsOutput) {
            $match = [regex]::Match(
                [string]$line,
                '(?<!\d)v?(?<version>\d+\.\d+\.\d+)(?!\d)'
            )

            if ($match.Success) {
                $latestLtsVersion = $match.Groups["version"].Value
                break
            }
        }

        if (-not $latestLtsVersion) {
            throw (
                "fnm list-remote --lts --latest lieferte keine " +
                "auswertbare Node-Version."
            )
        }

        $currentNodeVersion = $null
        $node = Get-Command `
            -Name "node" `
            -ErrorAction SilentlyContinue

        if ($node) {
            $currentNodeOutput = (
                @(
                    & $node.Source --version 2>$null
                ) -join "`n"
            ).Trim()

            if (
                $LASTEXITCODE -eq 0 -and
                $currentNodeOutput -match '^v?(?<version>\d+\.\d+\.\d+)$'
            ) {
                $currentNodeVersion = $Matches["version"]
            }
        }

        if ($currentNodeVersion -ne $latestLtsVersion) {
            Write-Host (
                "[UPDATE] Node.js LTS: {0} -> {1}" -f
                $(if ($currentNodeVersion) { $currentNodeVersion } else { "<fehlt>" }),
                $latestLtsVersion
            ) -ForegroundColor Cyan

            & $fnm.Source install --lts

            if ($LASTEXITCODE -ne 0) {
                throw "Aktuelle Node-LTS-Version konnte nicht installiert werden."
            }

            & $fnm.Source default lts-latest

            if ($LASTEXITCODE -ne 0) {
                throw "fnm-Default konnte nicht auf lts-latest gesetzt werden."
            }
        }
        else {
            Write-Host (
                "[CURRENT] Node.js {0} ist die aktuelle LTS-Version." -f
                $currentNodeVersion
            ) -ForegroundColor Green
        }

        $fnmEnvironment = (
            & $fnm.Source env --shell powershell |
            Out-String
        )

        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($fnmEnvironment)) {
            throw "fnm-PowerShell-Umgebung konnte nicht erzeugt werden."
        }

        $fnmScript = [scriptblock]::Create($fnmEnvironment)
        & $fnmScript

        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw "npm ist nach der fnm-Konfiguration nicht verfügbar."
        }

        $activeNodeVersion = (
            @(
                & node --version
            ) -join "`n"
        ).Trim().TrimStart("v")

        if ($activeNodeVersion -ne $latestLtsVersion) {
            Write-Host "[USE] Node.js LTS $latestLtsVersion"

            & $fnm.Source use lts-latest

            if ($LASTEXITCODE -ne 0) {
                throw "fnm konnte lts-latest nicht für die aktuelle Session aktivieren."
            }

            $fnmEnvironment = (
                & $fnm.Source env --shell powershell |
                Out-String
            )

            $fnmScript = [scriptblock]::Create($fnmEnvironment)
            & $fnmScript
        }

        Write-Host "[OK] Node LTS $(& node --version)" -ForegroundColor Green

        foreach ($package in @(
                @{
                    Name    = "npm"
                    Command = "npm"
                },
                @{
                    Name    = "pnpm"
                    Command = "pnpm"
                },
                @{
                    Name    = "yarn"
                    Command = "yarn"
                }
            )) {
            Write-Host "[CHECK] $($package.Name)"

            $latestVersion = (
                @(
                    & npm view $package.Name version 2>$null
                ) -join "`n"
            ).Trim()

            if ($LASTEXITCODE -ne 0 -or -not $latestVersion) {
                throw (
                    "Aktuelle Registry-Version konnte nicht ermittelt werden: {0}"
                ) -f $package.Name
            }

            $installedCommand = Get-Command `
                -Name $package.Command `
                -ErrorAction SilentlyContinue

            $installedVersion = $null

            if ($installedCommand) {
                $installedVersion = (
                    @(
                        & $installedCommand.Source --version 2>$null
                    ) -join "`n"
                ).Trim()

                if ($LASTEXITCODE -ne 0) {
                    $installedVersion = $null
                }
            }

            if ($installedVersion -eq $latestVersion) {
                Write-Host (
                    "[CURRENT] {0} {1}" -f
                    $package.Name,
                    $installedVersion
                ) -ForegroundColor Green

                continue
            }

            Write-Host (
                "[UPDATE] {0}: {1} -> {2}" -f
                $package.Name,
                $(if ($installedVersion) { $installedVersion } else { "<fehlt>" }),
                $latestVersion
            ) -ForegroundColor Cyan

            & npm install `
                --global `
                ("{0}@latest" -f $package.Name)

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "{0} konnte nicht auf latest aktualisiert werden." -f
                    $package.Name
                )
            }

            $updatedCommand = Get-Command `
                -Name $package.Command `
                -ErrorAction Stop

            $updatedVersion = (
                @(
                    & $updatedCommand.Source --version
                ) -join "`n"
            ).Trim()

            Write-Host (
                "[OK] {0} {1}" -f
                $package.Name,
                $updatedVersion
            ) -ForegroundColor Green
        }
    }
    else {
        Write-Warning "fnm nicht gefunden."
    }

    Write-Host "[CHECK] Bun"

    if (Get-Command bun -ErrorAction SilentlyContinue) {
        Write-Host (
            "[OK] Bun {0}; Updates werden über den verwalteten Winget-Paketpfad geprüft." -f
            (& bun --version)
        ) -ForegroundColor Green
    }

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


