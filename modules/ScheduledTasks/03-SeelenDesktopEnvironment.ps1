function Test-SeelenUiRunning {
    return [bool](
        Get-Process `
            -Name "seelen-ui" `
            -ErrorAction SilentlyContinue
    )
}

function Get-SeelenStartApp {
    $startAppMatches = @(
        Get-StartApps |
        Where-Object {
            $_.Name -eq "Seelen UI" -or
            $_.AppID -match "Seelen"
        }
    )

    if ($startAppMatches.Count -eq 0) {
        throw "Seelen UI wurde in Get-StartApps nicht gefunden."
    }

    $exact = @(
        $startAppMatches |
        Where-Object { $_.Name -eq "Seelen UI" }
    )

    if ($exact.Count -eq 1) {
        return $exact[0]
    }

    if ($startAppMatches.Count -eq 1) {
        return $startAppMatches[0]
    }

    throw "Seelen UI konnte nicht eindeutig ermittelt werden."
}

function Stop-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Get-Process `
        -Name "seelen-ui" `
        -ErrorAction SilentlyContinue |
    Stop-Process `
        -Force `
        -ErrorAction Stop
}

function Start-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    if (Test-SeelenUiRunning) {
        Write-Host "[SKIP] Seelen UI läuft bereits." `
            -ForegroundColor Green

        return
    }

    $app = Get-SeelenStartApp

    Start-Process `
        -FilePath "explorer.exe" `
        -ArgumentList "shell:AppsFolder\$($app.AppID)"

    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (Test-SeelenUiRunning) {
            Write-Host "[OK] Seelen UI läuft." `
                -ForegroundColor Green

            return
        }

        Start-Sleep -Milliseconds 250
    }

    throw "Seelen UI wurde nach dem Start nicht innerhalb von 10 Sekunden erkannt."
}

function Restart-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Stop-WindowsDesktopEnvironment
    Start-Sleep -Milliseconds 500
    Start-WindowsDesktopEnvironment

    Write-Host "[OK] Seelen Desktop Environment neu gestartet." `
        -ForegroundColor Green
}
