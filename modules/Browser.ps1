function Set-BrowserConfiguration {

    param(
        [Parameter(Mandatory)]
        $Config
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Browser"
    Write-Host "========================================"


    if ($Config.ChromeBeta) {

        Set-ChromiumExtensions `
            -Extensions $Config.ChromeBeta.Extensions `
            -PolicyPath $Config.ChromeBeta.PolicyPath
    }


    if ($Config.Zen) {

        Set-ZenExtensions `
            -Extensions $Config.Zen.Extensions

        if ($Config.Zen.Preferences) {

            Set-ZenPreferences `
                -Preferences $Config.Zen.Preferences
        }

        if ($Config.Zen.Mods) {
            Set-ZenMods `
                -Mods $Config.Zen.Mods
        }

    }


    Write-Host ""
    Write-Host "[OK] Browser Konfiguration abgeschlossen." `
        -ForegroundColor Green
}



function Set-ChromiumExtensions {

    param(
        [Parameter(Mandatory)]
        $Extensions,

        [Parameter(Mandatory)]
        $PolicyPath
    )


    Write-Host ""
    Write-Host "[CONFIG] Chromium Extensions"


    $extensionPath = Join-Path `
        $PolicyPath `
        "ExtensionInstallForcelist"


    # alten Key entfernen
    if (Test-Path $extensionPath) {
        Remove-Item `
            -Path $extensionPath `
            -Recurse `
            -Force
    }


    # neuen Key erstellen
    New-Item `
        -Path $extensionPath `
        -Force |
    Out-Null


    $index = 1


    foreach ($extension in $Extensions) {

        $value =
        "$($extension.Id);https://clients2.google.com/service/update2/crx"


        New-ItemProperty `
            -Path $extensionPath `
            -Name $index `
            -PropertyType String `
            -Value $value `
            -Force |
        Out-Null


        Write-Host (
            "[ADD] {0}" -f $extension.Name
        )


        $index++
    }


    Write-Host "[OK] Chromium Extensions gesetzt."
}

function Get-ZenInstallPath {

    $possiblePaths = @(
        "${env:ProgramFiles}\Zen Browser",
        "${env:ProgramFiles(x86)}\Zen Browser",
        "$env:LOCALAPPDATA\Programs\Zen Browser"
    )


    foreach ($path in $possiblePaths) {

        if (Test-Path $path) {

            $exe = Join-Path `
                $path `
                "zen.exe"


            if (Test-Path $exe) {
                return $path
            }
        }
    }


    return $null
}

function Set-ZenExtensions {

    param(
        [Parameter(Mandatory)]
        $Extensions
    )


    Write-Host ""
    Write-Host "[CONFIG] Zen Browser Extensions"


    $zenPath = Get-ZenInstallPath

    if (-not $zenPath) {
        Write-Warning "Zen Browser nicht gefunden."
        return
    }

    $distribution = Join-Path `
        $zenPath `
        "distribution"


    $installPath = $distribution


    Write-Host "[FOUND] $installPath"


    $distributionPath = Join-Path `
        $installPath `
        "distribution"


    if (-not (Test-Path $distributionPath)) {

        New-Item `
            -Path $distributionPath `
            -ItemType Directory `
            -Force |
        Out-Null
    }


    $policy = @{
        policies = @{

            Extensions       = @{
                Install = @(
                    foreach ($extension in $Extensions) {
                        $extension.InstallUrl
                    }
                )
            }

            RequestedLocales = @(
                "de"
            )

            Languages        = @{
                Requested = @(
                    "de-DE"
                )
            }
        }
    }


    $policyPath = Join-Path `
        $distributionPath `
        "policies.json"


    $policy |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -Path $policyPath `
        -Encoding UTF8


    foreach ($extension in $Extensions) {
        Write-Host "[ADD] $($extension.Name)"
    }


    Write-Host "[OK] Zen Browser konfiguriert."
}

function Set-ZenPreferences {

    param(
        [Parameter(Mandatory)]
        $Preferences
    )


    Write-Host ""
    Write-Host "[CONFIG] Zen Browser Policies"


    $zenPath = Get-ZenInstallPath

    if (-not $zenPath) {
        Write-Warning "Zen Browser nicht gefunden."
        return
    }


    $distribution = Join-Path `
        $zenPath `
        "distribution"


    if (-not (Test-Path $distribution)) {

        New-Item `
            -Path $distribution `
            -ItemType Directory `
            -Force |
        Out-Null
    }


    $policyPath = Join-Path `
        $distribution `
        "policies.json"


    $policy = @{
        policies = @{

            RequestedLocales      = @(
                $Preferences.Locale
            )

            SpellcheckEnabled     = $true

            DisableTelemetry      = $Preferences.DisableTelemetry

            DisableFirefoxStudies = $true

            DisablePocket         = $Preferences.DisablePocket


            Preferences           = @{

                "browser.startup.page"                                = @{
                    Value = 3

                }

                "toolkit.legacyUserProfileCustomizations.stylesheets" = @{
                    Value  = $true
                    Status = "locked"
                }
            }
        }
    }


    $policy |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -Path $policyPath `
        -Encoding UTF8


    Write-Host "[OK] Zen Policies gesetzt."
}

function Read-ZenMarionettePacket {

    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream
    )

    $lengthText = ""

    while ($true) {

        $byte = $Stream.ReadByte()

        if ($byte -eq -1) {
            throw "Marionette Verbindung wurde geschlossen."
        }

        $char = [char]$byte

        if ($char -eq ":") {
            break
        }

        $lengthText += $char
    }

    if (-not $lengthText) {
        throw "Ungültiges Marionette Paket."
    }

    $length = [int]$lengthText
    $buffer = [byte[]]::new($length)
    $offset = 0

    while ($offset -lt $length) {

        $read = $Stream.Read(
            $buffer,
            $offset,
            $length - $offset
        )

        if ($read -le 0) {
            throw "Marionette Paket wurde unvollständig übertragen."
        }

        $offset += $read
    }

    $json = [System.Text.Encoding]::UTF8.GetString($buffer)

    return $json | ConvertFrom-Json
}


function Send-ZenMarionettePacket {

    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream,

        [Parameter(Mandatory)]
        $Packet
    )

    $json = $Packet |
    ConvertTo-Json `
        -Compress `
        -Depth 30

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    $prefix = [System.Text.Encoding]::ASCII.GetBytes(
        "$($bytes.Length):"
    )

    $Stream.Write(
        $prefix,
        0,
        $prefix.Length
    )

    $Stream.Write(
        $bytes,
        0,
        $bytes.Length
    )

    $Stream.Flush()
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


    $zenPath = "C:\Program Files\Zen Browser\zen.exe"

    if (-not (Test-Path $zenPath)) {
        Write-Host "[SKIP] Zen Browser ist nicht installiert."
        return
    }


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

    Start-Process `
        -FilePath $zenPath `
        -ArgumentList @(
        "--marionette"
        "-remote-allow-system-access"
    )


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


        foreach ($mod in $Mods) {

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

function Install-ZenMod {

    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream,

        [Parameter(Mandatory)]
        $Mod,

        [Parameter(Mandatory)]
        [int] $MessageId
    )


    $script = @'
const done = arguments[arguments.length - 1];
const modId = arguments[0];

(async () => {
    try {

        const win =
            Services.wm.getMostRecentWindow("navigator:browser");

        if (!win) {
            throw new Error(
                "Kein Zen Browserfenster gefunden."
            );
        }

        const modsManager =
            win.gZenMods;

        if (!modsManager) {
            throw new Error(
                "gZenMods ist nicht verfügbar."
            );
        }


        const existingMods =
            await modsManager.getMods();


        if (existingMods?.[modId]) {

            const existingMod =
                existingMods[modId];

            done({
                success: true,
                alreadyInstalled: true,
                name: existingMod.name ?? null,
                version: existingMod.version ?? null
            });

            return;
        }


        const mod =
            await modsManager.requestMod(modId);

        if (!mod) {
            throw new Error(
                "Zen konnte den Mod nicht laden."
            );
        }


        mod.enabled = true;


        const mods =
            await modsManager.getMods();

        mods[mod.id] = mod;


        await modsManager.updateMods(mods);


        done({
            success: true,
            alreadyInstalled: false,
            name: mod.name ?? null,
            version: mod.version ?? null
        });

    }
    catch (error) {

        done({
            success: false,
            error:
                error?.stack ??
                error?.toString() ??
                String(error)
        });
    }
})();
'@


    Send-ZenMarionettePacket `
        -Stream $Stream `
        -Packet @(
        0
        $MessageId
        "WebDriver:ExecuteAsyncScript"
        @{
            script        = $script
            args          = @($Mod.Id)
            newSandbox    = $true
            sandbox       = "system"
            scriptTimeout = 30000
        }
    )


    $result =
    Read-ZenMarionettePacket `
        -Stream $Stream


    if ($result[2]) {

        Write-Host (
            "[FAIL] {0}: {1}" `
                -f `
                $Mod.Name,
            $result[2].message
        )

        return
    }


    $value =
    $result[3].value


    if (-not $value.success) {

        Write-Host (
            "[FAIL] {0}: {1}" `
                -f `
                $Mod.Name,
            $value.error
        )

        return
    }


    if ($value.alreadyInstalled) {

        Write-Host (
            "[SKIP] {0} bereits installiert." `
                -f $Mod.Name
        )

        return
    }


    Write-Host (
        "[ADD] {0} ({1})" `
            -f `
            $value.name,
        $value.version
    )
}

function Stop-ZenBrowser {

    param(
        [int] $GracePeriodSeconds = 2
    )

    $zenProcesses = Get-Process `
        -Name "zen" `
        -ErrorAction SilentlyContinue


    if (-not $zenProcesses) {
        return
    }


    #
    # Erst sauber schließen
    #

    $zenProcesses |
    Where-Object {
        $_.MainWindowHandle -ne 0
    } |
    ForEach-Object {
        $null = $_.CloseMainWindow()
    }


    Start-Sleep `
        -Seconds $GracePeriodSeconds


    #
    # Verbleibende Prozesse hart beenden
    #

    $remainingProcesses = Get-Process `
        -Name "zen" `
        -ErrorAction SilentlyContinue


    if ($remainingProcesses) {

        $remainingProcesses |
        Stop-Process `
            -Force
    }


    #
    # Auf vollständiges Beenden warten
    #

    for ($attempt = 1; $attempt -le 20; $attempt++) {

        $remainingProcesses = Get-Process `
            -Name "zen" `
            -ErrorAction SilentlyContinue


        if (-not $remainingProcesses) {
            return
        }


        Start-Sleep `
            -Milliseconds 250
    }


    throw "Zen Browser konnte nicht vollständig beendet werden."
}
