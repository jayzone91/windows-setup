# Windows Setup

Automatisiertes, reproduzierbares und weitgehend idempotentes Setup für meine Windows-11-Arbeitsumgebung.

Das Repository dient sowohl zur Einrichtung eines frisch installierten Windows-Systems als auch zur regelmäßigen Wartung eines bereits eingerichteten Rechners. Derselbe `bootstrap.ps1` wird für Neuinstallation, manuelle Setup-Durchläufe und automatische Wartung verwendet.

Ein zweites wichtiges Ziel ist eine Windows-Desktop-Umgebung, die sich funktional und optisch an meiner Arch-/Hyprland-Workstation orientiert. Dafür werden komorebi, whkd, masir und Zebar kombiniert und mit Catppuccin Mocha gestaltet.

## Aktueller Stand

Der Kern des Setups ist produktiv nutzbar und weitgehend reproduzierbar.

Bereits umgesetzt sind unter anderem:

- Paketinstallation und Updates über `winget` und Microsoft Store
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
- Catppuccin Mocha als gemeinsame Designsprache

Die nächsten größeren Desktop-Themen sind PowerToys Command Palette + Everything, Windhawk für die Windows-Shell, ein eigenes OSD sowie weiterer Catppuccin-Polish.

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

# Desktop Experience

## Zielbild

Die Windows-Desktop-Umgebung soll sich im täglichen Workflow möglichst ähnlich zur Arch-/Hyprland-Umgebung verhalten:

```text
Arch                           Windows
────────────────────────────────────────────────
Hyprland                       komorebi
Waybar                         Zebar
Fuzzel                         PowerToys Command Palette (geplant)
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
├── Launcher / Search (geplant)
│   ├── PowerToys Command Palette
│   └── Everything
│
├── Windows Shell Styling (geplant)
│   └── Windhawk
│       ├── File Explorer Styler
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
- Autostart über die Windows-Aufgabenplanung

Der Desktop-Task läuft mit erhöhten Rechten. Dadurch kann komorebi auch erhöhte Anwendungen verwalten. Beispielsweise wird ein als Administrator gestartetes Windows Terminal normal in das bestehende Tiling-Layout aufgenommen.

## Focus Follows Mouse mit masir

`LGUG2Z.masir` ergänzt komorebi um Focus Follows Mouse.

Dadurch reicht es aus, mit der Maus über ein Fenster zu fahren:

```text
Mauszeiger
    │
    ▼
  masir
    │
    ▼
Windows-Fokus
    │
    ▼
 komorebi
