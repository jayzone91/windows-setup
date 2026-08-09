# Windows Setup

Automatisiertes, reproduzierbares und weitgehend idempotentes Setup für meine Windows-11-Arbeitsumgebung.

Das Repository dient sowohl zur Einrichtung eines frisch installierten Windows-Systems als auch zur regelmäßigen Wartung eines bereits eingerichteten Rechners. Derselbe zentrale `bootstrap.ps1` wird für Neuinstallation, manuelle Setup-Durchläufe und automatische Wartung verwendet.

Ein zweites wichtiges Ziel ist eine Windows-Desktop-Umgebung, die sich funktional und optisch an meiner Arch-/Hyprland-Workstation orientiert. Dafür werden komorebi, whkd, masir, Zebar und OneCommander kombiniert und mit Catppuccin Mocha gestaltet.

## Aktueller Stand

Der Kern des Setups ist produktiv nutzbar und weitgehend reproduzierbar.

Bereits umgesetzt sind unter anderem:

- Paketinstallation und Updates über `winget` und Microsoft Store
- Versions-Pinning einzelner Pakete
- Windows-Debloat und Grundkonfiguration
- Windows- und Microsoft-Updates
- Treiberlogik für NVIDIA und Intel
- PowerShell-, Node.js-, Bun- und Go-Entwicklungsumgebung
- Git, GitHub CLI und GitHub Desktop
- Visual Studio Code inklusive Extensions und Settings
- Windows Terminal, Nushell und Starship
- Zen Browser und Google Chrome Beta
- Logitech G HUB inklusive Konfigurationssynchronisierung
- ReFS Dev Drive und separates Games-Laufwerk
- Microsoft Defender Dev Drive Performance Mode
- automatische wöchentliche Wartung
- Desktop-Benachrichtigungen
- PSScriptAnalyzer-Codeprüfung
- `just` als einheitliche Bedienoberfläche für manuelle Projektaktionen
- `just update` für den vollständigen manuellen Wartungs-/Setup-Lauf
- `just check` für die rekursive PSScriptAnalyzer-Prüfung
- Bootstrap-Ausführung mit `ExecutionPolicy Bypass` ausschließlich auf Prozessebene
- komorebi + whkd als Tiling Window Manager
- masir für Focus Follows Mouse
- Zebar als eigene interaktive Desktop-Bar
- OneCommander als Explorer-Ersatz
- Catppuccin-Mocha-Theme für OneCommander
- Catppuccin-Mocha-Folder-Icons für OneCommander
- automatisch generiertes Catppuccin-Mocha-File-Icon-Pack aus `catppuccin/vscode-icons`
- Datei-Dotfiles werden als NTFS-Hardlinks eingebunden
- Verzeichnis-Dotfiles werden als NTFS-Junctions eingebunden
- Catppuccin Mocha als gemeinsame Designsprache
- präzisere Reboot-Erkennung mit Auswertung konkreter Ursachen

Die nächsten größeren Arbeitspakete sind NanaZip, Home-Office-Werkzeuge, PowerToys Command Palette + Everything, Windhawk für Taskbar, Startmenü und Notification Center, ein eigenes OSD sowie weiterer Catppuccin-Polish.

Siehe auch [`roadmap.md`](roadmap.md).

---

# Installation

Eine **PowerShell als Administrator** öffnen und ausführen:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

`init.ps1` übernimmt automatisch:

1. Prüfung von `winget`
2. Installation von Git, falls erforderlich
3. Klonen des Repositories nach `%USERPROFILE%\windows-setup`
4. Aktualisierung eines bereits vorhandenen Repositories
5. Start von `bootstrap.ps1` in einem eigenen PowerShell-Prozess
6. Verwendung von `ExecutionPolicy Bypass` ausschließlich für diesen Bootstrap-Prozess

Die globale Benutzer- oder System-Execution-Policy wird dabei **nicht** verändert.

Das ist wichtig, weil das Repository mehrere PowerShell-Dateien unter `modules/` und `scripts/` nachlädt. Der komplette Bootstrap-Prozess erhält deshalb eine definierte Ausführungsumgebung, ohne die Sicherheitskonfiguration des Systems dauerhaft aufzuweichen.

---

# Manuelle Nutzung mit Just

