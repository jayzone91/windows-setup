# justfile

set shell := ["pwsh", "-NoProfile", "-Command"]

# Normaler manueller Setup-/Wartungslauf
update:
    pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1

# Nur Syntax/Qualitätschecks, später erweiterbar
check:
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-ScriptAnalyzer -Path . -Recurse"
