function Get-OutlookClassicExecutablePath {
    $appPathKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"
    )

    foreach ($key in $appPathKeys) {
        if (-not (Test-Path -LiteralPath $key)) {
            continue
        }

        $path = (Get-Item -LiteralPath $key).GetValue("")

        if (
            -not [string]::IsNullOrWhiteSpace($path) -and
            (Test-Path -LiteralPath $path -PathType Leaf)
        ) {
            return $path
        }
    }

    $candidates = @(
        (Join-Path $env:ProgramFiles "Microsoft Office\root\Office16\OUTLOOK.EXE"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft Office\root\Office16\OUTLOOK.EXE")
    )

    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return $path
        }
    }

    return $null
}


function Get-OfficeDeploymentToolPath {
    $candidates = @(
        (Join-Path $env:ProgramFiles "OfficeDeploymentTool\setup.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "OfficeDeploymentTool\setup.exe")
    )

    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return $path
        }
    }

    return $null
}


function Install-OutlookClassic {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Outlook Classic"
    Write-Host "========================================"

    if (Get-OutlookClassicExecutablePath) {
        Write-Host "[SKIP] Outlook Classic ist bereits installiert." `
            -ForegroundColor Green
        return
    }

    $odtPath = Get-OfficeDeploymentToolPath

    if (-not $odtPath) {
        throw (
            "Office Deployment Tool wurde nicht gefunden. " +
            "Erwartet unter Program Files\OfficeDeploymentTool."
        )
    }

    foreach ($required in @(
        "ProductId",
        "Channel",
        "Language",
        "FallbackLanguage"
    )) {
        if (
            -not $Config.ContainsKey($required) -or
            [string]::IsNullOrWhiteSpace([string] $Config[$required])
        ) {
            throw "Outlook-Konfiguration '$required' fehlt."
        }
    }

    $generatedDirectory = Join-Path $RepositoryPath ".generated\office"
    $configurationPath = Join-Path $generatedDirectory "outlook-install.xml"

    if (-not (Test-Path -LiteralPath $generatedDirectory -PathType Container)) {
        $null = New-Item `
            -ItemType Directory `
            -Path $generatedDirectory `
            -Force
    }

    $xml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="$($Config.Channel)">
    <Product ID="$($Config.ProductId)">
      <Language ID="$($Config.Language)" Fallback="$($Config.FallbackLanguage)" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Excel" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="OutlookForWindows" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Word" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" Channel="$($Config.Channel)" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

    [IO.File]::WriteAllText(
        $configurationPath,
        $xml,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Host "[INSTALL] Outlook Classic über Office Deployment Tool"

    $process = Start-Process `
        -FilePath $odtPath `
        -ArgumentList @(
            "/configure",
            "`"$configurationPath`""
        ) `
        -Wait `
        -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Office Deployment Tool fehlgeschlagen. ExitCode: $($process.ExitCode)"
    }

    if (-not (Get-OutlookClassicExecutablePath)) {
        throw "Outlook Classic wurde nach ODT-Lauf nicht gefunden."
    }

    Write-Host "[OK] Outlook Classic installiert." -ForegroundColor Green
}


function Initialize-OutlookClassicFirstRun {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $outlookPath = Get-OutlookClassicExecutablePath

    if (-not $outlookPath) {
        Write-Warning "Outlook Classic ist nicht installiert."
        return
    }

    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\outlook\activation.initialized"

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        Write-Host "[SKIP] Outlook-Aktivierung wurde bereits bestätigt." `
            -ForegroundColor Green
        return
    }

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message "[ACTION] Outlook Classic wird für die Microsoft-365-Aktivierung gestartet."
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Mit dem lizenzierten Microsoft-365-Konto anmelden. " +
            "Noch kein Mailkonto manuell einrichten."
        )
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Falls anschließend der Outlook-Kontoassistent erscheint, " +
            "diesen schließen bzw. abbrechen."
        )

    Start-Process -FilePath $outlookPath

    do {
        $confirmation = Read-WindowsSetupPrompt `
            -Prompt "Microsoft-365-Anmeldung/Aktivierung abgeschlossen? [Y]"

        if ($confirmation -cne "Y") {
            Write-WindowsSetupInteractive `
                -Message "[WAIT] Aktivierung abschließen und anschließend mit Y bestätigen."
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

    Write-Host "[OK] Outlook-Aktivierung als abgeschlossen markiert." `
        -ForegroundColor Green
}


function Initialize-OutlookSignatureDirectory {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Outlook Signatur"
    Write-Host "========================================"

    if (-not (Get-OutlookClassicExecutablePath)) {
        Write-Warning "Outlook Classic ist nicht installiert."
        return
    }

    $signatureDirectory = Join-Path $env:APPDATA "Microsoft\Signatures"
    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\outlook\signatures.initialized"

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        Write-Host "[SKIP] Outlook-Signaturordner wurde bereits initialisiert." `
            -ForegroundColor Green
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
        -Message "[ACTION] Outlook-Signaturordner wird geöffnet."
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Vorhandene *.htm, *.rtf, *.txt und den zugehörigen " +
            "Ressourcenordner vollständig hierher kopieren."
        )
    Write-WindowsSetupInteractive `
        -Message ("[INFO] Ziel: {0}" -f $signatureDirectory)

    Start-Process `
        -FilePath "explorer.exe" `
        -ArgumentList @($signatureDirectory)

    do {
        $confirmation = Read-WindowsSetupPrompt `
            -Prompt "Outlook-Signatur vollständig kopiert? [Y]"

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

    Write-Host "[OK] Outlook-Signaturordner als initialisiert markiert." `
        -ForegroundColor Green
}