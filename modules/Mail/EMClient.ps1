function Protect-EMClientSettings {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $sourcePath = Join-Path $RepositoryPath ".generated\emclient\settings.xml"
    $targetPath = Join-Path $RepositoryPath "secrets\emclient-settings.sops.xml"
    $temporaryPath = "$targetPath.tmp"

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        return
    }

    if (-not (Get-Command sops -ErrorAction SilentlyContinue)) {
        throw "sops ist nicht verfügbar."
    }

    Write-Host "[ENCRYPT] Neue eM-Client-Konfiguration gefunden."

    try {
        & sops encrypt `
            --input-type xml `
            --output-type xml `
            --output $temporaryPath `
            $sourcePath

        if ($LASTEXITCODE -ne 0) {
            throw "eM-Client-Konfiguration konnte nicht verschlüsselt werden."
        }

        Move-Item `
            -LiteralPath $temporaryPath `
            -Destination $targetPath `
            -Force

        $stateDirectory = Join-Path $RepositoryPath ".generated\state\emclient"
        $statePath = Join-Path $stateDirectory "settings.sha256"

        New-Item $stateDirectory -ItemType Directory -Force | Out-Null

        (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash |
        Set-Content -LiteralPath $statePath -NoNewline

        Remove-Item -LiteralPath $sourcePath -Force

        Write-Host "[OK] eM-Client-Konfiguration verschlüsselt." `
            -ForegroundColor Green
    }
    finally {
        Remove-Item `
            -LiteralPath $temporaryPath `
            -Force `
            -ErrorAction SilentlyContinue
    }
}


function Restore-EMClientSettings {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $mailClientPath = "C:\Program Files (x86)\eM Client\MailClient.exe"
    $encryptedPath = Join-Path $RepositoryPath "secrets\emclient-settings.sops.xml"
    $stateDirectory = Join-Path $RepositoryPath ".generated\state\emclient"
    $statePath = Join-Path $stateDirectory "settings.sha256"

    $currentHash = (Get-FileHash -LiteralPath $encryptedPath -Algorithm SHA256).Hash

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $restoredHash = (Get-Content -LiteralPath $statePath -Raw).Trim()

        if ($restoredHash -ceq $currentHash) {
            Write-Host "[SKIP] eM-Client-Konfiguration bereits angewendet." `
                -ForegroundColor Green
            return
        }
    }
    $secretsPath = Join-Path $RepositoryPath "secrets\mail.sops.json"
    $temporaryPath = Join-Path $env:TEMP "emclient-settings.xml"

    if (-not (Test-Path -LiteralPath $mailClientPath -PathType Leaf)) {
        Write-Warning "eM Client ist nicht installiert."
        return
    }

    if (-not (Test-Path -LiteralPath $encryptedPath -PathType Leaf)) {
        Write-Host "[SKIP] Keine eM-Client-Konfiguration vorhanden."
        return
    }

    try {
        & sops decrypt `
            --input-type xml `
            --output-type xml `
            --output $temporaryPath `
            $encryptedPath

        if ($LASTEXITCODE -ne 0) {
            throw "eM-Client-Konfiguration konnte nicht entschlüsselt werden."
        }

        $decryptedSecrets = @(
            & sops decrypt `
                --input-type json `
                --output-type json `
                $secretsPath
        )

        if ($LASTEXITCODE -ne 0) {
            throw "Mail-Secrets konnten nicht entschlüsselt werden."
        }

        $secrets = ($decryptedSecrets -join [Environment]::NewLine) |
        ConvertFrom-Json

        $password = [string] $secrets.emclient.import_password

        if ([string]::IsNullOrWhiteSpace($password)) {
            throw "eM-Client-Import-Passwort fehlt."
        }

        Set-Clipboard -Value $password

        Write-Host "[INFO] eM-Client-Import-Passwort liegt in der Zwischenablage."

        Get-Process MailClient -ErrorAction SilentlyContinue |
        Stop-Process -Force

        Start-Process `
            -FilePath $mailClientPath `
            -ArgumentList @(
            "/importsettings"
            "`"$temporaryPath`""
            "-s"
        )

        $null = Read-Host (
            "Passwort mit STRG+V einfügen und nach abgeschlossenem Import ENTER drücken"
        )
    }
    finally {
        Set-Clipboard -Value ""

        $password = $null
        $secrets = $null
        $decryptedSecrets = $null

        Remove-Item `
            -LiteralPath $temporaryPath `
            -Force `
            -ErrorAction SilentlyContinue
    }

    New-Item $stateDirectory -ItemType Directory -Force | Out-Null

    $currentHash |
    Set-Content -LiteralPath $statePath -NoNewline

    Write-Host "[OK] eM-Client-Import abgeschlossen." -ForegroundColor Green
}
