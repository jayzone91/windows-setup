# Windows Setup Roadmap

## Ziel

Ein vollständig automatisiertes, reproduzierbares und wartbares Windows-11-Entwickler-, Gaming- und Arbeitsplatz-Setup.

Der gleiche `bootstrap.ps1` soll für drei Fälle funktionieren:

- Neuinstallation
- manueller erneuter Setup-Durchlauf
- automatische wöchentliche Wartung

Zusätzlich soll die Windows-Desktop-Umgebung funktional und optisch möglichst nah an die Arch-/Hyprland-Umgebung angelehnt werden, ohne Windows gegen seine Plattform zu verbiegen.

Zielbild Desktop:

- Arch: Hyprland + Waybar + Fuzzel + SwayOSD
- Windows: komorebi + Zebar + PowerToys Command Palette + eigenes OSD
- Catppuccin Mocha als gemeinsame Designsprache, aber mit nativer Konfiguration pro Anwendung
- Windhawk für die Bereiche der Windows-Shell, die sich mit Bordmitteln nicht ausreichend anpassen lassen

Grundprinzipien:

- [x] ein zentraler Bootstrap statt getrennten Setup-/Maintenance-Skripten
- [x] möglichst idempotente Module
- [x] Konfiguration im Repository
- [x] keine automatischen Neustarts
- [x] keine automatischen Git-Commits oder Pushes
- [x] lokale Änderungen und notwendige Neustarts per Desktop-Benachrichtigung melden
- [x] Desktop-Umgebung mit komorebi, whkd und Zebar reproduzierbar konfigurieren
- [x] Zebar lokal und offline-fähig über npm/TypeScript/esbuild bauen
- [ ] Catppuccin Mocha als gemeinsame Designsprache über alle sinnvoll anpassbaren Desktop-Komponenten
- [ ] keine erzwungene gemeinsame CSS-Basis; jedes Programm nutzt seine native bzw. sinnvollste Theme-Methode
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
- [ ] PowerToys aufnehmen
- [ ] Everything aufnehmen
- [ ] Windhawk aufnehmen
- [x] masir aufnehmen

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
- [ ] PowerToys
- [ ] Everything
- [ ] Windhawk
- [x] masir

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
- [ ] Taskbar automatisch ausblenden, da Zebar die primäre Desktop-Bar ist
- [ ] Lock Screen optisch an Desktop/Wallpaper-Konzept anpassen
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
- [ ] NextJS Workflow vervollständigen
- [ ] Golang Workflow vervollständigen
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
- [ ] Browser-UI weiter an Catppuccin Mocha anpassen
- [ ] benötigte eigene CSS-Anpassungen reproduzierbar im Repository hinterlegen

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
- [x] integriertes Catppuccin-Theme nutzen
- [x] komorebi nach echtem Neustart erfolgreich im Autostart getestet

## whkd

- [x] whkd installiert und aktualisierbar
- [x] `whkdrc` im Repository
- [x] `%USERPROFILE%\.config\whkdrc` per Symlink anbinden
- [x] Fokus, Move, Resize, Workspaces, Stacking und Window-Aktionen
- [x] komorebi und whkd gemeinsam über Scheduled Task starten
- [ ] PowerToys Command Palette mit passendem Keybinding integrieren
- [ ] bevorzugt `Win+Space` als Windows-Äquivalent zu `Super+Space` unter Arch prüfen/einrichten

## Focus Follows Mouse / masir

- [x] `LGUG2Z.masir` über Winget installieren
- [x] masir 0.1.2 praktisch getestet
- [x] automatische komorebi-Integration von masir verwenden
- [x] Focus Follows Mouse wie unter Hyprland
- [x] masir parameterlos starten
- [x] masir gemeinsam mit komorebi/whkd über den Desktop-Task starten
- [x] keine separate masir-Konfiguration notwendig

## Autostart

- [x] Scheduled Task `komorebi Desktop`
- [x] Start bei Benutzeranmeldung
- [x] interaktiver Benutzerkontext
- [x] komorebi, whkd und masir gemeinsam starten
- [x] Task mit `RunLevel Highest` starten
- [x] dadurch auch erhöhte/Admin-Fenster durch komorebi verwaltbar
- [x] Windows Terminal als Administrator wird korrekt in das Tiling-Layout aufgenommen
- [x] realer manueller Task-Test erfolgreich
- [x] realer Neustart-/Login-Test für komorebi grundsätzlich bereits erfolgreich

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

## Linke Seite – Workspaces & Tiling

