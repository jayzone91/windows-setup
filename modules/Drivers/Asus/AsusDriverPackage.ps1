function Get-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update
    )

    if (-not $Update.DownloadUrl) {
        throw "Keine Download-URL für $($Update.Name) vorhanden."
    }

    $downloadDirectory = Join-Path $env:TEMP "windows-setup\asus\downloads"

    if (-not (Test-Path $downloadDirectory)) {
        New-Item `
            -Path $downloadDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    $fileName = [System.IO.Path]::GetFileName(
        ([uri]$Update.DownloadUrl).AbsolutePath
    )

    $destination = Join-Path $downloadDirectory $fileName

    Write-Host ""
    Write-Host "[DOWNLOAD] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "           $($Update.AvailableVersion)"

    Invoke-WebRequest `
        -Uri $Update.DownloadUrl `
        -OutFile $destination `
        -UseBasicParsing

    if (-not (Test-Path $destination)) {
        throw "ASUS-Paket wurde nicht heruntergeladen: $($Update.Name)"
    }

    # Größe aus dem ASUS-Manifest prüfen
    if ($Update.Size) {
        $actualSize = (Get-Item $destination).Length

        if ($actualSize -ne [long]$Update.Size) {
            Remove-Item $destination -Force

            throw (
                "Dateigröße stimmt nicht überein: $($Update.Name). " +
                "Erwartet: $($Update.Size), erhalten: $actualSize"
            )
        }
    }

    Write-Host "[OK] Download erfolgreich." -ForegroundColor Green

    return $destination
}

function Expand-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$ZipPath
    )

    $safeName = $Update.Name -replace '[^\w\.-]', '_'

    $extractRoot = Join-Path `
        $env:TEMP `
        "windows-setup\asus\packages"

    $destination = Join-Path $extractRoot $safeName

    if (Test-Path $destination) {
        Remove-Item `
            -Path $destination `
            -Recurse `
            -Force
    }

    New-Item `
        -Path $destination `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[EXTRACT] $($Update.Name)" -ForegroundColor Cyan

    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $destination `
        -Force

    Write-Host "[OK] Paket entpackt." -ForegroundColor Green

    return $destination
}

