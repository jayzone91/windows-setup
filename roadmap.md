# Windows Setup Roadmap

> **Zweck dieses Dokuments**
>
> Diese Roadmap ist nicht nur eine Checkliste, sondern die **Arbeits- und Entscheidungsgrundlage für eine KI**, die das Repository weiterentwickelt.
>
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
2. manueller erneuter Setup-/Wartungsdurchlauf
3. automatische regelmäßige Wartung

Das Repository ist die **Source of Truth** für alle sinnvoll versionierbaren Einstellungen.

Für wiederkehrende manuelle Aktionen dient `just` als einheitliche Bedienoberfläche. Das `Justfile` darf dabei keine zweite Setup-Architektur aufbauen, sondern ruft ausschließlich bestehende PowerShell-Einstiegspunkte auf.

---

# 2. Desktop-Zielbild

Die Windows-Umgebung soll funktional und optisch möglichst nah an die vorhandene Arch-/Hyprland-Arbeitsumgebung herankommen, ohne Windows gegen seine Plattform zu verbiegen.

## Vergleich

| Arch / Linux                     | Windows                               |
| -------------------------------- | ------------------------------------- |
| Hyprland                         | komorebi                              |
| Waybar                           | Zebar                                 |
| Focus follows mouse              | masir                                 |
| Fuzzel / Launcher                | Raycast + Everything                  |
| Dolphin                          | OneCommander                          |
| SwayOSD                          | eigenes Catppuccin-OSD                |
| Catppuccin Mocha                 | Catppuccin Mocha                      |
| native Wayland-Tiling-Funktionen | komorebi + whkd                       |
| dotfiles                         | Repository + NTFS-Hardlinks/Junctions |

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
├── Archive Manager
│   └── NanaZip
│
├── Launcher / Search
│   ├── Raycast
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
- [x] Bootstrap wird aus `init.ps1` in einem eigenen PowerShell-Prozess gestartet
- [x] Bootstrap-Prozesse verwenden `ExecutionPolicy Bypass` ausschließlich auf Prozessebene
- [x] Globale Benutzer-/System-Execution-Policy wird nicht verändert
- [x] Execution-Policy-Fix auf dem aktuellen Windows-System erfolgreich getestet
- [x] laufende Anwendungen werden bei wiederholten Läufen nur geschlossen, wenn eine tatsächliche Änderung dies erfordert

## Just / manueller Workflow

- [x] `Justfile` als einheitliche Bedienoberfläche
- [x] `just` als Base-Abhängigkeit über `Casey.Just`
- [x] `just update` startet den vollständigen Bootstrap
- [x] `just update` verwendet `-NoProfile -ExecutionPolicy Bypass`
- [x] `just check` und Bootstrap verwenden denselben zentralen `Test-PowerShellCode`-Workflow; Dateien werden wegen eines PSScriptAnalyzer-`-Recurse`-Crashes einzeln mit `PSScriptAnalyzerSettings.psd1` geprüft
- [x] interne PSScriptAnalyzer-Runtimefehler einzelner Dateien werden einmal in einem frischen `pwsh -NoProfile`-Prozess erneut geprüft
- [x] `just desktop-restart` startet die Desktop-Umgebung kontrolliert neu
- [x] `just ghub-backup` sichert die G-HUB-Konfiguration bewusst ins Repository
- [x] `just ghub-restore` stellt die G-HUB-Konfiguration bewusst wieder her
- [x] `just update` auf dem aktuellen System erfolgreich getestet
- [x] `just check` auf dem aktuellen System erfolgreich getestet
- [x] `just desktop-restart` auf dem aktuellen System erfolgreich getestet
- [x] Das `Justfile` enthält keine eigentliche Setup-Logik
- [x] Neue wiederkehrende manuelle Aktionen dürfen als Recipes ergänzt werden, wenn die Implementierung in PowerShell verbleibt

## Konfigurationsdateien

Projektweite Regel:

- [x] **Dateien werden standardmäßig als NTFS-Hardlinks eingebunden**
- [x] **Verzeichnisse werden als NTFS-Junctions eingebunden**
- [x] Symbolic Links sind ausschließlich als expliziter Kompatibilitäts-Fallback erlaubt, wenn eine Anwendung Hardlinks technisch nicht zuverlässig unterstützt
- [x] VS Code `settings.json` verwendet einen Symbolic Link, da VS Code beim Speichern die Datei ersetzt und dadurch einen NTFS-Hardlink auftrennt
- [x] Windows Terminal `settings.json` verwendet ebenfalls den Symbolic-Link-Kompatibilitätsfallback; ein Hardlink wurde beim Speichern über die Settings-GUI praktisch als ungeeignet bestätigt
- [x] `Set-FileHardLink` zentral als Standard-Helper
- [x] `Set-FileSymbolicLink` zentral als Kompatibilitäts-Helper
- [x] `Set-DirectoryJunction` zentral als Helper

Begründung:

- OneCommander behandelt Hardlinks wie normale Dateien.
- Änderungen auf beiden Seiten wirken sofort auf dieselben Dateidaten.
- Das Repository liegt durch `init.ps1` immer unter dem Benutzerprofil auf `C:`.
- Verzeichnis-Hardlinks existieren unter NTFS nicht; dafür werden Junctions verwendet.
- Hardlinks bleiben der Standard für einzelne Dateien.
- Symbolic Links werden nur verwendet, wenn das Verhalten einer Anwendung praktisch als inkompatibel mit Hardlinks bestätigt wurde.
- VS Code ersetzt `settings.json` beim Speichern und trennt dadurch einen Hardlink auf; ein Symbolic Link bleibt dagegen erhalten und Änderungen landen direkt in der Repository-Datei.
- Windows Terminal trennt einen Hardlink beim Speichern über die Settings-GUI ebenfalls auf. Mit dem Symbolic Link landen GUI-Änderungen direkt in `dotfiles/terminal/settings.json`; ein vollständiger Neustart von Windows Terminal ist erforderlich, damit geänderte Einstellungen zuverlässig neu eingelesen werden.

## Generierte Inhalte und lokaler Zustand

- [x] Generierte Daten gehören nicht zwischen manuell gepflegte Dotfiles
- [x] Generierte Daten liegen unter `.generated/`
- [x] `.generated/` wird nicht committed
- [x] Generator-Code selbst wird committed
- [x] Generierte Inhalte müssen auf einer Neuinstallation reproduzierbar erzeugt werden können
- [x] lokaler Initialisierungsstatus darf unter `.generated/state/` gespeichert werden
- [x] State-Marker werden nicht committed
- [x] State-Marker dürfen einmalige oder bewusst interaktive Schritte bei späteren `just update`-Läufen überspringen
- [x] State-Marker dürfen erst nach erfolgreich abgeschlossener Benutzerinteraktion erzeugt werden

## Theme

- [x] Catppuccin Mocha ist die gemeinsame Designsprache
- [x] Zebar zeigt den Akku der Logitech G502 X Plus über eine lokale PowerShell-Bridge zur G-HUB-WebSocket-API
  - G HUB wird über `ws://127.0.0.1:9010` mit `Origin: file://` abgefragt; der direkte WebSocket-Zugriff aus dem Zebar-WebView wird nicht verwendet
  - Zebar ruft die Bridge über den bereits etablierten `zebar.shellExec`-/PowerShell-Weg auf
  - angezeigt werden Maus-Icon und Akkustand in Prozent; Wireless benötigt kein zusätzliches Statussymbol
  - direkte USB-Verbindung wird zusätzlich mit einem USB-Symbol dargestellt
  - beim Laden wird ein Catppuccin-Yellow-Blitz langsam von unten nach oben gefüllt
  - bei vollständig geladenem Akku wird derselbe Blitz statisch in Catppuccin Green dargestellt
  - der Prozentwert verwendet regulär Catppuccin Text, bei `<= 30 %` Catppuccin Peach und bei von G HUB gemeldetem `criticalLevel` Catppuccin Red
  - fehlende bzw. nicht erreichbare G-HUB-/Mausdaten blenden das Widget aus, statt veraltete Werte anzuzeigen
  - PowerShell-Bridge, Zebar-Build, Wireless-/USB-/Ladeanzeige und `just update` wurden auf dem aktuellen System praktisch getestet
  - `just check` läuft nach der Umsetzung ohne neue relevante PSScriptAnalyzer-Probleme
- [x] Keine künstliche universelle CSS-Datei für alle Programme
- [x] Jedes Programm nutzt seine native bzw. stabilste Theme-Methode
- [x] Funktionalität und Wartbarkeit haben Vorrang vor rein optischem Styling

---

# 4. Phase 1 – Repository, Bootstrap und Projektstruktur

## Bestehende Struktur

- [x] `init.ps1`
- [x] `bootstrap.ps1`
- [x] `Justfile`
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
- [x] Bootstrap in definiertem PowerShell-Prozess starten
- [x] `ExecutionPolicy Bypass` nur für Bootstrap-Prozess verwenden
- [x] PATH der laufenden PowerShell-Session nach Installationen aktualisieren

## Manueller Workflow

- [x] `just update`
- [x] `just check`
- [x] `just desktop-restart`
- [x] `just ghub-backup`
- [x] `just ghub-restore`
- [x] direkter Bootstrap-Fallback dokumentiert
- [x] Just als Base-Paket
- [x] Just-Workflow im README dokumentiert

## Noch offen

- [ ] zentrale Logging-Strategie für komplette Bootstrap-Läufe
- [ ] Log-Dateien mit Datum/Uhrzeit und Ergebnisstatus
- [ ] optionaler `-Verbose`-Modus für detailliertere Diagnose
- [ ] optionaler `-DryRun` / `-WhatIf`-Modus
- [ ] ein maschinenlesbarer Abschlussstatus des Bootstrap-Laufs
- [ ] optional eine Zusammenfassung der Änderungen eines Durchlaufs

### Akzeptanzkriterien

Ein frisches Windows-System soll mit möglichst wenigen manuellen Schritten über `init.ps1` bis zu einer arbeitsfähigen Umgebung gelangen.

Nach der Erstinstallation sollen wiederkehrende manuelle Aktionen über kurze, dokumentierte `just`-Recipes möglich sein.

---

# 5. Phase 2 – Paketverwaltung

## Gemeinsame Paketarchitektur