- [x] fünf komorebi-Workspaces anzeigen
- [x] aktiven Workspace dynamisch hervorheben
- [x] Layout/Tiling-Methode dynamisch anzeigen
- [x] Catppuccin-Mocha-Pill-Design
- [x] Workspace-Pills per Mausklick steuerbar machen
- [x] Klick auf Workspace 1–5 fokussiert direkt den entsprechenden komorebi-Workspace
- [x] Hover-/Pointer-/Pressed-Feedback für interaktive Workspace-Pills
- [x] Layout-/Tiling-Anzeige per Mausklick steuerbar machen
- [x] Catppuccin-Popup/Dropdown für verfügbare komorebi-Layouts umsetzen
- [x] aktuelles Layout im Selector hervorheben
- [x] Layout-Auswahl setzt die Tiling-Methode direkt in komorebi
- [x] `UltrawideVerticalStack` im Selector berücksichtigen
- [x] Interaktionen praktisch gegen komorebi testen
- [x] Layout-Selector als separates Zebar-Widget umgesetzt
- [x] Popup schließt nach Layout-Auswahl automatisch
- [x] Popup schließt bei Fokusverlust/Klick außerhalb
- [x] Hover-Tooltip mit Bezeichnung jeder Tiling-Methode
- [x] Rand-Tooltips gegen Abschneiden am Popup-Rand abgesichert
- [x] gesamte Layout-Pill klickbar, nicht nur das Icon

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

## Feinschliff

- [ ] CSS weiter konsolidieren, wo es innerhalb von Zebar sinnvoll ist
- [ ] optional Responsive-/Overflow-Verhalten für kleinere Monitore
- [ ] optional Icon-Fallback für spezielle UWP-/Store-Anwendungen verbessern

> **Status:** Zebar ist für den aktuellen Funktionsumfang abgeschlossen. Workspace-Wechsel und Layout-Auswahl funktionieren per Maus; der Layout-Selector ist als separates Popup-Widget mit Tooltips und automatischem Schließen umgesetzt.

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
- [x] Zebar Workspace-Klicks praktisch getestet
- [x] Zebar Layout-Selector praktisch getestet
- [x] masir Focus-Follows-Mouse praktisch getestet
- [x] Admin-Windows-Terminal im komorebi-Tiling praktisch getestet
- [ ] PowerToys/Everything-Launcher praktisch getestet
- [ ] Windhawk-Konfiguration nach Windows-Neustart praktisch getestet
- [ ] vollständiger Test auf einer wirklich frischen Windows-11-Installation
- [ ] optional GitHub Actions für PowerShell- und TypeScript-Prüfungen
- [ ] optional Pester-Tests für kritische PowerShell-Module
- [ ] optional automatisierter `npm run typecheck`/Build in CI
- [ ] README um komorebi/Zebar/PowerToys/Windhawk und aktuelle Desktop-Architektur ergänzen
- [ ] Dokumentation der wichtigsten Tastenkombinationen ergänzen

---

# Phase 19 – Apple Integration

## iCloud

- [x] Installation
- [x] automatische Updates
- [x] iCloud Passwords Browser-Erweiterung
- [x] Voraussetzungen für Apple Passwords/Windows Hello prüfen

---

# Phase 20 – Desktop Experience & Catppuccin

## Designstrategie

Ziel ist eine konsistente Catppuccin-Mocha-Designsprache ähnlich der Arch-Workstation.

Es wird bewusst **keine universelle gemeinsame CSS-Datei** für alle Programme erzwungen. Die Anwendungen besitzen unterschiedliche Theme-Systeme und sollen jeweils mit der stabilsten nativen Methode konfiguriert werden.

- [x] Catppuccin Mocha als Ziel-Design festgelegt
- [x] JetBrainsMono Nerd Font als zentrale Desktop-/Terminal-Schrift vorhanden
- [ ] Farben/Designwerte bei eigenen Komponenten konsistent halten
- [ ] keine unnötige Theme-Abstraktion einführen

### Theme-Methode pro Komponente

- [x] komorebi: integriertes Catppuccin
- [x] Zebar: eigenes CSS
- [x] Windows Terminal: Farbschema in JSON
- [x] VS Code: Catppuccin-Theme/Extension
- [ ] Zen Browser: eigene CSS-/UI-Anpassungen
- [ ] PowerToys Command Palette: vorhandene Theme-Möglichkeiten ausschöpfen
- [ ] Explorer: Windhawk File Explorer Styler
- [ ] Taskbar: Windhawk Taskbar Styler
- [ ] Startmenü: Windhawk Start Menu Styler
- [ ] Notification Center / Quick Settings: Windhawk Notification Center Styler
- [ ] eigenes OSD: eigenes Catppuccin-Design
- [ ] GitHub Desktop: nur soweit technisch sinnvoll/unterstützt; keine fragile Sonderlösung erzwingen

