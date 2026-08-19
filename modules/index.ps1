$moduleRoot = $PSScriptRoot

$modules = @(
    "Drivers\index.ps1"
    "Windows\index.ps1"
    "Browser\index.ps1"
    "Debloat.ps1"
    "Development\index.ps1"
    "FileAssociations.ps1"
    "Git.ps1"
    "Gaming.ps1"
    "Helpers\index.ps1"
    "HomeOffice.ps1"
    "Languages.ps1"
    "Logitech.ps1"
    "Mail\index.ps1"
    "Notifications.ps1"
    "Packages\index.ps1"
    "PowerToys\index.ps1"
    "Raycast.ps1"
    "PowerShell\index.ps1"
    "ScheduledTasks\index.ps1"
    "Secrets\index.ps1"
    "Security.ps1"
    "Storage\index.ps1"
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