`config/packages.psd1` bleibt die zentrale deklarative Paketliste. Paketgruppen sind weiterhin fachlich organisiert; die Eigenschaft `Source` entscheidet über den Installationsweg.

Unterstützte Quellen:

- `winget`
- `msstore`
- `chocolatey`
- `scoop`

Für Scoop muss zusätzlich der gewünschte `Bucket` direkt am Paket angegeben werden. Für eigene Buckets kann optional `BucketUrl` hinterlegt werden.

- [x] `Source` als zentraler Dispatcher für mehrere Paketmanager
- [x] Winget-Pakete nur für `Source = winget` oder `Source = msstore` an Winget übergeben
- [x] Chocolatey als generisches Paket-Backend
- [x] Scoop als generisches Paket-Backend
- [x] Chocolatey bei Bedarf automatisch installieren
- [x] Chocolatey bei jedem Bootstrap selbst aktualisieren
- [x] Scoop bei Bedarf automatisch installieren
- [x] Scoop bei jedem Bootstrap selbst und seine Manifeste aktualisieren
- [x] Scoop-Pakete verlangen einen expliziten Bucket
- [x] optionale `BucketUrl` für eigene Scoop-Buckets unterstützen
- [x] benötigte Scoop-Buckets aus allen Paketgruppen ableiten
- [x] automatisches Hinzufügen/Erkennen eines zusätzlichen Scoop-Buckets praktisch mit `versions` + `neovim-nightly` getestet
- [x] Chocolatey-Cache-Cleanup in den Bootstrap integrieren
- [x] Scoop-Download-Cache nur bereinigen, wenn der Cache existiert
- [x] alte Scoop-App-Versionen per Cleanup entfernen
- [x] Paketmanager-Cleanup auch bei Fehlern innerhalb der Paketphase über `finally` ausführen
- [x] Winget-Cache nicht durch inoffizielles Löschen interner Verzeichnisse manipulieren
- [x] Paketkonfiguration in `config/packages.psd1` mit Beispielen und unterstützten Quellen dokumentieren
- [x] `just check` nach dem Paketmanager-Umbau ohne relevante Analyzer-Warnungen
- [x] wiederholter `just update` mit Chocolatey/Scoop ohne erneute Installation der Paketmanager

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
- [x] direkte Winget-Aufrufe außerhalb der Paketgruppen müssen `Source` explizit angeben
- [x] Intel Driver & Support Assistant an die explizite Winget-Source angepasst

## Aktuelle Paketgruppen

### Base

- [x] JetBrainsMono Nerd Font
- [x] Just (`Casey.Just`)

### Tools

- [x] Windows HDR Calibration
- [x] iCloud
- [x] ChatGPT Desktop-App (`9PLM9XGG6VKS`) über Microsoft Store
- [x] Raycast (`9PFXXSHC64H3`) über Microsoft Store
- [x] OpenVPN
- [x] Logitech G HUB
- [x] komorebi
- [x] whkd
- [x] masir
- [x] Zebar
- [x] OneCommander
- [x] **NanaZip**
- [x] PowerToys
- [x] Everything

#### ChatGPT Desktop-App

- [x] neue ChatGPT Desktop-App über den bestehenden generischen `msstore`-Paketworkflow installieren
- [x] Microsoft-Store-ID `9PLM9XGG6VKS` verwenden
- [x] Paketupdates über `Update = $true` verwalten
- [x] ChatGPT Classic (`9NT1R1C2HH7J`) wird bewusst nicht verwendet
- [x] `winget show --id 9PLM9XGG6VKS --exact --source msstore` praktisch verifiziert: Publisher OpenAI, Installer-Typ `msstore`
- [x] Installation über `just update` praktisch erfolgreich getestet
- [x] `just check` nach der Integration erfolgreich getestet
- [x] Anwendung praktisch gestartet und als funktionsfähig bestätigt

### HomeOffice

- [x] Remote Desktop Manager über Winget
- [x] FileZilla Client über Chocolatey
- [x] PCVisit Supporter Modul über eigenen Installationsworkflow
- [x] OpenVPN als vorhandene Abhängigkeit verfügbar

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
- [x] Neovim Nightly über Scoop `versions`
- [x] ripgrep (`rg`)
- [x] eza
- [x] fd
- [x] bat
- [x] fzf
- [x] jq
- [x] zoxide

### Browser

- [x] Zen Browser
- [x] Google Chrome Beta

## NanaZip

Ziel:

- NanaZip als moderner Archivmanager
- möglichst native Windows-11-Integration
- Nutzung für ZIP, 7z und weitere klassische Archivformate
- Installation über Winget
- Standard-App-Konfiguration ohne unsichere Manipulation geschützter `UserChoice`-Einträge

Umgesetzt:

- [x] passende Winget-Paket-ID `M2Team.NanaZip` verifiziert
- [x] NanaZip in `config/packages.psd1` aufgenommen
- [x] Installation im Bootstrap integriert
- [x] Installation über `just update` auf dem aktuellen System getestet
- [x] Update-/Wiederholungspfad über `just update` getestet
- [x] NanaZip-AppX-Paket dynamisch ermitteln
- [x] NanaZip-ProgID dynamisch aus der tatsächlichen Windows-Registrierung ermitteln
- [x] `AppUserModelID` dynamisch ermitteln
- [x] direkte NanaZip-Seite unter **Einstellungen → Apps → Standard-Apps** öffnen
- [x] Fallback auf die allgemeine Standard-App-Seite, wenn keine direkte ID ermittelt werden kann
- [x] Bootstrap wartet, bis das sichtbare Windows-Einstellungsfenster tatsächlich geschlossen wurde
- [x] gehostete `SystemSettings`-Child-Windows bei der Fenstererkennung berücksichtigen
- [x] generischen Default-App-Initialisierungsworkflow statt NanaZip-Sonderlogik verwenden
- [x] lokalen Marker `.generated/state/default-apps/nanazip.initialized` erst nach dem Schließen von Settings erzeugen
- [x] spätere `just update`-Läufe öffnen die Standard-App-Konfiguration nicht erneut, wenn der Marker vorhanden ist
- [x] erneute manuelle Konfiguration durch Löschen des Markers ermöglichen
- [x] PSScriptAnalyzer für die neue File-Association-Logik ohne relevante Warnungen
- [x] zweiter `just update`-Lauf auf dem aktuellen System erfolgreich und ohne erneutes Öffnen der Settings-Seite
- [x] README um NanaZip und den generischen Standard-App-Workflow ergänzt

Bewusste Auswahl:

- NanaZip soll klassische Archivformate übernehmen.
- Windows-Image- und Datenträgerformate wie ISO, VHD/VHDX und WIM sollen nicht pauschal NanaZip zugeordnet werden, da Windows dafür eigene Mount- und Image-Funktionen bereitstellt.
- Die eigentliche Auswahl der Standard-App bleibt eine Benutzerinteraktion, weil Windows benutzerspezifische Standard-App-Zuordnungen schützt.

Noch offen:

- [ ] Kontextmenü-Integration explizit als eigenen Akzeptanztest dokumentieren, falls noch nicht separat geprüft
- [ ] Catppuccin-Anpassung nur verfolgen, falls stabil unterstützt

### Generischer Standard-App-Workflow

Der NanaZip-Workflow ist absichtlich generisch aufgebaut und soll für weitere Programme wiederverwendet werden.

- [x] direkte App-Seite über `ms-settings:defaultapps` verwenden, wenn eine passende Windows-App-ID vorhanden ist
- [x] allgemeine Standard-App-Seite als Fallback verwenden
- [x] Benutzer klar auffordern, die gewünschte Anwendung manuell zu suchen, wenn keine direkte ID ermittelt werden kann
- [x] Bootstrap während der Benutzerinteraktion pausieren
- [x] erst nach tatsächlichem Schließen der Windows-Einstellungen fortfahren
- [x] erfolgreichen Abschluss über lokalen State-Marker merken
- [x] Marker pro Anwendung unter `.generated/state/default-apps/<app>.initialized`
- [x] wiederholte Wartungsläufe störungsarm und ohne erneute Benutzerinteraktion halten

## Noch offen in der Paketlogik

- [ ] Retry-Mechanismus bei temporären Paketmanager-/Download-Fehlern
- [ ] bessere maschinenlesbare Update-Zusammenfassung
- [ ] Paket-Fehler am Ende gesammelt ausgeben statt nur während des Laufs
- [ ] optionale zentrale Paket-Logs
- [x] Scoop-Bucket-Autobereitstellung mit `versions` + `neovim-nightly` praktisch getestet

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
- [x] globale PowerShell Execution Policy nicht verändern
- [x] interne Bootstrap-Skripte über prozesslokale Execution Policy ausführbar halten
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
- [x] BIOS-/Firmware-Update-Konzept für ASUS festgelegt: erkennen und melden, nicht automatisch über den ASUS-Statuspfad installieren
- [ ] Monitor-/Peripherie-Firmware nur automatisieren, wenn zuverlässig möglich

## ASUS / Armoury Crate

Feste Zuständigkeit:

- Intel Driver & Support Assistant bleibt die zuständige Quelle für Intel-Treiber. Der Intel-Autoinstallationspfad bleibt absichtlich auf bereits verifizierte Installationsregeln beschränkt; weitere Intel-Pakete werden erst automatisiert, wenn deren Installationsverhalten verifiziert wurde.
- ASUS-/Mainboard-spezifische Komponenten sowie Drittanbieter-Treiber wie Realtek werden über den offiziellen ASUS-Pfad in Armoury Crate bewertet.
- Intel-Angebote werden im automatischen ASUS-Statuspfad bewusst herausgefiltert und nicht über ASUS installiert.
- Der vorhandene direkte ASUS-`file.idx`-Download-/Installationscode wird nicht zusätzlich in `Install-Drivers` aktiviert. Damit existiert kein konkurrierender zweiter Updatepfad neben Armoury Crate.
- BIOS-/UEFI-/Firmware wird separat erkannt und gemeldet, aber nicht automatisch über den ASUS-Statuspfad installiert oder geflasht.
- Ein offizieller Übergang zu ASUS DriverHub bleibt grundsätzlich zulässig; bei der bisherigen praktischen Prüfung blieb der Workflow jedoch vollständig in Armoury Crate.

Armoury-Crate-Installation und -Updates:

