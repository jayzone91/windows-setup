function Initialize-ThunderbirdSignatureDirectory {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Thunderbird Signatur"
    Write-Host "========================================"

    if (-not (Test-WingetPackage -Id "Mozilla.Thunderbird.ESR")) {
        Write-Warning (
            "Thunderbird ESR ist nicht installiert. " +
            "Signatur-Initialisierung wird übersprungen."
        )
        return
    }

    $signatureDirectory = Join-Path `
        $env:APPDATA `
        "Thunderbird\Signatures"

    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\thunderbird\signatures.initialized"

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        Write-Host (
            "[OK] Thunderbird-Signaturordner wurde bereits initialisiert."
        ) -ForegroundColor Green
        return
    }

    if (-not (Test-Path -LiteralPath $signatureDirectory -PathType Container)) {
        $null = New-Item `
            -ItemType Directory `
            -Path $signatureDirectory `
            -Force
    }

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message "[ACTION] Thunderbird-Signaturordner wird geöffnet."
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Outlook-*.htm und den zugehörigen " +
            "Ressourcenordner vollständig hierher kopieren."
        )
    Write-WindowsSetupInteractive `
        -Message ("[INFO] Ziel: {0}" -f $signatureDirectory)

    Start-Process `
        -FilePath "explorer.exe" `
        -ArgumentList @($signatureDirectory)

    do {
        $confirmation = Read-WindowsSetupPrompt `
            -Prompt "Signaturdatei und Ressourcenordner vollständig kopiert? [Y]"

        if ($confirmation -cne "Y") {
            Write-WindowsSetupInteractive `
                -Message (
                    "[WAIT] Signatur vollständig kopieren und " +
                    "anschließend mit Y bestätigen."
                )
        }
    }
    until ($confirmation -ceq "Y")

    $stateDirectory = Split-Path -Path $statePath -Parent

    if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
        $null = New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force
    }

    $null = New-Item `
        -ItemType File `
        -Path $statePath `
        -Force

    Write-Host (
        "[OK] Thunderbird-Signaturordner als initialisiert markiert."
    ) -ForegroundColor Green
}