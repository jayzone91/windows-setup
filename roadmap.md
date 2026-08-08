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
- [x] Desktop-Umgebung mit komorebi, whkd und Zebar reproduzierbar konfigurieren
- [x] Zebar lokal und offline-fähig über npm/TypeScript/esbuild bauen
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
- [x] Session-PATH aktualisieren, ohne vorhandene Session-Einträge zu verlieren

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
- [x] komorebi über `LGUG2Z.komorebi`
- [x] whkd über `LGUG2Z.whkd`
- [x] Zebar über `glzr-io.zebar`

## Aktuelle Gruppen

### Basis

- [x] JetBrainsMono Nerd Font

### Tools

- [x] Windows HDR Calibration
- [x] iCloud
- [x] OpenVPN
- [x] Logitech G HUB
- [x] komorebi
- [x] whkd
- [x] Zebar

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
- [ ] Gaming Setup
- [ ] Home Office Setup

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

## Windows-Konfiguration

- [x] Taskbar-Konfiguration
- [x] Startmenü-Konfiguration
- [x] Windows Theme
- [x] Power-Einstellungen
- [x] HDR
- [x] Wallpaper Slideshow
- [x] Consumer-/Content-Delivery-Einstellungen
- [x] Windows Snap deaktiviert, damit komorebi die Fensterverwaltung übernimmt
- [x] Widgets-Ausblenden so behandelt, dass ein geschützter `TaskbarDa`-Wert den Bootstrap nicht abbricht
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

- [x] Treiberlogik in `modules/Drivers/` aufgeteilt
- [x] gemeinsame Treiber-Helfer
- [x] Treiber-Reboot-Erkennung
- [x] Windows-Update-Treiber berücksichtigen
- [x] NVIDIA App installieren und aktualisieren
- [x] Intel-Treiberlogik
- [x] PSScriptAnalyzer-Probleme in Treibermodulen bereinigt
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
- [ ] VPN-Profile automatisiert bereitstellen
- [ ] Firmen-/Privatprofile sauber trennen
- [ ] optional Zertifikate automatisiert importieren

---

# Phase 8 – Entwicklerumgebung

## Node.js

- [x] fnm installieren
- [x] Node LTS installieren/verwenden
- [x] npm aktualisieren
- [x] pnpm installieren und aktualisieren
- [x] Yarn installieren und aktualisieren
- [x] PATH-/PNPM_HOME-Konfiguration
- [x] npm für den Zebar-Build im Bootstrap verfügbar machen

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

## Codex

- [x] Codex CLI installieren
- [ ] Codex-/CLI-Konfiguration bei Bedarf weiter automatisieren

---

# Phase 9 – Development Storage

- [x] leere interne Datenträger sicher erkennen
- [x] Boot-/System-Disk ausschließen
- [x] ungeeignete Datenträger ausschließen
- [x] destruktive Änderungen nur nach expliziter Bestätigung
- [x] bestehendes D:/G:-Layout erkennen

## Layout

- [x] `D:` mit 100 GB ReFS Dev Drive, Label `Dev`
- [x] `G:` mit restlichem Speicher, NTFS, Label `Games`

## Caches

- [x] npm
- [x] pnpm
- [x] Yarn
- [x] Bun
- [x] Go Build Cache
- [x] Go Module Cache

---

# Phase 10 – PowerShell & Codequalität

- [x] PowerShell 7
- [x] Modulinstallation automatisiert
- [x] `PSScriptAnalyzer`
- [x] `BurntToast`
- [x] `PSWindowsUpdate`
- [x] `Test-PowerShellCode`
- [x] Codeprüfung am Ende jedes Bootstrap-Laufs
- [ ] optionale CI-Prüfung in GitHub Actions
- [ ] optional Pester-Tests für kritische Module
- [ ] optional Dry-Run-/WhatIf-Konzept

---

# Phase 11 – Terminal Umgebung

- [x] Windows Terminal konfigurieren
- [x] Nushell installieren und konfigurieren
- [x] Starship integrieren
- [x] Catppuccin-orientiertes Terminal-Design
- [ ] weiterer Feinschliff bei Bedarf
- [ ] optional Profile/Keybindings vollständig versionieren

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
- [ ] Browser-UI weiter an Catppuccin anpassen

---

# Phase 14 – Logitech G HUB