- Armoury Crate wird nicht über die generische `Drivers`-Paketgruppe verwaltet, weil eine von ASUS selbst aktualisierte Installation nicht zuverlässig der Winget-Paket-ID `Asus.ArmouryCrate` zugeordnet wird.
- Bestehende Installationen werden unabhängig von Winget über AppX, Registry, Start-Apps und als letzten Fallback den Armoury-Crate-Service erkannt.
- Wenn Armoury Crate fehlt, bleibt Winget mit `Asus.ArmouryCrate` der ausschließlich vorgesehene Installationsweg. Es gibt bewusst keinen direkten ASUS-Installer-Fallback.
- Scheitert die Winget-Erstinstallation, wird dies als Warnung ausgegeben und der restliche Bootstrap darf weiterlaufen; ein späterer `just update` versucht die Installation erneut.
- Updates der Armoury-Crate-Anwendung selbst werden über deren nativen Update-Mechanismus verwaltet.
- Ein normaler `just update` öffnet die interaktive Armoury-Crate-Oberfläche nicht ungefragt.
- Der normale `just update` wertet den lokal von Armoury Crate / ROG Live Service gepflegten Update-Zustand read-only aus.
- Für Softwarezustände zählt ausschließlich der zuletzt beobachtete vollständige RLS-Komponenten-Snapshot; historische Vor-Update-Snapshots dürfen keine False Positives erzeugen.
- Die Aktualität der ausgewerteten ASUS-/RLS-Daten wird mit Zeitstempel ausgegeben; alte Metadaten werden als möglicherweise veraltet kenntlich gemacht.
- Nicht-Intel-Softwareupdates werden erkannt und gemeldet. Eine automatische Installation wird erst ergänzt, wenn ein offizieller ASUS-/RLS-Installationsweg praktisch verifiziert ist und BIOS/Firmware sicher ausgeschlossen werden kann.

Praktisch festgestellter Upstream-Zustand am 2026-08-10:

- [x] Auf dem aktuellen System ist Armoury Crate `6.5.7.0` bereits installiert.
- [x] `winget list --id Asus.ArmouryCrate --exact` erkennt diese vorhandene Installation nicht.
- [x] Winget bietet aktuell nur Manifest-Version `6.2.11.0` an.
- [x] Die Installation dieses Manifests scheitert aktuell mit `Installer hash does not match`, weil der ASUS-Download nicht mehr zum im Winget-Manifest hinterlegten SHA256 passt.
- [x] Der generische Winget-Paketworkflow ist damit für Armoury Crate als Desired-State-Erkennung ungeeignet.

Praktisch bestätigt:

- [x] AppX-/Registry-Erkennung erkennt die vorhandene Armoury-Crate-Version `6.5.7.0`.
- [x] `just update` versucht bei vorhandener Armoury-Crate-Installation keine erneute Winget-Installation und kein Downgrade.
- [x] Armoury Crate Update Center einschließlich Geräte-/Komponentenbereich auf ASUS-/Drittanbieter-Treiber und Firmware geprüft.
- [x] Intel-Angebote werden im automatischen ASUS-Statuspfad herausgefiltert.
- [x] aktuell keine Realtek-Updates angeboten.
- [x] aktuell keine BIOS-/Firmware-Updates angeboten.
- [x] bei der bisherigen Prüfung keine Weiterleitung zu ASUS DriverHub; der Workflow blieb in Armoury Crate.
- [x] ASUS-RLS-Metadaten und Logs als read-only Quelle für den Update-Status praktisch verifiziert.
- [x] historische Vor-Update-Snapshots als False-Positive-Quelle erkannt und die Auswertung auf den letzten vollständigen Komponenten-Snapshot beschränkt.
- [x] Firmware-Markierungen werden separat erkannt und nicht als Softwareupdate behandelt.
- [x] `just update` meldet auf dem aktuellen Stand korrekt keine Nicht-Intel-ASUS-Softwareupdates.
- [x] `just update` meldet auf dem aktuellen Stand korrekt keine aktive Firmware-Markierung.
- [x] wiederholter `just update` auf störungsarme Wiederholung des Armoury-Crate-/ASUS-Statuspfads getestet.
- [x] finaler `just check` erfolgreich.
- [x] finaler kompletter `just update` erfolgreich.

Offen / zu testen:

- [ ] Verhalten einer Winget-Erstinstallation auf einem System ohne Armoury Crate testen, sobald das Upstream-Manifest wieder funktionsfähig ist.
- [ ] automatische Installation erkannter Nicht-Intel-ASUS-Softwareupdates nur ergänzen, wenn der offizielle ASUS-/RLS-Installationsweg zuverlässig und firmwarefrei angesteuert werden kann.
- [ ] Verhalten bei einem zukünftig tatsächlich angebotenen BIOS-/Firmware-Update erneut praktisch prüfen; weiterhin nur melden, nicht automatisch installieren.
- [ ] Verhalten bei einer zukünftig tatsächlich auftretenden Weiterleitung zu ASUS DriverHub erneut praktisch prüfen.
- [ ] `just asus-updates` als manuellen Armoury-Crate-Einstieg separat praktisch testen und nur beibehalten, wenn er neben dem automatischen read-only Statuscheck weiterhin echten Nutzen hat.

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

## Neovim

### Installation und Konfiguration

- [x] Neovim Nightly über Scoop-Bucket `versions`
- [x] Neovim `0.12.0` oder neuer erzwingen
- [x] extern gepflegtes Repository `jayzone91/nvim` als Git-Submodule unter `external/nvim`
- [x] Submodule auf Branch `main`
- [x] `%LOCALAPPDATA%\nvim` per Junction auf `external/nvim`
- [x] Submodule bei jedem Bootstrap synchronisieren und initialisieren
- [x] externes Neovim-Repository bei jedem Bootstrap per `git pull --ff-only origin main` aktualisieren
- [x] neue Commits des extern verwalteten Submodules durch `ignore = all` nicht als lokale Änderung von `windows-setup` behandeln
- [x] Änderungen am extern verwalteten Neovim-Repository nicht automatisch in die Git-History von `windows-setup` übernehmen

### Lokale Änderungen im Neovim-Submodule

- [x] lokale Änderungen einschließlich untracked Dateien vor dem Pull automatisch stagen
- [x] Bootstrap-Stash mit eindeutiger Nachricht erzeugen
- [x] Stash nach erfolgreichem Pull per `stash pop --index` wiederherstellen
- [x] fehlgeschlagene Stash-Wiederherstellung nicht automatisch zurücksetzen
- [x] bei Stash-Konflikten den Stash erhalten
- [x] bei Stash-Konflikten am Ende des Bootstrap Repository-Pfad, Stash-Referenz, Stash-Commit, Nachricht, ursprünglichen und aktuellen Git-Status sowie Diagnosebefehle ausgeben

### Tree-sitter Toolchain

- [x] `tree-sitter-cli` über Scoop-Bucket `main`
- [x] mindestens `tree-sitter-cli 0.26.1`
- [x] kein npm-Installationsweg für `tree-sitter-cli`
- [x] Zig über Scoop-Bucket `main` als C/C++-Toolchain
- [x] Scoop-Shim `cc` auf `zig cc`
- [x] Scoop-Shim `c++` auf `zig c++`
- [x] `CC=cc` als persistente Benutzer-Umgebungsvariable und im Bootstrap-Prozess
- [x] `CXX=c++` als persistente Benutzer-Umgebungsvariable und im Bootstrap-Prozess
- [x] `CRATE_CC_NO_DEFAULTS=1`, damit `cc-rs` Zig nicht automatisch das inkompatible Target `x86_64-pc-windows-msvc` übergibt
- [x] `tar`, `curl`, `tree-sitter`, `zig`, `cc` und `c++` im Bootstrap prüfen

### Praktisch bestätigt

- [x] `just check` nach der Neovim-Integration fehlerfrei
- [x] vollständiger `just update` nach der Neovim-Integration fehlerfrei
- [x] `external/nvim` auf `main` und aktuell zu `origin/main`
- [x] `cc.exe` wird aus dem Scoop-Shim-Verzeichnis aufgelöst
- [x] Zig/Clang über `cc --version` praktisch verifiziert
- [x] alle in der Neovim-Konfiguration angeforderten Tree-sitter-Parser erfolgreich kompiliert

### Feste Entscheidung

Das Repository `jayzone91/nvim` wird **extern** gepflegt. `windows-setup` stellt lediglich Installation, Aktualisierung, Toolchain und Junction bereit.

Der Gitlink des Submodules gehört zur initialen Repository-Struktur von `windows-setup`. Laufende neue Commits und lokale Änderungen innerhalb von `external/nvim` sollen dagegen nicht als normale Änderungen des Superprojekts auftauchen oder automatisch in dessen Git-History übernommen werden.

Für Tree-sitter unter Windows bleibt Zig die vorgesehene Compiler-Toolchain. Der getestete Pfad verwendet reale `cc`-/`c++`-Scoop-Shims und die Umgebungsvariablen `CC=cc`, `CXX=c++` sowie `CRATE_CC_NO_DEFAULTS=1`. Ein zusätzlicher Visual-Studio-/MSVC-Compiler ist für diesen Workflow nicht erforderlich.

---

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
- [x] `just check` als manueller Einstiegspunkt für PSScriptAnalyzer
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
- [x] `dotfiles/terminal/settings.json` als dauerhafte versionierte Source of Truth
- [x] strukturierte Erstinstallationswerte in `config/terminal.psd1` statt fest verdrahteter Einstellungen im Modul
- [x] Catppuccin-Farben für die initiale Konfiguration aus der zentralen `config/theme.psd1` ableiten
- [x] Terminal-JSON-`$schema` beim Generieren direkt setzen und nicht als konfigurierbaren Wert behandeln
- [x] initiale `settings.json` nur erzeugen, wenn noch keine versionierte Terminal-Konfiguration vorhanden ist
- [x] lokalen Initialisierungsmarker `.generated/state/default-apps/terminal.initialized` verwenden
- [x] eine bereits versionierte `settings.json` bei späteren Bootstrap-Läufen nicht aus den Initialwerten regenerieren oder überschreiben
- [x] Windows-Terminal-`settings.json` per Symbolic Link einbinden; Hardlink-Inkompatibilität beim Speichern über die Settings-GUI praktisch bestätigt
- [x] Änderungen über die Terminal-Settings-GUI landen in `dotfiles/terminal/settings.json`
- [x] GUI-Änderungen bleiben nach vollständigem Neustart von Windows Terminal aktiv

