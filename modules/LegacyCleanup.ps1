function Remove-LegacyWindhawk {
    [CmdletBinding()]
    param()

    $windhawkPaths = @(
        "$env:ProgramFiles\Windhawk\windhawk.exe"
        "${env:ProgramFiles(x86)}\Windhawk\windhawk.exe"
    )

    $installed = $windhawkPaths |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
        Select-Object -First 1

    if (-not $installed) {
        Write-Host "[SKIP] Windhawk ist nicht installiert." -ForegroundColor Green
        return
    }

    Write-Host "[REMOVE] Veraltete Windhawk-Installation."

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "Windhawk erkannt, aber winget.exe fehlt."
        return
    }

    & $winget.Source uninstall `
        --name "Windhawk" `
        --exact `
        --silent `
        --disable-interactivity `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Warning (
            "Windhawk konnte nicht automatisch entfernt werden. " +
            "Bitte einmal manuell deinstallieren."
        )
        return
    }

    Write-Host "[OK] Windhawk entfernt." -ForegroundColor Green
}
