# Windows Setup Roadmap

> **Zweck dieses Dokuments**
>
> Diese Roadmap ist nicht nur eine Checkliste, sondern die **Arbeits- und Entscheidungsgrundlage für eine KI**, die das Repository weiterentwickelt.
> Eine KI soll nach dem Einlesen dieses Dokuments verstehen:
>
> 1. welches Zielbild für das Windows-System verfolgt wird,
> 2. welche Komponenten bereits umgesetzt und getestet sind,
> 3. welche Entscheidungen bereits bewusst getroffen wurden,
> 4. welche Ansätze verworfen wurden und nicht erneut verfolgt werden sollen,
> 5. welche Arbeiten noch offen sind,
> 6. welche Abhängigkeiten zwischen den Arbeitspaketen bestehen,
> 7. wie aus dem aktuellen Stand selbstständig die sinnvollsten nächsten Schritte abzuleiten sind,
> 8. welche Akzeptanzkriterien erfüllt sein müssen, bevor ein Punkt als abgeschlossen gilt.
>
> **Wichtig:** Bestehende, als `[x]` markierte Entscheidungen sollen nicht ohne konkreten technischen Grund zurückgebaut oder durch alternative Ansätze ersetzt werden.

---

# 1. Gesamtziel

Ein vollständig automatisiertes, reproduzierbares und wartbares Windows-11-Setup für:

- Entwicklung
- Gaming
- privaten Alltag
- Home Office / Firmenzugriff
- einen stark angepassten Desktop-Workflow

Der gleiche zentrale `bootstrap.ps1` soll für drei Fälle funktionieren:

1. Neuinstallation eines frisch installierten Windows-11-Systems
2. manueller erneuter Setup-Durchlauf
3. automatische regelmäßige Wartung

Das Repository ist die **Source of Truth** für alle sinnvoll versionierbaren Einstellungen.

---

# 2. Desktop-Zielbild

Die Windows-Umgebung soll funktional und optisch möglichst nah an die vorhandene Arch-/Hyprland-Arbeitsumgebung herankommen, ohne Windows gegen seine Plattform zu verbiegen.

## Vergleich

| Arch / Linux                     | Windows                                |
| -------------------------------- | -------------------------------------- |
| Hyprland                         | komorebi                               |
| Waybar                           | Zebar                                  |
| Focus follows mouse              | masir                                  |
| Fuzzel / Launcher                | PowerToys Command Palette + Everything |
| Dolphin                          | OneCommander                           |
| SwayOSD                          | eigenes Catppuccin-OSD                 |
| Catppuccin Mocha                 | Catppuccin Mocha                       |
| native Wayland-Tiling-Funktionen | komorebi + whkd                        |
| dotfiles                         | Repository + NTFS-Hardlinks/Junctions  |

## Desktop-Architektur

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
├── Launcher / Search
│   ├── PowerToys Command Palette
│   └── Everything
│
├── Windows Shell Styling
│   └── Windhawk
│       ├── Taskbar Styler
│       ├── Start Menu Styler
│       └── Notification Center Styler
│
├── OSD
│   └── eigenes Catppuccin-OSD
│       ├── Volume
│       ├── Mute
│       ├── Brightness
│       ├── Media
│       ├── Caps Lock Toggle
│       └── Num Lock Toggle
│
└── Theme
    └── Catppuccin Mocha