### Feste Entscheidung

`config/terminal.psd1` ist ausschließlich die deklarative Quelle für die **erstmalige Erzeugung** einer Windows-Terminal-Konfiguration. Die Datei enthält verständlich strukturierte Standardwerte, aber keine Kopie der vollständigen `settings.json`.

Das JSON-Schema wird vom Generator direkt gesetzt. Die Catppuccin-Farben werden bei der Ersterzeugung aus `config/theme.psd1` abgeleitet, damit die zentrale Palette maßgeblich bleibt.

Nach der Initialisierung ist ausschließlich `dotfiles/terminal/settings.json` die versionierte Source of Truth. Der Bootstrap darf diese Datei bei späteren Läufen nicht wieder aus `config/terminal.psd1` erzeugen oder Benutzeränderungen überschreiben. Der lokale Marker `.generated/state/default-apps/terminal.initialized` kennzeichnet die abgeschlossene Initialisierung.

Für die produktive Terminal-`settings.json` wird bewusst der projektweite Symbolic-Link-Kompatibilitätsfallback verwendet. Ein NTFS-Hardlink wurde praktisch getestet und verworfen, weil Windows Terminal ihn beim Speichern über die Settings-GUI auftrennt. Mit dem Symbolic Link werden Änderungen aus der GUI direkt im Repository-Dotfile gespeichert und können normal committed werden.

Windows Terminal übernimmt geänderte Einstellungen nicht in jedem Fall vollständig im laufenden Prozess. Nach einer Änderung über die Settings-GUI ist deshalb ein vollständiges Beenden und erneutes Starten von Windows Terminal der dokumentierte Workflow.

## PowerShell

- [x] Profil im Repository
- [x] Profil als Hardlink eingebunden

## CLI-Tools / moderne Shell-Werkzeuge

Ziel ist ein schneller, komfortabler CLI-Workflow ähnlich zur Linux-Arbeitsumgebung. Geeignete moderne CLI-Tools sollen reproduzierbar über die Paketverwaltung installiert und sinnvoll in das PowerShell-Profil integriert werden.

Pflicht / bereits konkret gewünscht:

- [x] `ripgrep` (`rg`) installieren
- [x] `eza` als modernen Ersatz für klassische Verzeichnisauflistung installieren
- [x] Fish-artige PowerShell-Abbreviation für `ls` auf `eza --icons --group-directories-first` umstellen
- [x] `ls`, `ll`, `la` und `lt` als interaktive PSReadLine-Abbreviations mit sinnvollen `eza`-Defaults definieren

Weitere Kandidaten prüfen und bei echtem Nutzen integrieren:

- [x] `fd` als schnellere Dateisuche
- [x] `bat` als moderner Datei-Viewer
- [x] `fzf` für fuzzy selection
- [x] `jq` für JSON-Verarbeitung
- [x] `zoxide` für schnelles Verzeichnis-Navigieren
- [ ] weitere geeignete CLI-Tools anhand des tatsächlichen Workflows inventarisieren

Integration:

- [x] Fish-artige PSReadLine-Abbreviations für CLI- und Git-Kommandos im versionierten PowerShell-Profil hinterlegen
- [x] Abbreviations expandieren interaktiv über PSReadLine und verändern keine globalen Befehle für Skripte
- [x] Abbreviation-Expansion in interaktiver PowerShell praktisch getestet
- [x] `zoxide init powershell` im Profil integrieren
- [x] Fish-`shellAbbrs` für `ls`, `ll`, `la`, `lt`, `cat`, `grep`, `find`, Verzeichnisnavigation und Git-Kommandos nach PowerShell übertragen
- [x] Abbreviations beim Drücken von Space oder Enter sichtbar expandieren
- [x] Git-Repository-Root für projektspezifische Commands ermitteln
- [x] dynamisches Modul `WindowsSetupProjectCommands` nur innerhalb von `~/windows-setup` laden
- [x] `update` → `just update`
- [x] `check` → `just check`
- [x] `desktop-restart` → `just desktop-restart`
- [x] Projektcommands beim Verlassen des Repositories wieder vollständig entfernen
- [x] dynamische Projektcommands mit `zoxide`-Verzeichniswechsel praktisch getestet
- [ ] prüfen, welche Tools auch sinnvoll in Nushell eingebunden werden sollen
- [x] CLI-Installation und Wiederholung über `just update` getestet
- [ ] `just check` nach Profilanpassungen ausführen

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
- [x] aktives Zen-Profil über die Installationszuordnung ermitteln
- [x] vorhandene Mods vor dem Schließen über `zen-themes.json` prüfen
- [x] nur tatsächlich fehlende Mods an Marionette übergeben
- [x] Zen bei vollständig vorhandenen Mods geöffnet lassen
- [x] Zen nur bei erforderlicher Mod-Konfiguration schließen und danach normal neu starten
- [ ] Browser-UI weiter an Catppuccin Mocha anpassen
- [ ] stabile eigene CSS-Anpassungen versionieren

### Akzeptanzkriterien für Zen-Mods

- Ein normaler `just update` schließt Zen nicht, wenn alle konfigurierten Mods bereits vorhanden sind.
- Fehlt ein Mod, wird nur der fehlende Mod über Marionette installiert.
- Die lokale Vorprüfung verwendet das tatsächlich aktive Zen-Profil und nicht lediglich den `Default=1`-Eintrag aus `profiles.ini`.

---

# 17. Phase 14 – Logitech G HUB

- [x] Installation
- [x] Updates
- [x] `settings.db` im Repository
- [x] einmalige Initialisierung auf einem neuen System
- [x] Marker für bereits initialisierte Systeme
- [x] nach der Erstinitialisierung keine automatische Datenbank-Synchronisierung im normalen Bootstrap
- [x] `just ghub-backup` für eine bewusste Sicherung ins Repository
- [x] `just ghub-restore` für eine bewusste Wiederherstellung
- [x] G HUB für Initialisierung, Backup oder Restore kontrolliert beenden
- [x] G HUB danach wieder starten
- [x] Git erkennt bewusst gesicherte Änderungen für spätere manuelle Commits
- [x] G HUB bei normalen `just update`-Läufen geöffnet lassen

## Feste Entscheidung

`settings.db` wird **nicht** per Hardlink oder Symbolic Link mit dem Repository verbunden.

Grund:

- G HUB verändert die SQLite-Datenbank laufend, auch ohne bewusste Konfigurationsänderung.
- Ein Dateihash ist deshalb kein sinnvoller Desired-State-Indikator.
- Die Datenbank wird als bewusster Snapshot behandelt.
- Der Bootstrap stellt sie auf einem neuen System einmalig wieder her; spätere Sicherungen erfolgen nur explizit.

### Akzeptanzkriterien

- Auf einem bereits initialisierten System darf `just update` G HUB nicht schließen.
- `just ghub-backup` und `just ghub-restore` dürfen G HUB kontrolliert schließen und anschließend wieder starten.

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

## whkd App-Shortcuts

- [x] Win + B startet Zen Browser
- [x] Win + T startet Windows Terminal
- [x] Win + Shift + T startet Windows Terminal über UAC erhöht
- [x] alle drei App-Shortcuts auf dem aktuellen System praktisch testen

## Anwendungsregeln / Floating-Verhalten

### iCloud Passwords

- [x] iCloud Passwords (`iCloudPasswords.exe`) grundsätzlich vom Tiling ausschließen
- [x] Ignore-Regel reproduzierbar in `dotfiles/komorebi/applications.json` hinterlegen
- [x] stabilen Match über `Exe = iCloudPasswords.exe` mit `matching_strategy = Equals` verwenden; lokalisierten Fenstertitel nicht als dauerhaften Identifier verwenden
- [x] iCloud Passwords behält normales Windows-Fensterverhalten und bleibt frei beweglich/resizbar
- [x] Bedienbarkeit der App nach dem Ausschluss praktisch bestätigt
- [x] `just check` und `just update` mit der Regel erfolgreich ausgeführt

- [ ] Microsoft Kurznotizen / Sticky Notes grundsätzlich vom Tiling ausschließen
- [ ] für Kurznotizen normales Windows-Fensterverhalten verwenden
- [ ] Regel reproduzierbar in der vorgesehenen komorebi-Anwendungskonfiguration hinterlegen
- [ ] prüfen, dass mehrere Kurznotiz-Fenster nicht versehentlich getiled oder gestackt werden
- [ ] Verhalten nach Neustart von komorebi erneut testen

## Bootstrap / Desktop-Neustart

- [x] fehlerhafte Zebar-Z-Order nach wiederholten Bootstrap-Läufen reproduziert
- [x] entschieden, komorebi und Zebar am Ende des Bootstrap kontrolliert neu zu starten
- [x] zentralen `Stop-WindowsDesktopEnvironment`-Workflow implementiert
- [x] zentralen `Start-WindowsDesktopEnvironment`-Workflow implementiert
- [x] zentralen `Restart-WindowsDesktopEnvironment`-Workflow implementiert
- [x] Zebar zuerst beenden
- [x] komorebi/whkd/masir anschließend kontrolliert beenden
- [x] komorebi mit `--whkd --masir` starten
- [x] auf komorebi/whkd warten
- [x] Zebar erst danach starten
- [x] zwei getrennte Scheduled Tasks beibehalten
- [x] komorebi-Task erhöht ausführen
- [x] Zebar-Task nicht erhöht ausführen
- [x] Neustartlogik idempotent gestalten und doppelte Instanzen vermeiden
- [x] `just desktop-restart` als manuellen Einstiegspunkt ergänzen
- [x] Desktop-Neustart am Ende von `bootstrap.ps1` ausführen
- [x] `just update` mit der neuen Reihenfolge erfolgreich getestet
- [x] normale Fenster liegen nach dem Bootstrap nicht mehr über bzw. falsch relativ zur Zebar
- [x] Fenster bleiben nach dem Bootstrap normal bedienbar

### Akzeptanzkriterien für Desktop-Stabilität

