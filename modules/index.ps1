$moduleRoot = $PSScriptRoot

$modules = @(
    "Drivers\index.ps1"
    "Windows\index.ps1"
    "Browser.ps1"
    "Debloat.ps1"
    "Development.ps1"
    "Git.ps1"
    "Helpers.ps1"
    "Languages.ps1"
    "Logitech.ps1"
    "Notifications.ps1"
    "Nushell.ps1"
    "Packages.ps1"
    "PowerShell.ps1"
    "Security.ps1"
    "Storage.ps1"
    "Terminal.ps1"
    "VSCode.ps1"
    "WindowsUpdate.ps1"
)

foreach ($module in $modules) {
    $modulePath = Join-Path $moduleRoot $module

    if (-not (Test-Path $modulePath)) {
        throw "Modul nicht gefunden: $modulePath"
    }

    . $modulePath
}

Write-Host "[OK] PowerShell-Module geladen." -ForegroundColor Green
