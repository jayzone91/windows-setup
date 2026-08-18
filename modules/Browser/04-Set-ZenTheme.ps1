function Start-ZenBrowserForTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ZenExecutable
    )

    Start-Process `
        -FilePath $ZenExecutable |
    Out-Null

    for ($attempt = 1; $attempt -le 40; $attempt++) {
        if (Get-Process -Name "zen" -ErrorAction SilentlyContinue) {
            return
        }

        Start-Sleep `
            -Milliseconds 250
    }

    throw "Zen Browser wurde nach der Theme-Bereinigung nicht gestartet."
}


function Set-ZenTheme {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-Host ""
    Write-Host "[CONFIG] Zen Theme"

    $profilePath = Get-ZenProfilePath

    if (-not $profilePath) {
        Write-Warning "Aktives Zen-Profil konnte nicht eindeutig ermittelt werden."
        return $false
    }

    $chromeDirectory = Join-Path `
        $profilePath `
        "chrome"

    $legacyFiles = @(
        "userChrome.css"
        "userContent.css"
        "zen-logo-mocha.svg"
    )

    $changed = $false

    foreach ($file in $legacyFiles) {
        $path = Join-Path `
            $chromeDirectory `
            $file

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        Remove-Item `
            -LiteralPath $path `
            -Force

        $changed = $true

        Write-Host "[OK] Veraltetes Zen-CSS-Artefakt entfernt: $file" `
            -ForegroundColor Green
    }

    $websitePath = Join-Path `
        $chromeDirectory `
        "websites"

    $websiteItem = Get-Item `
        -LiteralPath $websitePath `
        -Force `
        -ErrorAction SilentlyContinue

    if ($websiteItem) {
        if (
            $websiteItem.PSIsContainer -and
            $websiteItem.LinkType -eq "Junction"
        ) {
            Remove-Item `
                -LiteralPath $websitePath `
                -Force

            $changed = $true

            Write-Host "[OK] Veraltete Zen-Website-Style-Junction entfernt." `
                -ForegroundColor Green
        }
        else {
            Write-Warning (
                "Zen-Pfad 'chrome\websites' ist keine verwaltete Junction " +
                "und bleibt unangetastet: $websitePath"
            )
        }
    }

    $repositoryPath = [IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot "..\..")
    )

    $legacyStatePath = Join-Path `
        $repositoryPath `
        ".generated\state\zen\catppuccin-mocha-mauve.sha256"

    if (Test-Path -LiteralPath $legacyStatePath -PathType Leaf) {
        Remove-Item `
            -LiteralPath $legacyStatePath `
            -Force

        Write-Host "[OK] Veralteter Zen-Catppuccin-State entfernt." `
            -ForegroundColor Green
    }

    if (-not $changed) {
        Write-Host "[SKIP] Zen Custom-CSS bereits vollständig entfernt." `
            -ForegroundColor Green

        return $false
    }

    $zenInstallPath = Get-ZenInstallPath

    if (-not $zenInstallPath) {
        throw "Zen Browser wurde nach der Theme-Bereinigung nicht gefunden."
    }

    $zenExecutable = Join-Path `
        $zenInstallPath `
        "zen.exe"

    if (Get-Process -Name "zen" -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Zen wird nach der Theme-Bereinigung neu gestartet."
        Stop-ZenBrowser
    }

    Start-ZenBrowserForTheme `
        -ZenExecutable $zenExecutable

    Write-Host "[OK] Zen läuft ohne repositoryverwaltetes Custom-CSS." `
        -ForegroundColor Green

    return $true
}