- Microsoft Kurznotizen werden nicht getiled.
- Nach `just update` funktioniert die komorebi-/Zebar-Erkennung ohne manuelle Nacharbeit.
- Normale Fenster landen nicht hinter Zebar.
- Fenster lassen sich nach dem Bootstrap weiterhin normal verschieben und schließen.
- Es laufen jeweils nur die erwarteten komorebi-/Zebar-Instanzen.

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
- [x] Start über `komorebic start --whkd --masir`
- [x] Stop über `komorebic stop --whkd --masir`
- [x] kontrollierter Desktop-Neustart praktisch getestet

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
- [x] separater nicht erhöhter Scheduled Task
- [x] zentraler Desktop-Restart
- [x] Start erst nach komorebi/whkd
- [x] korrekte Z-Order nach `just update` praktisch getestet

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

## Vollbild-Verhalten

- [ ] Zebar darf nicht über echten Vollbild-Anwendungen liegen
- [ ] YouTube-/Browser-Vollbild darf nicht von Zebar überlagert werden
- [ ] Spiele und andere Fullscreen-Anwendungen dürfen nicht von Zebar überlagert werden
- [ ] prüfen, ob echtes Fullscreen und Borderless Fullscreen unterschiedlich behandelt werden müssen
- [ ] Zebar nach Verlassen des Vollbildmodus zuverlässig wieder anzeigen
- [ ] normale maximierte Fenster dürfen Zebar nicht versehentlich ausblenden
- [ ] kein sichtbares Flackern oder unnötiger Prozess-Neustart beim Wechsel in oder aus Vollbild
- [ ] Lösung möglichst ohne anwendungsspezifische Sonderregeln umsetzen

### Akzeptanzkriterien für Vollbild

- Bei echtem Vollbild ist Zebar vollständig unsichtbar.
- Nach Verlassen des Vollbildmodus erscheint Zebar automatisch wieder.
- Normale maximierte Fenster blenden Zebar nicht aus.
- Verhalten funktioniert mindestens mit Browser-/YouTube-Vollbild und einer typischen Fullscreen-Anwendung.

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

## Desired-State / störungsarme Wiederholung

- [x] vollständigen OneCommander-Desired-State vor dem Beenden prüfen
- [x] verwaltete OneCommander-Settings prüfen
- [x] Theme-Junction prüfen
- [x] Folder-Icon-Junction prüfen
- [x] Main-Folder-Icon per SHA256 prüfen
- [x] generiertes File-Icon-Pack und `_manifest.json` prüfen
- [x] File-Icon-Junction prüfen
- [x] Registry-Integration für Directory/Drive/Win+E prüfen
- [x] OneCommander bei vollständig aktuellem Zustand geöffnet lassen
- [x] OneCommander nur bei tatsächlichem Drift schließen und danach neu starten
- [x] Verhalten auf dem aktuellen System praktisch getestet

### Akzeptanzkriterium für wiederholte Bootstrap-Läufe

Ein normaler `just update` darf OneCommander nicht schließen, wenn der verwaltete Zustand bereits vollständig korrekt ist.

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

- [x] Taskbar Styler
- [x] Start Menu Styler
- [x] Notification Center Styler
  - integriertes `Matter`-Theme als Basis
  - Matter-Layout und -Geometrie bleiben unverändert; angepasst werden nur Farben
  - Catppuccin-Mocha-Flächen verwenden dezente `surface1`-/`surface2`-Töne statt Mauve als große Flächenfarbe
  - Mauve bleibt für kleine Highlights und Borders reserviert
  - Konfiguration deklarativ in `config/windhawk.psd1` und reproduzierbar über den bestehenden Windhawk-CLI-Workflow
  - Installation, `just check`, `just update` und optische Sichtprüfung auf dem aktuellen System erfolgreich getestet
- [x] alle drei optisch an Catppuccin Mocha anpassen
- [x] bisherige Konfiguration reproduzierbar über Windhawk CLI
- [x] keine manuelle Mod-Konfiguration, wenn CLI-Automatisierung möglich ist
- [ ] Änderungen auf weiteren Windows-/Windhawk-Versionen testen

---

## Windows-Shell-Personalisierung

- [x] `config/windows.psd1` als deklarativen Desired State für verwaltete Taskleisten-/Start-Schalter angelegt
- [x] Taskleisten-Autohide durch gezieltes Setzen von Bit `0x01` in `StuckRects3\Settings[8]` umgesetzt
- [x] übrige Bits und der restliche `StuckRects3`-Blob bleiben unangetastet
- [x] Zuletzt hinzugefügte Apps deaktiviert
- [x] zuletzt verwendete/empfohlene Dateien und Sprunglisten deaktiviert
- [x] Tipps, Verknüpfungen und App-Empfehlungen deaktiviert
- [x] meistverwendete Apps aktiviert
- [x] Windows-Shell-Desired-State über `just update` praktisch getestet
- [x] wiederholten `just update` auf Idempotenz geprüft

---
## Windhawk Desired State

- [x] `config/windhawk.psd1` als deklarative Mod-Liste vorgesehen
- [x] Mod-Installation und Aktivierung generisch über `modules/Windhawk.ps1`
- [x] Windhawk-CLI-2.x-JSON-Envelope bei installierten Mods berücksichtigen
- [x] generische Übersetzung verschachtelter Settings in Flat-Storage-Keys
- [x] Windows 11 Taskbar Styler als erster deklarativer Mod
- [x] RosePine als gewünschtes Basis-Theme hinterlegt
- [x] Taskbar Styler über `just update` auf dem aktuellen System installiert
- [x] RosePine praktisch verifiziert
- [x] wiederholten `just update` mit installiertem Taskbar Styler erfolgreich getestet
- [x] Catppuccin-Mocha-Farboverrides für RosePine definiert
- [x] Catppuccin-Mocha-Farboverrides auf dem aktuellen System praktisch getestet
- [x] Windows 11 Start Menu Styler als zweiten deklarativen Mod ergänzt
- [x] RosePine als Layout-Basis für das Startmenü verwendet
- [x] Catppuccin-Mocha-Farboverrides für Startmenü und Suchansicht definiert
- [x] Startmenü-Außenrahmen auf `Surface1 #45475a` abgestimmt
- [x] Suchansicht-Außenrahmen auf `Surface1 #45475a` abgestimmt
- [x] fokussiertes Suchfeld mit `Mauve #cba6f7` als Akzent beibehalten
- [x] normales Startmenü und Suchansicht optisch praktisch verifiziert
- [x] wiederholten `just update` mit installiertem Start Menu Styler erfolgreich getestet
- [x] `Taskbar auto-hide speed` als deklarativen Windhawk-Mod ergänzt
  - Ein- und Ausblendanimation jeweils auf `250 %` Speedup gesetzt
  - `90 FPS` als konfigurierte Animations-Framerate
  - Windows-11-Standardtaskbar verwendet; Legacy-/ExplorerPatcher-Pfad bleibt deaktiviert
  - Installation und Verhalten auf dem aktuellen System praktisch getestet
- [x] `Lock Keys Notifier` als deklarativen Windhawk-Mod ergänzt
  - Benachrichtigungen für Caps Lock, Num Lock und Scroll Lock aktiviert
  - Insert-Benachrichtigung bleibt deaktiviert
  - `Pill`-Layout als Basis verwendet
  - Catppuccin-Mocha-Farben direkt über die nativen Mod-Settings gesetzt
  - `Base #1e1e2e` als Hintergrund und `Text #cdd6f4` als Schriftfarbe
  - `Mauve #cba6f7` nur als dünne Border, nicht als große Flächenfarbe
  - `Green #a6e3a1` als ON-Akzent für Lock-Key-Zustände
  - Installation, `just check`, `just update` und optische Sichtprüfung auf dem aktuellen System erfolgreich getestet
  - dient aktuell als Lock-Key-OSD; ein späteres gemeinsames OSD für Volume, Mute, Brightness, Media und Lock Keys bleibt als eigener Roadmap-Punkt bestehen
- [ ] Settings-Drift vor dem Schreiben erkennen und unveränderte Mod-Settings unangetastet lassen

### Zentrale Catppuccin-Palette

- [x] `config/theme.psd1` als zentrale Catppuccin-Mocha-Palette angelegt
- [x] gemeinsame Desktop-Hauptfläche auf Catppuccin Base `#1e1e2e` festgelegt
- [x] Windows Terminal auf Base `#1e1e2e` ohne Acrylic/Transparenz umgestellt
- [x] Zebar-Hauptflächen auf Base `#1e1e2e` umgestellt
- [x] Windhawk Taskbar-Styler-Hauptflächen auf Base `#1e1e2e` umgestellt
- [x] Terminal, Zebar und Taskbar optisch gemeinsam geprüft
- [ ] Zebar-Palette zukünftig aus `config/theme.psd1` generieren statt CSS-Farbwerte separat zu pflegen
- [ ] Windhawk-Farbwerte zukünftig semantisch aus `config/theme.psd1` auflösen statt Hex-Werte in Mod-Settings zu duplizieren
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

## Entscheidung

Raycast ersetzt die PowerToys Command Palette als primären Launcher.

Gründe:

- Raycast bietet den gewünschten keyboard-first Workflow näher am Linux-/Fuzzel-Zielbild.
- `Win + Space` kann direkt als globaler Raycast-Hotkey verwendet werden.
- Extensions, Themes und relevante Launcher-Einstellungen lassen sich über Raycasts eigenes Export-/Importformat reproduzierbar sichern und wiederherstellen.
- Die PowerToys Command Palette bleibt deaktiviert und wird nicht erneut als primärer Launcher verfolgt.
- PowerToys selbst bleibt für die weiterhin genutzten Module wie Advanced Paste, File Locksmith, Find My Mouse und PowerRename installiert.
- Everything bleibt als eigenständiger Dienst/Index installiert und wird über die Raycast-Extension `everything-search` verwendet.
- Der frühere Everything-Provider speziell für die PowerToys Command Palette (`lin-ycv.EverythingCmdPal`) wird nicht mehr verwaltet.

## Raycast Installation

- [x] Raycast über den bestehenden generischen `msstore`-Paketworkflow installieren
- [x] Microsoft-Store-ID `9PFXXSHC64H3` verwenden
- [x] Paketupdates über `Update = $true` verwalten
- [x] `winget show --id 9PFXXSHC64H3 --exact --source msstore` praktisch verifiziert
- [x] Installation über `just update` praktisch erfolgreich getestet
- [x] wiederholter `just update` prüft Raycast regulär auf Updates

## Launcher-Hotkey und PowerToys-Abgrenzung

