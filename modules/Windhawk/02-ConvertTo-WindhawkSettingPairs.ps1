function ConvertTo-WindhawkSettingPairs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Settings,

        [string] $Prefix = ""
    )

    $pairs = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $Settings.Keys) {
        $path = if ($Prefix) {
            "$Prefix.$key"
        }
        else {
            [string] $key
        }

        $value = $Settings[$key]

        if ($value -is [System.Collections.IDictionary]) {
            $nestedPairs = ConvertTo-WindhawkSettingPairs `
                -Settings $value `
                -Prefix $path

            foreach ($pair in $nestedPairs) {
                $pairs.Add($pair)
            }

            continue
        }

        if (
            $value -is [System.Collections.IEnumerable] -and
            $value -isnot [string]
        ) {
            $index = 0

            foreach ($item in $value) {
                $itemPath = "${path}[$index]"

                if ($item -is [System.Collections.IDictionary]) {
                    $nestedPairs = ConvertTo-WindhawkSettingPairs `
                        -Settings $item `
                        -Prefix $itemPath

                    foreach ($pair in $nestedPairs) {
                        $pairs.Add($pair)
                    }
                }
                else {
                    $itemValue = if ($item -is [bool]) {
                        $item.ToString().ToLowerInvariant()
                    }
                    elseif ($null -eq $item) {
                        ""
                    }
                    else {
                        [string] $item
                    }

                    $pairs.Add("$itemPath=$itemValue")
                }

                $index++
            }

            continue
        }

        $serializedValue = if ($value -is [bool]) {
            $value.ToString().ToLowerInvariant()
        }
        elseif ($null -eq $value) {
            ""
        }
        else {
            [string] $value
        }

        $pairs.Add("$path=$serializedValue")
    }

    return $pairs.ToArray()
}


function Set-WindhawkModSettings {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $ModId,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Settings
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    $pairs = @(
        ConvertTo-WindhawkSettingPairs `
            -Settings $Settings
    )

    if ($pairs.Count -eq 0) {
        return $false
    }

    $response = & $cli --json mod settings get $ModId |
    ConvertFrom-Json

    if (
        $LASTEXITCODE -ne 0 -or
        -not $response.success -or
        -not $response.data
    ) {
        throw (
            "Windhawk-Mod-Settings konnten nicht gelesen werden: " +
            $ModId
        )
    }

    $runtimeSettings = $response.data.settings
    $changedPairs = [Collections.Generic.List[string]]::new()

    foreach ($pair in $pairs) {
        $separatorIndex = $pair.IndexOf("=")

        if ($separatorIndex -lt 1) {
            throw "Ungültiges Windhawk-Setting-Paar: $pair"
        }

        $key = $pair.Substring(0, $separatorIndex)
        $desiredValue = $pair.Substring($separatorIndex + 1)

        $property = $runtimeSettings.PSObject.Properties[$key]
        $currentValue = $null

        if ($property) {
            $rawValue = $property.Value

            $currentValue = if ($rawValue -is [bool]) {
                $rawValue.ToString().ToLowerInvariant()
            }
            elseif (
                $desiredValue -in @("true", "false") -and
                $rawValue -is [IConvertible]
            ) {
                $numericValue = [Convert]::ToInt32(
                    $rawValue,
                    [Globalization.CultureInfo]::InvariantCulture
                )

                if ($numericValue -eq 0) {
                    "false"
                }
                elseif ($numericValue -eq 1) {
                    "true"
                }
                else {
                    [Convert]::ToString(
                        $rawValue,
                        [Globalization.CultureInfo]::InvariantCulture
                    )
                }
            }
            elseif ($null -eq $rawValue) {
                ""
            }
            elseif ($rawValue -is [IConvertible]) {
                [Convert]::ToString(
                    $rawValue,
                    [Globalization.CultureInfo]::InvariantCulture
                )
            }
            else {
                [string] $rawValue
            }
        }

        if ($currentValue -cne $desiredValue) {
            $changedPairs.Add($pair)
        }
    }

    if ($changedPairs.Count -eq 0) {
        Write-Host (
            "[CURRENT] Windhawk-Mod-Settings unverändert: {0}" -f
            $ModId
        ) -ForegroundColor Green

        return $false
    }

    Write-Host (
        "[CONFIG] Windhawk-Mod Settings: {0} ({1} Änderung(en))" -f
        $ModId,
        $changedPairs.Count
    )

    & $cli mod settings set $ModId @($changedPairs)

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Windhawk-Mod-Settings konnten nicht gesetzt werden: " +
            $ModId
        )
    }

    return $true
}


function Set-WindhawkModEnabledState {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $ModId,

        [Parameter(Mandatory)]
        [bool] $Enabled,

        [AllowNull()]
        [object] $CurrentMod
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    if (
        $CurrentMod -and
        $null -ne $CurrentMod.enabled -and
        [bool] $CurrentMod.enabled -eq $Enabled
    ) {
        Write-Host (
            "[CURRENT] Windhawk-Mod ist bereits {0}: {1}" -f
            $(if ($Enabled) { "aktiviert" } else { "deaktiviert" }),
            $ModId
        ) -ForegroundColor Green

        return $false
    }

    if ($Enabled) {
        & $cli mod enable $ModId
    }
    else {
        & $cli mod disable $ModId
    }

    if ($LASTEXITCODE -ne 0) {
        $state = if ($Enabled) {
            "aktiviert"
        }
        else {
            "deaktiviert"
        }

        throw "Windhawk-Mod konnte nicht $state werden: $ModId"
    }

    return $true
}


function Set-WindhawkConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windhawk Konfiguration"
    Write-Host "========================================"
    Write-Host ""

    if (-not $Config.Mods) {
        Write-Host "[INFO] Keine Windhawk-Mods konfiguriert."
        return $false
    }

    $configurationChanged = $false
    $installedMods = @(
        Get-WindhawkInstalledMods
    )

    foreach ($mod in $Config.Mods) {
        if (-not $mod.Id) {
            throw "Windhawk-Mod ohne Id in der Konfiguration."
        }

        $name = if ($mod.Name) {
            $mod.Name
        }
        else {
            $mod.Id
        }

        Write-Host ""
        Write-Host "[MOD] $name ($($mod.Id))"

        $currentMod = $installedMods |
        Where-Object {
            $_.id -eq $mod.Id
        } |
        Select-Object -First 1

        if (-not $currentMod) {
            Install-WindhawkMod -ModId $mod.Id
            $configurationChanged = $true

            $currentMod = [pscustomobject]@{
                id      = $mod.Id
                enabled = $true
            }
        }
        else {
            Write-Host (
                "[OK] Windhawk-Mod bereits installiert: {0}" -f
                $mod.Id
            )
        }

        if ($mod.Settings) {
            $settingsChanged = Set-WindhawkModSettings `
                -ModId $mod.Id `
                -Settings $mod.Settings

            if ($settingsChanged) {
                $configurationChanged = $true
            }
        }

        $enabled = if ($null -eq $mod.Enabled) {
            $true
        }
        else {
            [bool] $mod.Enabled
        }

        $enabledChanged = Set-WindhawkModEnabledState `
            -ModId $mod.Id `
            -Enabled $enabled `
            -CurrentMod $currentMod

        if ($enabledChanged) {
            $configurationChanged = $true
        }
    }

    Write-Host ""

    if ($configurationChanged) {
        Write-Host "[OK] Windhawk-Konfiguration aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Windhawk-Konfiguration unverändert." `
            -ForegroundColor Green
    }

    return $configurationChanged
}
