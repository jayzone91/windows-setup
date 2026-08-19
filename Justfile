# justfile

set shell := ["pwsh", "-NoProfile", "-Command"]

# Normaler manueller Setup-/Wartungslauf: bewusst ohne Konsolenausgabe
update:
    @pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1

# Diagnosemodus: nur Warnungen und Fehler
update-warning:
    @pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1 -Warning

# Vollständige Ausgabe für funktionale Tests und Diagnose
update-log:
    @pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1 -Log

# Reproduzierbarer Performance-Test des stillen Bootstrap
update-performance:
    @pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/Measure-BootstrapPerformance.ps1

# Vollständiger manueller Codecheck; erfolgreicher Lauf aktualisiert den Bootstrap-Fingerprint
check:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/Helpers/index.ps1; . ./modules/PowerShell/index.ps1; Test-PowerShellCode -Path . -FailOnAnyIssue -UpdateFingerprint"


# ASUS-/Drittanbieter-Treiber, Firmware und BIOS bewusst über Armoury Crate prüfen
asus-updates:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Open-AsusArmouryCrate"

# Aktuelle Logitech-G-HUB-Konfiguration bewusst ins Repository sichern
ghub-backup:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Backup-LogitechGHubConfiguration -RepositoryPath './config/lghub'"

# Gesicherte Logitech-G-HUB-Konfiguration bewusst wiederherstellen
ghub-restore:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ". ./modules/index.ps1; Restore-LogitechGHubConfiguration -RepositoryPath './config/lghub'"