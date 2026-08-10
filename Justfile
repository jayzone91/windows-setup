# justfile

set shell := ["pwsh", "-NoProfile", "-Command"]

# Normaler manueller Setup-/Wartungslauf
update:
    pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1

# Nur Syntax/Qualitätschecks, später erweiterbar
check:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/PowerShell.ps1; Test-PowerShellCode -Path ."

# komorebi, whkd, masir und Zebar sauber neu starten
desktop-restart:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Restart-WindowsDesktopEnvironment"

# ASUS-/Drittanbieter-Treiber, Firmware und BIOS bewusst über Armoury Crate prüfen
asus-updates:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Open-AsusArmouryCrate"

# Aktuelle Logitech-G-HUB-Konfiguration bewusst ins Repository sichern
ghub-backup:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Backup-LogitechGHubConfiguration -RepositoryPath './config/lghub'"

# Gesicherte Logitech-G-HUB-Konfiguration bewusst wiederherstellen
ghub-restore:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Restore-LogitechGHubConfiguration -RepositoryPath './config/lghub'"