function Install-Drivers {
    if (-not (Test-Administrator)) {
        throw "Das Treiber-Setup muss als Administrator ausgeführt werden."
    }

    $script:DriverRebootRequired = $false

    Write-Step "Treiber-Setup gestartet"

    Write-Step "Fehlende Geräte vor Installation"

    $missingBefore = Get-MissingDevices

    if ($missingBefore) {
        $missingBefore | Format-Table -AutoSize
    }
    else {
        Write-Host "[OK] Keine problematischen Geräte gefunden." `
            -ForegroundColor Green
    }

    Install-WindowsDriverUpdates

    Install-AsusArmouryCrate

    Install-IntelDriverSupport
    Install-IntelDsaUpdates

    Show-AsusArmouryCrateUpdates

    Write-Step "Fehlende Geräte nach Installation"

    $missingAfter = Get-MissingDevices

    if ($missingAfter) {
        $missingAfter | Format-Table -AutoSize
    }
    else {
        Write-Host "[OK] Alle erkannten Geräte melden Status OK." `
            -ForegroundColor Green
    }

    Show-DriverInventory

    if ($script:DriverRebootRequired) {
        Write-Host ""
        Write-Host "[!] Neustart erforderlich." -ForegroundColor Yellow
    }
}
