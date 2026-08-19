function Install-Drivers {
    if (-not (Test-Administrator)) {
        throw "Das Treiber-Setup muss als Administrator ausgeführt werden."
    }

    $script:DriverRebootRequired = $false

    Write-Step "Treiber-Setup gestartet"

    Write-Step "Fehlende Geräte vor Installation"

    $missingBefore = Get-MissingDevices
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Missing Before"

    if ($missingBefore) {
        $missingBefore | Format-Table -AutoSize
    }
    else {
        Write-Host "[OK] Keine problematischen Geräte gefunden." `
            -ForegroundColor Green
    }

    Install-WindowsDriverUpdates
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Windows Update"

    Install-AsusArmouryCrate
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Armoury Crate"

    Install-IntelDriverSupport
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Intel Support"
    Install-IntelDsaUpdates
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Intel DSA"

    Show-AsusArmouryCrateUpdates
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: ASUS Status"

    Write-Step "Fehlende Geräte nach Installation"

    $missingAfter = Get-MissingDevices
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Missing After"

    if ($missingAfter) {
        $missingAfter | Format-Table -AutoSize
    }
    else {
        Write-Host "[OK] Alle erkannten Geräte melden Status OK." `
            -ForegroundColor Green
    }

    Show-DriverInventory
    Write-WindowsSetupPerformanceCheckpoint -Name "Driver: Inventory"

    if ($script:DriverRebootRequired) {
        Write-Host ""
        Write-Host "[!] Neustart erforderlich." -ForegroundColor Yellow
    }
}