```

Ein Mausklick zum Fokussieren ist nicht notwendig.

masir nutzt seine automatische komorebi-Integration und wird ohne zusätzliche Parameter gestartet.

komorebi, whkd und masir starten gemeinsam über den Scheduled Task `komorebi Desktop`.

## Zebar

Zebar ersetzt im normalen Desktop-Betrieb weitgehend die Windows-Taskbar.

Die eigene Bar befindet sich unter:

```text
dotfiles/zebar/windows-setup-bar/
```

Sie wird mit TypeScript entwickelt und lokal mit esbuild gebündelt. Es bestehen keine CDN-Abhängigkeiten.

### Linke Seite

- fünf komorebi-Workspaces
- aktiver Workspace dynamisch hervorgehoben
- Workspace-Wechsel per Mausklick
- aktuelle Tiling-Methode
- Layout-Pill vollständig klickbar
- separates Layout-Popup
- direkte Auswahl einer Tiling-Methode
- aktuelles Layout im Popup hervorgehoben
- Tooltips mit den Namen der Tiling-Methoden
- Popup schließt nach Auswahl
- Popup schließt bei Fokusverlust

### Mitte

- Titel des fokussierten Fensters
- echtes Windows-Anwendungsicon
- Icon-Ermittlung über EXE und PowerShell
- Base64-PNG und Icon-Cache
- Schutz vor asynchronen Render-Races

### Rechte Seite

- CPU-Auslastung
- RAM verwendet/gesamt
- Storage-Auslastung
- aktive Netzwerk-Schnittstelle
- IPv4-Adresse
- Download-/Upload-Durchsatz
- Lautstärke
- Mute-Status
- Klick zum Muten/Entmuten
- Mausrad zur Lautstärkeregelung
- Media-Titel und Artist
- Previous / Play-Pause / Next
- deutsches Datum
- 24-Stunden-Uhrzeit

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

Der Build führt zunächst einen TypeScript-Typecheck aus und erstellt anschließend die Browser-Bundles mit esbuild.

## Catppuccin Mocha

Catppuccin Mocha ist die gemeinsame Designsprache des Windows-Desktops.

Es wird bewusst keine universelle CSS-Datei für alle Anwendungen erzwungen. Jedes Programm verwendet die für es sinnvollste und stabilste Theme-Methode.

Beispiele:

| Komponente          | Theme-Methode                                 |
| ------------------- | --------------------------------------------- |
| komorebi            | integriertes Catppuccin                       |
| Zebar               | eigenes CSS                                   |
| Windows Terminal    | Farbschema in `settings.json`                 |
| VS Code             | Catppuccin Theme/Extension                    |
| Zen Browser         | eigene CSS-/UI-Anpassungen                    |
| Explorer            | Windhawk File Explorer Styler (geplant)       |
| Taskbar             | Windhawk Taskbar Styler (geplant)             |
| Startmenü           | Windhawk Start Menu Styler (geplant)          |
| Notification Center | Windhawk Notification Center Styler (geplant) |
| eigenes OSD         | eigene Styles (geplant)                       |

GitHub Desktop wird nur soweit angepasst, wie es stabil unterstützt wird.

---

# Automatische wöchentliche Wartung

Der Bootstrap richtet die Windows-Aufgabe

```text
Windows Setup Weekly Maintenance
```

ein.

Sie startet den vollständigen `bootstrap.ps1` **jeden Sonntag um 12:00 Uhr**.

Es existiert bewusst kein separater Maintenance-Workflow. Neuinstallation, manuelle Aktualisierung und automatische Wartung verwenden dieselbe Logik.

Die Aufgabe läuft im interaktiven Benutzerkontext mit erhöhten Rechten.

Der Wartungslauf umfasst unter anderem:

- Repository aktualisieren, sofern keine lokalen Änderungen vorliegen
- konfigurierte Winget-/Store-Pakete aktualisieren
- Entwicklungswerkzeuge aktualisieren
- Treiber prüfen und aktualisieren
- Windows- und Microsoft-Updates installieren
- Logitech-G-HUB-Konfiguration synchronisieren
- Windows- und Entwicklungs-Konfiguration erneut anwenden
- Zebar-Abhängigkeiten und Build sicherstellen
- PSScriptAnalyzer ausführen
- erforderlichen Neustart erkennen
- lokale Git-Änderungen erkennen
- noch nicht gepushte Commits erkennen

Der Rechner wird **nicht automatisch neu gestartet**.

## Desktop-Benachrichtigungen

Für Benachrichtigungen wird `BurntToast` verwendet.

Nach einem Wartungslauf wird eine Benachrichtigung angezeigt, wenn:

- Windows oder ein Update einen Neustart benötigt
- das Repository lokale Änderungen enthält
- noch nicht gepushte Commits vorhanden sind

Änderungen werden bewusst **nicht automatisch committed oder gepusht**.

---

# Windows Updates

Normale Windows- und Microsoft-Updates werden über `PSWindowsUpdate` installiert.

Dazu gehören unter anderem:

- kumulative Windows-Updates
- Security Updates
- .NET-Updates
- Microsoft Defender Security Intelligence Updates

Treiber werden separat durch die Treiberlogik behandelt.

Ein erforderlicher Neustart wird erkannt, aber nicht automatisch durchgeführt.

---

# Software und Paketverwaltung

Software wird deklarativ über `config/packages.psd1` verwaltet.

Pakete können:

- installiert werden
- automatisch aktualisiert werden
- von Updates ausgeschlossen werden
- auf eine bestimmte Version festgelegt werden

OpenVPN ist beispielsweise bewusst auf Version `2.7.101` festgelegt.

## Basis

- JetBrainsMono Nerd Font

## System- und Desktop-Tools

- Windows HDR Calibration
- iCloud
- OpenVPN
- Logitech G HUB
- komorebi
- whkd
- masir
- Zebar

Geplant:

- PowerToys
- Everything
- Windhawk

## Browser

- Zen Browser
- Google Chrome Beta

## Entwicklung

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
- Codex CLI

---

# Development Storage

Das Setup kann eine vollständig leere, geeignete interne SSD für Entwicklungs- und Spieldaten einrichten.

System-/Bootdisk und ungeeignete Datenträger werden ausgeschlossen. Vor destruktiven Änderungen werden der erkannte Datenträger und die geplante Partitionierung angezeigt und müssen explizit bestätigt werden.

| Laufwerk |        Größe | Dateisystem    | Label   | Zweck       |
| -------- | -----------: | -------------- | ------- | ----------- |
| `D:`     |       100 GB | ReFS Dev Drive | `Dev`   | Entwicklung |
| `G:`     | Rest der SSD | NTFS           | `Games` | Spiele      |

Für das Games-Laufwerk müssen mindestens 100 GB zur Verfügung stehen.

Existieren die Laufwerke bereits in der erwarteten Form, wird die Partitionierung nicht erneut durchgeführt.

## Dev-Drive-Verzeichnisse

```text
D:\
├── Projects\
├── Build\
└── Cache\
    ├── npm\
    ├── pnpm\
    ├── yarn\
    ├── bun\
    └── go\
        ├── build\
        └── modules\