## PowerToys & App Launcher

PowerToys soll die Launcher-Funktion übernehmen. Ein separater Flow Launcher ist nicht vorgesehen.

- [ ] PowerToys installieren und aktualisieren
- [ ] PowerToys reproduzierbar konfigurieren
- [ ] Command Palette aktivieren und als primären App Launcher verwenden
- [ ] nicht benötigte PowerToys-Module gezielt deaktivieren
- [ ] Everything installieren und konfigurieren
- [ ] Everything-Suche mit PowerToys/Command Palette verbinden
- [ ] Launcher optisch soweit möglich an Catppuccin Mocha anpassen
- [ ] `Win+Space` als bevorzugten Launcher-Hotkey prüfen/einrichten
- [ ] Verhalten mit whkd und Windows-eigenen Shortcuts testen
- [ ] Windows-Startmenü als Fallback erhalten

## Windhawk & Windows Shell

Windhawk wird gezielt für Shell-Bereiche eingesetzt, die Windows selbst nicht ausreichend themen lässt. Mods müssen reproduzierbar konfiguriert und so behandelt werden, dass ein inkompatibler Mod nach einem Windows-Update nicht den gesamten Bootstrap scheitern lässt.

- [ ] Windhawk installieren und aktualisieren
- [ ] Windhawk-Konfiguration im Repository abbilden
- [ ] benötigte Mods reproduzierbar installieren/aktivieren
- [ ] Fehler/inkompatible Mods fehlertolerant behandeln

### Explorer

- [ ] Windows 11 File Explorer Styler
- [ ] Catppuccin-Mocha-Explorer-Theme erstellen/anpassen
- [ ] Explorer-Hintergründe, Navigation, Toolbar, Tabs und Auswahlzustände abstimmen
- [ ] Lesbarkeit und Kontrast prüfen
- [ ] Verhalten nach Explorer-Neustart und Windows-Update prüfen

### Taskbar

Die Taskbar bleibt trotz Zebar relevant, da Windows sie u. a. beim Startmenü einblendet.

- [ ] Taskbar Auto-Hide aktivieren
- [ ] Windows 11 Taskbar Styler
- [ ] Taskbar auf Catppuccin Mocha abstimmen
- [ ] Styling an Zebar/Waybar-Designsprache annähern
- [ ] Search/Widgets/Task-View und unnötige Buttons reduzieren
- [ ] Verhalten beim Öffnen des Startmenüs prüfen

### Startmenü

- [ ] Windows 11 Start Menu Styler
- [ ] Startmenü auf Catppuccin Mocha abstimmen
- [ ] Taskbar und Startmenü optisch als Einheit behandeln
- [ ] Startmenü weiterhin als Fallback zum PowerToys Launcher nutzbar halten

### Notification Center / Quick Settings

- [ ] Windows 11 Notification Center Styler
- [ ] Notification Center auf Catppuccin Mocha abstimmen
- [ ] Quick Settings auf Catppuccin Mocha abstimmen
- [ ] Lesbarkeit von Systemzuständen und Toggles sicherstellen

## Eigenes Windows OSD

Ziel ist ein einheitliches OSD analog zum SwayOSD-Konzept unter Arch.

- [ ] technische Basis für eigenes OSD festlegen
- [ ] Catppuccin-Mocha-Design
- [ ] Lautstärke anzeigen
- [ ] Mute anzeigen
- [ ] Mikrofon-Mute anzeigen
- [ ] Caps Lock anzeigen
- [ ] Num Lock anzeigen
- [ ] optional Media-Status
- [ ] OSD ohne störende dauerhafte Hintergrundfenster starten
- [ ] Autostart reproduzierbar konfigurieren
- [ ] Zusammenspiel mit vorhandenen Windows-/Geräte-OSDs prüfen

## Lock Screen

- [ ] Lock Screen anpassen
- [ ] Wallpaper/Design an Desktop-Konzept angleichen
- [ ] reproduzierbare Konfiguration prüfen

---

# Phase 21 – Gaming

- [ ] Steam
- [ ] EA App
- [ ] Ubisoft Connect
- [ ] GOG
- [ ] Epic Games Launcher
- [ ] Installationen in Paket-/Setup-Logik integrieren
- [ ] sinnvolle Games-Laufwerk-Defaults berücksichtigen

---

# Phase 22 – Home Office

- [ ] Remote Desktop Manager
- [ ] FileZilla
- [ ] weitere Firmen-/Homeoffice-Tools bei Bedarf als eigene Paketgruppe
- [ ] VPN-Profile/Zertifikate aus Phase 7 bei Bedarf vervollständigen

---

# Phase 23 – Priorisierte nächste Schritte

