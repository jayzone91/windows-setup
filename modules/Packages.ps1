function Test-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    winget list `
        --id $Id `
        --exact `
        --accept-source-agreements `
        --disable-interactivity *> $null

    return $LASTEXITCODE -eq 0
}


function Install-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Source,

        [bool]$Update = $true
    )

    Write-Host ""
    Write-Host "[CHECK] $Name"

    # ------------------------------------------------------------
    # Prüfen, ob das Paket bereits installiert ist
    # ------------------------------------------------------------

    $listArguments = @(
        "list"
        "--id", $Id
        "--exact"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    if ($Source) {
        $listArguments += @(
            "--source", $Source
        )
    }

    & winget @listArguments *> $null

    $isInstalled = ($LASTEXITCODE -eq 0)

    # ------------------------------------------------------------
    # Nicht installiert -> installieren
    # ------------------------------------------------------------

    if (-not $isInstalled) {
        Write-Host "[INSTALL] $Name" -ForegroundColor Cyan

        $installArguments = @(
            "install"
            "--id", $Id
            "--exact"
            "--accept-package-agreements"
            "--accept-source-agreements"
            "--disable-interactivity"
        )

        if ($Source) {
            $installArguments += @(
                "--source", $Source
            )
        }

        & winget @installArguments

        if ($LASTEXITCODE -ne 0) {
            throw "Installation fehlgeschlagen: $Name"
        }

        Write-Host "[OK] $Name installiert." `
            -ForegroundColor Green

        return
    }

    Write-Host "[OK] $Name ist installiert." `
        -ForegroundColor Green

    # ------------------------------------------------------------
    # Updates für dieses Paket deaktiviert
    # ------------------------------------------------------------

    if (-not $Update) {
        Write-Host "[SKIP] Update-Prüfung deaktiviert."
        return
    }

    # ------------------------------------------------------------
    # Auf Update prüfen
    # ------------------------------------------------------------

    Write-Host "[UPDATE] Prüfe auf Updates..."

    $upgradeArguments = @(
        "upgrade"
        "--id", $Id
        "--exact"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    if ($Source) {
        $upgradeArguments += @(
            "--source", $Source
        )
    }

    $upgradeOutput = & winget @upgradeArguments 2>&1
    $upgradeExitCode = $LASTEXITCODE

    switch ($upgradeExitCode) {
        0 {
            Write-Host "[UPDATED] $Name wurde aktualisiert." `
                -ForegroundColor Green
        }

        -1978335189 {
            Write-Host "[CURRENT] $Name ist bereits aktuell." `
                -ForegroundColor Green
        }

        default {
            Write-Warning (
                "Winget-Update für '$Name' fehlgeschlagen. " +
                "ExitCode: $upgradeExitCode"
            )

            $upgradeOutput | ForEach-Object {
                Write-Host $_
            }
        }
    }

    Write-Host "[OK] Update-Prüfung abgeschlossen." `
        -ForegroundColor Green
}
function Install-PackageGroup {
    param(
        [Parameter(Mandatory)]
        [array]$Packages,

        [Parameter(Mandatory)]
        [string]$GroupName
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " $GroupName"
    Write-Host "========================================"

    foreach ($package in $Packages) {

        $source = $null
        $update = $true

        if ($package.ContainsKey("Source")) {
            $source = $package.Source
        }

        if ($package.ContainsKey("Update")) {
            $update = [bool]$package.Update
        }

        Install-WingetPackage `
            -Id $package.Id `
            -Name $package.Name `
            -Source $source `
            -Update $update
    }
}