```

---

# 3. Grundprinzipien und feste Architekturentscheidungen

## Bootstrap

- [x] Ein zentraler `bootstrap.ps1`
- [x] Kein separater Wartungs-Workflow
- [x] `init.ps1` als minimaler Erstinstallations-Einstieg
- [x] Repository wird nach `%USERPROFILE%\windows-setup` geklont
- [x] `bootstrap.ps1` wird nach der Erstinstallation automatisch gestartet
- [x] Der Bootstrap kann wiederholt ausgeführt werden
- [x] Lokale Git-Änderungen verhindern ein automatisches `git pull`
- [x] Keine automatischen Git-Commits
- [x] Keine automatischen Git-Pushes
- [x] Kein automatischer Windows-Neustart

## Konfigurationsdateien

Projektweite Regel:

- [x] **Dateien werden als NTFS-Hardlinks eingebunden**
- [x] **Verzeichnisse werden als NTFS-Junctions eingebunden**
- [x] Keine Symbolic Links mehr für verwaltete Dotfiles
- [x] Alte verwaltete Symbolic Links werden bei einem Setup-Lauf entfernt und migriert
- [x] `Set-FileHardLink` zentral als Helper
- [x] `Set-DirectoryJunction` zentral als Helper

Begründung:

- OneCommander behandelt Hardlinks wie normale Dateien.
- Änderungen auf beiden Seiten wirken sofort auf dieselben Dateidaten.
- Das Repository liegt durch `init.ps1` immer unter dem Benutzerprofil auf `C:`.
- Verzeichnis-Hardlinks existieren unter NTFS nicht; dafür werden Junctions verwendet.

## Generierte Inhalte

- [x] Generierte Daten gehören nicht zwischen manuell gepflegte Dotfiles
- [x] Generierte Daten liegen unter `.generated/`
- [x] `.generated/` wird nicht committed
- [x] Generator-Code selbst wird committed
- [x] Generierte Inhalte müssen auf einer Neuinstallation reproduzierbar erzeugt werden können

## Theme

- [x] Catppuccin Mocha ist die gemeinsame Designsprache
- [x] Keine künstliche universelle CSS-Datei für alle Programme
- [x] Jedes Programm nutzt seine native bzw. stabilste Theme-Methode
- [x] Funktionalität und Wartbarkeit haben Vorrang vor rein optischem Styling

---

# 4. Phase 1 – Repository, Bootstrap und Projektstruktur

## Bestehende Struktur

- [x] `init.ps1`
- [x] `bootstrap.ps1`
- [x] `config/`
- [x] `modules/`
- [x] `modules/index.ps1`
- [x] `dotfiles/`
- [x] `assets/`
- [x] `scripts/`
- [x] `.generated/`
- [x] `README.md`
- [x] `roadmap.md`
- [x] `PSScriptAnalyzerSettings.psd1`

## Erstinstallation

- [x] `winget` prüfen
- [x] Git bei Bedarf installieren
- [x] Repository klonen
- [x] bereits vorhandenes Repository aktualisieren
- [x] `bootstrap.ps1` starten
- [x] PATH der laufenden PowerShell-Session nach Installationen aktualisieren

## Noch offen

- [ ] zentrale Logging-Strategie für komplette Bootstrap-Läufe
- [ ] Log-Dateien mit Datum/Uhrzeit und Ergebnisstatus
- [ ] optionaler `-Verbose`-Modus für detailliertere Diagnose
- [ ] optionaler `-DryRun` / `-WhatIf`-Modus
- [ ] ein maschinenlesbarer Abschlussstatus des Bootstrap-Laufs
- [ ] optional eine Zusammenfassung der Änderungen eines Durchlaufs

### Akzeptanzkriterien

Ein frisches Windows-System soll mit möglichst wenigen manuellen Schritten über `init.ps1` bis zu einer arbeitsfähigen Umgebung gelangen.

---

# 5. Phase 2 – Paketverwaltung

## Generische Winget-Logik

- [x] Paketgruppen über `config/packages.psd1`
- [x] Installation über `winget`
- [x] Microsoft-Store-Quelle unterstützen
- [x] installierte Pakete erkennen
- [x] Updates durchführen
- [x] Updates pro Paket deaktivieren
- [x] feste Versionen definieren
- [x] installierte Version gepinnter Pakete prüfen
- [x] Winget-Ausgabe robust anhand der Paket-ID auswerten
- [x] gepinnte Version gezielt installieren
- [x] OpenVPN als realer Test für Versions-Pinning

## Aktuelle Paketgruppen

### Base

- [x] JetBrainsMono Nerd Font

### Tools

- [x] Windows HDR Calibration
- [x] iCloud
- [x] OpenVPN
- [x] Logitech G HUB
- [x] komorebi
- [x] whkd
- [x] masir
- [x] Zebar
- [x] OneCommander
- [ ] **NanaZip**
- [ ] PowerToys
- [ ] Everything

### Development

- [x] fnm
- [x] Go
- [x] Bun
- [x] Git
- [x] GitHub CLI
- [x] GitHub Desktop
- [x] Visual Studio Code
- [x] PowerShell 7
- [x] Nushell
- [x] Starship

### Browser

- [x] Zen Browser
- [x] Google Chrome Beta

## NanaZip

Ziel:

- NanaZip als moderner Archivmanager
- möglichst native Windows-11-Integration
- Nutzung für ZIP, 7z und weitere Archive
- Installation über Winget oder Microsoft Store, je nachdem welcher Weg reproduzierbarer ist

Aufgaben:

- [ ] passende Paket-ID prüfen
- [ ] NanaZip in `config/packages.psd1` aufnehmen
- [ ] Installation im Bootstrap testen
- [ ] Update-Verhalten testen
- [ ] Kontextmenü-Integration prüfen
- [ ] prüfen, ob NanaZip sinnvoll als Standardhandler für unterstützte Archive gesetzt werden kann
- [ ] Catppuccin-Anpassung nur verfolgen, falls stabil unterstützt

## Noch offen in der Paketlogik

- [ ] Retry-Mechanismus bei temporären Winget-/Download-Fehlern
- [ ] bessere maschinenlesbare Update-Zusammenfassung
- [ ] Paket-Fehler am Ende gesammelt ausgeben statt nur während des Laufs
- [ ] optionale zentrale Paket-Logs

---

# 6. Phase 3 – Windows Debloat und Grundkonfiguration

## Debloat

- [x] provisionierte AppX-Pakete ermitteln
- [x] definierte unerwünschte Apps entfernen
- [x] systemweites Provisioning berücksichtigen
- [x] Consumer Features deaktivieren
- [x] wiederholbaren Ablauf sicherstellen
- [x] Gaming-Funktionen nicht unnötig beschädigen
- [x] Entwicklungsfunktionen erhalten
- [x] Windows Hello erhalten

## Windows-Konfiguration

- [x] Taskbar-Grundeinstellungen
- [x] Startmenü-Grundeinstellungen
- [x] Windows Theme
- [x] Power-Einstellungen
- [x] HDR
- [x] Wallpaper Slideshow
- [x] Windows Snap deaktivieren, da komorebi übernimmt
- [x] geschützte Registry-Werte dürfen Bootstrap nicht abbrechen
- [ ] Taskbar passend zum Zebar-Workflow automatisch ausblenden
- [ ] Lock-Screen optisch angleichen
- [ ] weitere Datenschutz-/Telemetry-Einstellungen nur gezielt ergänzen
- [ ] keine aggressive pauschale Service-Deaktivierung

---

# 7. Phase 4 – Sicherheit und Systemstatus

- [x] Windows-Hello-Voraussetzungen für Apple Passwords prüfen
- [x] Microsoft Defender aktiv lassen
- [x] Defender Dev Drive Performance Mode
- [x] Rebootbedarf prüfen
- [x] Component Based Servicing als Rebootgrund erkennen
- [x] Windows Update als Rebootgrund erkennen
- [x] `PendingFileRenameOperations` auswerten
- [x] konkrete Ursachen diagnostisch anzeigen
- [x] reine NSIS-/Temp-Cleanup-Einträge nicht als relevanten Rebootbedarf melden
- [ ] BitLocker-Status prüfen
- [ ] Secure-Boot-Status in Abschlussprüfung anzeigen
- [ ] Firewall-Status in Abschlussprüfung anzeigen
- [ ] Windows-Hello-Status detaillierter ausgeben
- [ ] optional Security-Baseline weiter ausbauen

---

# 8. Phase 5 – Treiber

- [x] modulare Treiberstruktur unter `modules/Drivers/`
- [x] gemeinsame Treiber-Helfer
- [x] NVIDIA App installieren
- [x] NVIDIA Update-Workflow
- [x] Intel-Treiberlogik
- [x] Neustartbedarf aus Treiberinstallationen erkennen
- [x] Treiber nicht unkontrolliert über normalen Windows-Update-Pfad behandeln
- [ ] kompakte Hardware-Zusammenfassung am Ende des Setup-Laufs
- [ ] BIOS-/Firmware-Update-Konzept prüfen
- [ ] Monitor-/Peripherie-Firmware nur automatisieren, wenn zuverlässig möglich

---

# 9. Phase 6 – Windows und Microsoft Updates

- [x] `PSWindowsUpdate`
- [x] Microsoft Update
- [x] Software-Updates installieren
- [x] kumulative Windows-Updates
- [x] .NET-Updates
- [x] Defender Security Intelligence
- [x] `AcceptAll`
- [x] `IgnoreReboot`
- [x] Neustart nie automatisch ausführen
- [x] Neustartstatus nach Updates erneut prüfen
- [ ] verständliche Update-Zusammenfassung für Wartungs-Logs

---

# 10. Phase 7 – Netzwerk und VPN

## OpenVPN

- [x] `OpenVPNTechnologies.OpenVPN`
- [x] feste Version `2.7.101`
- [x] Update für dieses Paket deaktiviert
- [x] Version-Pinning funktioniert
- [x] installierte Version robust ermitteln

## VPN-Konfiguration

- [ ] VPN-Profile automatisiert bereitstellen
- [ ] Firmen- und Privatprofile sauber trennen
- [ ] Zertifikate bei Bedarf automatisiert importieren
- [ ] sensible Daten nicht im öffentlichen Repository speichern
- [ ] Konzept für Secrets/Zertifikate festlegen
- [ ] prüfen, welche Home-Office-Komponenten zwingend VPN benötigen

---

# 11. Phase 8 – Entwicklerumgebung

## Node.js

- [x] fnm installieren
- [x] Node LTS
- [x] npm
- [x] pnpm
- [x] Yarn
- [x] PATH / `PNPM_HOME`
- [x] npm während desselben Bootstrap-Laufs verfügbar machen
- [x] npm für Zebar-Build
- [x] npm für OneCommander-Icon-Generator

## Bun

- [x] installieren
- [x] aktualisieren
- [x] Cache auf Dev Drive

## Go

- [x] installieren
- [x] aktualisieren
- [x] `GOCACHE` auf Dev Drive
- [x] `GOMODCACHE` auf Dev Drive

## Git

- [x] Benutzername
- [x] E-Mail
- [x] globale Git-Konfiguration
- [x] globale Gitignore
- [x] Editor
- [x] Git LFS
- [x] sinnvolle Defaults
- [x] Repository-Status auswerten
- [x] lokale Änderungen erkennen
- [x] ungepushte Commits erkennen

## Codex

- [x] Codex CLI installieren
- [ ] zusätzliche Codex-Konfiguration nur bei echtem Bedarf
- [ ] optional VS-Code-/Terminal-Workflow dokumentieren

---

# 12. Phase 9 – Development Storage

## Ziel

Eine zusätzliche interne SSD automatisch und sicher für Entwicklung und Games vorbereiten.

- [x] leere interne Disk erkennen
- [x] Boot-/Systemdisk ausschließen
- [x] ungeeignete Datenträger ausschließen
- [x] destruktive Änderungen explizit bestätigen
- [x] vorhandenes erwartetes Layout erkennen und nicht neu formatieren

## Layout

| Laufwerk |  Größe | Dateisystem    | Label   | Zweck       |
| -------- | -----: | -------------- | ------- | ----------- |
| `D:`     | 100 GB | ReFS Dev Drive | `Dev`   | Entwicklung |
| `G:`     |   Rest | NTFS           | `Games` | Spiele      |

## Verzeichnisse und Caches

- [x] `D:\Projects`
- [x] `D:\Build`
- [x] `D:\Cache\npm`
- [x] `D:\Cache\pnpm`
- [x] `D:\Cache\yarn`
- [x] `D:\Cache\bun`
- [x] `D:\Cache\go\build`
- [x] `D:\Cache\go\modules`
- [x] Defender Dev Drive Performance Mode

---

# 13. Phase 10 – PowerShell und Codequalität

- [x] PowerShell 7
- [x] PowerShell-Module automatisiert installieren
- [x] PSScriptAnalyzer
- [x] BurntToast
- [x] PSWindowsUpdate
- [x] Codeprüfung am Ende des Bootstrap-Laufs
- [x] Fehler, Warnungen und Hinweise getrennt zählen
- [x] Analyzer-Probleme im OneCommander-Icon-Build bereinigt
- [ ] GitHub Actions für statische Prüfung
- [ ] Pester-Tests für kritische Helper
- [ ] Tests für Paket-Versionserkennung
- [ ] Tests für Hardlink-/Junction-Migration
- [ ] Tests für Reboot-Erkennung
- [ ] Dry-Run / WhatIf

---

# 14. Phase 11 – Terminal-Umgebung

## Windows Terminal

- [x] PowerShell 7 als Standardprofil
- [x] JetBrainsMono Nerd Font
- [x] Catppuccin Mocha
- [x] Acrylic / Transparenz
- [x] Profil-Defaults
- [x] alte Windows-PowerShell-/CMD-Profile bei Bedarf ausblenden

## PowerShell

- [x] Profil im Repository
- [x] Profil als Hardlink eingebunden

## Nushell

- [x] Installation
- [x] `config.nu` im Repository
- [x] `env.nu` im Repository
- [x] beide Dateien als Hardlinks

## Starship

- [x] Installation
- [x] `starship.toml`
- [x] Hardlink

## Offen

- [ ] weiterer UX-Feinschliff
- [ ] Keybindings/Profiles vollständig dokumentieren, falls weitere Anpassungen dazukommen

---

# 15. Phase 12 – Visual Studio Code

- [x] Installation
- [x] Extensions automatisiert installieren
- [x] Settings im Repository
- [x] `settings.json` als Hardlink
- [x] Catppuccin
- [x] Codex-Integration
- [x] Setup wiederholbar
- [ ] Next.js-/TypeScript-Workflow weiter vervollständigen
- [ ] Go-Workflow vervollständigen
- [ ] Extension-Liste regelmäßig bereinigen
- [ ] Keybindings/Profile versionieren, falls erforderlich

---

# 16. Phase 13 – Browser

## Google Chrome Beta

- [x] Installation
- [x] Updates
- [x] Enterprise Policies
- [x] Extension Deployment

## Zen Browser

- [x] Installation
- [x] Updates
- [x] Erweiterungen
- [x] deutsche Sprache
- [x] deutsches Wörterbuch
- [x] Enterprise Policies
- [x] Session Restore
- [x] Google als Suchmaschine
- [x] Telemetrie deaktivieren
- [x] Firefox Studies deaktivieren
- [x] Pocket deaktivieren
- [x] Zen Mods automatisiert installieren
- [x] Marionette für Mod-Installation
- [x] Mod-Installation idempotent
- [x] Browser danach normal neu starten
- [ ] Browser-UI weiter an Catppuccin Mocha anpassen
- [ ] stabile eigene CSS-Anpassungen versionieren

---

# 17. Phase 14 – Logitech G HUB

- [x] Installation
- [x] Updates
- [x] `settings.db` im Repository
- [x] Erstimport
- [x] spätere lokale Änderungen zurück ins Repository synchronisieren
- [x] G HUB für Datenbankzugriff kontrolliert beenden
- [x] G HUB wieder starten
- [x] Git erkennt Änderungen für spätere manuelle Commits

---

# 18. Phase 15 – komorebi / Tiling Window Management

## Grundfunktion

- [x] komorebi installieren
- [x] whkd installieren
- [x] fünf Workspaces
- [x] Windows Snap deaktivieren
- [x] Catppuccin-Integration
- [x] bevorzugtes `UltrawideVerticalStack`
- [x] Fokussteuerung
- [x] Fenster verschieben
- [x] Fenster resizen
- [x] Stacks
- [x] Workspace-Steuerung
- [x] Layout-Wechsel
- [x] Konfiguration im Repository

## Rechte / erhöhte Anwendungen

- [x] komorebi über Scheduled Task mit erhöhten Rechten starten
- [x] als Administrator gestartete Terminals/Fenster in Tiling aufnehmen

## Dotfiles

- [x] `komorebi.json` als Hardlink
- [x] `komorebi.bar.json` als Hardlink
- [x] `applications.json` als Hardlink
- [x] `whkdrc` als Hardlink
- [x] alte Symlinks migrieren

---

# 19. Phase 16 – masir / Focus Follows Mouse

- [x] `LGUG2Z.masir`
- [x] Installation per Winget
- [x] automatische komorebi-Integration
- [x] Focus folgt Maus-Hover
- [x] kein Klick erforderlich
- [x] masir zusammen mit komorebi/whkd starten
- [x] Integration in Desktop Scheduled Task

---

# 20. Phase 17 – Zebar

## Grundarchitektur

- [x] eigenes Widget
- [x] TypeScript
- [x] esbuild
- [x] lokaler Build
- [x] keine CDN-Abhängigkeiten
- [x] `settings.json` als Hardlink
- [x] `windows-setup-bar` als Junction
- [x] Scheduled Task / reproduzierbarer Start

## Linke Seite

- [x] fünf komorebi-Workspaces
- [x] aktiven Workspace darstellen
- [x] Workspace per Klick wechseln
- [x] aktuelles Layout anzeigen
- [x] komplette Layout-Pill klickbar
- [x] separates Layout-Popup
- [x] verfügbare Tiling-Layouts auswählen
- [x] Auswahl sofort auf komorebi anwenden
- [x] aktuelles Layout hervorheben
- [x] Tooltip pro Layout
- [x] Popup nach Auswahl schließen
- [x] Popup bei Fokusverlust schließen
- [x] Popup ohne Scrollbar-/Clipping-Probleme

## Mitte

- [x] fokussierten Fenstertitel anzeigen
- [x] echtes Windows-Anwendungsicon
- [x] Icon über EXE/PowerShell bestimmen
- [x] PNG/Base64
- [x] Cache
- [x] Race-Condition-Schutz

## Rechte Seite

- [x] CPU
- [x] RAM
- [x] Storage
- [x] aktive Netzwerk-Schnittstelle
- [x] IPv4
- [x] Download
- [x] Upload
- [x] Lautstärke
- [x] Mute
- [x] Klick für Mute
- [x] Mausrad für Lautstärke
- [x] Media Titel
- [x] Artist
- [x] Previous
- [x] Play/Pause
- [x] Next
- [x] deutsches Datum
- [x] 24-Stunden-Uhrzeit

## Bewusste Nicht-Ziele

- [x] keine Batterieanzeige
- [x] kein Systray in Zebar

---

# 21. Phase 18 – OneCommander

## Entscheidung

Der native Windows Explorer wird **nicht weiter über Windhawk File Explorer Styler thematisiert**.

Grund:

- File Explorer Styler lieferte kein zufriedenstellendes vollständiges Ergebnis.
- OneCommander bietet bessere Theme- und Icon-Möglichkeiten.
- OneCommander soll den Explorer für den täglichen Dateimanager-Workflow ersetzen.

## Installation

- [x] `MilosParipovic.OneCommander`
- [x] Winget-Version statt Store-Version
- [x] Installation automatisiert
- [x] OOBE erkennen
- [x] AGB-/OOBE-Bestätigung bewusst manuell
- [x] keine unsichere Umgehung der OOBE

## Explorer-Ersatz

- [x] `Win + E` auf OneCommander
- [x] CLSID-Konfiguration
- [x] `DelegateExecute`
- [x] Directory Shell Handler
- [x] Drive Shell Handler
- [x] Directory Background
- [x] Drive Background
- [x] OneCommander als Default File Manager

## Theme

- [x] eigenes Catppuccin-Mocha-XAML
- [x] Theme-Verzeichnis per Junction
- [x] dunkle Bereiche vollständig angepasst
- [x] Datei-Alter-Farben an Mocha angepasst
- [x] Accent-Farbe Mauve

## Folder Icons

- [x] Main Folder Icon
- [x] Special-Folder-Icon-Pack
- [x] Catppuccin Mocha
- [x] Main Folder Icon als echte PNG kopieren
- [x] FolderIcons per Junction
- [x] von OneCommander generierten `16`-Cache berücksichtigen

## File Icons

Quelle:

```text
https://github.com/catppuccin/vscode-icons
```

- [x] kompletter Upstream-Bestand verwenden
- [x] nicht nur ausgewählte Icons
- [x] Upstream-Commit pinnen
- [x] Upstream unter `.generated/onecommander/Sources`
- [x] Mocha-SVGs bauen
- [x] SVG → PNG
- [x] alle gerenderten Icons unter `.generated/onecommander/Rendered`
- [x] OneCommander-Mappings unter `.generated/onecommander/FileIcons`
- [x] mappings als Hardlinks, nicht als Dateikopien
- [x] Extensions übernehmen
- [x] exakte Dateinamen übernehmen
- [x] Dotfiles übernehmen
- [x] `.gitignore`
- [x] `.gitconfig`
- [x] `.gitignore_global`
- [x] JSON
- [x] TOML
- [x] YAML
- [x] TypeScript/JavaScript
- [x] viele weitere Dev-Dateien automatisch
- [x] `_manifest.json`
- [x] Kollisionen dokumentieren
- [x] ungültige Windows-Dateinamen dokumentieren
- [x] FileIcons-Theme per Junction einbinden
- [x] `FileIconsTheme = CatppuccinMocha`

## Noch prüfen / verbessern

- [ ] `.lesshst` mit passendem Shell-/Terminal-Icon ergänzen, falls noch nicht im Generator enthalten
- [ ] weitere fehlende Dotfiles nur als Generator-Alias ergänzen, nicht manuell im Zielordner pflegen
- [ ] prüfen, ob nach zukünftigen OneCommander-Updates Mapping-Verhalten unverändert bleibt

---

# 22. Phase 19 – Windhawk

## Installationsstrategie

- [x] Windhawk-Automatisierung vorhanden
- [x] bevorzugt stabile 2.x-Version
- [x] solange keine stabile 2.x-Version existiert: aktuelle 2.x-Pre-Release verwenden
- [x] GitHub-Releases automatisiert auswerten
- [x] `windhawk_setup.exe`
- [x] Windhawk CLI verwenden
- [x] Mods per CLI installierbar
- [x] Mod-Settings per CLI konfigurierbar

## Verworfen

- [x] File Explorer Styler nicht weiter verfolgen
- [x] Explorer-Theme stattdessen über OneCommander

## Noch offen

- [ ] Taskbar Styler
- [ ] Start Menu Styler
- [ ] Notification Center Styler
- [ ] alle drei optisch an Catppuccin Mocha anpassen
- [ ] Konfiguration reproduzierbar über Windhawk CLI
- [ ] keine manuelle Mod-Konfiguration, wenn CLI-Automatisierung möglich ist
- [ ] Änderungen auf Windows-/Windhawk-Versionen testen

---

# 23. Phase 20 – Eigenes OSD

## Ziel

Windows soll ein eigenes, optisch zu Catppuccin Mocha passendes OSD erhalten, funktional ähnlich zu SwayOSD unter Linux.

Das OSD soll sich unaufdringlich, schnell und modern verhalten.

## Pflichtfunktionen

### Audio

- [ ] Volume Up OSD
- [ ] Volume Down OSD
- [ ] aktuelle Lautstärke als Prozent
- [ ] grafischer Fortschrittsbalken
- [ ] Mute OSD
- [ ] Unmute OSD
- [ ] passendes Audio-/Mute-Icon

### Helligkeit

- [ ] Brightness Up OSD
- [ ] Brightness Down OSD
- [ ] aktuelle Helligkeit als Prozent
- [ ] grafischer Fortschrittsbalken
- [ ] passendes Helligkeits-Icon

### Medien

- [ ] Play OSD
- [ ] Pause OSD
- [ ] Next OSD
- [ ] Previous OSD
- [ ] optional Titel/Artist, wenn zuverlässig und ohne unnötige Verzögerung verfügbar

### Tastatur-Toggles

- [ ] **Caps Lock Toggle OSD**
- [ ] Caps Lock aktiviert klar anzeigen
- [ ] Caps Lock deaktiviert klar anzeigen
- [ ] **Num Lock Toggle OSD**
- [ ] Num Lock aktiviert klar anzeigen
- [ ] Num Lock deaktiviert klar anzeigen
- [ ] Statusänderung unmittelbar nach Tastendruck anzeigen

## Design

- [ ] Catppuccin Mocha
- [ ] gleiche Rundungen/Abstände wie restlicher Desktop
- [ ] Nerd-/SVG-Icons
- [ ] Animationen dezent
- [ ] keine unnötigen Fensterrahmen
- [ ] immer im Vordergrund
- [ ] kein Fokusraub
- [ ] automatisch nach kurzer Zeit ausblenden
- [ ] korrekte Darstellung auf dem gewünschten Monitor
- [ ] DPI-/Scaling-Unterstützung

## Integration

- [ ] prüfen, welche Windows-Hotkeys bereits vom System behandelt werden
- [ ] bestehende Keyboard-Hardware-Events zuverlässig erkennen
- [ ] OSD automatisch starten
- [ ] reproduzierbar über Bootstrap installieren/konfigurieren
- [ ] Windows-eigenes OSD nur dann deaktivieren/umgehen, wenn dies stabil möglich ist
- [ ] keine doppelte OSD-Anzeige

## Akzeptanzkriterien

- alle sechs Kernbereiche funktionieren: Volume, Mute, Brightness, Media, Caps Lock, Num Lock
- keine merkbare Verzögerung
- kein Fokuswechsel
- keine störende Taskbar-Anzeige
- Catppuccin-Design konsistent

---

# 24. Phase 21 – Launcher / Suche

## PowerToys

- [ ] PowerToys installieren
- [ ] Command Palette als primären Launcher einrichten
- [ ] Start-Hotkey definieren
- [ ] unnötige PowerToys-Module deaktivieren
- [ ] Konfiguration soweit möglich automatisieren

## Everything

- [ ] Everything installieren
- [ ] Index konfigurieren
- [ ] Everything in PowerToys Command Palette integrieren
- [ ] schnelle Datei-/Ordnersuche sicherstellen
- [ ] prüfen, ob Admin-/Service-Komponente benötigt wird

## Design

- [ ] möglichst Catppuccin-orientierter Look
- [ ] Workflow ähnlich zu Fuzzel
- [ ] keyboard-first
- [ ] schnelle App-, Datei- und Command-Suche

---

# 25. Phase 22 – Home Office

Diese Phase wurde bewusst als eigener Bereich eingeplant und darf nicht mit allgemeinen Tools oder Development vermischt werden.

## Ziel

Alle Anwendungen und Einstellungen, die für Firmenzugriff/Home Office benötigt werden, sollen als eigene Paketgruppe reproduzierbar installiert werden können.

## Remote Desktop Manager

- [ ] Remote Desktop Manager installieren
- [ ] passende Winget-Paket-ID prüfen
- [ ] Update-Verhalten testen
- [ ] benötigte Konfigurationen identifizieren
- [ ] prüfen, welche Einstellungen exportierbar/versionierbar sind
- [ ] RDP-Verbindungen mit aktivem VPN testen
- [ ] RDP-Verbindungen ohne VPN testen
- [ ] keine Passwörter/Credentials im öffentlichen Repository speichern

## FileZilla

- [ ] FileZilla installieren
- [ ] passende Winget-Paket-ID prüfen
- [ ] FTP/FTPS/SFTP-Nutzung testen
- [ ] Site-Manager nur automatisieren, wenn Secrets sauber getrennt werden können
- [ ] keine Zugangsdaten committen

## VPN / Zertifikate

Aus Phase 7 übernehmen:

- [ ] VPN-Profile bei Bedarf vervollständigen
- [ ] Firmen-/Privat-VPN trennen
- [ ] Zertifikate automatisiert bereitstellen, falls sicher möglich
- [ ] Secrets-Konzept festlegen

## Weitere Firmen-/Homeoffice-Tools

- [ ] weitere Firmen-/Homeoffice-Tools bei Bedarf als **eigene Paketgruppe**
- [ ] PCVisit Supporter Modul prüfen / integrieren, falls automatisierbar
- [ ] Agfeo Dashboard / Softphone prüfen, falls Windows-Setup dies benötigt
- [ ] sonstige interne Tools nur ergänzen, wenn tatsächlich benötigt
- [ ] interne URLs/Portale nicht als Secrets behandeln, Zugangsdaten aber niemals committen

## Paketgruppe

Langfristig:

```powershell
HomeOffice = @(
    # Remote Desktop Manager
    # FileZilla
    # weitere Firmen-Tools
)
```

und im Bootstrap separat:

```powershell
Install-PackageGroup `
    -Packages $Packages.HomeOffice `
    -GroupName "Home Office"
