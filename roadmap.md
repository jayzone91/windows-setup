# Windows Setup Roadmap

## Ziel

Ein vollständig automatisiertes, reproduzierbares und wartbares Windows-11-Entwickler-, Gaming- und Arbeitsplatz-Setup.

Der gleiche `bootstrap.ps1` soll für drei Fälle funktionieren:

- Neuinstallation
- manueller erneuter Setup-Durchlauf
- automatische wöchentliche Wartung

Grundprinzipien:

- [x] ein zentraler Bootstrap statt getrennten Setup-/Maintenance-Skripten
- [x] möglichst idempotente Module
- [x] Konfiguration im Repository
- [x] keine automatischen Neustarts
- [x] keine automatischen Git-Commits oder Pushes
- [x] lokale Änderungen und notwendige Neustarts per Desktop-Benachrichtigung melden
- [ ] zentrale Logging-Strategie für vollständige Wartungsläufe
- [ ] optionaler Dry-Run-Modus

---

# Phase 1 – Bootstrap, Repository & Grundarchitektur

## Repository-Struktur

- [x] `init.ps1` als minimaler Einstiegspunkt
- [x] `bootstrap.ps1` als zentrale Orchestrierung
- [x] `config/` für deklarative Konfiguration
- [x] `modules/` für PowerShell-Logik
- [x] `dotfiles/`
- [x] `assets/`
- [x] zentrale Modul-Ladelogik über `modules/index.ps1`
- [x] README
- [x] Roadmap

## Installation

- [x] Installation mit:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

- [x] `winget` prüfen
- [x] Git bei Bedarf installieren
- [x] Repository automatisch nach `%USERPROFILE%\windows-setup` klonen
- [x] bestehendes Repository aktualisieren
- [x] `bootstrap.ps1` automatisch starten
- [x] Repository am Anfang des Bootstrap per Git aktualisieren
- [x] automatisches Pull bei lokal verändertem Working Tree überspringen

---

# Phase 2 – Paketverwaltung

## Grundfunktion

- [x] Paketgruppen in `config/packages.psd1`
- [x] Installation über `winget`
- [x] Microsoft-Store-Pakete unterstützen
- [x] installierte Pakete erkennen
- [x] Pakete einzeln aktualisieren
- [x] Updates pro Paket deaktivierbar
- [x] optionale feste Paketversion unterstützen
- [x] installierte Version bei gepinnten Paketen prüfen
- [x] gewünschte Version gezielt installieren
- [x] OpenVPN als realen Test für Versions-Pinning

## Aktuelle Gruppen

### Basis

- [x] JetBrainsMono Nerd Font

### Tools

- [x] Windows HDR Calibration
- [x] iCloud
- [x] OpenVPN
- [x] Logitech G HUB

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

## Noch offen

- [ ] Retry-Mechanismus bei temporären Download-/Winget-Fehlern
- [ ] optional strukturierte zentrale Paket-Logs
- [ ] zusätzliche Paketgruppen für Gaming, Firmen-Tools, Media und Communication

---

# Phase 3 – Windows Debloat & Grundkonfiguration

## AppX Debloat

- [x] provisionierte AppX-Pakete ermitteln
- [x] nicht benötigte Apps für den aktuellen Benutzer entfernen
- [x] Provisioning systemweit über DISM entfernen
- [x] wiederholbaren/idempotenten Ablauf herstellen
- [x] Consumer Features deaktivieren
- [x] Gaming- und Entwicklungsfunktionen nicht unnötig beschädigen
- [x] Windows Hello erhalten

Aktuell entfernt/deprovisioniert werden unter anderem:

- [x] Bing News
- [x] Bing Search
- [x] Bing Weather
- [x] Microsoft Solitaire Collection
- [x] Feedback Hub
- [x] Get Help
- [x] Copilot
- [x] Outlook for Windows
- [x] Phone Link
- [x] Microsoft To Do
- [x] Power Automate Desktop
- [x] Quick Assist
- [x] Teams Consumer
- [x] Clipchamp
- [x] Zune Music
- [x] Sound Recorder
- [x] Windows Alarms

