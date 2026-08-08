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