```

Die Entwicklungs-Caches werden auf das Dev Drive verschoben:

| Tool            | Pfad                  |
| --------------- | --------------------- |
| npm             | `D:\Cache\npm`        |
| pnpm            | `D:\Cache\pnpm`       |
| Yarn            | `D:\Cache\yarn`       |
| Bun             | `D:\Cache\bun`        |
| Go Build Cache  | `D:\Cache\go\build`   |
| Go Module Cache | `D:\Cache\go\modules` |

Für das ReFS Dev Drive wird Microsoft Defender Dev Drive Performance Mode aktiviert. Der Echtzeitschutz bleibt grundsätzlich aktiv.

---

# Windows Debloat

Der Bootstrap entfernt beziehungsweise deprovisioniert eine definierte Auswahl nicht benötigter Windows-AppX-Pakete und deaktiviert verschiedene Consumer- und Content-Delivery-Funktionen.

Die Debloat-Logik ist wiederholbar. Bereits entfernte Pakete werden erkannt und übersprungen.

Gaming-, Entwicklungs- und für Windows Hello relevante Funktionen sollen erhalten bleiben.

Windows Snap wird deaktiviert, da komorebi die Fensterverwaltung übernimmt.

---

# Entwicklerumgebung

## Node.js

- Installation und Versionsverwaltung über fnm
- Node LTS
- npm
- pnpm
- Yarn

## Bun

- automatische Installation und Updates
- Cache auf dem Dev Drive

## Go

- automatische Installation und Updates
- Build- und Module-Cache auf dem Dev Drive

## Git

Das Setup konfiguriert unter anderem:

- Benutzername
- E-Mail
- globale Git-Konfiguration
- globale Gitignore
- Editor
- Git LFS
- sinnvolle Default-Einstellungen

Am Ende eines Wartungslaufs werden lokale Änderungen und ungepushte Commits erkannt.

## Codex

Die Codex CLI wird automatisch installiert.

---

# Browser

## Zen Browser

Automatisiert werden unter anderem:

- Installation und Updates
- Erweiterungen
- deutsche Sprache
- deutsches Wörterbuch
- Enterprise Policies
- Session Restore
- Google als Suchmaschine
- Telemetrie deaktivieren
- Firefox Studies deaktivieren
- Pocket deaktivieren
- Zen Mods installieren
- Zen-Mod-Installation über Marionette
- idempotente Mod-Installation

Weitere Catppuccin-CSS-Anpassungen sind geplant.

## Google Chrome Beta

- Installation
- automatische Updates
- Enterprise Policies
- Extension Deployment

---

# Logitech G HUB

Logitech G HUB wird über `winget` installiert und automatisch aktuell gehalten.

Die aktuelle Konfiguration wird als

```text
config/lghub/settings.db
```

im Repository gesichert.

Auf einem frisch eingerichteten System wird die gespeicherte Konfiguration einmalig nach G HUB übernommen. Bei späteren Bootstrap-Durchläufen wird die aktuelle lokale G-HUB-Datenbank bei Änderungen zurück ins Repository kopiert.

G HUB wird für den Datenbankzugriff kontrolliert beendet und anschließend wieder gestartet.

Da G HUB die Datenbank intern verändern kann, kann `settings.db` nach einem Wartungslauf als Git-Änderung erscheinen. Der abschließende Repository-Check weist darauf hin.

---

# PowerShell und Codequalität

Folgende PowerShell-Module werden automatisch verwaltet:

- `PSScriptAnalyzer`
- `BurntToast`
- `PSWindowsUpdate`

Manuelle Codeprüfung:

```powershell
. .\modules\index.ps1
Test-PowerShellCode .
```

Die Prüfung läuft außerdem am Ende des Bootstraps.

Ziel:

```text
[OK] Keine PSScriptAnalyzer-Probleme gefunden.
```

CI und zusätzliche Pester-Tests sind für einen späteren Ausbau vorgesehen.

---

# Projektstruktur

```text
windows-setup/
├── bootstrap.ps1
├── init.ps1
├── roadmap.md
├── README.md
│
├── config/
│   ├── browsers.psd1
│   ├── debloat.psd1
│   ├── packages.psd1
│   ├── powershell.psd1
│   ├── storage.psd1
│   ├── vscode.psd1
│   └── lghub/
│       └── settings.db
│
├── modules/
│   ├── Drivers/
│   ├── Windows/
│   ├── Browser.ps1
│   ├── Debloat.ps1
│   ├── Development.ps1
│   ├── Git.ps1
│   ├── Helpers.ps1
│   ├── Languages.ps1
│   ├── Logitech.ps1
│   ├── Notifications.ps1
│   ├── Nushell.ps1
│   ├── Packages.ps1
│   ├── PowerShell.ps1
│   ├── ScheduledTasks.ps1
│   ├── Security.ps1
│   ├── Storage.ps1
│   ├── Terminal.ps1
│   ├── VSCode.ps1
│   └── WindowsUpdate.ps1
│
├── dotfiles/
│   ├── komorebi/
│   └── zebar/
│       └── windows-setup-bar/
│           ├── src/
│           ├── dist/
│           ├── index.html
│           ├── layout-menu.html
│           ├── styles.css
│           ├── layout-menu.css
│           ├── package.json
│           └── zpack.json
│
├── assets/
├── AGENTS.md
└── .codex/
```

## `init.ps1`

Minimaler Einstiegspunkt für ein frisch installiertes Windows. Installiert Voraussetzungen, lädt beziehungsweise aktualisiert das Repository und startet `bootstrap.ps1`.

## `bootstrap.ps1`

Zentrale Orchestrierung für:

- Erstinstallation
- manuelle erneute Setup-Durchläufe
- automatische wöchentliche Wartung

Die eigentliche Installations- und Konfigurationslogik befindet sich in den Modulen.

## `config/`

Deklarative Konfiguration für Pakete, Browser, VS-Code-Erweiterungen, PowerShell-Module, Debloat, Storage und weitere Komponenten.

## `modules/`

PowerShell-Implementierung des Setups. `modules/index.ps1` lädt die einzelnen Module zentral.

## `dotfiles/`

Versionierte Konfigurationen der Desktop- und Benutzeranwendungen, insbesondere komorebi und Zebar.

---

# Geplante nächste Schritte

Die Desktop-Basis ist inzwischen funktional. Die aktuelle Reihenfolge für den weiteren Ausbau ist:

1. **PowerToys + Everything**
   - Command Palette als App Launcher
   - Everything-Integration
   - bevorzugt `Win+Space` als Launcher-Hotkey

2. **Windhawk**
   - File Explorer Styler
   - Taskbar Styler
   - Start Menu Styler
   - Notification Center Styler
   - Catppuccin Mocha für die Windows-Shell

3. **Eigenes OSD**
   - Lautstärke
   - Mute
   - Mikrofon
   - Caps Lock
   - Num Lock

4. **Desktop-Polish**
   - Zen Browser
   - Lock Screen
   - verbleibende visuelle Inkonsistenzen

5. **Gaming und Home Office**

6. **Qualität und Wartbarkeit**
   - vollständiges Lauf-Logging
   - Clean-Install-Test
   - CI
   - Pester
   - Security-Abschlussprüfungen

Die detaillierte Planung befindet sich in [`roadmap.md`](roadmap.md).

---

# Grundprinzipien

- **Ein Bootstrap:** Keine getrennte Setup- und Maintenance-Logik.
- **Idempotenz:** Bereits eingerichtete Komponenten werden erkannt und nicht unnötig neu erstellt.
- **Konfiguration im Repository:** Relevante Einstellungen sollen reproduzierbar und nachvollziehbar sein.
- **Keine automatischen Git-Pushes:** Änderungen werden gemeldet und vor Commit beziehungsweise Push geprüft.
- **Keine automatischen Neustarts:** Ein erforderlicher Neustart wird gemeldet, aber nicht erzwungen.
- **Sichere Storage-Einrichtung:** Destruktive Änderungen benötigen eine explizite Bestätigung.
- **Automatische Wartung:** Derselbe Bootstrap hält das System regelmäßig aktuell.
- **Desktop als Code:** Window Manager, Bar, Hotkeys und Desktop-Verhalten werden soweit sinnvoll reproduzierbar versioniert.
- **Native Theme-Wege bevorzugen:** Catppuccin wird pro Anwendung über die jeweils stabilste unterstützte Methode umgesetzt.
