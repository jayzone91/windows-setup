function Get-FluentFlyoutLatestRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $uri = "https://api.github.com/repos/$($Config.Repository)/releases/latest"

    return Invoke-RestMethod `
        -Uri $uri `
        -Headers @{
            Accept = "application/vnd.github+json"
        }
}


function Test-FluentFlyoutAssetHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [object] $Asset
    )

    if (-not $Asset.digest) {
        return
    }

    $parts = [string]$Asset.digest -split ":", 2
    if ($parts.Count -ne 2 -or $parts[0] -ne "sha256") {
        throw "Nicht unterstützter Release-Digest: $($Asset.digest)"
    }

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $parts[1].ToUpperInvariant()) {
        throw "SHA256-Prüfung fehlgeschlagen: $($Asset.name)"
    }
}


function Install-FluentFlyout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " FluentFlyout"
    Write-Host "========================================"
    Write-Host ""

    $release = Get-FluentFlyoutLatestRelease -Config $Config

    $bundleAsset = @(
        $release.assets |
        Where-Object name -Like $Config.BundleAssetPattern
    )

    $certificateAsset = @(
        $release.assets |
        Where-Object name -Like $Config.CertificateAssetPattern
    )

    if ($bundleAsset.Count -ne 1) {
        throw "Erwartete genau ein MSIX-Bundle. Treffer=$($bundleAsset.Count)"
    }

    if ($certificateAsset.Count -ne 1) {
        throw "Erwartete genau ein Zertifikat. Treffer=$($certificateAsset.Count)"
    }

    if ($bundleAsset[0].name -notmatch "_(\d+\.\d+\.\d+\.\d+)_") {
        throw "Paketversion nicht aus Asset-Namen lesbar: $($bundleAsset[0].name)"
    }

    $targetVersion = [version]$Matches[1]
    $installed = Get-AppxPackage `
        -Name $Config.PackageName `
        -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($installed -and [version]$installed.Version -ge $targetVersion) {
        Write-Host (
            "[OK] FluentFlyout bereits aktuell: " +
            $installed.Version
        ) -ForegroundColor Green
        return
    }

    $tempDir = Join-Path $env:TEMP "windows-setup-fluentflyout"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        $bundlePath = Join-Path $tempDir $bundleAsset[0].name
        $certificatePath = Join-Path $tempDir $certificateAsset[0].name

        Invoke-WebRequest `
            -Uri $bundleAsset[0].browser_download_url `
            -OutFile $bundlePath

        Invoke-WebRequest `
            -Uri $certificateAsset[0].browser_download_url `
            -OutFile $certificatePath

        Test-FluentFlyoutAssetHash `
            -Path $bundlePath `
            -Asset $bundleAsset[0]

        Test-FluentFlyoutAssetHash `
            -Path $certificatePath `
            -Asset $certificateAsset[0]

        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $certificatePath
        )

        try {
            $trustedPath = Join-Path `
                $Config.CertificateStore `
                $certificate.Thumbprint

            if (-not (Test-Path -LiteralPath $trustedPath)) {
                Write-Host "[CERT] FluentFlyout-Zertifikat vertrauen."

                Import-Certificate `
                    -FilePath $certificatePath `
                    -CertStoreLocation $Config.CertificateStore |
                    Out-Null
            }
            else {
                Write-Host "[OK] FluentFlyout-Zertifikat bereits vertraut."
            }
        }
        finally {
            $certificate.Dispose()
        }

        Write-Host "[INSTALL] FluentFlyout $targetVersion"
        Add-AppxPackage -Path $bundlePath -ErrorAction Stop

        $installedAfter = Get-AppxPackage `
            -Name $Config.PackageName `
            -ErrorAction Stop

        if ([version]$installedAfter.Version -lt $targetVersion) {
            throw "FluentFlyout-Installation konnte nicht verifiziert werden."
        }

        Write-Host (
            "[OK] FluentFlyout installiert: " +
            $installedAfter.Version
        ) -ForegroundColor Green
    }
    finally {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}
