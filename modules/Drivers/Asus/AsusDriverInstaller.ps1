function Get-AsusInstallerCommand {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$PackageDirectory
    )

    if (-not $Update.Execute) {
        throw "Kein Installationsbefehl für $($Update.Name) vorhanden."
    }

    #
    # ASUS verwendet:
    #
    # .\AsusSetup.exe%%-s
    #
    # bzw.
    #
    # .\Install\AsusSetup.exe%%-s
    #
    # %% trennt Programm und Argumente.
    #

    $parts = $Update.Execute -split '%%', 2

    $relativeExecutable = $parts[0].Trim()

    $arguments = @()

    if ($parts.Count -gt 1 -and $parts[1]) {
        $arguments = @(
            $parts[1].Trim()
        )
    }

    $relativeExecutable = $relativeExecutable `
        -replace '^[.][\\/]', ''

    $executable = Join-Path `
        $PackageDirectory `
        $relativeExecutable

    if (-not (Test-Path $executable)) {

        #
        # Falls ASUS die ZIP-Struktur später ändert,
        # suchen wir AsusSetup.exe rekursiv.
        #

        $fileName = Split-Path `
            $relativeExecutable `
            -Leaf

        $found = Get-ChildItem `
            -Path $PackageDirectory `
            -Recurse `
            -File `
            -Filter $fileName `
            -ErrorAction SilentlyContinue |
        Select-Object -First 1

        if ($found) {
            $executable = $found.FullName
        }
        else {
            throw (
                "Installer nicht gefunden: " +
                "$relativeExecutable ($($Update.Name))"
            )
        }
    }

    [PSCustomObject]@{
        Executable = $executable
        Arguments  = $arguments
    }
}

function Test-AsusInstallerSignature {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $signature = Get-AuthenticodeSignature $Path

    if ($signature.Status -ne "Valid") {
        throw (
            "Ungültige Authenticode-Signatur: $Path " +
            "($($signature.Status))"
        )
    }

    Write-Host (
        "[OK] Signatur gültig: " +
        $signature.SignerCertificate.Subject
    ) -ForegroundColor Green
}

function Install-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$PackageDirectory
    )

    $command = Get-AsusInstallerCommand `
        -Update $Update `
        -PackageDirectory $PackageDirectory

    Write-Host ""
    Write-Host "[INSTALL] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "          Installed: $($Update.InstalledVersion)"
    Write-Host "          Available: $($Update.AvailableVersion)"
    Write-Host "          Installer: $($command.Executable)"
    Write-Host "          Arguments: $($command.Arguments -join ' ')"

    Test-AsusInstallerSignature `
        -Path $command.Executable

    $process = Start-Process `
        -FilePath $command.Executable `
        -ArgumentList $command.Arguments `
        -WorkingDirectory (Split-Path $command.Executable -Parent) `
        -Wait `
        -PassThru

    #
    # ASUS Setup verwendet nicht zwingend MSI-Exitcodes.
    # 0 behandeln wir sicher als Erfolg.
    #
    if ($process.ExitCode -ne 0) {
        throw (
            "ASUS-Installation fehlgeschlagen: " +
            "$($Update.Name), ExitCode $($process.ExitCode)"
        )
    }

    Write-Host "[OK] Installation abgeschlossen." `
        -ForegroundColor Green

    if (Test-PendingReboot) {
        $script:DriverRebootRequired = $true

        Write-Host "[REBOOT] Neustart erforderlich." `
            -ForegroundColor Yellow
    }

    return $true
}

