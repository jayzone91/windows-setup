function Clear-WindowsSetupTemp {
    $tempPath = Join-Path $env:TEMP "windows-setup"

    Write-Host ""
    Write-Host "[CLEANUP] Temporäre Setup-Dateien bereinigen..."

    if (Test-Path $tempPath) {
        Remove-Item `
            -Path $tempPath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    New-Item `
        -Path $tempPath `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[OK] Temporäre Setup-Dateien bereinigt." `
        -ForegroundColor Green
}
