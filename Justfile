# justfile

set shell := ["pwsh", "-NoProfile", "-Command"]

# Normaler manueller Setup-/Wartungslauf
update:
    pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1

# Nur Syntax/Qualitätschecks, später erweiterbar
check:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-ScriptAnalyzer -Path . -Recurse"

# komorebi, whkd, masir und Zebar sauber neu starten
desktop-restart:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Restart-WindowsDesktopEnvironment"
# Aktuelle Logitech-G-HUB-Konfiguration bewusst ins Repository sichern
ghub-backup:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Backup-LogitechGHubConfiguration -RepositoryPath './config/lghub'"

# Gesicherte Logitech-G-HUB-Konfiguration bewusst wiederherstellen
ghub-restore:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Restore-LogitechGHubConfiguration -RepositoryPath './config/lghub'"