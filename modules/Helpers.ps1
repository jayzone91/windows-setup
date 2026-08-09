function Update-SessionPath {

    Write-Host ""
    Write-Host "[CONFIG] Aktualisiere PATH"


    $machinePath =
    [Environment]::GetEnvironmentVariable(
        "Path",
        "Machine"
    )

    $userPath =
    [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $currentPath =
    $env:Path


    $paths = @(
        $currentPath
        $machinePath
        $userPath
    ) |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    ForEach-Object {
        $_ -split ";"
    } |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    Select-Object -Unique


    $env:Path =
    $paths -join ";"


    Write-Host "[OK] PATH aktualisiert."
}


function Set-FileHardLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target,

        [switch] $ReplaceExistingFile
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
        throw "Hardlink-Ziel existiert nicht oder ist keine Datei: $Target"
    }

    $parent = Split-Path `
        -Path $Path `
        -Parent

    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
        Out-Null
    }

    $existingItem = Get-Item `
        -LiteralPath $Path `
        -Force `
        -ErrorAction SilentlyContinue

    if ($existingItem) {
        if ($existingItem.PSIsContainer) {
            throw "Hardlink-Zielpfad ist ein Verzeichnis: $Path"
        }

        if (
            $existingItem.LinkType -eq "SymbolicLink" -or
            $existingItem.LinkType -eq "HardLink"
        ) {
            Write-Host "[REMOVE] Bestehende Verknüpfung: $Path"

            Remove-Item `
                -LiteralPath $Path `
                -Force
        }
        elseif (
            $existingItem.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) {
            throw "Nicht unterstützte ReparsePoint-Datei vorhanden: $Path"
        }
        elseif ($ReplaceExistingFile) {
            Write-Host "[REMOVE] Bestehende Datei: $Path"

            Remove-Item `
                -LiteralPath $Path `
                -Force
        }
        else {
            throw (
                "Pfad existiert bereits als normale Datei: " +
                $Path
            )
        }
    }

    New-Item `
        -ItemType HardLink `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[LINK] Hardlink: $Path -> $Target"
    ) -ForegroundColor Green
}


function Set-DirectoryJunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        throw "Junction-Ziel existiert nicht oder ist kein Verzeichnis: $Target"
    }

    $parent = Split-Path `
        -Path $Path `
        -Parent

    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
        Out-Null
    }

    $existingItem = Get-Item `
        -LiteralPath $Path `
        -Force `
        -ErrorAction SilentlyContinue

    if ($existingItem) {
        if (-not $existingItem.PSIsContainer) {
            throw "Junction-Zielpfad ist eine Datei: $Path"
        }

        if (
            $existingItem.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) {
            $currentTarget = [string] $existingItem.Target

            if (
                $existingItem.LinkType -eq "Junction" -and
                $currentTarget -eq $Target
            ) {
                Write-Host "[OK] Junction bereits korrekt: $Path"
                return
            }

            Write-Host "[REMOVE] Bestehende Verzeichnis-Verknüpfung: $Path"

            Remove-Item `
                -LiteralPath $Path `
                -Force
        }
        else {
            throw (
                "Pfad existiert bereits und ist keine Junction: " +
                $Path
            )
        }
    }

    New-Item `
        -ItemType Junction `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[LINK] Junction: $Path -> $Target"
    ) -ForegroundColor Green
}