## Windows-Konfiguration

- [x] Taskbar-Konfiguration
- [x] Startmenü-Konfiguration
- [x] Windows Theme
- [x] Power-Einstellungen
- [x] HDR
- [x] Wallpaper Slideshow
- [x] Consumer-/Content-Delivery-Einstellungen
- [ ] weitere Datenschutz-/Telemetry-Einstellungen nur dort ergänzen, wo sie keine benötigten Windows-Funktionen beeinträchtigen
- [ ] Dienste nur gezielt optimieren; keine aggressive pauschale Service-Deaktivierung

---

# Phase 4 – Sicherheit

- [x] Windows-Hello-Voraussetzungen für Apple Passwords prüfen
- [x] Defender für normalen Betrieb aktiv lassen
- [x] Defender Dev Drive Performance Mode einrichten
- [x] Neustartbedarf zuverlässig erkennen
- [ ] BitLocker-Status prüfen und optional automatisiert konfigurieren
- [ ] Secure-Boot-Status als Abschlussprüfung anzeigen
- [ ] Firewall-Status als Abschlussprüfung anzeigen
- [ ] optional Windows-Hello-Status expliziter prüfen
- [ ] optional Security-Baseline/Hardening weiter ausbauen

---

# Phase 5 – Treiber

## Architektur

- [x] Treiberlogik in `modules/Drivers/` aufgeteilt
- [x] gemeinsame Treiber-Helfer
- [x] Treiber-Reboot-Erkennung
- [x] Windows-Update-Treiber berücksichtigen
- [x] NVIDIA App installieren und aktualisieren
- [x] Intel-Treiberlogik
- [x] PSScriptAnalyzer-Probleme in Treibermodulen bereinigt

## Noch offen

- [ ] zentrale übersichtliche Hardware-Zusammenfassung
- [ ] Firmware-/BIOS-Update-Konzept prüfen
- [ ] optional Monitor-/Geräte-Firmware prüfen, falls sinnvoll automatisierbar

---

# Phase 6 – Windows & Microsoft Updates

- [x] `PSWindowsUpdate` automatisch installieren
- [x] Microsoft Update verwenden
- [x] normale Software-Updates suchen
- [x] kumulative Windows-Updates installieren
- [x] .NET-Updates installieren
- [x] Defender Security Intelligence Updates installieren
- [x] Treiber aus diesem Update-Pfad ausschließen bzw. separat behandeln
- [x] `AcceptAll` für unbeaufsichtigte Wartung
- [x] keinen automatischen Neustart durchführen
- [x] Neustartbedarf nach Updates melden
- [x] wiederholter Lauf ohne verfügbare Updates funktioniert sauber

---

# Phase 7 – Netzwerk & VPN

## OpenVPN

- [x] Paket-ID `OpenVPNTechnologies.OpenVPN`
- [x] feste Version `2.7.101`
- [x] Version-Pinning in generischer Paketlogik
- [x] Update deaktiviert
- [x] Installation erfolgreich getestet

---

# Phase 8 – Entwicklerumgebung

## Node.js

- [x] fnm installieren
- [x] Node LTS installieren/verwenden
- [x] npm aktualisieren
- [x] pnpm installieren und aktualisieren
- [x] Yarn installieren und aktualisieren
- [x] PATH-/PNPM_HOME-Konfiguration
- [x] pnpm 11.x getestet

## Bun

- [x] installieren
- [x] automatisch aktualisieren
- [x] Cache auf Dev Drive verschieben

## Go

- [x] installieren
- [x] automatisch aktualisieren
- [x] `GOCACHE` auf Dev Drive
- [x] `GOMODCACHE` auf Dev Drive

## Git

