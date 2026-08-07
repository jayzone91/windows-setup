$driverModuleRoot = $PSScriptRoot

$driverModules = @(
    "DriverCommon.ps1"
    "DriverInventory.ps1"
    "WindowsDriverUpdates.ps1"
    "IntelDrivers.ps1"
    "AsusDrivers.ps1"
    "Drivers.ps1"
)

foreach ($driverModule in $driverModules) {
    $driverModulePath = Join-Path $driverModuleRoot $driverModule

    if (-not (Test-Path $driverModulePath)) {
        throw "Treiber-Modul nicht gefunden: $driverModulePath"
    }

    . $driverModulePath
}
