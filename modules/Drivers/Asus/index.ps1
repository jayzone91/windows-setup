$asusModuleRoot = $PSScriptRoot

$asusModules = @(
    "ArmouryCrate.ps1"
    "AsusDriverDiscovery.ps1"
    "AsusDriverPackage.ps1"
    "AsusDriverInstaller.ps1"
    "AsusDrivers.ps1"
    "AsusArmouryCrateUpdates.ps1"
)

foreach ($asusModule in $asusModules) {
    $asusModulePath = Join-Path $asusModuleRoot $asusModule

    if (-not (Test-Path $asusModulePath)) {
        throw "ASUS-Modul nicht gefunden: $asusModulePath"
    }

    . $asusModulePath
}