Nach der Erstinstallation steht `just` als einheitliche Bedienoberfläche für wiederkehrende Projektaktionen zur Verfügung.

`just` wird über `config/packages.psd1` als **Base-Abhängigkeit** mit der Winget-ID `Casey.Just` installiert.

Das `Justfile` enthält bewusst keine eigentliche Setup-Logik. Es ruft lediglich die bestehenden PowerShell-Einstiegspunkte auf.

## Setup aktualisieren

```powershell
cd ~/windows-setup
just update
```

`just update` startet:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1
```

Der vollständige Bootstrap:

- aktualisiert das Repository, sofern keine lokalen Änderungen vorliegen,
- installiert oder aktualisiert konfigurierte Pakete,
- synchronisiert Konfigurationen,
- führt Treiber- und Windows-Update-Logik aus,
- wendet Desktop- und Entwicklungs-Konfiguration erneut an,
- prüft Rebootbedarf,
- prüft Repository-Status und ungepushte Commits,
- richtet bzw. aktualisiert Scheduled Tasks,
- führt die statische PowerShell-Prüfung aus.

## Projekt prüfen

```powershell
just check
```

`just check` führt PSScriptAnalyzer rekursiv über das gesamte Repository aus:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

## Direkter Bootstrap-Aufruf

Falls `just` nicht verfügbar ist, kann der Bootstrap weiterhin direkt gestartet werden:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Der direkte PowerShell-Aufruf bleibt der technische Fallback. Für normale manuelle Nutzung ist `just update` der bevorzugte Einstiegspunkt.

---

# Projektstruktur

```text
windows-setup/
├── init.ps1
├── bootstrap.ps1
├── Justfile
├── README.md
├── roadmap.md
├── PSScriptAnalyzerSettings.psd1
├── config/
├── modules/
├── scripts/
├── dotfiles/
├── assets/
└── .generated/
```

Grundprinzip:

```text
Justfile
   │
   │ Bedienoberfläche
   ▼
PowerShell Entry Points
   │
   │ Orchestrierung
   ▼