- [x] Benutzername konfigurieren
- [x] E-Mail konfigurieren
- [x] globale Git-Konfiguration
- [x] globale Gitignore
- [x] Editor konfigurieren
- [x] Git LFS aktivieren, wenn vorhanden
- [x] sinnvolle Default-Settings
- [x] Repository-Status auswerten
- [x] lokale Änderungen erkennen
- [x] ungepushte Commits erkennen
- [ ] optionale Git-Aliases
- [ ] optional SSH-Key-Bootstrap
- [ ] optional GPG/SSH Commit Signing

## Codex

- [x] Codex CLI installieren
- [ ] Codex-/CLI-Konfiguration bei Bedarf weiter automatisieren

---

# Phase 9 – Development Storage

## SSD-Erkennung

- [x] komplett leere interne Datenträger erkennen
- [x] Boot-Disk ausschließen
- [x] System-Disk ausschließen
- [x] ReadOnly-/Offline-Datenträger ausschließen
- [x] USB-Sticks und ungeeignete Bus-Typen ausschließen
- [x] bei mehreren möglichen Ziel-Datenträgern sicher abbrechen
- [x] Mindestgröße prüfen
- [x] geplantes Layout vor Änderungen anzeigen
- [x] destruktive Änderungen nur nach expliziter `Y`-Bestätigung
- [x] bestehendes D:/G:-Layout erkennen und nicht erneut partitionieren

## Layout

- [x] `D:` mit 100 GB
- [x] echtes ReFS Dev Drive
- [x] Label `Dev`
- [x] `G:` mit restlichem Speicher
- [x] NTFS
- [x] Label `Games`

Aktueller getesteter Zustand:

```text
D: 100 GB ReFS Dev Drive
G: Rest der SSD NTFS Games
```

## Dev Drive

- [x] als vertrauenswürdiges Dev Drive erstellt
- [x] Microsoft Defender `WdFilter` aktiv
- [x] Defender Performance Mode aktiv
- [x] Echtzeitschutz bleibt aktiv

## Ordnerstruktur

- [x] `D:\Projects`
- [x] `D:\Build`
- [x] `D:\Cache\npm`
- [x] `D:\Cache\pnpm`
- [x] `D:\Cache\yarn`
- [x] `D:\Cache\bun`
- [x] `D:\Cache\go\build`
- [x] `D:\Cache\go\modules`

## Cache-Konfiguration

- [x] npm
- [x] pnpm
- [x] Yarn Classic
- [x] Bun
- [x] Go Build Cache
- [x] Go Module Cache

---

# Phase 10 – PowerShell & Codequalität

## PowerShell

- [x] PowerShell 7
- [x] Modulinstallation automatisiert
- [x] `PSScriptAnalyzer`
- [x] `BurntToast`
- [x] `PSWindowsUpdate`

## Code Check

- [x] `Test-PowerShellCode`
- [x] Analyzer-Regeln bereinigt
- [x] externe CLI-Positionsargumente sauber behandelt
- [x] keine aktuellen Fehler
- [x] keine aktuellen Warnungen
- [x] keine aktuellen Hinweise
- [x] Codeprüfung am Ende jedes Bootstrap-Laufs

Zielzustand:

```text
[OK] Keine PSScriptAnalyzer-Probleme gefunden.
```

## Noch offen

- [ ] optionale CI-Prüfung in GitHub Actions
- [ ] optional Pester-Tests für kritische Module
- [ ] optional Dry-Run-/WhatIf-Konzept

---

# Phase 11 – Terminal Umgebung

## Windows Terminal

- [x] Einstellungen automatisiert anwenden
- [x] Windows-Terminal-Konfiguration im Setup
- [ ] Feinschliff der Profile bei Bedarf
- [ ] weitere Aliases/Komfortfunktionen bei Bedarf

## Nushell

- [x] Installation
- [x] Konfiguration
- [x] Starship-Integration
- [ ] weitere Aliases/Komfortfunktionen bei Bedarf

## Starship

- [x] Installation
- [x] Integration
- [x] Catppuccin-orientiertes Terminal-Design
- [ ] optional weiterer Prompt-Feinschliff

