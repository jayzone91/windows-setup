function Get-VSCodeCommand {
    $command = Get-Command "code" -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}


function Test-VSCodeExtension {
    param(
        [Parameter(Mandatory)]
        [string] $ExtensionId
    )

    $code = Get-VSCodeCommand

    if (-not $code) {
        return $false
    }

    $extensions = @(
        & $code --list-extensions 2>$null |
        ForEach-Object {
            $_.Trim().ToLowerInvariant()
        }
    )

    return $extensions -contains $ExtensionId.ToLowerInvariant()
}


function Install-VSCodeExtension {
    param(
        [Parameter(Mandatory)]
        [string] $ExtensionId
    )

    $code = Get-VSCodeCommand

    if (-not $code) {
        throw "Visual Studio Code wurde nicht gefunden"
    }

    Write-Host ""
    Write-Host "[CHECK] VS Code Extension: $ExtensionId"

    if (Test-VSCodeExtension -ExtensionId $ExtensionId) {
        Write-Host "[OK] Bereits installiert." -ForegroundColor Green
        return
    }

    Write-Host "[INSTALL] $ExtensionId" -ForegroundColor Cyan

    & $code `
        --install-extension $ExtensionId `
        --force

    if ($LASTEXITCODE -ne 0) {
        throw "VS Code Extension konnte nicht installiert werden: $ExtensionId"
    }

    Write-Host "[OK] $ExtensionId installiert." -ForegroundColor Green
}


function Install-VSCodeExtensions {
    param(
        [Parameter(Mandatory)]
        [array] $Extensions
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " VS Code Extensions"
    Write-Host "========================================"

    foreach ($extension in $Extensions) {
        Install-VSCodeExtension -ExtensionId $extension
    }
}


function Set-VSCodeSettings {
    param(
        [Parameter(Mandatory)]
        [string] $Source
    )

    $settingsDirectory = Join-Path `
        $env:APPDATA `
        "Code\User"

    $destination = Join-Path `
        $settingsDirectory `
        "settings.json"

    if (-not (Test-Path $settingsDirectory)) {
        New-Item `
            -Path $settingsDirectory `
            -ItemType Directory `
            -Force |
        Out-Null
    }

    $existingItem = Get-Item `
        -LiteralPath $destination `
        -Force `
        -ErrorAction SilentlyContinue

    if (
        $existingItem -and
        -not $existingItem.LinkType
    ) {
        $backup = "$destination.backup"

        Write-Host "[BACKUP] $destination -> $backup"

        Copy-Item `
            -Path $destination `
            -Destination $backup `
            -Force

        Remove-Item `
            -LiteralPath $destination `
            -Force
    }

    Set-FileHardLink `
        -Path $destination `
        -Target $Source

    Write-Host "[OK] VS Code Settings verlinkt." `
        -ForegroundColor Green
}
