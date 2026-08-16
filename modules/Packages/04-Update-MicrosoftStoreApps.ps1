function Update-MicrosoftStoreApps {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Microsoft Store Updates"
    Write-Host "========================================"

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "Winget ist nicht verfügbar. Store-Updates werden übersprungen."
        return
    }

    $sourceArguments = @(
        "source"
        "update"
        "--name", "msstore"
        "--disable-interactivity"
    )

    & winget @sourceArguments *> $null

    if ($LASTEXITCODE -ne 0) {
        Write-Warning (
            "Microsoft-Store-Quelle konnte nicht aktualisiert werden. " +
            "Der eigentliche Update-Lauf wird trotzdem versucht."
        )
    }

    $upgradeArguments = @(
        "upgrade"
        "--all"
        "--source", "msstore"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    $upgradeOutput = @(
        & winget @upgradeArguments 2>&1
    )

    $upgradeExitCode = $LASTEXITCODE

    switch ($upgradeExitCode) {
        0 {
            Write-Host "[OK] Microsoft-Store-Updates abgeschlossen." `
                -ForegroundColor Green
        }

        -1978335189 {
            Write-Host "[CURRENT] Microsoft-Store-Apps sind aktuell." `
                -ForegroundColor Green
        }

        default {
            Write-Warning (
                "Microsoft-Store-Update meldet ExitCode {0}." `
                    -f $upgradeExitCode
            )

            $upgradeOutput |
            ForEach-Object {
                Write-Host $_
            }
        }
    }
}
