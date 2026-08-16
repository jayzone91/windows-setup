function New-WindhawkAmalgamatedSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [string] $ModId
    )

    $sourceDirectory = Split-Path -Parent $SourcePath

    $repositoryRoot = (
        & git `
            -C $sourceDirectory `
            rev-parse `
            --show-toplevel
    ).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repositoryRoot)) {
        throw "Repository-Root für lokale Windhawk-Mod konnte nicht ermittelt werden."
    }

    $generatedRoot = Join-Path `
        $repositoryRoot `
        ".generated\windhawk"

    New-Item `
        -ItemType Directory `
        -Path $generatedRoot `
        -Force |
    Out-Null

    $content = [IO.File]::ReadAllText($SourcePath).Replace("`r`n", "`n")
    $includePattern = '(?m)^[ \t]*#include[ \t]+"([^"]+)"[ \t]*$'

    for ($depth = 0; $depth -lt 16; $depth++) {
        $match = [regex]::Match($content, $includePattern)

        if (-not $match.Success) {
            break
        }

        $relativeInclude = $match.Groups[1].Value
        $includePath = Join-Path $sourceDirectory $relativeInclude

        if (-not (Test-Path -LiteralPath $includePath -PathType Leaf)) {
            throw "Lokaler Windhawk-Include fehlt: $relativeInclude"
        }

        $includeContent = [IO.File]::ReadAllText($includePath).Replace("`r`n", "`n")
        $includeContent = [regex]::Replace(
            $includeContent,
            '(?m)^[ \t]*#pragma[ \t]+once[ \t]*\r?\n?',
            ""
        )

        $content = (
            $content.Substring(0, $match.Index) +
            "// BEGIN INLINE: $relativeInclude`n" +
            $includeContent.TrimEnd() +
            "`n// END INLINE: $relativeInclude" +
            $content.Substring($match.Index + $match.Length)
        )
    }

    if ([regex]::IsMatch($content, $includePattern)) {
        throw "Zu viele verschachtelte lokale Windhawk-Includes."
    }

    $safeModId = $ModId -replace '[^a-zA-Z0-9._-]', '_'
    $outputPath = Join-Path `
        $generatedRoot `
        "$safeModId.wh.cpp"

    [IO.File]::WriteAllText(
        $outputPath,
        $content.TrimEnd() + "`n",
        [Text.UTF8Encoding]::new($false)
    )

    return $outputPath
}
function Install-WindhawkLocalMod {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $ModId,

        [Parameter(Mandatory)]
        [string] $SourceFile,

        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [string[]] $Replaces = @()
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    $sourcePath = Join-Path $RepositoryPath $SourceFile

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Lokale Windhawk-Mod-Quelle nicht gefunden: $sourcePath"
    }

    $desiredHash = (
        Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256
    ).Hash

    $stateDirectory = Join-Path `
        $RepositoryPath `
        ".generated\state\windhawk"

    $statePath = Join-Path `
        $stateDirectory `
        "$ModId.sha256"

    $storageModId = "local@$ModId"
    $installed = Test-WindhawkModInstalled -ModId $storageModId

    $currentHash = if (Test-Path -LiteralPath $statePath) {
        (
            Get-Content -LiteralPath $statePath -Raw
        ).Trim()
    }
    else {
        ""
    }

    $changed = (
        -not $installed -or
        $currentHash -cne $desiredHash
    )

    if ($changed) {
        Install-WindhawkDevelopmentTools

        $cli = Get-WindhawkCliPath

        if (-not $cli) {
            throw "windhawk-cli.exe wurde nach Installation der Development Tools nicht gefunden."
        }

        Write-Host "[COMPILE] Lokaler Windhawk-Mod: $ModId"

        $compileSourcePath = New-WindhawkAmalgamatedSource `
            -SourcePath $sourcePath `
            -ModId $ModId

        & $cli mod install $ModId --file $compileSourcePath

        if ($LASTEXITCODE -ne 0) {
            throw "Lokaler Windhawk-Mod konnte nicht installiert werden: $ModId"
        }

        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null

        Set-Content `
            -LiteralPath $statePath `
            -Value $desiredHash `
            -Encoding utf8NoBOM
    }
    else {
        Write-Host "[CURRENT] Lokaler Windhawk-Mod aktuell: $ModId" `
            -ForegroundColor Green
    }

    & $cli mod enable $storageModId

    if ($LASTEXITCODE -ne 0) {
        throw "Lokaler Windhawk-Mod konnte nicht aktiviert werden: $storageModId"
    }

    foreach ($replacedMod in $Replaces) {
        if (-not (Test-WindhawkModInstalled -ModId $replacedMod)) {
            continue
        }

        Write-Host "[REMOVE] Ersetzter Windhawk-Mod: $replacedMod"

        & $cli --yes mod remove $replacedMod

        if ($LASTEXITCODE -ne 0) {
            throw "Ersetzter Windhawk-Mod konnte nicht entfernt werden: $replacedMod"
        }

        $changed = $true
    }

    return $changed
}
