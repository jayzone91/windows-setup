function Install-WindowsDriverUpdates {
    Write-Step "Windows-Treiberupdates"

    $updates = @(Get-WindowsSetupUpdatesByType -Type Driver)

    if ($updates.Count -eq 0) {
        Write-Host "[OK] Keine Windows-Treiberupdates verfügbar." `
            -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "Gefundene Treiberupdates:"

    foreach ($update in $updates) {
        Write-Host " - $($update.Title)"
    }

    $status = Install-WindowsSetupUpdateCollection `
        -Updates $updates `
        -Label "Treiberupdates"

    if ($status.RebootRequired) {
        $script:DriverRebootRequired = $true
    }
}
