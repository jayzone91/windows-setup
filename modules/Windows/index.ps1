$windowsModuleRoot = $PSScriptRoot

$windowsModules = @(
    "WindowsWallpaper.ps1"
    "WindowsShell.ps1"
    "WindowsSystem.ps1"
    "SetupTemp.ps1"
)

foreach ($windowsModule in $windowsModules) {
    $windowsModulePath = Join-Path $windowsModuleRoot $windowsModule

    if (-not (Test-Path $windowsModulePath)) {
        throw "Windows-Modul nicht gefunden: $windowsModulePath"
    }

    . $windowsModulePath
}