```

## Akzeptanzkriterien

Nach einer Neuinstallation sollen die benötigten Home-Office-Programme mit einem Bootstrap-Lauf verfügbar sein; sensible Verbindungsdaten bleiben außerhalb des öffentlichen Repositories.

---

# 26. Phase 23 – Gaming

## Ziel

Das System soll nach Neuinstallation auch als Gaming-PC möglichst schnell einsatzbereit sein.

## Bereits vorhanden

- [x] separates `G:`-Games-Laufwerk
- [x] Gaming-Funktionen im Debloat nicht aggressiv entfernen
- [x] NVIDIA-Treiber-/App-Workflow

## Offen

- [ ] eigene Paketgruppe `Gaming`
- [ ] Steam installieren
- [ ] ggf. weitere Launcher nur nach tatsächlichem Bedarf
- [ ] Steam Library auf `G:` vorbereiten
- [ ] Standard-Installationspfade prüfen
- [ ] Xbox-/Gaming-Komponenten nur behalten, wenn benötigt
- [ ] Game Mode prüfen/konfigurieren
- [ ] Hardware Accelerated GPU Scheduling prüfen
- [ ] VRR/G-Sync-relevante Windows-Einstellungen prüfen
- [ ] HDR-Gaming-Workflow dokumentieren
- [ ] keine unnötigen "Gaming Tweaks", die Stabilität verschlechtern

---

# 27. Phase 24 – Apple / iCloud Integration

- [x] iCloud installieren
- [x] Apple Passwords als benötigte Funktion berücksichtigen
- [x] Windows Hello nicht durch Debloat beschädigen
- [x] Apple-Passwords-Voraussetzungen prüfen
- [ ] iCloud-Konfiguration nur automatisieren, soweit Apple dies stabil unterstützt
- [ ] keine Apple-Credentials automatisieren oder speichern

---

# 28. Phase 25 – Wartung und Scheduled Tasks

## Wöchentliche Wartung

- [x] Scheduled Task
- [x] Sonntag 12:00 Uhr
- [x] kompletter `bootstrap.ps1`
- [x] interaktiver Benutzerkontext
- [x] erhöhte Rechte
- [x] Repository aktualisieren, wenn Working Tree sauber
- [x] Pakete prüfen
- [x] Windows Updates
- [x] Treiber
- [x] G HUB Sync
- [x] Konfiguration erneut anwenden
- [x] Zebar Build
- [x] OneCommander-Konfiguration
- [x] PSScriptAnalyzer
- [x] Rebootstatus
- [x] Git-Status
- [x] ungepushte Commits
- [x] kein automatischer Reboot

## Benachrichtigungen

- [x] BurntToast
- [x] relevante Reboot-Meldung
- [x] Repository mit lokalen Änderungen melden
- [x] ungepushte Commits melden
- [x] keine Meldung für reine NSIS-Temp-Cleanup-Renames
- [ ] optional Wartungszusammenfassung auch bei erfolgreichem Lauf
- [ ] optional Fehlerzusammenfassung, wenn einzelne nichtkritische Schritte fehlschlagen

---

# 29. Phase 26 – Catppuccin Mocha Gesamtpolish

## Bereits umgesetzt

- [x] komorebi
- [x] Zebar
- [x] Windows Terminal
- [x] VS Code
- [x] OneCommander Theme
- [x] OneCommander Folder Icons
- [x] OneCommander File Icons
- [x] Zen teilweise

## Offen

- [ ] PowerToys Command Palette
- [ ] Windhawk Taskbar
- [ ] Windhawk Start Menu
- [ ] Windhawk Notification Center
- [ ] eigenes OSD
- [ ] Browser-Feinschliff
- [ ] weitere Anwendungen nur themen, wenn die Anpassung stabil und wartbar ist

---

# 30. Phase 27 – Dokumentation

## README

Das README soll den **aktuellen produktiven Stand** erklären.

- [x] Installationsweg
- [x] Bootstrap-Grundidee
- [x] Desktop-Zielbild
- [x] komorebi
- [x] masir
- [x] Zebar
- [x] OneCommander
- [x] Hardlinks/Junctions
- [x] Catppuccin
- [x] Wartung
- [ ] nach jeder größeren abgeschlossenen Phase aktualisieren

## Roadmap

Die Roadmap ist ausführlicher als das README und enthält auch offene Ziele.

- [x] aktuelle Architekturentscheidungen
- [x] erledigte Punkte
- [x] offene Punkte
- [x] verworfene Ansätze
- [x] Home Office
- [x] Gaming
- [x] NanaZip
- [x] OSD inklusive Caps Lock und Num Lock
- [x] klare nächste Prioritäten
- [ ] bei jeder größeren Designentscheidung aktualisieren

---

# 31. Bewusst verworfene oder nicht weiter zu verfolgende Ansätze

Eine KI soll diese Punkte **nicht erneut vorschlagen**, außer es gibt einen neuen technischen Grund.

- [x] Windows File Explorer vollständig mit Windhawk File Explorer Styler themen
  - Ergebnis war nicht ausreichend
  - OneCommander wurde als bessere Lösung gewählt
- [x] Symbolic Links für verwaltete Dotfile-Dateien
  - OneCommander zeigte dafür teilweise keine Dateityp-Icons
  - Hardlinks sind der definierte Standard
- [x] generierte OneCommander-Icons ins Repository committen
  - Generator + `.generated/` ist die gewünschte Architektur
- [x] separate Setup- und Maintenance-Skripte
  - ein Bootstrap ist bewusst gewünscht
- [x] aggressive pauschale Windows-Service-/Debloat-Tweaks
  - Stabilität und benötigte Funktionen haben Vorrang
- [x] automatische Git-Commits/Pushes
  - Änderungen sollen nur gemeldet werden
- [x] automatischer Neustart nach Updates
  - Neustart wird nur gemeldet

---

# 32. Prioritäten / empfohlene nächste Schritte

Eine KI soll bei der Auswahl des nächsten Arbeitspakets grundsätzlich folgende Reihenfolge verwenden, sofern der Benutzer nichts anderes vorgibt.

## Priorität 1 – kleine fehlende Basis-Tools

1. [ ] NanaZip in Paketverwaltung aufnehmen
2. [ ] Installation und Kontextmenü testen
3. [ ] Roadmap/README anschließend aktualisieren

## Priorität 2 – Home Office Paketgruppe

1. [ ] `HomeOffice` in `packages.psd1` anlegen
2. [ ] Remote Desktop Manager integrieren
3. [ ] FileZilla integrieren
4. [ ] weitere benötigte Firmen-Tools inventarisieren
5. [ ] VPN-/Zertifikat-Konzept getrennt und sicher planen

## Priorität 3 – Launcher

1. [ ] PowerToys installieren
2. [ ] Command Palette konfigurieren
3. [ ] Everything installieren
4. [ ] Everything integrieren
5. [ ] Workflow testen

## Priorität 4 – Windows Shell

1. [ ] Windhawk Taskbar Styler
2. [ ] Windhawk Start Menu Styler
3. [ ] Windhawk Notification Center Styler
4. [ ] alle Einstellungen per CLI reproduzierbar machen

## Priorität 5 – eigenes OSD

1. [ ] technische Architektur festlegen
2. [ ] Volume/Mute
3. [ ] Brightness
4. [ ] Media
5. [ ] Caps Lock Toggle
6. [ ] Num Lock Toggle
7. [ ] Catppuccin-Design
8. [ ] Autostart/Bootstrap
9. [ ] Windows-OSD-Doppelanzeige vermeiden

## Priorität 6 – Gaming

1. [ ] Paketgruppe
2. [ ] Steam
3. [ ] Game-Library-Pfade
4. [ ] sinnvolle Windows-Gaming-Einstellungen

## Priorität 7 – Qualität

1. [ ] Logging
2. [ ] GitHub Actions
3. [ ] Pester
4. [ ] Dry-Run
5. [ ] maschinenlesbarer Abschlussreport

---

# 33. Regeln für eine KI, die diese Roadmap bearbeitet

## Vor jeder Änderung

1. Repository vollständig bzw. die betroffenen Module neu einlesen.
2. Prüfen, ob der gewünschte Punkt bereits teilweise implementiert ist.
3. Bestehende Helper und Architektur verwenden statt Parallel-Implementierungen zu erzeugen.
4. Bestehende Designentscheidungen respektieren.
5. Keine Secrets in das Repository schreiben.

## Während der Implementierung

1. Änderungen idempotent gestalten.
2. Bestehende Installationen erkennen.
3. manuelle Eingriffe nur dort verlangen, wo sie technisch oder rechtlich erforderlich sind.
4. neue generierte Inhalte unter `.generated/` ablegen.
5. Dateien per Hardlink, Verzeichnisse per Junction integrieren.
6. Fehler verständlich ausgeben.
7. bestehende Konfiguration nicht ohne Backup überschreiben, wenn sie nicht bereits verwaltet wird.
8. PowerShell-Code mit PSScriptAnalyzer kompatibel halten.

## Nach einer Implementierung

1. Funktion gezielt testen.
2. Bootstrap erneut testen.
3. PSScriptAnalyzer ausführen.
4. Git-Status prüfen.
5. Roadmap aktualisieren.
6. README aktualisieren, falls sich der produktive Stand oder Benutzer-Workflow geändert hat.
7. neue offene Folgearbeiten als eigene Checkboxen dokumentieren.

---

# 34. Definition of Done

Ein Roadmap-Punkt darf nur `[x]` werden, wenn:

- die Funktion implementiert ist,
- sie auf dem aktuellen System getestet wurde,
- ein erneuter Lauf keinen unerwarteten Fehler erzeugt,
- die Umsetzung in den bestehenden Bootstrap integriert ist, sofern sie Teil des automatischen Setups sein soll,
- Konfigurationsdateien reproduzierbar sind,
- keine unnötigen manuellen Schritte bestehen,
- keine Secrets im Repository gelandet sind,
- PSScriptAnalyzer keine neuen relevanten Probleme meldet,
- Roadmap und bei Bedarf README aktualisiert wurden.

---

# 35. Langfristiges Endergebnis

Nach Abschluss der Roadmap soll ein frisch installiertes Windows 11 nach möglichst wenig manueller Interaktion automatisch zu folgendem Zustand gelangen:

- aktuelle Windows-Updates
- aktuelle benötigte Treiber
- sauber debloatetes Windows
- vollständig eingerichtete Entwicklerumgebung
- Dev Drive + Games Drive
- Git/VS Code/Terminal/Nushell/Starship
- Browser
- iCloud / Apple Passwords Voraussetzungen
- komorebi + whkd + masir
- Zebar
- OneCommander mit vollständigem Catppuccin-Theme und Dev-File-Icons
- PowerToys Command Palette + Everything
- Windhawk für verbleibende Shell-Bereiche
- eigenes Catppuccin-OSD inklusive Caps Lock und Num Lock
- NanaZip
- Home-Office-Werkzeuge
- Gaming-Werkzeuge
- Logitech G HUB
- wöchentliche Wartung
- aussagekräftige Benachrichtigungen
- reproduzierbare, im Repository nachvollziehbare Konfiguration
- keine unnötigen manuellen Nacharbeiten
