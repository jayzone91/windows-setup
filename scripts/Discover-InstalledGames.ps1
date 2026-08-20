$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

. (Join-Path $root "modules\index.ps1")

$storageConfig = Import-PowerShellDataFile (
    Join-Path $root "config\storage.psd1"
)

$executables = @(
    Get-InstalledGameExecutable -StorageConfig $storageConfig
)

if ($executables.Count -eq 0) {
    Write-Host "[INFO] Keine Spiele-Executables gefunden."
    exit 0
}

$executables |
    Format-Table `
        Launcher,
        Game,
        Executable,
        Running,
        Path `
        -AutoSize