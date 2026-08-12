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

function Set-ZenConfiguration {
    param(
        [Parameter(Mandatory)]
        $Config
    )

    Write-Host ""
    Write-Host "[CONFIG] Zen Browser"

    $zenPath = Get-ZenInstallPath

    if (-not $zenPath) {
        Write-Warning "Zen Browser nicht gefunden."
        return $false
    }

    $distributionPath = Join-Path `
        $zenPath `
        "distribution"

    if (-not (Test-Path -LiteralPath $distributionPath -PathType Container)) {
        New-Item `
            -Path $distributionPath `
            -ItemType Directory `
            -Force |
        Out-Null
    }

    $policies = [ordered]@{}

    if ($Config.Extensions) {
        $policies.Extensions = [ordered]@{
            Install = @(
                foreach ($extension in $Config.Extensions) {
                    $extension.InstallUrl
                }
            )
        }
    }

    if ($Config.Preferences) {
        $preferences = $Config.Preferences

        if ($preferences.Locale) {
            $policies.RequestedLocales = @(
                $preferences.Locale
            )
        }

        if ($null -ne $preferences.DisableTelemetry) {
            $policies.DisableTelemetry = [bool]$preferences.DisableTelemetry
        }

        if ($null -ne $preferences.DisableFirefoxStudies) {
            $policies.DisableFirefoxStudies = [bool]$preferences.DisableFirefoxStudies
        }

        if ($null -ne $preferences.DisablePocket) {
            $policies.DisablePocket = [bool]$preferences.DisablePocket
        }

        if ($preferences.SearchEngine) {
            $policies.SearchEngines = [ordered]@{
                Default = $preferences.SearchEngine
            }
        }

        $browserPreferences = [ordered]@{}

        if ($preferences.RestorePreviousSession) {
            $browserPreferences["browser.startup.page"] = [ordered]@{
                Value  = 3
                Status = "default"
            }
        }

        if ($preferences.SpellcheckDictionary) {
            $browserPreferences["layout.spellcheckDefault"] = [ordered]@{
                Value  = 2
                Status = "default"
            }

            $browserPreferences["spellchecker.dictionary"] = [ordered]@{
                Value  = $preferences.SpellcheckDictionary
                Status = "default"
            }
        }

        if ($preferences.EnableUserStyles) {
            $browserPreferences["toolkit.legacyUserProfileCustomizations.stylesheets"] = [ordered]@{
                Value  = $true
                Status = "user"
            }
        }

        if ($browserPreferences.Count -gt 0) {
            $policies.Preferences = $browserPreferences
        }
    }

    $policy = [ordered]@{
        policies = $policies
    }

    $desiredContent = (
        $policy |
        ConvertTo-Json -Depth 10
    ).Trim()

    $policyPath = Join-Path `
        $distributionPath `
        "policies.json"

    $currentContent = $null

    if (Test-Path -LiteralPath $policyPath -PathType Leaf) {
        $currentContent = (
            Get-Content `
                -LiteralPath $policyPath `
                -Raw `
                -Encoding UTF8
        ).Trim()
    }

    if ($currentContent -ceq $desiredContent) {
        Write-Host "[SKIP] Zen Browser Policies unverändert." `
            -ForegroundColor Green

        return $false
    }

    [IO.File]::WriteAllText(
        $policyPath,
        $desiredContent + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Host "[OK] Zen Browser Policies aktualisiert." `
        -ForegroundColor Green

    return $true
}