- [x] Raycast als primären Launcher verwenden
- [x] globalen Raycast-Hotkey auf `Win + Space` setzen
- [x] PowerToys Command Palette deaktivieren (`CmdPal = $false`)
- [x] PowerToys Run deaktiviert lassen
- [x] `Alt + Space` nicht mehr als Launcher-Hotkey verwenden
- [x] PowerToys Command Palette nach Deaktivierung praktisch nicht mehr aktiv
- [x] PowerToys weiterhin für Advanced Paste, File Locksmith, Find My Mouse und PowerRename verwenden

## Raycast Desired State

Versionierter, generischer Desired State:

```text
dotfiles/raycast/config.json
```

Lokale Transportkonfiguration:

```text
config/raycast.psd1
```

- [x] `config/raycast.psd1` enthält ein frei änderbares `ExportPassword`
- [x] `config/raycast.psd1` enthält den frei wählbaren Raycast-Backup-Pfad als `BackupPath`
- [x] `BackupPath` wird explizit aus der Konfiguration gelesen; der Workflow verlässt sich nicht auf `SpecialFolder::MyDocuments`
- [x] Umgebungsvariablen wie `%USERPROFILE%` im Backup-Pfad werden unterstützt
- [x] `ExportPassword` ist bewusst ein generisches lokales Transportpasswort und kein Repository-Secret
- [x] der versionierte Desired State enthält ausschließlich eine Allowlist reproduzierbarer, nicht sensibler Einstellungen
- [x] General-Settings nur gezielt übernehmen, darunter `globalHotkey`, Theme, Fensterverhalten, `navigationBindings` und `pageNavigationKeys`
- [x] vollständige benutzerdefinierte Themes übernehmen
- [x] Store-Extensions dynamisch anhand ihrer UUID übernehmen
- [x] Extension-Versionen nicht pinnen bzw. nicht im Desired State versionieren
- [x] Node-Extension-Settings nur als `id` + `enabled` übernehmen
- [x] Command-Settings nur für die tatsächlich versionierten Store-Extensions übernehmen
- [x] interne Raycast-Commands wie Clipboard History nicht in den Desired State übernehmen
- [x] AI-Daten, Clipboard History, Notes, MCP-Server, Quicklinks, Snippets, User Activity und andere persönliche Laufzeitdaten nicht versionieren
- [x] bekannte Credential-/Secret-Felder zusätzlich durch den Sanitizer hart ablehnen

## Raycast Export-/Importformat

Die aktuelle Raycast-Windows-Implementierung wurde für den benötigten Konfigurationsworkflow praktisch analysiert und verifiziert.

- [x] äußeres `.rayconfig` ist GZip-komprimiertes JSON
- [x] Schema-Version 2 verwenden
- [x] Nutzdaten vor der Verschlüsselung mit GZip komprimieren
- [x] Schlüssel mit `scrypt(password, salt, 32)` ableiten
- [x] AES-256-GCM verwenden
- [x] zufällige 16-Byte-Werte für Salt und IV verwenden
- [x] `salt`, `iv`, `authTag` und `data` als Hex speichern
- [x] lokales Importarchiv reproduzierbar aus `dotfiles/raycast/config.json` erzeugen
- [x] aktuelle lokale `.rayconfig` reproduzierbar entschlüsseln und sanitizen
- [x] Node.js aus dem System verwenden; Raycasts gebündeltes Node dient als Fallback

## Erstinitialisierung und lokales Archivmodell

Feste Annahme dieses Projekts: Das vollständige Raycast-`.rayconfig`-Archiv liegt lokal. Eine spätere externe Synchronisierung oder Weitergabe dieses Archivs liegt außerhalb des Verantwortungsbereichs dieses Setups.

- [x] Benutzer bei der Erstinitialisierung darauf hinweisen, dass vollständige Raycast-Backups persönliche und sensible Daten enthalten können
- [x] Benutzer muss das lokale Archivmodell ausdrücklich bestätigen
- [x] lokalen Initialisierungsmarker unter `.generated/state/default-apps/raycast.initialized` verwenden
- [x] Marker erst nach erfolgreich bestätigter Initialisierung erzeugen
- [x] vorhandenes lokales Backup bei bereits eingerichteter Raycast-Installation übernehmen und sanitizen
- [x] auf einem frischen System ohne lokales Backup einmalig ein lokales `.generated/raycast/raycast-import.rayconfig` erzeugen
- [x] Benutzer beim initialen Raycast-Import sowie bei der Einrichtung von Daily Backup, Backup Location und Auto-Delete führen
- [x] `.rayconfig` niemals ins Repository übernehmen
- [x] nach erfolgreicher Initialisierung bei normalen `just update`-Läufen kein neues Restore-Archiv erzeugen
- [x] nach erfolgreicher Initialisierung ausschließlich das neueste lokale Backup sanitizen und den Desired State bei relevanter Änderung aktualisieren

## Theme

- [x] Catppuccin Mocha als benutzerdefiniertes Raycast-Theme verwenden
- [x] vollständigen Theme-Datensatz im Desired State versionieren
- [x] Dark Appearance mit dem Catppuccin-Mocha-Theme verwenden
- [x] Theme über Raycasts nativen Import-/Exportweg wiederherstellen

## Extensions

Aktuell im Desired State enthalten:

- [x] Everything Search
- [x] Visual Studio Code
- [x] ChatGPT
- [x] Google Search
- [x] Shell
- [x] Zen Browser
- [x] Lucide Icons Search

Die Extension-Liste ist absichtlich dynamisch. Weitere installierte Store-Extensions, beispielsweise eine spätere GitHub-Extension, werden bei einem späteren erfolgreichen Export automatisch in den generischen Desired State übernommen.

## Everything

- [x] Everything installieren
- [x] Everything-Index / Service auf dem aktuellen System funktionsfähig
- [x] Everything über die Raycast-Extension `everything-search` integrieren
- [x] CmdPal-spezifischen Everything-Provider aus der Paketverwaltung entfernen
- [x] schnelle Datei-/Ordnersuche über Raycast + Everything verwenden

## Praktisch bestätigt

- [x] `just check` nach der Raycast-Integration erfolgreich; keine neuen PSScriptAnalyzer-Probleme
- [x] vollständiger `just update` mit Raycast-Initialisierung erfolgreich
- [x] lokaler Marker `.generated/state/default-apps/raycast.initialized` erfolgreich erzeugt
- [x] vollständiges lokales Backup erfolgreich entschlüsselt und als generischer Desired State sanitiziert
- [x] keine `.rayconfig` und keine Secrets im Repository-Status
- [x] wiederholter `just update` erfolgreich
- [x] wiederholter Lauf erkennt `[OK] Raycast wurde bereits initialisiert.`
- [x] wiederholter Lauf erkennt `[OK] Raycast Desired State unverändert.`
- [x] bei unverändertem Zustand keine erneute Benutzerinteraktion und kein neues Restore-Archiv

### Akzeptanzkriterien

- `Win + Space` öffnet Raycast als primären Launcher.
- PowerToys Command Palette bleibt deaktiviert.
- Everything-Suche ist über Raycast verfügbar.
- Catppuccin Mocha und die versionierten Raycast-Einstellungen lassen sich auf einem neuen System aus dem Desired State wiederherstellen.
- vollständige persönliche Raycast-Backups bleiben lokal und werden nicht committed.
- wiederholte `just update`-Läufe bleiben ohne unnötige Benutzerinteraktion und ohne erneutes Restore-Artefakt idempotent.

---
# 25. Phase 22 – Home Office

Diese Phase ist als eigener Bereich umgesetzt und wird nicht mit allgemeinen Tools oder Development vermischt.

## Ziel

Alle für Firmenzugriff/Home Office benötigten Programme werden reproduzierbar installiert. Die eigentlichen RDP-, VPN-, FTP-/SFTP- und sonstigen Zieldefinitionen liegen nicht im öffentlichen Repository, sondern werden zentral über die Datenbank von Remote Desktop Manager bereitgestellt.

## Paketgruppe

- [x] eigene Paketgruppe `HomeOffice`
- [x] Home-Office-Paketgruppe im Bootstrap separat aufrufen
- [x] wiederholte Installation über `just update` erfolgreich getestet

## Remote Desktop Manager

- [x] Remote Desktop Manager installieren
- [x] Winget-Paket `Devolutions.RemoteDesktopManager`
- [x] Update-Verhalten über den generischen Paketworkflow getestet
- [x] RDM als zentrale Quelle für RDP-, VPN-, FTP-/SFTP- und weitere Verbindungsziele verwenden
- [x] keine Verbindungsziele oder Credentials im öffentlichen Repository speichern
- [x] vorhandene RDM-Datenbank wird außerhalb dieses Setups verbunden

## FileZilla

- [x] FileZilla Client installieren
- [x] Winget als Quelle verworfen, da das Paket in der aktuellen Winget-Quelle nicht verfügbar ist
- [x] FileZilla über Chocolatey installieren
- [x] Installation über `just update` praktisch getestet
- [x] wiederholter Lauf führt nur die Chocolatey-Update-Prüfung aus
- [x] FTP-Nutzung über Remote Desktop Manager getestet
- [x] FileZilla vollständig von komorebi ignorieren
- [x] FileZilla kann von RDM in einen Tab eingebettet werden, ohne einen verwaisten Tiling-Slot zurückzulassen

## PCVisit Supporter Modul

- [x] PCVisit **Supporter Modul** als Pflichtbestandteil festgelegt
- [x] normales PCVisit-Kundenmodul ausdrücklich nicht verwenden
- [x] vorhandene Installation erkennen
- [x] offizielles Supporter-Setup nur installieren, wenn das Modul fehlt
- [x] PCVisit-eigene automatische Update-Funktion verwenden
- [x] keine zusätzliche Versions-/Update-Logik im Bootstrap
- [x] Installation/Erkennung im Bootstrap praktisch getestet

## OpenVPN und Verbindungsdaten

- [x] OpenVPN ist bereits als benötigter Client installiert und versionsgepinnt
- [x] keine eigene VPN-Profilverwaltung im Repository erforderlich
- [x] keine Trennung von Firmen-/Privatprofilen durch dieses Setup erforderlich
- [x] keine eigene Zertifikatsverwaltung durch dieses Setup erforderlich
- [x] keine RDM-/FileZilla-Verbindungsdaten im Repository erforderlich
- [x] Secrets bleiben vollständig außerhalb des öffentlichen Repositories