- [x] Installation über `winget`
- [x] automatische Updates
- [x] gespeicherte Konfiguration unter `config/lghub/settings.db`
- [x] Erstimport auf frisch eingerichteten Systemen
- [x] spätere lokale Änderungen zurück ins Repository synchronisieren
- [x] G HUB für DB-Zugriff kontrolliert beenden und wieder starten
- [x] Git-Änderungen an `settings.db` am Ende des Wartungslaufs melden

---

# Phase 15 – Desktop Window Management

## komorebi

- [x] komorebi installiert und aktualisierbar
- [x] Konfiguration im Repository unter `dotfiles/komorebi/`
- [x] `%USERPROFILE%\komorebi.json` per Symlink anbinden
- [x] `applications.json` per Symlink anbinden
- [x] fünf Workspaces konfigurieren
- [x] `UltrawideVerticalStack` als bevorzugtes Layout
- [x] Windows Snap deaktivieren
- [x] komorebi nach echtem Neustart erfolgreich im Autostart getestet

## whkd

- [x] whkd installiert und aktualisierbar
- [x] `whkdrc` im Repository
- [x] `%USERPROFILE%\.config\whkdrc` per Symlink anbinden
- [x] Fokus, Move, Resize, Workspaces, Stacking und Window-Aktionen
- [x] komorebi und whkd gemeinsam über Scheduled Task starten

## Autostart

- [x] Scheduled Task `komorebi Desktop`
- [x] Start bei Benutzeranmeldung
- [x] interaktiver Benutzerkontext
- [x] keine unnötigen Adminrechte
- [x] realer Neustart-/Login-Test erfolgreich

---

# Phase 16 – Zebar Desktop Bar

## Installation & Build

- [x] Zebar installiert
- [x] Zebar-Konfiguration unter `dotfiles/zebar/`
- [x] `%USERPROFILE%\.glzr\zebar\settings.json` per Symlink
- [x] kompletter `windows-setup-bar`-Ordner per Symlink
- [x] keine CDN-Abhängigkeit mehr
- [x] `zebar` lokal als npm-Abhängigkeit
- [x] TypeScript
- [x] esbuild
- [x] `tsc --noEmit` vor dem Build
- [x] Ausgabe nach `dist/main.js`
- [x] `npm ci` im Bootstrap
- [x] `npm run build` im Bootstrap
- [x] lokaler/offline-fähiger Runtime-Build
- [x] `npm run dev:reload`
- [x] Zebar-Restart ohne dauerhaftes Terminal-Logging

## Struktur

- [x] `src/main.ts`
- [x] `src/providers.ts`
- [x] `src/zebar.ts`
- [x] `src/utils/`
- [x] `src/komorebi/`
- [x] `src/system/`

## Linke Seite

- [x] fünf komorebi-Workspaces
- [x] aktiven Workspace hervorheben
- [x] Layout-Anzeige
- [x] Catppuccin-Mocha-Pill-Design

## Mitte

- [x] Titel des fokussierten Fensters
- [x] echtes Windows-Anwendungsicon
- [x] kein manuelles App-zu-Icon-Mapping
- [x] Icon-Ermittlung über EXE-Namen und `Get-AppIcon.ps1`
- [x] Base64-PNG
- [x] Icon-Cache
- [x] Schutz vor asynchronen Render-Races

## Rechte Seite

- [x] CPU-Auslastung
- [x] RAM inkl. verwendet/gesamt
- [x] Storage-Auslastung
- [x] aktive Netzwerk-Schnittstelle
- [x] IPv4-Adresse
- [x] Download-/Upload-Durchsatz
- [x] feste Breiten für Traffic-Werte
- [x] Audio-Lautstärke
- [x] Mute-Status und dynamisches Icon
- [x] Klick zum Muten/Entmuten
- [x] Mausrad zur Lautstärkeregelung
- [x] Media: Titel und Artist
- [x] Previous / Play-Pause / Next
- [x] korrektes Play/Pause-Icon
- [x] Ellipsis für lange Media-Texte
- [x] deutsches Datum
- [x] 24-Stunden-Uhrzeit
- [x] Batterie bewusst nicht umgesetzt
- [x] Systray bewusst nicht umgesetzt

## Autostart

- [x] Scheduled Task `Zebar Desktop`
- [x] Start bei Benutzeranmeldung
- [x] interaktiver Benutzerkontext
- [x] keine unnötigen Adminrechte
- [x] realer Neustart-/Login-Test erfolgreich
- [x] komorebi + whkd + Zebar starten gemeinsam sauber

## Optionaler Feinschliff