Die Desktop-Basis ist bereits funktionsfähig. Die weitere Arbeit erfolgt in dieser Reihenfolge:

1. [x] **Zebar fertigstellen**
   - Workspace-Umschaltung per Klick
   - Layout-/Tiling-Auswahl per Klick
   - separates Catppuccin-Popup für Layouts
   - Hover-/Pressed-Feedback
   - Tooltips für Tiling-Methoden
   - Schließen bei Auswahl und Fokusverlust
2. [x] **Focus Follows Mouse**
   - masir über Winget
   - automatische komorebi-Integration
   - Autostart gemeinsam mit komorebi/whkd
   - erhöhten Desktop-Task verwenden, damit Admin-Fenster getiled werden
3. [ ] **PowerToys + Everything**
   - Command Palette als App Launcher
   - `Win+Space`
   - reproduzierbare Konfiguration
4. [ ] **Windhawk**
   - Explorer
   - Taskbar
   - Startmenü
   - Notification Center / Quick Settings
5. [ ] **Eigenes OSD**
   - Volume/Mute/Mic
   - Caps Lock / Num Lock
6. [ ] **Desktop-Polish**
   - Zen Catppuccin
   - Lock Screen
   - verbleibende visuelle Inkonsistenzen
7. [ ] **Gaming & Home Office**
8. [ ] **Qualität & Wartbarkeit**
   - Logging
   - Clean-Install-Test
   - CI/Pester/TypeScript-Checks
   - Security-Abschlussprüfungen
   - Dokumentation

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
- Browser-Grundkonfiguration
- VS Code
- Logitech G HUB
- komorebi + whkd
- Zebar inklusive TypeScript-/esbuild-Build
- Zebar System-, Audio-, Media-, Netzwerk- und Window-Widgets
- Zebar Workspace- und Layout-Steuerung inklusive Popup/Tooltips
- masir Focus Follows Mouse
- Tiling von normalen und erhöhten/Admin-Fenstern
- Desktop-Autostart
- wöchentliche Wartung
- Desktop-Benachrichtigungen
- PSScriptAnalyzer-Codeprüfung

## Aktueller Desktop-Stand

Die Windows-Desktop-Architektur steht grundsätzlich:

```text
komorebi
   │
   ├── whkd
   │
   └── Zebar
```

Zebar zeigt die fünf Workspaces und die aktuelle Tiling-Methode dynamisch an und ist inzwischen vollständig interaktiv. Workspaces können per Klick gewechselt werden. Die Layout-Pill öffnet ein separates Catppuccin-Popup mit den verfügbaren Tiling-Methoden; Hover zeigt Tooltips, Auswahl wird direkt angewendet und das Popup schließt bei Auswahl oder Fokusverlust.

masir ergänzt komorebi um Focus Follows Mouse wie unter Hyprland. komorebi, whkd und masir werden gemeinsam über den Desktop-Scheduled-Task gestartet. Der Task läuft erhöht, damit auch als Administrator gestartete Anwendungen – beispielsweise Windows Terminal – korrekt in das Tiling-Layout aufgenommen werden.

Das geplante Zielbild lautet:

```text
Windows Desktop
│
├── Window Management
│   ├── komorebi
│   ├── whkd
│   └── masir (Focus Follows Mouse)
│
├── Bar
│   └── Zebar
│
├── Launcher / Search
│   ├── PowerToys Command Palette
│   └── Everything
│
├── Windows Shell Styling
│   └── Windhawk
│       ├── File Explorer Styler
│       ├── Taskbar Styler
│       ├── Start Menu Styler
│       └── Notification Center Styler
│
└── OSD
    └── eigenes Catppuccin OSD
```

## Größte verbleibende Themen

Die aktuelle Priorität liegt bewusst auf der Fertigstellung des Desktop-Erlebnisses:

1. PowerToys Command Palette + Everything
2. Windhawk-basierte Catppuccin-Anpassung der Windows-Shell
3. eigenes Catppuccin-OSD
4. Zen-/Lock-Screen-/Desktop-Polish
5. Gaming- und Homeoffice-Pakete
6. zentrale Logging-Strategie
7. vollständiger Clean-Install-Test auf einem frischen Windows 11
8. CI/Pester/TypeScript-Checks
9. Security-Abschlussprüfungen für BitLocker, Secure Boot und Firewall
10. Dokumentations-Feinschliff

Damit ist der Grundaufbau nicht mehr das Hauptproblem. Der Fokus verschiebt sich jetzt auf einen vollständig bedienbaren, konsistenten und reproduzierbaren Windows-Desktop, der sich funktional und optisch an der Arch-/Hyprland-Umgebung orientiert.

TODOs:

- NanaZip für Zipfiles.
