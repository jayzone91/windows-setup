function Install-WindowsDriverUpdates {
    Write-Step "Suche Windows Update nach Treibern"

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    $searchResult = $updateSearcher.Search(
        "IsInstalled=0 and Type='Driver' and IsHidden=0"
    )

    if ($searchResult.Updates.Count -eq 0) {
        Write-Host "[OK] Keine Windows-Treiberupdates verfügbar." `
            -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "Gefundene Treiberupdates:"

    foreach ($update in $searchResult.Updates) {
        Write-Host " - $($update.Title)"
    }

    $updates = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $searchResult.Updates) {
        if (-not $update.EulaAccepted) {
            $update.AcceptEula()
        }

        [void]$updates.Add($update)
    }

    Write-Step "Treiberupdates werden heruntergeladen"

    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloadResult = $downloader.Download()

    Write-Host "Download ResultCode: $($downloadResult.ResultCode)"

    Write-Step "Treiberupdates werden installiert"

    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updates

    $installResult = $installer.Install()

    Write-Host "Install ResultCode: $($installResult.ResultCode)"
    Write-Host "Neustart erforderlich: $($installResult.RebootRequired)"

    if ($installResult.RebootRequired) {
        $script:DriverRebootRequired = $true
    }
}