- [ ] CSS weiter konsolidieren
- [ ] Workspaces/Layout per Mausklick steuerbar machen
- [ ] optional Responsive-/Overflow-Verhalten für kleinere Monitore
- [ ] optional Icon-Fallback für spezielle UWP-/Store-Anwendungen verbessern

---

# Phase 17 – Automatische Wartung & Benachrichtigungen

- [x] Scheduled Task `Windows Setup Weekly Maintenance`
- [x] Sonntag 12:00 Uhr
- [x] kompletter Bootstrap als Wartungsworkflow
- [x] `StartWhenAvailable`
- [x] Mehrfachstarts verhindern
- [x] interaktiver Benutzerkontext
- [x] erhöhte Rechte für Wartungsaufgaben
- [x] BurntToast-Benachrichtigung bei notwendigem Neustart
- [x] Repository-Status nach Wartung prüfen
- [x] lokale Änderungen melden
- [x] ungepushte Commits melden
- [x] keine automatischen Commits oder Pushes
- [x] keine automatischen Neustarts
- [ ] vollständiges Lauf-Logging in Datei
- [ ] Historie der letzten Wartungsläufe
- [ ] optional kompakte Wartungs-Zusammenfassung als Notification
- [ ] optional Fehlerstatus einzelner Module persistieren

---

# Phase 18 – Abschlussprüfungen & Qualität

- [x] Bootstrap mehrfach erfolgreich ausgeführt
- [x] Windows-Updates mit anschließendem Neustart getestet
- [x] komorebi-Autostart nach echtem Neustart getestet
- [x] Zebar-Autostart nach echtem Neustart getestet
- [x] Zebar-TypeScript-Build erfolgreich
- [x] Network-, Audio-, Media- und Date-Time-Widgets praktisch getestet
- [x] PSScriptAnalyzer am Ende des Bootstraps
- [ ] vollständiger Test auf einer wirklich frischen Windows-11-Installation
- [ ] optional GitHub Actions für PowerShell- und TypeScript-Prüfungen
- [ ] optional Pester-Tests für kritische PowerShell-Module
- [ ] optional automatisierter `npm run typecheck`/Build in CI
- [ ] README um komorebi/Zebar und aktuelle Desktop-Architektur ergänzen
- [ ] Dokumentation der wichtigsten Tastenkombinationen ergänzen

---

---

# Phase 19 – Apple Integration

## iCloud

- [x] Installation
- [x] automatische Updates
- [x] iCloud Passwords Browser-Erweiterung
- [x] Voraussetzungen für Apple Passwords/Windows Hello prüfen

---

---

# Phase 20 – Sonstiges

## Gaming

- [ ] Steam
- [ ] EA
- [ ] Ubisoft
- [ ] GOG
- [ ] Epic

## Windows

- [ ] Lock Screen anpassen!
- [ ] Startleiste ausblenden
- [ ] App Launcher installieren
- [ ] Windows key binding auf App Launcher
- [ ] Caps Lock / Num Lock OSD (Ähnlich Logitech Options)

## Home Office

- [ ] Remote Desktop Manager
- [ ] Filezilla

## Enwicklung

- [ ] NextJS Workflow in VS Code
- [ ] Golang Workflow in VS Code

---

# Aktueller Gesamtstatus

Die Kernarchitektur des Setups ist produktiv nutzbar und weitgehend reproduzierbar.

Besonders weit abgeschlossen sind:

- Bootstrap- und Repository-Architektur
- Paketverwaltung
- Windows Debloat und Grundkonfiguration
- Windows-/Microsoft-Updates
- Development Toolchain
- ReFS Dev Drive und Cache-Verlagerung
- Browser-Konfiguration
- VS Code
- Logitech G HUB
- komorebi + whkd
- Zebar inklusive TypeScript-/esbuild-Build
- Desktop-Autostart
- wöchentliche Wartung
- Desktop-Benachrichtigungen
- PSScriptAnalyzer-Codeprüfung

Die größten verbleibenden Themen sind damit nicht mehr der Grundaufbau, sondern Qualitäts- und Komfortthemen:

1. zentrale Logging-Strategie
2. vollständiger Clean-Install-Test auf einem frischen Windows 11
3. CI/Pester/TypeScript-Checks
4. Security-Abschlussprüfungen für BitLocker, Secure Boot und Firewall
5. Dokumentations-Feinschliff
6. optionale VPN-/Zertifikats-Automatisierung
7. kleinere Desktop-/Zebar-Polish-Aufgaben
