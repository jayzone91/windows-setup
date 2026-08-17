function Get-WindowsSetupAgeKeyPath {
    return Join-Path `
        $env:APPDATA `
        "sops\age\keys.txt"
}


function Get-WindowsSetupAgeRecipient {
    param(
        [Parameter(Mandatory)]
        [string] $KeyPath
    )

    if (-not (Test-Path -LiteralPath $KeyPath -PathType Leaf)) {
        throw "age-Identity nicht gefunden: $KeyPath"
    }

    $recipientOutput = @(
        & age-keygen -y $KeyPath 2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Public age Recipient konnte nicht ermittelt werden."
    }

    $recipients = @(
        $recipientOutput |
            ForEach-Object { [string] $_ } |
            Where-Object { $_ -match '^age1' } |
            ForEach-Object { $_.Trim() }
    )

    if ($recipients.Count -ne 1) {
        throw (
            "Erwartet wurde genau ein age Recipient, gefunden: {0}" `
                -f $recipients.Count
        )
    }

    return $recipients[0]
}


function Read-WindowsSetupAgeRecoveryKey {
    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message (
            "[ACTION] iCloud Passwords öffnen und den Eintrag " +
            "'mac-config age recovery key' aufrufen."
        )
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Den AGE-SECRET-KEY vollständig kopieren und " +
            "anschließend hier einfügen. Die Eingabe wird nicht angezeigt."
        )

    $secureKey = Read-Host `
        -Prompt "age Recovery Key" `
        -AsSecureString

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim()
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}


function Save-WindowsSetupAgeRecoveryKey {
    param(
        [Parameter(Mandatory)]
        [string] $KeyPath,

        [Parameter(Mandatory)]
        [string] $RecoveryKey
    )

    if ($RecoveryKey -notmatch '^AGE-SECRET-KEY-1[A-Z0-9]+$') {
        throw (
            "Die Eingabe hat nicht das erwartete Format " +
            "'AGE-SECRET-KEY-1...'."
        )
    }

    $keyDirectory = Split-Path -Path $KeyPath -Parent

    if (-not (Test-Path -LiteralPath $keyDirectory -PathType Container)) {
        $null = New-Item `
            -ItemType Directory `
            -Path $keyDirectory `
            -Force
    }

    [IO.File]::WriteAllText(
        $KeyPath,
        $RecoveryKey + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )

    try {
        $null = Get-WindowsSetupAgeRecipient -KeyPath $KeyPath
    }
    catch {
        Remove-Item `
            -LiteralPath $KeyPath `
            -Force `
            -ErrorAction SilentlyContinue

        throw (
            "Der eingegebene age Recovery Key ist ungültig. " +
            "Die lokale keys.txt wurde wieder entfernt."
        )
    }
}


function Initialize-WindowsSetupAgeIdentity {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Secrets / age"
    Write-Host "========================================"

    foreach ($commandName in @("sops", "age-keygen")) {
        if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
            Write-Warning (
                "'{0}' ist nicht verfügbar. Secrets-Initialisierung wird übersprungen." `
                    -f $commandName
            )
            return
        }
    }

    $keyPath = Get-WindowsSetupAgeKeyPath

    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
        $recoveryKey = Read-WindowsSetupAgeRecoveryKey

        try {
            Save-WindowsSetupAgeRecoveryKey `
                -KeyPath $keyPath `
                -RecoveryKey $recoveryKey
        }
        finally {
            $recoveryKey = $null
        }

        Write-Host (
            "[OK] Vorhandene age-Identity lokal gespeichert: {0}" `
                -f $keyPath
        ) -ForegroundColor Green
    }

    $recipient = Get-WindowsSetupAgeRecipient -KeyPath $keyPath

    $stateDirectory = Join-Path `
        $RepositoryPath `
        ".generated\state\secrets"

    if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
        $null = New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force
    }

    $recipientPath = Join-Path $stateDirectory "age-recipient.txt"

    [IO.File]::WriteAllText(
        $recipientPath,
        $recipient + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Host (
        "[OK] age Recipient: {0}" -f $recipient
    ) -ForegroundColor Green
}