# Windows Setup

Automatisiertes, reproduzierbares und weitgehend idempotentes Setup für meine Windows-11-Arbeitsumgebung.

Das Repository dient sowohl zur Einrichtung eines frisch installierten Windows-Systems als auch zur regelmäßigen Wartung eines bereits eingerichteten Rechners. Derselbe `bootstrap.ps1` wird für Neuinstallation, manuelle Setup-Durchläufe und automatische Wartung verwendet.

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

Die nächsten größeren Desktop-Themen sind PowerToys Command Palette + Everything, Windhawk für Taskbar, Startmenü und Notification Center, ein eigenes OSD sowie weiterer Catppuccin-Polish.

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
5. Start von `bootstrap.ps1`

## Erneuter Setup-Durchlauf

```powershell
cd ~/windows-setup
.\bootstrap.ps1
```

Der Bootstrap versucht zu Beginn, das Repository zu aktualisieren. Enthält das Working Tree lokale Änderungen, wird ein automatisches `git pull` aus Sicherheitsgründen übersprungen.

Bereits vorhandene Komponenten werden soweit vorgesehen erkannt, übersprungen oder aktualisiert.

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

---

# Desktop Experience

## Zielbild

```text
Arch                           Windows
────────────────────────────────────────────────
Hyprland                       komorebi
Waybar                         Zebar
Fuzzel                         PowerToys Command Palette (geplant)
Dolphin                        OneCommander
SwayOSD                        eigenes OSD (geplant)
Focus follows mouse            masir
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
- Task läuft mit erhöhten Rechten, damit auch erhöhte Fenster getiled werden

## Focus Follows Mouse mit masir

`LGUG2Z.masir` ergänzt komorebi um Focus Follows Mouse.

masir nutzt seine automatische komorebi-Integration und wird ohne zusätzliche Parameter gestartet.

komorebi, whkd und masir starten gemeinsam über den Scheduled Task `komorebi Desktop`.

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

# Automatische wöchentliche Wartung

Der Bootstrap richtet die Windows-Aufgabe:

```text
Windows Setup Weekly Maintenance
```

ein.

Sie startet den vollständigen `bootstrap.ps1` jeden Sonntag um 12:00 Uhr.

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

# Software und Paketverwaltung

Software wird deklarativ über `config/packages.psd1` verwaltet.

Pakete können:

- installiert werden
- automatisch aktualisiert werden
- von Updates ausgeschlossen werden
- auf eine bestimmte Version festgelegt werden

Die installierte Version gepinnter Pakete wird anhand des exakten Winget-Paket-IDs ermittelt.

OpenVPN ist bewusst auf Version `2.7.101` festgelegt.

Zu den Desktop-Tools gehören aktuell unter anderem:

- komorebi
- whkd
- masir
- Zebar
- OneCommander
- Windows HDR Calibration
- iCloud
- OpenVPN
- Logitech G HUB

Geplant:

- PowerToys
- Everything
- Windhawk

---

# Development Storage

Das Setup kann eine vollständig leere, geeignete interne SSD für Entwicklungs- und Spieldaten einrichten.

| Laufwerk |  Größe | Dateisystem    | Label   | Zweck       |
| -------- | -----: | -------------- | ------- | ----------- |
| `D:`     | 100 GB | ReFS Dev Drive | `Dev`   | Entwicklung |
| `G:`     |   Rest | NTFS           | `Games` | Spiele      |

Die Entwicklungs-Caches werden auf das Dev Drive verschoben.

---

# Entwicklerumgebung

Unter anderem:

- fnm + Node LTS
- npm
- pnpm
- Yarn
- Bun
- Go
- Git
- GitHub CLI
- GitHub Desktop
- PowerShell 7
- Nushell
- Starship
- Visual Studio Code
- Codex CLI

Konfigurationsdateien werden soweit sinnvoll als Hardlinks aus dem Repository eingebunden.

---

# Codequalität

Am Ende jedes Bootstrap-Laufs wird `PSScriptAnalyzer` ausgeführt.

Das Setup unterscheidet:

- Fehler
- Warnungen
- Hinweise

Informationsmeldungen verhindern den Setup-Durchlauf nicht.

---

# Repository-Struktur

```text
windows-setup/
├── assets/
├── config/
├── dotfiles/
│   ├── git/
│   ├── komorebi/
│   ├── nushell/
│   ├── onecommander/
│   ├── powershell/
│   ├── starship/
│   ├── vscode/
│   └── zebar/
├── modules/
├── scripts/
│   ├── Build-OneCommanderFileIcons.ps1
│   └── onecommander-file-icons/
├── .generated/          # nicht versioniert
├── bootstrap.ps1
├── init.ps1
├── README.md
└── roadmap.md
```

---

# Offene große Themen

- PowerToys Command Palette + Everything
- Windhawk Taskbar Styler
- Windhawk Start Menu Styler
- Windhawk Notification Center Styler
- eigenes Catppuccin OSD
- weiterer Catppuccin-Polish
- Logging
- Dry-Run
- CI/Pester
