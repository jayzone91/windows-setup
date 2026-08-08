function Set-WindowsPowerPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Energieoptionen"
    Write-Host "========================================"

    Write-Host "[CONFIG] Monitor niemals automatisch ausschalten"
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0

    Write-Host "[CONFIG] Standby deaktivieren"
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0

    Write-Host "[CONFIG] Ruhezustand deaktivieren"
    powercfg /hibernate off

    Write-Host "[OK] Energieoptionen gesetzt." -ForegroundColor Green
}

function Set-WindowsHDR {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " HDR"
    Write-Host "========================================"

    Write-Warning (
        "HDR kann auf diesem System aktuell nicht zuverlässig " +
        "über die Windows DisplayConfig API automatisiert werden."
    )

    Write-Host (
        "[INFO] HDR bitte einmalig über " +
        "'Einstellungen > System > Anzeige > HDR' aktivieren."
    )
}

function Disable-WindowsSnap {

    Write-Host "[CONFIG] Windows Snap deaktivieren"


    $desktopPath =
    "HKCU:\Control Panel\Desktop"

    $explorerAdvancedPath =
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"


    Set-ItemProperty `
        -Path $desktopPath `
        -Name "WindowArrangementActive" `
        -Value "0"


    New-ItemProperty `
        -Path $explorerAdvancedPath `
        -Name "EnableSnapAssistFlyout" `
        -PropertyType DWord `
        -Value 0 `
        -Force |
    Out-Null


    New-ItemProperty `
        -Path $explorerAdvancedPath `
        -Name "EnableSnapBar" `
        -PropertyType DWord `
        -Value 0 `
        -Force |
    Out-Null


    Write-Host "[OK] Windows Snap deaktiviert." `
        -ForegroundColor Green
}
