function Set-PowerShellPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell 7"
    Write-Host "========================================"

    $profileSource = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\powershell\Microsoft.PowerShell_profile.ps1"

    $starshipSource = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\starship\starship.toml"

    $pwshDocuments = Join-Path `
        $HOME `
        "Documents\PowerShell"

    $profileDestination = Join-Path `
        $pwshDocuments `
        "Microsoft.PowerShell_profile.ps1"

    $starshipDirectory = Join-Path `
        $HOME `
        ".config"

    $starshipDestination = Join-Path `
        $starshipDirectory `
        "starship.toml"

    foreach ($directory in @(
            $pwshDocuments,
            $starshipDirectory
        )) {
        if (-not (Test-Path $directory)) {
            New-Item `
                -Path $directory `
                -ItemType Directory `
                -Force |
            Out-Null
        }
    }

    if (-not (Test-Path $profileSource)) {
        throw "PowerShell-Profil nicht gefunden: $profileSource"
    }

    if (-not (Test-Path $starshipSource)) {
        throw "Starship-Konfiguration nicht gefunden: $starshipSource"
    }

    Set-FileHardLink `
        -Path $profileDestination `
        -Target $profileSource `
        -ReplaceExistingFile

    Set-FileHardLink `
        -Path $starshipDestination `
        -Target $starshipSource `
        -ReplaceExistingFile

    Write-Host "[OK] PowerShell- und Starship-Konfiguration verlinkt." `
        -ForegroundColor Green
}


function Install-PowerShellModules {

    param(
        [Parameter(Mandatory)]
        [string[]] $Modules
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell Module"
    Write-Host "========================================"


    foreach ($module in $Modules) {

        $installedModule = Get-Module `
            -ListAvailable `
            -Name $module |
        Sort-Object Version -Descending |
        Select-Object -First 1


        if ($installedModule) {

            Write-Host (
                "[SKIP] {0} bereits installiert ({1})." `
                    -f $module, $installedModule.Version
            )

            continue
        }


        Write-Host "[INSTALL] $module"


        Install-Module `
            -Name $module `
            -Scope CurrentUser `
            -Repository PSGallery `
            -Force `
            -AllowClobber


        Write-Host (
            "[OK] {0} installiert." `
                -f $module
        ) `
            -ForegroundColor Green
    }
}


function Test-PowerShellCode {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [switch] $FailOnAnyIssue
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell Code Check"
    Write-Host "========================================"


    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {

        if ($FailOnAnyIssue) {
            throw (
                "PSScriptAnalyzer ist nicht installiert. " +
                "Strikter Code-Preflight kann nicht ausgeführt werden."
            )
        }

        Write-Warning (
            "PSScriptAnalyzer ist nicht installiert. " +
            "Code-Prüfung wird übersprungen."
        )

        return
    }


    Import-Module `
        PSScriptAnalyzer `
        -ErrorAction Stop


    $settingsPath = Join-Path `
        $Path `
        "PSScriptAnalyzerSettings.psd1"


    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw "PSScriptAnalyzerSettings.psd1 nicht gefunden: $settingsPath"
    }


    $files = @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Recurse `
            -File `
            -Include *.ps1, *.psm1, *.psd1 `
            -ErrorAction Stop |
        Where-Object {
            $_.FullName -notmatch '\\\.generated\\' -and
            $_.FullName -notmatch '\\node_modules\\' -and
            $_.FullName -notmatch '\\\.git\\'
        } |
        Sort-Object FullName
    )


    $issues = @()
    $analyzerFailures = @()


    foreach ($file in $files) {

        try {

            $fileIssues = @(
                Invoke-ScriptAnalyzer `
                    -Path $file.FullName `
                    -Settings $settingsPath `
                    -ErrorAction Stop
            )


            if ($fileIssues.Count -gt 0) {
                $issues += $fileIssues
            }
        }
        catch {

            $relativePath = $file.FullName

            try {
                $relativePath = [System.IO.Path]::GetRelativePath(
                    $Path,
                    $file.FullName
                )
            }
            catch {
                $relativePath = $file.FullName
            }


            Write-Host (
                (
                    "[RETRY] PSScriptAnalyzer-Runtimefehler bei {0}. " +
                    "Erneuter Check in isoliertem PowerShell-Prozess."
                ) -f $relativePath
            ) -ForegroundColor Yellow


            $isolatedScript = @"
`$ErrorActionPreference = "Stop"

Import-Module PSScriptAnalyzer -ErrorAction Stop

try {
    `$results = @(
        Invoke-ScriptAnalyzer ``
            -Path '$($file.FullName.Replace("'", "''"))' ``
            -Settings '$($settingsPath.Replace("'", "''"))' ``
            -ErrorAction Stop
    )

    @(`$results) |
        Select-Object Severity, RuleName, ScriptName, Line, Message |
        ConvertTo-Json -Depth 10 -Compress

    exit 0
}
catch {
    Write-Error `$_.Exception.Message
    exit 2
}
"@


            $encodedCommand = [Convert]::ToBase64String(
                [Text.Encoding]::Unicode.GetBytes($isolatedScript)
            )


            $isolatedOutput = @(
                & pwsh `
                    -NoProfile `
                    -EncodedCommand $encodedCommand `
                    2>&1
            )

            $isolatedExitCode = $LASTEXITCODE


            if ($isolatedExitCode -eq 0) {

                $jsonOutput = (
                    $isolatedOutput |
                    ForEach-Object {
                        [string]$_
                    }
                ) -join [Environment]::NewLine


                if (-not [string]::IsNullOrWhiteSpace($jsonOutput)) {

                    try {

                        $isolatedIssues = @(
                            $jsonOutput |
                            ConvertFrom-Json -Depth 20
                        )


                        if ($isolatedIssues.Count -gt 0) {
                            $issues += $isolatedIssues
                        }
                    }
                    catch {

                        $analyzerFailures += [pscustomobject]@{
                            File    = $relativePath
                            Message = (
                                "Isolierter Analyzer-Check lief durch, " +
                                "aber die Ausgabe konnte nicht ausgewertet werden: " +
                                $_.Exception.Message
                            )
                        }
                    }
                }


                Write-Host (
                    "[OK] Isolierter Analyzer-Check erfolgreich: {0}" `
                        -f $relativePath
                ) -ForegroundColor Green

                continue
            }


            $failureMessage = (
                $isolatedOutput |
                ForEach-Object {
                    [string]$_
                }
            ) -join " "


            $analyzerFailures += [pscustomobject]@{
                File    = $relativePath
                Message = (
                    "Normaler Check: {0}; isolierter Check: {1}" `
                        -f $_.Exception.Message, $failureMessage
                )
            }
        }
    }


    if ($analyzerFailures.Count -gt 0) {

        Write-Host ""
        Write-Host "[ERROR] PSScriptAnalyzer konnte Dateien nicht prüfen:" `
            -ForegroundColor Red


        foreach ($failure in $analyzerFailures) {

            Write-Host (
                "  - {0}: {1}" `
                    -f $failure.File, $failure.Message
            ) -ForegroundColor Red
        }


        throw (
            "PSScriptAnalyzer ist bei {0} Datei(en) fehlgeschlagen." `
                -f $analyzerFailures.Count
        )
    }


    if ($issues.Count -eq 0) {

        Write-Host (
            "[OK] Keine PSScriptAnalyzer-Probleme gefunden. " +
            "Geprüfte Dateien: {0}" `
                -f $files.Count
        ) -ForegroundColor Green

        return
    }


    $errors = @(
        $issues |
        Where-Object {
            $_.Severity -eq "Error" -or
            $_.Severity -eq "ParseError"
        }
    )


    $warnings = @(
        $issues |
        Where-Object Severity -eq "Warning"
    )


    $information = @(
        $issues |
        Where-Object Severity -eq "Information"
    )


    Write-Host (
        (
            "[INFO] {0} Fehler, {1} Warnungen, {2} Hinweise gefunden. " +
            "Geprüfte Dateien: {3}"
        ) -f `
            $errors.Count,
        $warnings.Count,
        $information.Count,
        $files.Count
    )


    $issues |
    Select-Object `
        Severity,
    RuleName,
    ScriptName,
    Line,
    Message |
    Format-Table `
        -AutoSize


    if ($FailOnAnyIssue) {
        throw (
            "Strikter PowerShell-Codecheck fehlgeschlagen: " +
            "{0} Fehler, {1} Warnungen, {2} Hinweise." -f `
                $errors.Count,
            $warnings.Count,
            $information.Count
        )
    }

    if ($errors.Count -gt 0) {
        throw "PSScriptAnalyzer hat Fehler gefunden."
    }
}
