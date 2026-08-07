function Get-MissingDevices {
    Get-PnpDevice -PresentOnly |
    Where-Object {
        $_.Status -ne "OK" -or
        $_.Class -eq "Unknown"
    } |
    Select-Object Class, FriendlyName, Status, InstanceId
}

function Show-DriverInventory {
    Write-Step "Installierte relevante Treiber"

    Get-CimInstance Win32_PnPSignedDriver |
    Where-Object {
        $_.DeviceClass -in @(
            "DISPLAY",
            "NET",
            "MEDIA",
            "Bluetooth"
        )
    } |
    Select-Object `
        DeviceName,
    DriverProviderName,
    DriverVersion,
    DriverDate |
    Sort-Object DeviceName |
    Format-Table -AutoSize
}