---

# Phase 12 – VS Code

- [x] Installation
- [x] Settings automatisiert einspielen
- [x] Extensions automatisiert installieren
- [x] Codex-Integration
- [x] Setup wiederholbar
- [ ] Extension-Liste regelmäßig bereinigen/aktualisieren
- [ ] optional Profile/Keybindings vollständig versionieren

---

# Phase 13 – Browser

## Chrome Beta

- [x] Installation
- [x] automatische Updates
- [x] Enterprise Policies
- [x] Extension Deployment

## Zen Browser

- [x] Installation
- [x] automatische Updates
- [x] Erweiterungen
- [x] deutsche Sprache
- [x] deutsches Wörterbuch
- [x] Enterprise Policies
- [x] Session Restore
- [x] Google als Suchmaschine
- [x] Telemetrie deaktiviert
- [x] Firefox Studies deaktiviert
- [x] Pocket deaktiviert
- [x] Zen Mods automatisiert installieren
- [x] internen Zen-Mod-Handler über Marionette verwenden
- [x] Marionette-Konfigurationsmodus automatisch verlassen
- [x] Zen danach normal neu starten
- [x] Mod-Installation idempotent
- [ ] optional Browser-UI weiter an Catppuccin anpassen

---

# Phase 14 – Apple Integration

## iCloud

- [x] Installation
- [x] automatische Updates
- [x] iCloud Passwords Browser-Erweiterung
- [x] Voraussetzungen für Apple Passwords/Windows Hello prüfen


---

# Phase 15 – Logitech G502 X Plus

## Software

- [x] Logitech G HUB über `winget`
- [x] automatische Updates
- [x] G HUB bleibt dauerhaft aktiv
- [x] Akkuwarnungen über G HUB verfügbar

## Maus-Konfiguration

- [x] DPI manuell konfiguriert
- [x] Polling Rate manuell konfiguriert
- [x] Tastenbelegung manuell konfiguriert
- [x] G-Shift nach Wunsch konfiguriert
- [x] Catppuccin-Mocha-inspirierte RGB-Animation erstellt
- [x] Onboard-Memory-Ansatz getestet
- [x] wegen Einschränkungen des Onboard-RGB bewusst bei dauerhaft laufendem G HUB geblieben

## Konfigurationssicherung

- [x] `settings.db` identifiziert
- [x] DB im Repository unter `config\lghub\settings.db`
- [x] G HUB vor DB-Zugriff automatisch beenden
- [x] G HUB danach automatisch neu starten
- [x] stdout/stderr von G HUB umleiten
- [x] frisches System: Repo-Konfiguration einmalig einspielen
- [x] bestehendes System: lokale DB bei Änderung zurück ins Repo sichern
- [x] Änderungen anschließend über Git-Status melden
- [x] keine automatischen Commits oder Pushes

---

# Phase 16 – Automatische Wartung & Benachrichtigungen

## Windows Aufgabenplanung

- [x] Aufgabe `Windows Setup Weekly Maintenance`
- [x] wöchentlich
- [x] Sonntag 12:00 Uhr
- [x] `bootstrap.ps1` direkt ausführen
- [x] kein separates Maintenance-Skript
- [x] interaktiver Benutzerkontext
- [x] höchste Privilegien
- [x] Task bei bestehender Konfiguration aktualisieren
- [x] realer Task-Lauf erfolgreich getestet

## Wartungsumfang

- [x] Repository aktualisieren
- [x] Winget-/Store-Pakete aktualisieren
- [x] Development Tools aktualisieren
- [x] Treiber prüfen/aktualisieren
- [x] Windows Updates installieren
- [x] G-HUB-Konfiguration synchronisieren
- [x] Windows-Konfiguration wiederholt anwenden
- [x] Storage/Dev Drive prüfen
- [x] Codeanalyse durchführen
- [x] Neustartbedarf prüfen
- [x] Git-Status prüfen

