function Get-MissingZenMods {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        $Mods
    )

    $profilePath = Get-ZenProfilePath

    if (-not $profilePath) {
        Write-Host (
            "[INFO] Zen-Profil konnte für die lokale Mod-Prüfung " +
            "nicht eindeutig ermittelt werden."
        )

        return @($Mods)
    }

    $modsFile = Join-Path `
        $profilePath `
        "zen-themes.json"

    if (-not (Test-Path $modsFile)) {
        Write-Host (
            "[INFO] zen-themes.json ist noch nicht vorhanden. " +
            "Mods müssen konfiguriert werden."
        )

        return @($Mods)
    }

    try {
        $installedMods = Get-Content `
            -Path $modsFile `
            -Raw `
            -ErrorAction Stop |
        ConvertFrom-Json `
            -AsHashtable `
            -ErrorAction Stop
    }
    catch {
        Write-Warning (
            "zen-themes.json konnte nicht gelesen werden. " +
            "Die Mod-Konfiguration wird sicherheitshalber ausgeführt. " +
            "Fehler: {0}" `
                -f $_.Exception.Message
        )

        return @($Mods)
    }

    $missingMods = @()

    foreach ($mod in $Mods) {
        if ($installedMods.ContainsKey($mod.Id)) {
            Write-Host (
                "[OK] Zen Mod vorhanden: {0}" `
                    -f $mod.Name
            ) -ForegroundColor Green

            continue
        }

        Write-Host (
            "[MISSING] Zen Mod: {0}" `
                -f $mod.Name
        ) -ForegroundColor Yellow

        $missingMods += $mod
    }

    return $missingMods
}

function Set-ZenMods {

    param(
        [Parameter(Mandatory)]
        $Mods
    )

    Write-Host ""
    Write-Host "[CONFIG] Zen Mods"

    if (-not $Mods -or $Mods.Count -eq 0) {
        Write-Host "[SKIP] Keine Zen Mods konfiguriert."
        return
    }
    $missingMods = @(
        Get-MissingZenMods `
            -Mods $Mods
    )

    if ($missingMods.Count -eq 0) {        Write-Host (
            (
                "[SKIP] Alle {0} konfigurierten Zen Mods sind vorhanden. " +
                "Zen bleibt geöffnet."
            ) -f $Mods.Count
        ) -ForegroundColor Green

        return
    }

    Write-Host (
        "[INFO] {0} von {1} Zen Mods müssen installiert werden." `
            -f `
            $missingMods.Count,
        $Mods.Count
    )

    $zenPath = Get-ZenInstallPath

    if (-not (Test-Path $zenPath)) {
        Write-Host "[SKIP] Zen Browser ist nicht installiert."
        return
    }

    $zenPath = Join-Path `
        $zenPath `
        "zen.exe"

    #
    # Zen beenden, damit wir ihn mit Marionette starten können
    #

    $zenProcess = Get-Process `
        -Name "zen" `
        -ErrorAction SilentlyContinue

    if ($zenProcess) {

        Write-Host "[INFO] Zen Browser wird für die Mod-Konfiguration neu gestartet."

        Stop-ZenBrowser

        Start-Sleep `
            -Seconds 2
    }


    #
    # Zen mit Marionette starten
    #

    Write-Host "[INFO] Starte Zen Konfigurationsmodus."

    $stdoutLog = Join-Path `
        $env:TEMP `
        "zen-marionette.stdout.log"


    $stderrLog = Join-Path `
        $env:TEMP `
        "zen-marionette.stderr.log"


    Start-Process `
        -FilePath $zenPath `
        -ArgumentList @(
        "--marionette"
        "-remote-allow-system-access"
    ) `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog


    #
    # Auf Marionette warten
    #

    $portReady = $false

    for ($attempt = 1; $attempt -le 30; $attempt++) {

        try {

            $testClient =
            [System.Net.Sockets.TcpClient]::new()

            $testClient.Connect(
                "127.0.0.1",
                2828
            )

            $testClient.Close()
            $testClient.Dispose()

            $portReady = $true
            break

        }
        catch {

            Start-Sleep `
                -Milliseconds 500
        }
    }


    if (-not $portReady) {
        throw "Zen Marionette konnte nicht gestartet werden."
    }


    $client = $null


    try {

        #
        # Marionette verbinden
        #

        $client =
        [System.Net.Sockets.TcpClient]::new()

        $client.Connect(
            "127.0.0.1",
            2828
        )

        $stream =
        $client.GetStream()


        #
        # Hello lesen
        #

        $null =
        Read-ZenMarionettePacket `
            -Stream $stream


        #
        # Session öffnen
        #

        Send-ZenMarionettePacket `
            -Stream $stream `
            -Packet @(
            0
            1
            "WebDriver:NewSession"
            @{
                capabilities = @{}
            }
        )


        $session =
        Read-ZenMarionettePacket `
            -Stream $stream


        if ($session[2]) {
            throw $session[2].message
        }


        #
        # Chrome Context
        #

        Send-ZenMarionettePacket `
            -Stream $stream `
            -Packet @(
            0
            2
            "Marionette:SetContext"
            @{
                value = "chrome"
            }
        )


        $context =
        Read-ZenMarionettePacket `
            -Stream $stream


        if ($context[2]) {
            throw $context[2].message
        }


        #
        # Alle Mods installieren
        #

        $messageId = 3


        foreach ($mod in $missingMods) {

            Install-ZenMod `
                -Stream $stream `
                -Mod $mod `
                -MessageId $messageId

            $messageId++
        }


        Write-Host "[OK] Zen Mods konfiguriert."

    }
    finally {

        #
        # Marionette Verbindung schließen
        #

        if ($client) {
            $client.Close()
            $client.Dispose()
        }


        #
        # Zen Konfigurationsmodus beenden
        #

        Write-Host "[INFO] Beende Zen Konfigurationsmodus."


        try {

            Stop-ZenBrowser

        }
        catch {

            Write-Warning (
                "Zen konnte nach der Mod-Konfiguration nicht sauber beendet werden: {0}" `
                    -f $_.Exception.Message
            )
        }


        #
        # Zen wieder normal starten
        #

        Write-Host "[INFO] Starte Zen Browser normal."


        Start-Process `
            -FilePath $zenPath


        Write-Host "[OK] Zen Browser neu gestartet."
    }
}