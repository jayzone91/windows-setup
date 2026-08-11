function Get-TextFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $Text
    )

    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [Security.Cryptography.SHA256]::HashData($bytes)

    return [Convert]::ToHexString($hash).ToLowerInvariant()
}


function Get-FileSetFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $RootPath,

        [Parameter(Mandatory)]
        [System.IO.FileInfo[]] $Files
    )

    $entries = foreach ($file in @($Files | Sort-Object FullName)) {
        $relativePath = [System.IO.Path]::GetRelativePath(
            $RootPath,
            $file.FullName
        )

        $hash = (
            Get-FileHash `
                -LiteralPath $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        "{0}|{1}" -f $relativePath.Replace("\", "/"), $hash
    }

    return Get-TextFingerprint -Text ($entries -join "`n")
}


function Test-FileHardLinkTarget {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "fsutil ist ein natives Windows-Programm und verwendet positionsbasierte Argumente."
    )]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    $item = Get-Item `
        -LiteralPath $Path `
        -Force `
        -ErrorAction SilentlyContinue

    if (-not $item -or $item.LinkType -ne "HardLink") {
        return $false
    }

    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $targetFull = [System.IO.Path]::GetFullPath($Target)

    foreach ($reportedTarget in @($item.Target)) {
        if ([string]::IsNullOrWhiteSpace([string]$reportedTarget)) {
            continue
        }

        try {
            $reportedFull = [System.IO.Path]::GetFullPath(
                [string]$reportedTarget
            )

            if ($reportedFull -eq $targetFull) {
                return $true
            }
        }
        catch {
            Write-Verbose (
                "Hardlink-Ziel konnte nicht direkt normalisiert werden; " +
                "verwende fsutil-Fallback. Fehler: {0}" `
                    -f $_.Exception.Message
            )
        }
    }

    $fsutil = Get-Command `
        -Name "fsutil.exe" `
        -ErrorAction SilentlyContinue

    if (-not $fsutil) {
        return $false
    }

    $hardLinks = @(
        & $fsutil.Source hardlink list $pathFull 2>$null
    )

    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $driveRoot = [System.IO.Path]::GetPathRoot($pathFull)

    foreach ($hardLink in $hardLinks) {
        $candidate = ([string]$hardLink).Trim()

        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if ($candidate.StartsWith("\")) {
            $candidate = Join-Path `
                $driveRoot `
                $candidate.TrimStart("\")
        }

        try {
            if (
                [System.IO.Path]::GetFullPath($candidate) -eq
                $targetFull
            ) {
                return $true
            }
        }
        catch {
            continue
        }
    }

    return $false
}

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

        if ($existingItem.LinkType -eq "HardLink") {
            if (
                Test-FileHardLinkTarget `
                    -Path $Path `
                    -Target $Target
            ) {
                Write-Host "[OK] Hardlink bereits korrekt: $Path"
                return
            }

            Write-Host "[REMOVE] Bestehender Hardlink mit falschem Ziel: $Path"

            Remove-Item `
                -LiteralPath $Path `
                -Force
        }
        elseif ($existingItem.LinkType -eq "SymbolicLink") {
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
        -ItemType HardLink `
        -Path $Path `
        -Target $Target |
    Out-Null

    Write-Host (
        "[LINK] Hardlink: $Path -> $Target"
    ) -ForegroundColor Green
}


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