## Desktop Notifications

- [x] BurntToast integriert
- [x] Benachrichtigung bei notwendigem Neustart
- [x] Benachrichtigung bei lokalen Repository-Änderungen
- [x] Benachrichtigung bei ungepushten Commits
- [x] geänderte Dateien teilweise in Benachrichtigung anzeigen
- [x] Benachrichtigungen aus Scheduled Task erfolgreich getestet
- [ ] optional Erfolgs-Toast auch bei komplett sauberem Wartungslauf
- [ ] optional Fehler-Toast bei abgebrochenem Bootstrap

---

# Phase 17 – Gaming

## Basis

- [x] NVIDIA App
- [x] Windows HDR Calibration
- [x] Windows HDR konfigurieren
- [x] separates `G:`-Games-Laufwerk
- [ ] Steam automatisiert installieren
- [ ] Epic Games Launcher automatisiert installieren
- [ ] GOG Galaxy automatisiert installieren
- [ ] EA App automatisiert installieren
- [ ] Ubisoft Connect automatisiert installieren
- [ ] weitere benötigte Launcher ergänzen

## Games-Laufwerk

- [x] NTFS für maximale Spiele-/Launcher-Kompatibilität
- [ ] Bibliothekspfade der Launcher automatisiert auf `G:` setzen, soweit sinnvoll
- [ ] optional Ordnerstruktur definieren

## Monitor / Gaming Display

Samsung Odyssey G93SD:

- [ ] optimale Auflösung automatisiert/verifiziert
- [ ] maximale Bildwiederholrate verifiziert
- [x] HDR-Grundkonfiguration
- [ ] HDR/SDR-Feinschliff
- [ ] VRR/G-SYNC prüfen
- [ ] Farbprofil/Farbraum prüfen

---

# Phase 18 – Firmen-Tools

Noch offen beziehungsweise nur teilweise außerhalb des Repositories vorhanden:

- [ ] Remote Desktop Manager installieren
- [ ] FileZilla installieren
- [ ] PCVisit Supporter Modul installieren


---

# Phase 19 – Linux-ähnlicher Workflow unter Windows

## Tiling Window Manager

Evaluieren und anschließend festlegen:

- [ ] GlazeWM
- [ ] komorebi
- [ ] weitere sinnvolle Alternative nur bei Bedarf

Ziele:

- [ ] automatisches Tiling
- [ ] Floating-Ausnahmen
- [ ] Workspaces
- [ ] Tastatursteuerung
- [ ] Catppuccin-Mocha-Design
- [ ] reproduzierbare Konfiguration im Repository

## Waybar-ähnliche Leiste

- [ ] Workspaces
- [ ] aktiver Workspace
- [ ] CPU
- [ ] RAM
- [ ] VPN
- [ ] Uhr/Datum
- [ ] Lautstärke
- [ ] Netzwerk
- [ ] Akku-/Gerätestatus, soweit sinnvoll
- [ ] Catppuccin Mocha

## Launcher

- [ ] Programmstarter auswählen
- [ ] globale Suche
- [ ] Tastenkürzel
- [ ] Theme anpassen

---

# Phase 20 – Design / Catppuccin Mocha

Bereits umgesetzt beziehungsweise begonnen:

- [x] Terminal-/CLI-Umgebung
- [x] Starship
- [x] VS Code
- [x] G502-X-Plus-RGB
- [x] Windows Dark Theme
- [ ] Tiling-WM
- [ ] Statusleiste
- [ ] Launcher
- [ ] Browser optional weiter angleichen
- [ ] weitere Anwendungen nur dort themen, wo es stabil und wartbar ist

---

# Phase 21 – Backup & Restore

## Bereits reproduzierbar

- [x] Winget-/Store-Pakete über `packages.psd1`
- [x] Git-Konfiguration
- [x] VS-Code-Extensions und Settings
- [x] Terminal-Konfiguration
- [x] Nushell
- [x] Starship
- [x] Browser Policies
- [x] Zen Mods
- [x] G-HUB-Konfiguration
- [x] Windows-Konfiguration
- [x] Dev-Drive-Konfiguration

