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