Begründung:

Remote Desktop Manager verwendet eine externe Datenbank als zentrale Quelle der Verbindungsdefinitionen. Sobald RDM mit dieser Datenbank verbunden ist und die benötigten Clients wie OpenVPN und FileZilla installiert sind, stehen die gepflegten VPN-, FTP-/SFTP- und RDP-Ziele zur Verfügung.

## Weitere Firmen-/Homeoffice-Tools

- [x] Remote Desktop Manager
- [x] FileZilla
- [x] PCVisit Supporter Modul
- [ ] Agfeo Dashboard / Softphone nur ergänzen, falls es für dieses Windows-Setup tatsächlich benötigt wird
- [ ] sonstige interne Tools nur ergänzen, wenn ein konkreter Bedarf entsteht

## Akzeptanzkriterien

- [x] Remote Desktop Manager ist nach einem Bootstrap-Lauf verfügbar
- [x] FileZilla ist nach einem Bootstrap-Lauf verfügbar
- [x] PCVisit Supporter Modul ist vorhanden bzw. wird bei Bedarf installiert
- [x] OpenVPN ist verfügbar
- [x] RDM kann FileZilla für FTP-Verbindungen starten und in einen Tab einbetten
- [x] komorebi hinterlässt dabei keinen leeren Tiling-Slot
- [x] wiederholter `just update` verursacht keine unerwartete Neuinstallation
- [x] sensible Verbindungsdaten bleiben außerhalb des Repositories

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
- [x] `-NoProfile -ExecutionPolicy Bypass`
- [x] Repository aktualisieren, wenn Working Tree sauber
- [x] Pakete prüfen
- [x] Windows Updates
- [x] Treiber
- [x] G HUB auf neuen Systemen einmalig initialisieren
- [x] bereits initialisiertes G HUB bei normalen Wartungsläufen unangetastet lassen
- [x] Konfiguration erneut anwenden
- [x] bereits initialisierte Standard-App-Konfigurationen über `.generated/state/default-apps/` erkennen und überspringen
- [x] Zen-Mods vor möglichem Browser-Neustart lokal prüfen
- [x] Zebar Build
- [x] OneCommander-Desired-State vor möglichem Neustart prüfen
- [x] initialisiertes Raycast ohne erneuten Restore behandeln und aktuellen lokalen Export in den generischen Desired State sanitizen
- [x] Desktop-Environment am Ende definiert neu starten
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

- [x] Raycast mit Catppuccin-Mocha-Theme
- [x] Windhawk Taskbar
- [x] Windhawk Start Menu
- [x] Windhawk Notification Center
- [ ] eigenes OSD
- [ ] Browser-Feinschliff
- [ ] weitere Anwendungen nur themen, wenn die Anpassung stabil und wartbar ist

---

# 30. Phase 27 – Dokumentation

## README

Das README soll den **aktuellen produktiven Stand** erklären.

- [x] Installationsweg
- [x] Bootstrap-Grundidee
- [x] Execution-Policy-Verhalten
- [x] Just-Workflow
- [x] `just update`
- [x] `just check`
- [x] `just desktop-restart`
- [x] `just ghub-backup`
- [x] `just ghub-restore`
- [x] störungsarme Zen-Mod-Prüfung dokumentiert
- [x] OneCommander-Desired-State-Prüfung dokumentiert
- [x] G-HUB-Initialisierung/Backup/Restore dokumentiert
- [x] Desktop-Neustart-Architektur dokumentiert
- [x] Desktop-Zielbild
- [x] komorebi
- [x] masir
- [x] Zebar
- [x] OneCommander
- [x] NanaZip
- [x] Raycast als primärer Launcher inklusive Desired-State-/Backup-/Restore-Workflow
- [x] generischer Standard-App-Initialisierungsworkflow
- [x] lokale State-Marker unter `.generated/state/default-apps/`
- [x] Hardlinks/Junctions
- [x] Windows-Terminal-Desired-State, Initialisierung und Symlink-Fallback dokumentiert
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
- [x] Just-Workflow
- [x] Execution-Policy-Architektur
- [x] Desktop-Neustart-Architektur
- [x] Zen-Mod-Precheck
- [x] OneCommander-Desired-State-Precheck
- [x] G-HUB-Snapshot-Strategie
- [x] Standard-App-Initialisierungsstrategie
- [x] NanaZip-Default-App-Workflow
- [x] Raycast ersetzt PowerToys Command Palette als primären Launcher; Desired-State-/Initialisierungsstrategie dokumentiert
- [x] Markdown-Ausgaberegel für vollständig kopierbare Dateien
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
- [x] Setup-Logik in das `Justfile` verschieben
  - `Justfile` ist ausschließlich Bedienoberfläche
  - PowerShell bleibt die Implementierungsebene
- [x] globale Execution Policy für Benutzer oder System dauerhaft lockern
  - prozesslokales `ExecutionPolicy Bypass` ist der definierte Weg
- [x] aggressive pauschale Windows-Service-/Debloat-Tweaks
  - Stabilität und benötigte Funktionen haben Vorrang
- [x] automatische Git-Commits/Pushes
  - Änderungen sollen nur gemeldet werden
- [x] automatischer Neustart nach Updates
  - Neustart wird nur gemeldet
- [x] G-HUB-`settings.db` bei jedem Bootstrap per Hash automatisch synchronisieren
  - G HUB verändert die SQLite-Datenbank laufend
  - Hash-Unterschiede bilden keinen sinnvollen Konfigurations-Drift ab
  - Initialisierung + bewusstes Backup/Restore ist der definierte Weg
- [x] G-HUB-`settings.db` per Hardlink oder Symbolic Link direkt mit dem Repository verbinden
  - laufende SQLite-Datenbanken werden als Snapshot behandelt
  - sichere, bewusste Backup-/Restore-Aktionen haben Vorrang
- [x] geschützte Windows-`UserChoice`-Einträge direkt per Registry überschreiben
  - Windows schützt benutzerspezifische Standard-App-Zuordnungen mit zusätzlichen Integritätsmechanismen
  - keine inoffizielle Hash-Manipulation in diesem Projekt
  - Benutzerinteraktion über die offizielle Windows-Standard-App-Oberfläche ist der definierte Weg
- [x] Default-App-XML/GPO als allgemeine Lösung für bestehende lokale Benutzerprofile verwenden
  - der getestete Workflow hat die bestehende Benutzerzuordnung nicht zuverlässig übernommen
  - der Bootstrap verwendet stattdessen die interaktive Standard-App-Initialisierung
- [x] NanaZip-AppX-ProgID fest im Repository hinterlegen
  - AppX-ProgIDs werden dynamisch aus der tatsächlich installierten Paketregistrierung ermittelt
- [x] PowerToys Command Palette als primären Launcher weiterverwenden
  - Raycast wurde als neuer primärer Launcher gewählt
  - `Win + Space` ist der definierte Raycast-Hotkey
  - Command Palette und PowerToys Run bleiben deaktiviert
  - PowerToys bleibt nur für weiterhin benötigte Module installiert
- [x] vollständige persönliche Raycast-`.rayconfig` ins Repository committen
  - vollständige Exporte können persönliche und sensible Daten enthalten
  - im Repository liegt ausschließlich der sanitizte generische Desired State
  - `.rayconfig` bleibt ein lokales Transport-/Backup-Artefakt

---

# 32. Prioritäten / empfohlene nächste Schritte

Eine KI soll bei der Auswahl des nächsten Arbeitspakets grundsätzlich folgende Reihenfolge verwenden, sofern der Benutzer nichts anderes vorgibt.

## Kürzlich abgeschlossen – Home Office / Paketmanager

- [x] `HomeOffice`-Paketgruppe angelegt
- [x] Remote Desktop Manager über Winget integriert und getestet
- [x] FileZilla über Chocolatey integriert und getestet
- [x] PCVisit Supporter Modul integriert und getestet
- [x] RDM-Datenbank als zentrale Quelle für Verbindungsziele festgelegt
- [x] eigene VPN-/Zertifikats-/Secrets-Verwaltung als nicht erforderlich bewertet
- [x] Chocolatey als Paketbackend integriert
- [x] Scoop als Paketbackend integriert
- [x] Chocolatey- und Scoop-Self-Update integriert
- [x] Paketmanager-Cleanup integriert
- [x] FileZilla in komorebi ignoriert und RDM-Embedding getestet
- [x] Sticky Notes waren bereits korrekt vom Tiling ausgeschlossen; Dokumentation nachgezogen

Noch offen aus dem Paketmanager-Umbau:

- [x] Scoop-Bucket-Autobereitstellung mit `versions` + `neovim-nightly` praktisch getestet
- [ ] Retry-Mechanismus für temporäre Download-/Paketmanagerfehler
- [ ] maschinenlesbare Paket-/Update-Zusammenfassung

## Desktop-Stabilität

- [x] fehlerhafte komorebi-/Zebar-Z-Order nach `just update` analysiert
- [x] kontrollierten Desktop-Neustart implementiert
- [x] Startreihenfolge komorebi/whkd/masir → Zebar umgesetzt
- [x] `just desktop-restart` ergänzt
- [x] Sticky Notes vom Tiling ausgeschlossen
- [x] FileZilla vom Tiling ausgeschlossen
- [x] Zebar bei echten Vollbild-Anwendungen ausblenden
- [x] Verhalten bei Browser-/YouTube-Vollbild und Fullscreen-Anwendungen testen

## Kürzlich abgeschlossen – CLI Tools / Shell UX

- [x] `ripgrep` (`rg`) installiert
- [x] `eza` installiert und `ls`-/`ll`-/`la`-/`lt`-Workflow umgesetzt
- [x] `fd`, `bat`, `fzf`, `jq` und `zoxide` installiert
- [x] Neovim Nightly über Scoop `versions` integriert
- [x] Scoop-Zusatz-Bucket `versions` praktisch getestet
- [x] Fish-artige PowerShell-Abbreviations über PSReadLine umgesetzt
- [x] `zoxide` in PowerShell integriert
- [x] Git-Root-basierte Projektcommands umgesetzt
- [x] `update`, `check` und `desktop-restart` nur innerhalb von `windows-setup` verfügbar
- [x] Projektcommands beim Verlassen des Repositories wieder entfernt
- [x] Installation und Wiederholung über `just update` getestet
- [x] `just check` nach dem Umbau ohne relevante Probleme

