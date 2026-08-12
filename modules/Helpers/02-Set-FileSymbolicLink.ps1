function Set-FileSymbolicLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target,

        [switch] $ReplaceExistingFile
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
        throw "Symlink-Ziel existiert nicht oder ist keine Datei: $Target"
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
            throw "Symlink-Zielpfad ist ein Verzeichnis: $Path"
        }

        if ($existingItem.LinkType -eq "SymbolicLink") {
            $currentTarget = [string] $existingItem.Target

            if ($currentTarget -eq $Target) {
                Write-Host "[OK] Symlink bereits korrekt: $Path"
                return
            }

            Write-Host "[REMOVE] Bestehender Symlink: $Path"

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
        -ItemType SymbolicLink `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[LINK] Symlink: $Path -> $Target"
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
