# Windows Setup Roadmap

## Ziel

Ein vollständig automatisiertes, reproduzierbares Entwickler- und Arbeitsplatz-Setup.

Ziele:
- sauberes Windows 11 Grundsystem
- reproduzierbare Installation
- Entwicklerumgebung
- Gaming Setup
- Firmenarbeitsplatz
- Linux-ähnlicher Workflow unter Windows
- einheitliches Design mit Catppuccin

---

# Phase 1 – Hardware & Grundsystem

## SSD Layout

### SSD 1
- Windows System
- Programme
- Setup Repository

### SSD 2

Dateisystem:
- ReFS

Struktur:

```
D:\
├── Dev
│   ├── Projects
│   ├── Git
│   ├── Docker
│   └── VMs
│
└── Games
    ├── Steam
    ├── Epic
    └── weitere Launcher
```

Automatisierung:
- SSD erkennen
- ReFS prüfen
- Volume Label setzen
- Ordnerstruktur erstellen
- Entwicklerpfade setzen

---

# Phase 2 – Windows Debloat & Hardening

## Ziel

Ein sauberes Windows:
- weniger Hintergrunddienste
- weniger Telemetrie
- weniger Werbung
- bessere Performance

## Entfernen nicht benötigter Apps

Prüfen:
- Teams Consumer
- Clipchamp
- Xbox Apps
- Bing Apps
- News
- Wetter
- Feedback Hub
- Copilot

Nicht entfernen:
- Microsoft Store
- Windows Terminal
- Fotos
- Rechner
- Notepad

## Datenschutz

- Telemetrie reduzieren
- Werbe-ID deaktivieren
- App Tracking deaktivieren
- Feedback deaktivieren

## Dienste prüfen

- Connected User Experiences
- Diagnostic Data
- Retail Demo
- Fax
- Remote Registry
- Maps Broker
- Xbox Services

Nicht deaktivieren:
- Windows Update
- Defender
- Firewall
- BITS

---

# Phase 3 – Sicherheit

Prüfungen:
- Windows Passwort vorhanden
- Windows Hello aktiviert
- BitLocker Status
- Defender Status
- Firewall Status
- Secure Boot

---

# Phase 4 – Treiber

Drivers.ps1 Refactoring:

```
modules
└── Drivers
    ├── Detection.ps1
    ├── Nvidia.ps1
    ├── Intel.ps1
    ├── Firmware.ps1
    └── Tools.ps1
```

Hardware Erkennung:
- CPU
- GPU
- RAM
- SSD
- Monitor

---

# Phase 5 – Netzwerk & VPN

## OpenVPN

Vorgabe:
- feste Version OpenVPN 2.7.101

Aufgaben:
- Installation
- Versionsprüfung
- Update verhindern
- Profile konfigurieren

---

# Phase 6 – Paketverwaltung

Struktur:

```
Packages
├── Development
├── Browsers
├── Communication
├── Media
├── Gaming
└── Tools
```

Verbesserungen:
- Logging
- Retry
- Fehlerhandling
- Installationsstatus

---

# Phase 7 – Entwicklerumgebung

Erledigt:
- fnm
- Node LTS
- Bun
- Go

Weitere:
- PATH Reparatur
- Versionsprüfung

## Git

- Name
- Email
- globale Config

Erweitern:
- Aliases
- SSH Keys
- GPG Signing

## VS Code

- Installation
- Settings
- Extensions
- Codex Integration

Extensions:
- ESLint
- Prettier
- Tailwind
- Prisma
- Docker
- GitLens
- Codex

---

# Phase 8 – Browser

## Chrome Beta

Erledigt:
- Installation
- Enterprise Policies
- Extension Deployment

Extensions:
- iCloud Passwords
- AdBlock Plus

## Zen Browser

Erledigt:
- Installation
- Extensions
- deutsche Sprache
- deutsches Wörterbuch
- policies.json

Noch:
- Session Restore
- Datenschutz Einstellungen
- Suchmaschine
- Telemetrie deaktivieren
- Firefox Studies deaktivieren
- Pocket deaktivieren

Theme:
- optional, da Zen bereits dunkel ist

---

# Phase 9 – Apple Integration

## iCloud

Erledigt:
- Installation
- iCloud Passwörter
- Windows Hello Prüfung

Noch:
- iCloud Drive
- Synchronisation prüfen

---

# Phase 10 – Firmen Tools

Installieren:
- Remote Desktop Manager
- FileZilla
- PCVisit Supporter Modul

Konfiguration:
- RDP Profile
- VPN Abhängigkeiten
- Zertifikate

---

# Phase 11 – Linux Workflow unter Windows

## Tiling Window Manager

Evaluieren:
- GlazeWM
- komorebi
- Alternativen

Ziele:
- Fenster automatisch anordnen
- Tastatursteuerung
- Workspaces

## Waybar ähnliche Leiste

Funktionen:
- Workspaces
- aktiver Workspace
- CPU
- RAM
- VPN
- Uhr
- Lautstärke
- Netzwerk

## Launcher

- Programmstarter
- Suche
- Tastenkürzel

---

# Phase 12 – Terminal Umgebung

## Nushell

- Config
- Aliases
- Starship Integration

## Starship

Catppuccin:
- Prompt
- Git Status
- Icons

## Windows Terminal

Profile:
- PowerShell
- Nushell
- Git Bash

Theme:
- Catppuccin Mocha

---

# Phase 13 – Gaming

Installieren:
- Steam
- Epic Games
- weitere Launcher

Optimieren:
- NVIDIA App
- HDR
- Monitor Einstellungen
- 265 Hz Setup

---

# Phase 14 – Peripherie

## Logitech G502 X Plus

Installation:
- Logitech G Hub

Konfiguration:
- DPI
- Polling Rate
- G-Shift
- Seitentasten
- Beleuchtung

Catppuccin:
- Mauve
- Blue
- oder RGB deaktiviert

## Monitor

Samsung Odyssey G93SD:
- Auflösung
- HDR
- Bildwiederholrate
- Farbraum

---

# Phase 15 – Design

## Catppuccin Mocha

Bereits:
- Hyprland
- Waybar
- Walker
- SwayNC
- Hyprlock

Windows:
- Windows Terminal
- VS Code
- Starship
- optional Browser

---

# Phase 16 – Setup Script Qualität

Architektur:

```
config
modules
packages
assets
logs
```

Verbesserungen:
- zentrale Logs
- Try/Catch
- klare Statusausgaben
- Exit Codes
- Dry Run Modus
- Wiederholbarkeit

Ziel:

Erster Lauf:
- installiert alles

Weitere Läufe:
- prüfen
- aktualisieren

---

# Phase 17 – Backup & Restore

Exportieren:
- Winget Pakete
- Git Config
- VS Code Extensions
- Terminal Settings
- Nushell Config
- Starship Config
- Browser Policies

Ziel:

Ein vollständiges reproduzierbares Arbeitsplatz-Image.
