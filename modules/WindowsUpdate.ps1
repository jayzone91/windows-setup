$script:WindowsSetupUpdateSession = $null
$script:WindowsSetupUpdateScan = $null

function Get-WindowsSetupUpdateScan {
    if ($null -ne $script:WindowsSetupUpdateScan) {
        return $script:WindowsSetupUpdateScan
    }

    Write-Host "[CHECK] Gemeinsamer Microsoft-Update-Scan..."

    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()

    $microsoftUpdateServiceId = "7971f918-a847-4430-9279-4a52d1efe18d"
    $serviceManager = New-Object -ComObject Microsoft.Update.ServiceManager

    $microsoftUpdateService = @(
        $serviceManager.Services |
        Where-Object {
            $_.ServiceID -eq $microsoftUpdateServiceId
        }
    ) | Select-Object -First 1

    if ($null -ne $microsoftUpdateService) {
        $searcher.ServerSelection = 3
        $searcher.ServiceID = $microsoftUpdateServiceId
    }
    else {
        Write-Warning (
            "Microsoft Update ist nicht als Update-Service registriert. " +
            "Der gemeinsame Scan verwendet den konfigurierten Standarddienst."
        )
    }

    $script:WindowsSetupUpdateSession = $session
    $script:WindowsSetupUpdateScan = $searcher.Search(
        "IsInstalled=0 and IsHidden=0"
    )

    return $script:WindowsSetupUpdateScan
}

function Get-WindowsSetupUpdatesByType {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Software", "Driver")]
        [string] $Type
    )

    $typeValue = if ($Type -eq "Software") { 1 } else { 2 }
    $scan = Get-WindowsSetupUpdateScan

    return @(
        foreach ($update in $scan.Updates) {
            if ([int]$update.Type -eq $typeValue) {
                $update
            }
        }
    )
}

function Install-WindowsSetupUpdateCollection {
    param(
        [Parameter(Mandatory)]
        [object[]] $Updates,

        [Parameter(Mandatory)]
        [string] $Label
    )

    $status = [PSCustomObject]@{
        InstalledUpdates = @()
        RebootRequired   = $false
    }

    if ($Updates.Count -eq 0) {
        return $status
    }

    $collection = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $Updates) {
        if (-not $update.EulaAccepted) {
            $update.AcceptEula()
        }

        [void]$collection.Add($update)
    }

    Write-Step "$Label werden heruntergeladen"

    $downloader = $script:WindowsSetupUpdateSession.CreateUpdateDownloader()
    $downloader.Updates = $collection
    $downloadResult = $downloader.Download()

    Write-Host "Download ResultCode: $($downloadResult.ResultCode)"

    Write-Step "$Label werden installiert"

    $installer = $script:WindowsSetupUpdateSession.CreateUpdateInstaller()
    $installer.Updates = $collection
    $installResult = $installer.Install()

    Write-Host "Install ResultCode: $($installResult.ResultCode)"
    Write-Host "Neustart erforderlich: $($installResult.RebootRequired)"

    $installedUpdates = @(
        for ($index = 0; $index -lt $collection.Count; $index++) {
            $updateResult = $installResult.GetUpdateResult($index)

            if ([int]$updateResult.ResultCode -eq 2) {
                $collection.Item($index)
            }
        }
    )

    $status.InstalledUpdates = $installedUpdates
    $status.RebootRequired = [bool]$installResult.RebootRequired

    return $status
}

function Install-WindowsUpdates {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Updates"
    Write-Host "========================================"

    $updates = @(Get-WindowsSetupUpdatesByType -Type Software)

    if ($updates.Count -eq 0) {
        Write-Host "[CURRENT] Keine Windows Updates installiert." `
            -ForegroundColor Green

        return [PSCustomObject]@{
            InstalledUpdates = @()
            RebootRequired   = $false
        }
    }

    $status = Install-WindowsSetupUpdateCollection `
        -Updates $updates `
        -Label "Windows Updates"

    if ($status.InstalledUpdates.Count -eq 0) {
        Write-Host "[CURRENT] Keine Windows Updates installiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host (
            "[OK] {0} Windows Update(s) installiert:" `
                -f $status.InstalledUpdates.Count
        ) -ForegroundColor Green

        foreach ($update in $status.InstalledUpdates) {
            Write-Host "  - $($update.Title)"
        }
    }

    if ($status.RebootRequired) {
        Write-Host ""
        Write-Host "[REBOOT] Windows Update benötigt einen Neustart." `
            -ForegroundColor Yellow
    }
    else {
        Write-Host "[OK] Windows Update benötigt keinen Neustart." `
            -ForegroundColor Green
    }

    return $status
}
