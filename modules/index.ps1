$moduleRoot = $PSScriptRoot

$modules = @(
    "Browser.ps1"
    "Drivers.ps1"
    "Git.ps1"
    "Helpers.ps1"
    "Languages.ps1"
    "Nushell.ps1"
    "Packages.ps1"
    "PowerShell.ps1"
    "Security.ps1"
    "Terminal.ps1"
    "VSCode.ps1"
    "Windows.ps1"
)

foreach ($module in $modules) {
    $modulePath = Join-Path $moduleRoot $module

    if (-not (Test-Path $modulePath)) {
        throw "Modul nicht gefunden: $modulePath"
    }

    . $modulePath
}

Write-Host "[OK] PowerShell-Module geladen." -ForegroundColor Green
