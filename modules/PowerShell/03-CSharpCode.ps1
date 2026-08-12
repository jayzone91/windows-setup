function Get-CSharpCodeFiles {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Recurse `
            -File `
            -Filter "*.cs" `
            -ErrorAction Stop |
        Where-Object {
            $relativePath = [System.IO.Path]::GetRelativePath(
                $Path,
                $_.FullName
            ).Replace("\", "/")

            $relativePath -notmatch '(^|/)\.generated(/|$)' -and
            $relativePath -notmatch '(^|/)node_modules(/|$)' -and
            $relativePath -notmatch '(^|/)\.git(/|$)' -and
            $relativePath -notmatch '^external/nvim(/|$)' -and
            $relativePath -notmatch '^dotfiles/zebar/windows-setup-bar/dist(/|$)'
        } |
        Sort-Object FullName
    )
}

function Test-CSharpCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $files = @(Get-CSharpCodeFiles -Path $Path)

    if ($files.Count -eq 0) {
        Write-Host "[SKIP] Keine verwalteten C#-Quelldateien gefunden."
        return
    }

    $sourcePaths = @(
        $files |
        ForEach-Object {
            "'" + $_.FullName.Replace("'", "''") + "'"
        }
    )

    $isolatedScript = @"
`$ErrorActionPreference = "Stop"

`$sourceFiles = @(
$($sourcePaths -join ",`n")
)

Add-Type ``
    -LiteralPath `$sourceFiles ``
    -CompilerOptions @("warnaserror+") ``
    -ErrorAction Stop

exit 0
"@

    $encodedCommand = [Convert]::ToBase64String(
        [Text.Encoding]::Unicode.GetBytes($isolatedScript)
    )

    $output = @(
        & pwsh `
            -NoProfile `
            -EncodedCommand $encodedCommand `
            2>&1
    )

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $message = (
            $output |
            ForEach-Object {
                [string]$_
            }
        ) -join [Environment]::NewLine

        throw (
            "C#-Compilecheck fehlgeschlagen für {0} Datei(en): {1}" -f
            $files.Count,
            $message
        )
    }

    Write-Host (
        "[OK] C#-Compilecheck erfolgreich. Geprüfte Dateien: {0}" -f
        $files.Count
    ) -ForegroundColor Green
}