## Noch offen

- [ ] vollständigen Restore auf wirklich frischer Windows-Installation testen
- [ ] dokumentieren, welche manuellen Schritte unvermeidbar bleiben
- [ ] Export/Restore von Gaming-Launcher-Konfigurationen prüfen
- [ ] Export/Restore von Firmen-Tools prüfen
- [ ] optional Windows-Einstellungen ergänzen, die aktuell noch nicht versioniert sind
- [ ] Recovery-/Rollback-Konzept für fehlerhafte Bootstrap-Änderungen

---

# Phase 22 – Logging, Fehlerbehandlung & Qualität

## Erledigt

- [x] `$ErrorActionPreference = "Stop"`
- [x] klare Statusausgaben
- [x] wichtige Fehler führen zu Exceptions
- [x] PSScriptAnalyzer sauber
- [x] kritische Storage-Aktion benötigt Bestätigung
- [x] kein automatischer Reboot
- [x] Git-Änderungen werden nicht automatisch gepusht

## Noch offen

- [ ] zentraler Log-Ordner
- [ ] vollständiges Transcript pro Bootstrap-Lauf
- [ ] Log-Rotation
- [ ] Fehler-Toast bei Scheduled-Task-Fehler
- [ ] Task-Ergebnis/Exit-Code in Benachrichtigung integrieren
- [ ] optional Retry für Netzwerk-/Downloadfehler
- [ ] optional Pester-Tests
- [ ] optional GitHub Actions für statische Codeanalyse

---

# Nächste sinnvolle Schritte

Priorität für die nächsten Arbeiten:

1. [ ] **Linux-ähnlichen Windows-Workflow** – Tiling WM auswählen und einrichten
2. [ ] **Waybar-ähnliche Statusleiste** – Workspaces, Systemstatus, VPN, Audio und Netzwerk
3. [ ] **Launcher** – schneller programm-/suchbasierter Workflow
4. [ ] **Gaming-Pakete und Launcher** – Steam/Epic/GOG/EA/Ubisoft reproduzierbar installieren
5. [ ] **Firmen-Tools** – RDM, FileZilla, PCVisit und Zertifikate
6. [ ] **Logging/Fehler-Toast** – automatische Wochenwartung noch besser nachvollziehbar machen
7. [ ] **vollständiger Restore-Test** auf einer frischen Windows-Installation

---

# Aktueller Projektstatus

Der Kern des Projekts ist inzwischen funktionsfähig:

- [x] Windows kann mit einem Einzeiler initialisiert werden
- [x] derselbe Bootstrap kann wiederholt ausgeführt werden
- [x] Software wird installiert und aktualisiert
- [x] feste Paketversionen werden unterstützt
- [x] Windows wird debloated
- [x] Treiber werden gewartet
- [x] Windows Updates werden installiert
- [x] Entwicklerumgebung wird eingerichtet
- [x] Dev Drive wird automatisch und sicher eingerichtet
- [x] Defender ist für das Dev Drive optimiert
- [x] Browser werden automatisiert konfiguriert
- [x] Zen Mods werden automatisiert installiert
- [x] G502-X-Plus-/G-HUB-Konfiguration wird gesichert
- [x] das Repository meldet lokale und ungepushte Änderungen
- [x] notwendige Neustarts werden gemeldet
- [x] der komplette Bootstrap läuft wöchentlich automatisch
- [x] PSScriptAnalyzer meldet keine Probleme

Das Projekt ist damit nicht mehr nur ein Installationsskript, sondern bereits ein reproduzierbares Setup- und Wartungssystem. Die größten offenen Blöcke sind derzeit der Linux-ähnliche Desktop-Workflow unter Windows, Gaming-Launcher, Firmen-Tools sowie zusätzliche Restore-/Logging-Qualität.
