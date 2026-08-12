$script:WindowsSetupSourceRoot_modules_PowerShell = Split-Path -Parent $PSScriptRoot

function Set-PowerShellPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell 7"
    Write-Host "========================================"

    $profileSource = Join-Path `
        $script:WindowsSetupSourceRoot_modules_PowerShell `
        "..\dotfiles\powershell\Microsoft.PowerShell_profile.ps1"

    $starshipSource = Join-Path `
        $script:WindowsSetupSourceRoot_modules_PowerShell `
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


function Get-PowerShellCodeFiles {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return @(
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
}


function Get-PowerShellCodeFingerprint {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Git ist ein natives CLI-Programm; die verwendeten Argumente folgen der regulären Git-Syntax."
    )]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $ErrorActionPreference = "Stop"

    $git = Get-Command `
        -Name "git" `
        -ErrorAction SilentlyContinue

    if (-not $git -or -not (Test-Path -LiteralPath (Join-Path $Path ".git"))) {
        Write-Verbose (
            "Git-Zustand nicht verfügbar. Falle für den Code-Fingerprint " +
            "auf vollständiges Datei-Hashing zurück."
        )

        $files = Get-PowerShellCodeFiles -Path $Path

        return Get-FileSetFingerprint `
            -RootPath $Path `
            -Files $files
    }

    $head = (
        @(
            & $git.Source `
                -C $Path `
                rev-parse HEAD `
                2>$null
        ) -join "`n"
    ).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $head) {
        throw "Git-HEAD konnte für den Source-Codezustand nicht ermittelt werden."
    }

    $pathSpecs = @(
        ":(glob)**/*.ps1"
        ":(glob)**/*.psm1"
        ":(glob)**/*.psd1"
        ":(glob)**/*.cs"
        ":(glob)*.ps1"
        ":(glob)*.psm1"
        ":(glob)*.psd1"
        ":(glob)*.cs"
    )

    $changedPaths = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    $gitQueries = @(
        @(
            "diff"
            "--cached"
            "--name-only"
            "--diff-filter=ACMRTUXBD"
        ),
        @(
            "diff"
            "--name-only"
            "--diff-filter=ACMRTUXBD"
        ),
        @(
            "ls-files"
            "--others"
            "--exclude-standard"
        )
    )

    foreach ($query in $gitQueries) {
        $output = @(
            & $git.Source `
                -C $Path `
                @query `
                -- `
                @pathSpecs `
                2>$null
        )

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Git-Codezustand konnte nicht ermittelt werden. " +
                "Abfrage: {0}"
            ) -f ($query -join " ")
        }

        foreach ($relativePath in $output) {
            $candidate = ([string]$relativePath).Trim()

            if (-not [string]::IsNullOrWhiteSpace($candidate)) {
                [void]$changedPaths.Add($candidate)
            }
        }
    }

    $signature = [Collections.Generic.List[string]]::new()
    $signature.Add("HEAD=$head")

    foreach ($relativePath in @($changedPaths | Sort-Object)) {
        $fullPath = Join-Path $Path $relativePath

        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $blobHash = (
                @(
                    & $git.Source `
                        -C $Path `
                        hash-object `
                        -- `
                        $relativePath `
                        2>$null
                ) -join "`n"
            ).Trim()

            if ($LASTEXITCODE -ne 0 -or -not $blobHash) {
                throw (
                    "Git-Blob-Hash konnte nicht ermittelt werden: {0}"
                ) -f $relativePath
            }

            $signature.Add(
                (
                    "{0}|{1}" -f
                    $relativePath.Replace("\", "/"),
                    $blobHash
                )
            )
        }
        else {
            $signature.Add(
                "{0}|<deleted>" -f
                $relativePath.Replace("\", "/")
            )
        }
    }

    return Get-TextFingerprint -Text ($signature -join "`n")
}


function Get-PowerShellCodeFingerprintPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return Join-Path `
        $Path `
        ".generated\state\powershell-code.sha256"
}


function Test-PowerShellCodeFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $statePath = Get-PowerShellCodeFingerprintPath -Path $Path

    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return $false
    }

    $storedFingerprint = (
        Get-Content `
            -LiteralPath $statePath `
            -Raw `
            -ErrorAction Stop
    ).Trim()

    $currentFingerprint = Get-PowerShellCodeFingerprint -Path $Path

    return $storedFingerprint -eq $currentFingerprint
}


function Save-PowerShellCodeFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $statePath = Get-PowerShellCodeFingerprintPath -Path $Path
    $stateDirectory = Split-Path -Path $statePath -Parent

    if (-not (Test-Path -LiteralPath $stateDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    $fingerprint = Get-PowerShellCodeFingerprint -Path $Path

    Set-Content `
        -LiteralPath $statePath `
        -Value $fingerprint `
        -Encoding utf8NoBOM `
        -NoNewline

    Write-Host "[STATE] Source-Code-Fingerprint aktualisiert."
}