## Kürzlich abgeschlossen – Raycast Launcher

1. [x] Raycast über Microsoft Store integrieren
2. [x] PowerToys Command Palette als primären Launcher ablösen und deaktivieren
3. [x] `Win + Space` als Raycast-Hotkey verwenden
4. [x] Catppuccin-Mocha-Theme als Raycast Desired State übernehmen
5. [x] Everything über die Raycast-Extension integrieren
6. [x] generischen sanitizten Desired State unter `dotfiles/raycast/config.json` einführen
7. [x] lokales `.rayconfig`-Backup-/Restore-Format reproduzierbar verarbeiten
8. [x] einmalige Initialisierung über `.generated/state/default-apps/raycast.initialized` idempotent machen
9. [x] wiederholten `just update` ohne erneute Benutzerinteraktion und ohne Desired-State-Drift testen

## Priorität 2 – Windows Shell

1. [x] Windhawk Taskbar Styler
2. [x] Windhawk Start Menu Styler
3. [x] Windhawk Notification Center Styler
4. [x] alle bisherigen Windhawk-Einstellungen per CLI reproduzierbar machen

## Priorität 3 – eigenes OSD

1. [ ] technische Architektur festlegen
2. [ ] Volume/Mute
3. [ ] Brightness
4. [ ] Media
5. [ ] Caps Lock Toggle
6. [ ] Num Lock Toggle
7. [ ] Catppuccin-Design
8. [ ] Autostart/Bootstrap
9. [ ] Windows-OSD-Doppelanzeige vermeiden

## Priorität 4 – Gaming

1. [ ] Paketgruppe
2. [ ] Steam
3. [ ] Game-Library-Pfade
4. [ ] sinnvolle Windows-Gaming-Einstellungen

## Priorität 5 – Qualität

1. [ ] Logging
2. [ ] GitHub Actions
3. [ ] Pester
4. [ ] Dry-Run
5. [ ] maschinenlesbarer Abschlussreport

# 33. Regeln für eine KI, die diese Roadmap bearbeitet

## Vor jeder Änderung

1. Repository vollständig bzw. die betroffenen Module neu einlesen.
2. Den **aktuellen Default-Branch und neuesten Commit** prüfen.
3. Prüfen, ob der gewünschte Punkt bereits teilweise implementiert ist.
4. Bestehende Helper und Architektur verwenden statt Parallel-Implementierungen zu erzeugen.
5. Bestehende Designentscheidungen respektieren.
6. Keine Secrets in das Repository schreiben.
7. `Justfile` nur als Bedienoberfläche behandeln; Implementierung gehört in PowerShell.

## Bereitstellung von Repository-Änderungen

Wenn eine KI Änderungen an bestehenden Repository-Dateien für den Benutzer vorbereitet:

1. Änderungen sollen bevorzugt als **ausführbares PowerShell-Patch-Skript (`.ps1`)** bereitgestellt werden, statt den Benutzer mehrere bestehende Dateien manuell bearbeiten zu lassen.
2. Das Patch-Skript soll vom Root des `windows-setup`-Repositories aus ausführbar sein.
3. Das Patch-Skript muss den erwarteten Ausgangszustand prüfen und bei einem unerwarteten Zustand verständlich abbrechen, statt Dateien blind zu verändern.
4. Patches sollen soweit sinnvoll **idempotent** sein und bei wiederholter Ausführung keine doppelten Einträge oder unerwarteten Änderungen erzeugen.
5. Betroffene PowerShell-/PSD1-Dateien sollen nach der Änderung technisch validiert werden, sofern dies ohne zusätzliche Benutzerinteraktion möglich ist.
6. Das Patch-Skript ist grundsätzlich ein Transportmittel für die Änderung und muss nicht selbst in das Repository übernommen werden.
7. Nach erfolgreichem Patch gelten weiterhin die normalen Projektregeln: gezielt testen, `just check` ausführen, Git-Status prüfen und Roadmap/README bei Bedarf nachziehen.

## Während der Implementierung

1. Änderungen idempotent gestalten.
2. Bestehende Installationen erkennen.
3. manuelle Eingriffe nur dort verlangen, wo sie technisch oder rechtlich erforderlich sind.
4. neue generierte Inhalte unter `.generated/` ablegen.
5. Dateien standardmäßig per Hardlink und Verzeichnisse per Junction integrieren; Symbolic Links nur als expliziten, dokumentierten Kompatibilitäts-Fallback verwenden, wenn eine Anwendung Hardlinks nachweislich nicht zuverlässig unterstützt.
6. Fehler verständlich ausgeben.
7. bestehende Konfiguration nicht ohne Backup überschreiben, wenn sie nicht bereits verwaltet wird.
8. PowerShell-Code mit PSScriptAnalyzer kompatibel halten.
9. wiederkehrende manuelle Aktionen bei echtem Nutzen als `just`-Recipe bereitstellen.
10. keine eigentliche Setup-Logik in Recipes duplizieren.
11. laufende Anwendungen vor einem Stop/Restart nach Möglichkeit auf tatsächlichen Konfigurations-Drift prüfen.
12. unveränderte Anwendungen bei wiederholten Bootstrap-Läufen möglichst unangetastet lassen.
13. geschützte Windows-Standard-App-Zuordnungen nicht durch inoffizielle `UserChoice`-/Hash-Manipulation erzwingen.
14. erforderliche Standard-App-Benutzerinteraktionen über den generischen Settings-Workflow ausführen.
15. einmalige interaktive Schritte erst nach erfolgreichem Abschluss mit einem Marker unter `.generated/state/` als erledigt markieren.
16. bei einem Fallback ohne direkte App-ID die allgemeine Standard-App-Seite öffnen, den Benutzer zur manuellen Suche auffordern und auf das Schließen von Settings warten.

- [x] `bootstrap.ps1` führt vor der Setup-Logik einen strikten PowerShell-Code-Preflight aus und bricht bei Error, Warning oder Information ab

## Nach einer Implementierung

1. Funktion gezielt testen.
2. `just update` bzw. den relevanten Bootstrap-Pfad testen.
3. `just check` ausführen.
4. Git-Status prüfen.
5. Roadmap aktualisieren.
6. README aktualisieren, falls sich der produktive Stand oder Benutzer-Workflow geändert hat.
7. neue offene Folgearbeiten als eigene Checkboxen dokumentieren.

## Ausgabe vollständiger Markdown-Dateien

1. Wenn der Benutzer eine vollständige Markdown-Datei zur direkten Übernahme verlangt, muss die Ausgabe vollständig kopierbar bleiben.
2. Enthält die Datei selbst dreifache Markdown-Codeblöcke, ist der gesamte Dateiinhalt in einen äußeren Codeblock mit **mindestens vier Backticks** einzuschließen.
3. Innere Codeblöcke dürfen nicht durch die äußere Darstellung zerstört oder einzeln aus dem Gesamtinhalt herausgebrochen werden.
4. Ist die Datei für eine zuverlässige vollständige Chat-Ausgabe zu groß, soll stattdessen eine vollständige Datei als Download erzeugt und angeboten werden.
5. Bei einem Download muss die erzeugte Datei den vollständigen Inhalt enthalten; keine Abschnitte dürfen wegen Antwortlängenlimits ausgelassen werden.

---

# 34. Definition of Done

Ein Roadmap-Punkt darf nur `[x]` werden, wenn:

- die Funktion implementiert ist,
- sie auf dem aktuellen System getestet wurde,
- ein erneuter Lauf keinen unerwarteten Fehler erzeugt,
- die Umsetzung in den bestehenden Bootstrap integriert ist, sofern sie Teil des automatischen Setups sein soll,
- Konfigurationsdateien reproduzierbar sind,
- keine unnötigen manuellen Schritte bestehen,
- technisch notwendige Benutzerinteraktionen klar geführt, abgewartet und idempotent über lokalen Zustand behandelt werden,
- keine unnötigen Anwendungsneustarts oder Prozessabbrüche bei unverändertem Zustand bestehen,
- keine Secrets im Repository gelandet sind,
- `just check` bzw. PSScriptAnalyzer keine neuen relevanten Probleme meldet,
- Roadmap und bei Bedarf README aktualisiert wurden.

Für neue manuelle Projektaktionen gilt zusätzlich:

- vorhandene `just`-Recipes bevorzugen,
- neue Recipes nur bei wiederkehrendem Nutzen ergänzen,
- keine Setup-Logik im `Justfile` implementieren.

---

# 35. Langfristiges Endergebnis

Nach Abschluss der Roadmap soll ein frisch installiertes Windows 11 nach möglichst wenig manueller Interaktion automatisch zu folgendem Zustand gelangen:

- aktuelle Windows-Updates
- aktuelle benötigte Treiber
- sauber debloatetes Windows
- vollständig eingerichtete Entwicklerumgebung
- Dev Drive + Games Drive
- Git/VS Code/Terminal/Nushell/Starship
- Just als einheitliche manuelle Repository-Bedienoberfläche
- `just update` für Wartungs-/Setup-Läufe
- `just check` für statische Prüfung
- `just desktop-restart` für einen gezielten Desktop-Neustart
- `just ghub-backup` / `just ghub-restore` für bewusste G-HUB-Snapshots
- Browser
- iCloud / Apple Passwords Voraussetzungen
- komorebi + whkd + masir
- Zebar
- OneCommander mit vollständigem Catppuccin-Theme und Dev-File-Icons
- Raycast + Everything als primärer Launcher-/Suchworkflow
- Windhawk für verbleibende Shell-Bereiche
- eigenes Catppuccin-OSD inklusive Caps Lock und Num Lock
- NanaZip
- generischer, interaktiver Standard-App-Initialisierungsworkflow für geschützte Windows-Dateizuordnungen
- lokale Initialisierungsmarker unter `.generated/state/`
- Home-Office-Werkzeuge
- Gaming-Werkzeuge
- Logitech G HUB
- wöchentliche Wartung
- aussagekräftige Benachrichtigungen
- reproduzierbare, im Repository nachvollziehbare Konfiguration
- keine unnötigen manuellen Nacharbeiten
- keine unnötigen Anwendungsneustarts bei unverändertem Zustand
- keine dauerhafte Aufweichung der globalen PowerShell Execution Policy