modules/*.ps1
   │
   │ eigentliche Logik
   ▼
Windows / winget / Registry / Anwendungen
```

Das `Justfile` soll nicht zu einer zweiten Setup-Architektur werden. Neue wiederkehrende manuelle Aktionen können als Recipes ergänzt werden, während die eigentliche Implementierung weiterhin in PowerShell verbleibt.

---

# Konfigurations-Synchronisierung

Das Repository ist die Quelle der Wahrheit für verwaltete Konfigurationsdateien.

Es gilt projektweit folgende Regel:

- **Dateien** werden als NTFS-Hardlinks eingebunden.
- **Verzeichnisse** werden als NTFS-Junctions eingebunden.
- Symbolic Links werden nicht mehr verwendet.

Dadurch bleiben die Konfigurationen direkt mit den Dateien im Repository verbunden, werden von Windows-Programmen aber als normale Dateien beziehungsweise Verzeichnisse behandelt.

Beispiele für Hardlinks:

```text
%USERPROFILE%\komorebi.json
%USERPROFILE%\komorebi.bar.json
%USERPROFILE%\applications.json
%USERPROFILE%\.config\whkdrc
%USERPROFILE%\.config\starship.toml
%APPDATA%\nushell\config.nu
%APPDATA%\nushell\env.nu
%APPDATA%\Code\User\settings.json
%USERPROFILE%\.glzr\zebar\settings.json
```

Beispiel für eine Junction:

```text
%USERPROFILE%\.glzr\zebar\windows-setup-bar
```

Bestehende verwaltete Symbolic Links werden beim nächsten Setup-Durchlauf automatisch entfernt und durch Hardlinks beziehungsweise Junctions ersetzt.

Generierte Inhalte liegen unter `.generated/` und werden nicht committed. Generator-Code selbst bleibt versioniert.

---

# Desktop Experience

## Zielbild

```text
Arch                           Windows
────────────────────────────────────────────────
Hyprland                       komorebi
Waybar                         Zebar
Focus follows mouse            masir
Fuzzel                         PowerToys Command Palette (geplant)
Dolphin                        OneCommander
SwayOSD                        eigenes OSD (geplant)
Catppuccin Mocha               Catppuccin Mocha
```

Aktuelle Windows-Architektur:

```text
Windows Desktop
│
├── Window Management
│   ├── komorebi
│   ├── whkd
│   └── masir
│
├── Desktop Bar
│   └── Zebar
│
├── File Manager
│   └── OneCommander
│
├── Launcher / Search (geplant)
│   ├── PowerToys Command Palette
│   └── Everything
│
├── Windows Shell Styling (geplant)
│   └── Windhawk
│       ├── Taskbar Styler
│       ├── Start Menu Styler
│       └── Notification Center Styler
│
└── OSD (geplant)
    └── eigenes Catppuccin OSD
        ├── Volume
        ├── Mute
        ├── Brightness
        ├── Media
        ├── Caps Lock
        └── Num Lock
```

## komorebi

komorebi übernimmt die Tiling-Fensterverwaltung.

Umgesetzt sind:

- fünf Workspaces
- Windows Snap deaktiviert
- Catppuccin-Integration
- `UltrawideVerticalStack` als bevorzugtes Layout
- Fokus-, Move-, Resize-, Stack- und Workspace-Steuerung über whkd
- reproduzierbare Konfiguration unter `dotfiles/komorebi/`
- Konfigurationsdateien als Hardlinks
- Autostart über die Windows-Aufgabenplanung
- erhöhte Ausführung, damit auch erhöhte Fenster getiled werden können

## Focus Follows Mouse mit masir

`LGUG2Z.masir` ergänzt komorebi um Focus Follows Mouse.

masir nutzt seine automatische komorebi-Integration und wird gemeinsam mit komorebi/whkd über den Desktop-Scheduled-Task gestartet.

## Zebar

Zebar ersetzt im normalen Desktop-Betrieb weitgehend die Windows-Taskbar.

Die eigene Bar befindet sich unter:

```text
dotfiles/zebar/windows-setup-bar/
```

Sie wird mit TypeScript entwickelt und lokal mit esbuild gebündelt. Es bestehen keine CDN-Abhängigkeiten.

Die `settings.json` wird per Hardlink eingebunden; das Widget-Verzeichnis selbst wird per Junction verknüpft.

Umgesetzt sind unter anderem:

- fünf komorebi-Workspaces mit Klicksteuerung
- Layout-Anzeige und Layout-Popup
- Titel und echtes Windows-App-Icon des fokussierten Fensters
- CPU-, RAM-, Storage- und Netzwerk-Anzeige
- Lautstärke und Mute-Steuerung
- Mediensteuerung
- deutsches Datum und 24-Stunden-Uhrzeit

Batterie und Systray sind bewusst nicht Bestandteil der Bar.

### Entwicklung

```powershell
cd ~/windows-setup/dotfiles/zebar/windows-setup-bar
npm ci
npm run build
```

Für Entwicklung und Neustart:

```powershell
npm run dev:reload
```

---

# OneCommander

OneCommander ersetzt den Windows Explorer im normalen Dateimanager-Workflow.

Das Setup übernimmt:

- Installation über `winget`
- OOBE-/Lizenzstatus erkennen, aber nicht automatisiert bestätigen
- `Win + E` auf OneCommander umbiegen
- OneCommander als Standard-Dateimanager für Verzeichnisse und Laufwerke registrieren
- Catppuccin-Mocha-Theme installieren
- Catppuccin-Mocha-Accent konfigurieren
- Main-Folder-Icon installieren
- Catppuccin-Folder-Icon-Pack einbinden
- Catppuccin-File-Icon-Pack einbinden
- Datei-Alter-Farben für das dunkle Theme konfigurieren

## Theme

Das Theme liegt unter:

```text
dotfiles/onecommander/Themes/CatppuccinMocha/
```

Es wird per Junction nach:

```text
%LOCALAPPDATA%\OneCommander\Themes\CatppuccinMocha
```

eingebunden.

## Folder Icons

Manuell gepflegte OneCommander-Folder-Icons liegen unter:

```text
dotfiles/onecommander/Icons/
├── MainFolderIcon/
│   └── CatppuccinMocha.png
└── FolderIcons/
    └── CatppuccinMocha/
```

Das Main-Folder-Icon wird als echte Datei nach OneCommander kopiert. Das Folder-Icon-Theme wird per Junction eingebunden.

## File Icons

Die File-Icons werden aus dem offiziellen Projekt:

```text
catppuccin/vscode-icons
```

generiert.

Der Build liegt unter:

```text
scripts/Build-OneCommanderFileIcons.ps1
scripts/onecommander-file-icons/
```

Generierte Daten werden **nicht committed**. Sie landen unter:

```text
.generated/onecommander/
├── Sources/
│   └── vscode-icons/
├── Rendered/
│   └── CatppuccinMocha/
└── FileIcons/
    └── CatppuccinMocha/
```

`Rendered` enthält die gerenderten PNGs. `FileIcons` enthält OneCommander-kompatible Dateinamen als NTFS-Hardlinks auf diese PNGs.

Das erzeugte `FileIcons/CatppuccinMocha` wird anschließend per Junction nach OneCommander eingebunden.

Der Generator übernimmt:

- sämtliche Catppuccin-Icon-Definitionen
- Extension-Zuordnungen
- exakte Dateinamen
- Dotfiles
- zusätzliche projektbezogene Aliase
- SVG → PNG Rendering
- Manifest mit Mapping, übersprungenen Einträgen und Kollisionen

---

# Catppuccin Mocha

Catppuccin Mocha ist die gemeinsame Designsprache des Windows-Desktops.

Es wird bewusst keine universelle CSS-Datei für alle Anwendungen erzwungen. Jedes Programm verwendet die für es sinnvollste und stabilste Theme-Methode.

| Komponente          | Theme-Methode                                 |
| ------------------- | --------------------------------------------- |
| komorebi            | integriertes Catppuccin                       |
| Zebar               | eigenes CSS                                   |
| OneCommander        | eigenes XAML + Icon-Packs                     |
| Windows Terminal    | Farbschema in `settings.json`                 |
| VS Code             | Catppuccin Theme/Extension                    |
| Zen Browser         | eigene CSS-/UI-Anpassungen                    |
| Taskbar             | Windhawk Taskbar Styler (geplant)             |
| Startmenü           | Windhawk Start Menu Styler (geplant)          |
| Notification Center | Windhawk Notification Center Styler (geplant) |
| eigenes OSD         | eigene Styles (geplant)                       |

Der native File Explorer Styler über Windhawk wird nicht mehr verfolgt; OneCommander übernimmt stattdessen den Dateimanager-Part.

---

# Software und Paketverwaltung

Software wird deklarativ über `config/packages.psd1` verwaltet.

Pakete können:

- installiert werden,
- automatisch aktualisiert werden,
- von Updates ausgeschlossen werden,
- auf eine bestimmte Version festgelegt werden.

Die installierte Version gepinnter Pakete wird anhand der exakten Winget-Paket-ID ermittelt.

OpenVPN ist bewusst auf Version `2.7.101` festgelegt.

## Base

Base enthält Voraussetzungen, die für das Repository bzw. den grundlegenden Workflow selbst wichtig sind.

Aktuell unter anderem:

- JetBrainsMono Nerd Font
- Just (`Casey.Just`)

## Tools

Aktuell unter anderem:

- Windows HDR Calibration
- iCloud
- OpenVPN
- Logitech G HUB
- komorebi
- whkd
- masir
- Zebar
- OneCommander

Geplant:

- NanaZip
- PowerToys
- Everything

## Development

Unter anderem:

- fnm
- Go
- Bun
- Git
- GitHub CLI
- GitHub Desktop
- Visual Studio Code
- PowerShell 7
- Nushell
- Starship

---

# Automatische wöchentliche Wartung

Der Bootstrap richtet die Windows-Aufgabe:

```text
Windows Setup Weekly Maintenance
```

ein.

Sie startet den vollständigen `bootstrap.ps1` jeden Sonntag um 12:00 Uhr.

Auch der Scheduled Task startet PowerShell mit:

```text
-NoProfile -ExecutionPolicy Bypass -File bootstrap.ps1
```

Der Rechner wird nicht automatisch neu gestartet.

Der Wartungslauf umfasst unter anderem:

- Repository aktualisieren, sofern keine lokalen Änderungen vorliegen
- konfigurierte Winget-/Store-Pakete aktualisieren
- Entwicklungswerkzeuge aktualisieren
- Treiber prüfen und aktualisieren
- Windows- und Microsoft-Updates installieren
- Logitech-G-HUB-Konfiguration synchronisieren
- Windows- und Entwicklungs-Konfiguration erneut anwenden
- Zebar-Abhängigkeiten und Build sicherstellen
- OneCommander-Theme und Icons sicherstellen
- Catppuccin-File-Icons bei Bedarf generieren
- PSScriptAnalyzer ausführen
- erforderlichen Neustart erkennen
- lokale Git-Änderungen erkennen
- noch nicht gepushte Commits erkennen

## Reboot-Erkennung

Die Neustartprüfung unterscheidet konkrete Ursachen:

- Component Based Servicing
- Windows Update
- relevante `PendingFileRenameOperations`

Reine temporäre Installer-Cleanup-Einträge, beispielsweise NSIS-Temp-Dateien unter `%TEMP%`, werden nicht als relevanter Neustartbedarf gewertet.

## Desktop-Benachrichtigungen

Für Benachrichtigungen wird `BurntToast` verwendet.

Benachrichtigt wird bei:

- relevantem ausstehenden Neustart
- lokalen Repository-Änderungen
- ungepushten Commits

---

# Sicherheit und Ausführungsrichtlinie

Das Projekt verändert die globale PowerShell Execution Policy **nicht**.

Für kontrollierte Bootstrap-Läufe wird `ExecutionPolicy Bypass` ausschließlich auf Prozessebene verwendet:

- beim Start durch `init.ps1`
- bei `just update`
- beim wöchentlichen Scheduled Task

Damit können alle vom Repository nachgeladenen PowerShell-Module und Build-Skripte innerhalb des kontrollierten Setup-Prozesses ausgeführt werden, ohne `CurrentUser` oder `LocalMachine` dauerhaft aufzuweichen.

Eine durch zentrale Windows-Gruppenrichtlinien gesetzte `MachinePolicy` oder `UserPolicy` wird nicht umgangen und bleibt maßgeblich.

---

# Codequalität

PSScriptAnalyzer ist Teil des Setups.

Manuell:

```powershell
just check
```

Der Bootstrap führt ebenfalls eine PowerShell-Codeprüfung aus.

Geplant sind zusätzlich:

- GitHub Actions für statische Prüfung
- Pester-Tests für kritische Helper
- Tests für Paket-Versionserkennung
- Tests für Hardlink-/Junction-Migration
- Tests für Reboot-Erkennung
- Dry-Run / WhatIf

---

# Wichtige Architekturentscheidungen

Folgende Entscheidungen sind bewusst getroffen und sollen nicht ohne technischen Grund zurückgebaut werden:

- ein zentraler `bootstrap.ps1` statt separater Setup-/Maintenance-Skripte
- `init.ps1` als minimaler Erstinstallations-Einstieg
- `Justfile` als Bedienoberfläche, nicht als Ort für Setup-Logik
- `just update` als bevorzugter manueller Wartungs-/Setup-Aufruf
- `just check` als bevorzugte manuelle statische Prüfung
- Execution Policy nur auf Prozessebene setzen
- keine dauerhafte Änderung der globalen PowerShell Execution Policy
- Dateien per NTFS-Hardlink
- Verzeichnisse per NTFS-Junction
- keine Symbolic Links für verwaltete Dotfiles
- generierte Inhalte ausschließlich unter `.generated/`
- keine generierten OneCommander-Icons committen
- OneCommander statt Windhawk File Explorer Styler
- kein automatischer Git-Commit oder Push
- kein automatischer Windows-Neustart
- keine aggressiven pauschalen Service-/Debloat-Tweaks
- Catppuccin Mocha als gemeinsame Designsprache
- Funktionalität und Wartbarkeit vor rein optischem Styling

---

# Nächste Schritte

Die ausführliche Priorisierung befindet sich in [`roadmap.md`](roadmap.md).

Aktuell sind die nächsten Arbeitspakete:

1. NanaZip
2. Home Office Paketgruppe
3. PowerToys Command Palette + Everything
4. Windhawk Shell Styling
5. eigenes Catppuccin OSD
6. Gaming
7. Logging, Tests und weitere Qualitätssicherung
