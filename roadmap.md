# Windows Setup Roadmap

> **Source of Truth:** Diese Roadmap ist Arbeits- und Entscheidungsgrundlage für die Weiterentwicklung von `windows-setup`.
>
> `[x]` bedeutet implementiert und praktisch bestätigt. `[ ]` bedeutet offen. Bereits getroffene Architekturentscheidungen werden nur bei einem konkreten technischen Grund geändert.

---

# 1. Zielbild

Ein automatisiertes, reproduzierbares und wartbares Windows-11-Setup für Entwicklung, Gaming, privaten Alltag und Home Office.

Der zentrale `bootstrap.ps1` bedient:

1. Neuinstallation über `init.ps1`
2. manuelle Setup-/Wartungsläufe
3. automatische wöchentliche Wartung

Das Repository ist die Source of Truth für versionierbare Einstellungen. `just` ist ausschließlich Bedienoberfläche und enthält keine eigene Setup-Architektur.

## Produktiver Desktop

| Bereich | Lösung |
| --- | --- |
| Desktop / Taskleiste | Windows 11 |
| Window Management | Windows Snap + PowerToys FancyZones |
| Launcher / Suche | Raycast + Everything |
| Dateimanager | Windows File Explorer |
| Archivmanager | NanaZip |
| Volume / Media / System-OSD | Windows 11 |
| Browser | Vivaldi nativ; Zen als Firefox-WebDev-Testbrowser |
| Terminal | Windows Terminal + PowerShell 7 + Starship |

Nicht Teil des Zielbilds: Seelen UI, FluentFlyout, Windhawk, Files, Nushell, Warp, eigenes System-/Media-OSD und repositoryverwaltetes Vivaldi-Custom-HTML/CSS/JS.

---

# 2. Verbindliche Architekturentscheidungen

## Stabilität

- [x] Systemstabilität hat Vorrang vor Design.
- [x] Native Windows-Komponenten werden gegenüber rein optischen Shell-, Hook-, Compositor-, Resource-Redirect- oder Browser-UI-Schichten bevorzugt.
- [x] Desktop-nahe Änderungen müssen Fullscreen, Borderless, Alt+Tab, Fokuswechsel, Gaming und normale Fensterbedienung berücksichtigen.
- [x] Bei wiederkehrenden Stabilitätsproblemen wird auf native Windows-Funktionalität zurückgefallen.
- [x] Der aktuelle native Desktop wurde einschließlich Fullscreen, Alt+Tab, Fokus, Maximieren, Verschieben und Windows Snap praktisch bestätigt.

## Bootstrap

- [x] `bootstrap.ps1` ist der einzige zentrale Setup-/Wartungsworkflow.
- [x] `init.ps1` ist der minimale Erstinstallations-Einstieg und klont nach `%USERPROFILE%\windows-setup`.
- [x] Bootstrap ist wiederholbar und idempotent.
- [x] Keine automatischen Git-Commits oder Pushes.
- [x] Lokale Git-Änderungen verhindern automatisches `git pull`.
- [x] Kein automatischer Windows-Neustart.
- [x] Keine dauerhafte Änderung der globalen PowerShell Execution Policy.
- [x] Bootstrap-Prozesse verwenden `ExecutionPolicy Bypass` ausschließlich prozesslokal.
- [x] Manuelle Bootstrap-Läufe werden über Windows `sudo` erhöht gestartet; der Bootstrap führt keine Self-Elevation aus.
- [x] Laufende Anwendungen werden nur bei tatsächlichem Änderungsbedarf beendet oder neu gestartet.
- [x] Offline-Zustand ist ein sauberer No-Op mit ExitCode `0` und BurntToast-Benachrichtigung.
- [x] Ausfall einzelner GitHub-Dienste bleibt bei vorhandener Internetverbindung nichtfatal; vorhandener lokaler Stand wird soweit möglich weiterverwendet.

## Just / Tests

- [x] `Justfile` ist die einheitliche Bedienoberfläche.
- [x] `just update`: normaler stiller Bootstrap.
- [x] `just update-warning`: nur Warnungen und Fehler.
- [x] `just update-log`: vollständige Ausgabe und verbindlicher funktionaler Bootstrap-Test.
- [x] `just update-performance`: stiller reproduzierbarer Performance-Lauf.
- [x] `just check`: zentraler PSScriptAnalyzer- und C#-Compilecheck.
- [x] `just test`: Pester-Tests.
- [x] `just ghub-backup` / `just ghub-restore`: bewusste G-HUB-Snapshots.
- [x] Neue wiederkehrende Aktionen dürfen als Recipes ergänzt werden; Implementierung bleibt in PowerShell.

## Dateien und lokaler Zustand

- [x] Einzeldateien werden standardmäßig per NTFS-Hardlink eingebunden.
- [x] Verzeichnisse werden per NTFS-Junction eingebunden.
- [x] Symbolic Links sind nur dokumentierter Kompatibilitätsfallback.
- [x] VS Code `settings.json` und Windows Terminal `settings.json` verwenden Symlinks, da beide Anwendungen Hardlinks beim Speichern praktisch auftrennen.
- [x] Zentrale Helper: `Set-FileHardLink`, `Set-FileSymbolicLink`, `Set-DirectoryJunction`.
- [x] Generierte Daten liegen unter `.generated/` und werden nicht committed.
- [x] Lokale State-Marker liegen unter `.generated/state/`.
- [x] State-Marker werden erst nach erfolgreich abgeschlossener Initialisierung/Interaktion erzeugt.

## Performance

- [x] Bootstrap-Performance phasenweise messbar.
- [x] Wiederholter Lauf auf dem aktuellen System typischerweise ungefähr 40 Sekunden.
- [x] Windows-Software- und Treiberupdates teilen sich innerhalb eines Laufs einen WUA-/Microsoft-Update-Scan.
- [x] Winget verwendet einen laufzeitlokalen Inventar-Cache; kein persistenter Paket-/Updatecache zwischen Läufen.
- [x] `msstore` verwendet bei Bedarf einen gezielten Name-Fallback.
- [x] Externe Windows-/Microsoft-Update-Laufzeitvarianz wird akzeptiert.
- [x] Weitere Mikrooptimierung erfolgt nur bei einer reproduzierbaren realen Regression oder störendem Weekly-Workflow.

---

# 3. Repository und Qualität

## Struktur

- [x] `init.ps1`
- [x] `bootstrap.ps1` mit gesplitteter Implementierung über `bootstrap/index.ps1`
- [x] `Justfile`
- [x] `config/`
- [x] `config/packages/` mit zentralem `index.ps1`
- [x] `modules/` mit fachlichen Unterordnern und lokalen `index.ps1`
- [x] `dotfiles/`
- [x] `assets/`
- [x] `scripts/`
- [x] `.generated/`
- [x] `README.md`
- [x] `roadmap.md`
- [x] `PSScriptAnalyzerSettings.psd1`
- [x] Manuell gepflegte Repository-Source-Dateien bleiben unter 500 Zeilen; generierte/vendorisierte Inhalte sind ausgenommen.
- [x] Verwaiste Funktionen und Dateien wurden repositoryweit bereinigt.

## Codequalität

- [x] PowerShell 7.
- [x] PSScriptAnalyzer.
- [x] Verwaltete C#-Quelldateien werden kompiliert; Compilerwarnungen gelten als Fehler.
- [x] Git-basierter Source-Fingerprint umfasst PowerShell und C#.
- [x] Unveränderter Source-Code überspringt den vollständigen Preflight; geänderter Code muss ihn bestehen.
- [x] GitHub Actions für statische Prüfung.
- [x] Pester-Testbasis für kritische Helper.
- [x] Tests für Paket-Versionserkennung.
- [x] Tests für Hardlink-/Junction-Migration.
- [x] Tests für Reboot-Erkennung.
- [x] Package-Konfigurationsschema wird validiert.
- [x] Dry-Run / WhatIf bewusst nicht implementiert: Eine nur teilweise `ShouldProcess`-Abdeckung wäre irreführend. Neu bewerten nur bei Bedarf für eine vollständige Architektur.

---

# 4. Paketverwaltung

`config/packages/` ist die zentrale deklarative Paketliste. `Source` bestimmt den Installationsweg.

Unterstützte Quellen:

- `winget`
- `msstore`
- `chocolatey`
- `scoop`

Für Scoop ist `Bucket` Pflicht; `BucketUrl` ist optional.

## Implementierter Stand

- [x] Generischer Dispatcher für alle vier Paketquellen.
- [x] Chocolatey und Scoop werden bei Bedarf installiert und gepflegt.
- [x] Scoop-Buckets werden aus der Paketkonfiguration abgeleitet.
- [x] Paketmanager-Cleanup läuft auch bei Fehlern der Paketphase.
- [x] Winget-/MS-Store-Pakete werden sourceweise gebündelt aktualisiert.
- [x] Nur deklarierte Pakete werden aktualisiert; kein unkontrolliertes `winget upgrade --all`.
- [x] `Update = $false` und gepinnte Versionen werden respektiert.
- [x] OpenVPN dient als praktisch bestätigter Pinning-Fall.
- [x] Temporäre Chocolatey-/Scoop-Fehler verwenden gezielte Retries.
- [x] Maschinenlesbare Update-Zusammenfassung vorhanden.
- [x] NVIDIA App wird trotz MS-Store-ID-Besonderheit korrekt erkannt.

## Paketgruppen

### Base

- JetBrainsMono Nerd Font
- Just (`Casey.Just`)

### Tools

- Windows HDR Calibration
- iCloud
- ChatGPT Desktop-App (`9PLM9XGG6VKS`, Microsoft Store)
- Raycast (`9PFXXSHC64H3`, Microsoft Store)
- OpenVPN
- Logitech G HUB
- NanaZip
- PowerToys
- Everything

### HomeOffice

- Remote Desktop Manager
- FileZilla Client
- PCVisit Supporter Modul
- OpenVPN

### Development

- fnm
- Go
- Bun
- Git
- GitHub CLI
- GitHub Desktop
- Visual Studio Code
- PowerShell 7
- Starship
- Neovim Nightly
- ripgrep
- eza
- fd
- bat
- fzf
- jq
- zoxide

### Browser

- Zen Browser
- Google Chrome Beta

## NanaZip / Standard-Apps

- [x] NanaZip über `M2Team.NanaZip`.
- [x] Standard-App-Konfiguration verwendet den generischen interaktiven Windows-Settings-Workflow.
- [x] Keine Manipulation geschützter `UserChoice`-Hashes.
- [x] Direkte App-Seite wird verwendet, wenn eine Windows-App-ID ermittelbar ist; sonst allgemeine Standard-App-Seite.
- [x] Bootstrap wartet auf das Schließen der Settings-App.
- [x] Erfolgreiche Initialisierung wird unter `.generated/state/default-apps/<app>.initialized` gespeichert.
- [x] ISO, VHD/VHDX und WIM werden nicht pauschal NanaZip zugeordnet.
- [ ] NanaZip-Kontextmenü explizit praktisch prüfen und dokumentieren.
- [ ] Catppuccin-Anpassung nur verfolgen, falls stabil unterstützt.

## Offen

- [ ] Paketfehler am Ende eines Laufs gesammelt ausgeben.
- [ ] Zentrale Paket-Logs nur im Rahmen der allgemeinen Logging-Strategie ergänzen.
- [ ] npm-/pnpm-/Yarn-Updatepfad bei einer zukünftig tatsächlich verfügbaren neuen Version praktisch bestätigen.

---

# 5. Windows-Grundkonfiguration und Sicherheit

## Windows

- [x] Debloat wiederholbar und ohne Beschädigung von Gaming, Entwicklung oder Windows Hello.
- [x] Consumer Features deaktiviert.
- [x] Taskbar-/Startmenü-Grundeinstellungen.
- [x] Theme und Akzentfarbe `#0A84FF` über `config/windows.psd1`.
- [x] Power-Einstellungen und HDR.
- [x] Wallpaper Slideshow.
- [x] Windows Snap aktiv.
- [x] PowerToys FancyZones mit mindestens zwei Layouts und Hotkey-Wechsel; koexistiert praktisch mit Windows Snap.
- [x] Computername deklarativ über `config/windows.psd1`; Änderung löst keinen automatischen Neustart aus.
- [x] Windows `sudo` per offizieller Policy im Inline-Modus aktiviert.
- [x] Windows-Entwicklermodus aktiviert.
- [x] Long Paths aktiviert.
- [ ] Lock-Screen optisch angleichen.
- [ ] Datenschutz-/Telemetry-Einstellungen nur bei konkretem Bedarf gezielt ergänzen.
- [x] Keine aggressive pauschale Service-Deaktivierung.

## Sicherheit / Systemstatus

- [x] Microsoft Defender bleibt aktiv.
- [x] Defender Dev Drive Performance Mode.
- [x] Rebootbedarf aus CBS, Windows Update und `PendingFileRenameOperations`; irrelevante Temp-/NSIS-Einträge werden gefiltert.
- [x] Vor der Setup-Logik wird ein Systemwiederherstellungspunkt angelegt, sofern kein ausreichend frischer vorhanden ist.
- [x] BitLocker-Status wird geprüft und bei deaktiviertem Schutz gewarnt; keine automatische Aktivierung.
- [x] Secure-Boot-Status wird geprüft.
- [x] Firewall-Status aller Profile wird geprüft.
- [x] Windows-Hello-/Join-Status wird ausgegeben und lokale Konten werden korrekt behandelt.
- [x] Defender-Schutzkomponenten werden geprüft.

---

# 6. Treiber und Firmware

- [x] Modulare Treiberstruktur unter `modules/Drivers/`.
- [x] NVIDIA App und NVIDIA-Updateworkflow.
- [x] Intel Driver & Support Assistant bleibt zuständige Quelle für verifizierte Intel-Treiber.
- [x] ASUS-/Mainboard- und Drittanbieter-Treiber werden über Armoury Crate bewertet.
- [x] Intel-Angebote werden aus dem ASUS-Statuspfad gefiltert.
- [x] BIOS-/UEFI-/Firmware wird erkannt und gemeldet, aber nicht automatisch installiert.
- [x] Kein konkurrierender direkter ASUS-`file.idx`-Installationspfad.
- [x] Armoury Crate wird unabhängig von Winget über AppX/Registry/Start-Apps/Service erkannt.
- [x] Fehlt Armoury Crate, ist Winget `Asus.ArmouryCrate` der einzige vorgesehene Installationsweg.
- [x] Vorhandenes Armoury Crate wird nicht durch ein älteres Winget-Manifest ersetzt.
- [x] Normaler `just update` öffnet Armoury Crate nicht interaktiv.
- [x] RLS-Metadaten werden read-only ausgewertet; nur der letzte vollständige Snapshot zählt.
- [x] Firmware-Markierungen werden separat von Softwareupdates behandelt.

## Offen / ereignisabhängig

- [ ] Kompakte Hardware-Zusammenfassung am Ende des Setup-Laufs.
- [ ] Monitor-/Peripherie-Firmware nur automatisieren, wenn ein zuverlässiger Weg existiert.
- [ ] Winget-Erstinstallation von Armoury Crate auf einem System ohne Installation testen, sobald das Upstream-Manifest wieder funktioniert.
- [ ] Automatische Nicht-Intel-ASUS-Softwareupdates nur ergänzen, wenn ein offizieller firmwarefreier Installationsweg verifiziert ist.
- [ ] Zukünftiges reales BIOS-/Firmware-Angebot erneut prüfen; weiterhin nur melden.
- [ ] Zukünftige Weiterleitung zu ASUS DriverHub praktisch prüfen.
- [ ] `just asus-updates` praktisch testen und nur bei echtem Zusatznutzen behalten.

---

# 7. Windows- und Microsoft-Updates

- [x] `PSWindowsUpdate` / Microsoft Update.
- [x] Windows-, .NET- und Defender-Updates.
- [x] `AcceptAll`, `IgnoreReboot`.
- [x] Kein automatischer Neustart.
- [x] Rebootstatus wird nach Updates erneut geprüft.
- [ ] Verständliche Update-Zusammenfassung in die zentrale Wartungs-/Logging-Ausgabe integrieren.

---

# 8. Netzwerk, VPN und Home Office

## OpenVPN

- [x] `OpenVPNTechnologies.OpenVPN`.
- [x] Version `2.7.101` gepinnt; automatisches Paketupdate deaktiviert.
- [x] Installierte Version wird robust erkannt.

## VPN / Verbindungsdaten

- [x] Keine eigene VPN-Profilverwaltung im Repository erforderlich.
- [x] Keine Trennung von Firmen-/Privatprofilen durch dieses Setup erforderlich.
- [x] Keine eigene Zertifikatsverwaltung durch dieses Setup erforderlich.
- [x] Remote Desktop Manager verwendet eine externe Datenbank als zentrale Quelle für RDP-, VPN-, FTP-/SFTP- und weitere Verbindungsziele.
- [x] RDM-/FileZilla-Verbindungsdaten und Credentials bleiben vollständig außerhalb des öffentlichen Repositories.

## Home-Office-Werkzeuge

- [x] Eigene Paketgruppe `HomeOffice`.
- [x] Remote Desktop Manager.
- [x] FileZilla über Chocolatey.
- [x] PCVisit Supporter Modul über eigenen Installationsworkflow.
- [ ] Agfeo Dashboard / Softphone nur bei tatsächlichem Bedarf ergänzen.
- [ ] Weitere interne Tools nur bei konkretem Bedarf ergänzen.

## eM Client

- [x] eM Client über `eMClient.eMClient` installieren und aktualisieren.
- [x] Exchange/EWS sowie klassische IMAP-/SMTP-Konten praktisch bestätigt.
- [x] Vollständige Konfiguration einschließlich gespeicherter Account-Credentials ausschließlich über den offiziellen eM-Client-Settings-Export/-Import sichern.
- [x] Keine interne Credential-Erzeugung und kein Reverse Engineering von eM-Client-Datenbanken oder Assemblies.
- [x] Export zusätzlich mit SOPS als `secrets/emclient-settings.sops.xml` verschlüsseln.
- [x] Importpasswort verschlüsselt unter `emclient.import_password` in `secrets/mail.sops.json`.
- [x] Neuer manueller Export wird unter `.generated/emclient/settings.xml` abgelegt; der Bootstrap verschlüsselt ihn atomar und löscht Klartext erst nach erfolgreicher SOPS-Verschlüsselung.
- [x] Restore entschlüsselt nur temporär nach `%TEMP%\emclient-settings.xml`.
- [x] Importpasswort wird nicht als CLI-Argument oder Logausgabe verwendet, sondern nur temporär über die Zwischenablage an den eM-Client-Passwortdialog übergeben.
- [x] Zwischenablage, Passwortvariablen und temporäre Klartextdatei werden danach bereinigt.
- [x] Unveränderter Import wird per SHA-256-State unter `.generated/state/emclient/settings.sha256` übersprungen.
- [x] Vollständiger Backup-/Restore- und Bootstrap-Workflow praktisch bestätigt.

Verworfen: Thunderbird-Provisionierungsprototyp, Outlook-Classic-COM/UI-Automation, Canary Mail für den vorhandenen Exchange sowie Reverse Engineering der eM-Client-Credentials.

---

# 9. Entwicklerumgebung

## C# / .NET / WPF

- [x] Visual Studio Code + Microsoft C# Dev Kit.
- [x] `.NET 10` LTS als produktiver SDK-Track.
- [x] Moderne SDK-Style-WPF-Projekte.
- [x] `.NET Framework` nur bei konkretem Legacy-Bedarf.
- [x] Console- und WPF-Projekt einschließlich Build/Run/Debug praktisch bestätigt.
- [x] Repository-C#-Compilecheck bleibt unabhängig von Projekt-Builds bestehen.

## Node.js

- [x] fnm.
- [x] Aktuelle Node-LTS wird geprüft und nur bei Drift aktualisiert.
- [x] npm, pnpm und Yarn werden gegen ihre aktuellen Registry-Versionen geprüft.
- [x] `PNPM_HOME` / PATH und Verfügbarkeit innerhalb desselben Bootstrap-Laufs.
- [ ] Tatsächliche npm-/pnpm-/Yarn-Updateinstallation bei einer zukünftig neueren Version praktisch bestätigen.

## Bun / Go

- [x] Bun installieren/aktualisieren; Cache auf Dev Drive.
- [x] Go installieren/aktualisieren; `GOCACHE` und `GOMODCACHE` auf Dev Drive.

## Git

- [x] Benutzername, E-Mail, globale Konfiguration, globale Gitignore, Editor und Git LFS.
- [x] Repository-Status, lokale Änderungen und ungepushte Commits werden erkannt.

## Neovim

- [x] Neovim Nightly über Scoop `versions`, mindestens `0.12.0`.
- [x] Extern gepflegtes `jayzone91/nvim` als Submodule unter `external/nvim`, Branch `main`.
- [x] `%LOCALAPPDATA%\nvim` per Junction auf `external/nvim`.
- [x] Remote wird per Fetch geprüft; Pull nur bei tatsächlichem Fast-Forward.
- [x] Lokale Änderungen werden nur bei einem real nötigen Remote-Update temporär gestasht.
- [x] Stash-Konflikte werden nicht automatisch zurückgesetzt; Diagnose bleibt erhalten.
- [x] Laufende externe Submodule-Commits werden nicht automatisch in `windows-setup` übernommen.
- [ ] Remote-Update mit neuem Commit und gleichzeitig vorhandenen lokalen Änderungen erneut praktisch bestätigen.

### Tree-sitter

- [x] `tree-sitter-cli` über Scoop.
- [x] Zig als C/C++-Toolchain.
- [x] Scoop-Shims `cc` → `zig cc`, `c++` → `zig c++`.
- [x] `CC=cc`, `CXX=c++`, `CRATE_CC_NO_DEFAULTS=1`.
- [x] Parser-Kompilierung praktisch bestätigt.
- [x] Kein zusätzlicher MSVC-Compiler für diesen Workflow erforderlich.

## Codex

- [x] Codex CLI installiert.
- [ ] Zusätzliche Konfiguration nur bei echtem Bedarf.
- [ ] VS-Code-/Terminal-Workflow nur dokumentieren, wenn daraus ein dauerhafter Projektworkflow entsteht.

---

# 10. Development Storage

- [x] Zusätzliche interne Disk sicher erkennen; Boot-/Systemdisk und ungeeignete Datenträger ausschließen.
- [x] Destruktive Änderungen erfordern explizite Bestätigung.
- [x] Erwartetes vorhandenes Layout wird erkannt und nicht neu formatiert.

| Laufwerk | Größe | Dateisystem | Label | Zweck |
| --- | ---: | --- | --- | --- |
| `D:` | 100 GB | ReFS Dev Drive | `Dev` | Entwicklung |
| `G:` | Rest | NTFS | `Games` | Spiele |

Verwaltete Entwicklungsziele:

- `D:\Projects`
- `D:\Build`
- `D:\Cache\npm`
- `D:\Cache\pnpm`
- `D:\Cache\yarn`
- `D:\Cache\bun`
- `D:\Cache\go\build`
- `D:\Cache\go\modules`

- [x] Cache-/Umgebungswerte werden nur bei Desired-State-Drift erneut geschrieben.

---

# 11. Terminal, Shell und VS Code

## Windows Terminal

- [x] PowerShell 7 als Standardprofil.
- [x] JetBrainsMono Nerd Font, Catppuccin Mocha, Acrylic/Transparenz.
- [x] `config/terminal.psd1` dient nur der Erstinitialisierung.
- [x] Nach Initialisierung ist `dotfiles/terminal/settings.json` alleinige versionierte Source of Truth.
- [x] `settings.json` wird per Symlink eingebunden.
- [x] GUI-Änderungen landen direkt im Repository-Dotfile.
- [x] Nach Settings-Änderungen ist ein vollständiger Terminal-Neustart der dokumentierte Workflow.

## PowerShell / CLI

- [x] PowerShell-Profil im Repository und per Hardlink eingebunden.
- [x] Starship-Konfiguration im Repository und per Hardlink eingebunden.
- [x] `rg`, `eza`, `fd`, `bat`, `fzf`, `jq`, `zoxide`.
- [x] Fish-artige PSReadLine-Abbreviations für CLI-, Navigations- und Git-Kommandos.
- [x] `zoxide init powershell`.
- [x] Projektspezifische Commands werden nur innerhalb `~/windows-setup` dynamisch geladen und beim Verlassen entfernt.
- [ ] Weitere CLI-Tools nur anhand eines konkreten Workflows ergänzen.
- [ ] Weiterer Shell-UX-Feinschliff bei konkretem Bedarf.
- [ ] Keybindings/Profile nur dokumentieren/versionieren, wenn weitere dauerhafte Anpassungen entstehen.

## Visual Studio Code

- [x] Installation und Extension-Management.
- [x] `settings.json` im Repository per Symlink.
- [x] Catppuccin.
- [x] Codex-Integration.
- [x] Wiederholbarer Setup-Pfad.
- [ ] Next.js-/TypeScript-Workflow vervollständigen.
- [ ] Go-Workflow vervollständigen.
- [ ] Extension-Liste regelmäßig bereinigen.
- [ ] Keybindings/Profile bei tatsächlichem Bedarf versionieren.

---

# 12. Browser

## Google Chrome Beta

- [x] Installation und Updates.
- [x] Enterprise Policies.
- [x] Extension Deployment.

## Zen Browser

- [x] Installation, Updates, Erweiterungen, deutsche Sprache und Wörterbuch.
- [x] Enterprise Policies, Session Restore und Google-Suche.
- [x] Telemetrie, Firefox Studies und Pocket deaktiviert.
- [x] Zen Mods werden idempotent über Marionette installiert.
- [x] Aktives Profil wird über die reale Installationszuordnung ermittelt.
- [x] Zen wird nur geschlossen, wenn tatsächlich Mod-/Cleanup-Drift vorliegt.
- [x] Früheres Catppuccin-Custom-CSS, Logo und hostbezogene Website-Styles vollständig entfernt.
- [x] Zen verwendet wieder das native Standard-Theme.
- [x] `Set-ZenTheme` verwaltet nur noch die Abwesenheit alter repositoryverwalteter Custom-CSS-Artefakte.

Akzeptanz:

- Ein normaler `just update` schließt Zen nicht, wenn kein Drift besteht.
- Fehlende Mods werden gezielt installiert.
- Die Profilprüfung verwendet das tatsächlich aktive Profil.

## Vivaldi

- [x] Vivaldi bleibt Hauptbrowser.
- [x] Repositoryverwaltetes Custom-HTML/CSS/JS wurde vollständig verworfen.
- [x] Vivaldi bleibt im nativen UI-Zustand.

---

# 13. Logitech G HUB

- [x] Installation und Updates.
- [x] `settings.db` wird als bewusster Snapshot im Repository verwaltet.
- [x] Keine Hardlink-/Symlink-Verknüpfung der laufend veränderten SQLite-Datenbank.
- [x] Erstinitialisierung auf neuem System über lokalen Marker.
- [x] Normale Bootstrap-Läufe synchronisieren die Datenbank nicht automatisch.
- [x] `just ghub-backup` und `just ghub-restore`.
- [x] G HUB wird nur für Initialisierung, Backup oder Restore kontrolliert beendet und danach wieder gestartet.

---

# 14. Launcher und Suche

## Raycast

- [x] Raycast über Microsoft Store `9PFXXSHC64H3`.
- [x] Primärer Launcher mit `Win + Space`; PowerToys Command Palette und PowerToys Run bleiben deaktiviert.
- [x] Everything bleibt Suchbackend über die Raycast-Extension.
- [x] Versionierter, sanitizter Desired State liegt unter `dotfiles/raycast/config.json`.
- [x] `config/raycast.psd1` enthält Transportpasswort und frei wählbaren lokalen Backup-Pfad.
- [x] Vollständige `.rayconfig`-Backups bleiben lokal und werden niemals committed.
- [x] Initialisierung verwendet `.generated/state/default-apps/raycast.initialized`.
- [x] Nach Initialisierung wird nur das neueste lokale Backup sanitizt; bei unverändertem Zustand keine erneute Benutzerinteraktion oder Restore-Datei.
- [x] Catppuccin Mocha und Store-Extensions werden über Raycasts nativen Export-/Importweg reproduzierbar verwaltet.

## Everything

- [x] Installation und Integration als Suchbackend.

---

# 15. Gaming

- [x] Eigene Gaming-Paketgruppe.
- [x] Steam, Epic Games Launcher, GOG GALAXY, EA app, Battle.net und Ubisoft Connect installiert und praktisch initialisiert.
- [x] Launcher werden deklarativ einer `GameLibrary` unter `G:\Games\` zugeordnet.
- [x] Standard-Spielpfade werden über offiziell unterstützte Launcher-Einstellungen gesetzt; keine Manipulation interner Launcher-Datenbanken.
- [x] Einmalige Launcher-Initialisierung verwendet Marker unter `.generated/state/gaming-launchers/`.
- [x] Game Mode, Hardware Accelerated GPU Scheduling, VRR/G-Sync-relevante Windows-Einstellungen und HDR-Workflow geprüft.
- [x] Keine undokumentierten „Gaming Tweaks“ oder aggressive Service-/Scheduler-/Timer-Optimierungen.
- [x] PowerToys Find My Mouse verwendet automatisch aus den Game-Libraries ermittelte `.exe`-Namen als `excluded_apps`.
- [x] Ein `AtLogOn`-Scheduled-Task aktualisiert die Spiele-Exclusions nur bei Drift und ohne PowerToys-Neustart.
- [x] Horizon Zero Dawn Remastered sowie weitere Launcher/Game-Library-Pfade praktisch bestätigt.
- [x] Desktop-Stabilität mit Fullscreen/Borderless und Alt+Tab praktisch geprüft.

---

# 16. Apple / iCloud

- [x] iCloud installiert und aktualisierbar.
- [x] Windows-Hello-Voraussetzungen für Apple Passwords geprüft.
- [x] Windows-Hello-Status wird im Bootstrap diagnostisch ausgegeben.

Weitere Apple-/iCloud-Automatisierung nur über offiziell unterstützte Schnittstellen und ohne Secrets im Repository.

---

# 17. Wartung und Scheduled Tasks

## Weekly Maintenance

- [x] Wöchentlicher Wartungstask verwendet denselben parameterlosen Bootstrap.
- [x] Scheduled Tasks werden nur bei Drift von Action, Trigger, Principal oder Settings neu registriert.
- [x] Benutzeridentitäten werden für Vergleiche auf stabile SIDs normalisiert.
- [x] Kein automatischer Neustart.
- [x] Externe GitHub-/Content-Ausfälle sind soweit möglich nichtfatal.
- [ ] Wallpaper-Verhalten auf einer Neuinstallation ohne lokalen Stand bei fehlgeschlagenem Clone praktisch testen.

## Benachrichtigungen

- [x] BurntToast verfügbar.
- [x] Offline-Zustand wird sichtbar gemeldet.
- [x] Maschinenlesbarer Abschlussstatus vorhanden.
- [x] Fataler Bootstrap-Fehler wird mit Timestamp unter `.generated/logs/bootstrap-last-error.log` gespeichert.
- [x] Zentrale persistente Logging-Strategie für komplette Bootstrap-Läufe über eindeutige Transcript-Dateien unter `.generated/logs/runs/`.
- [ ] Warnungen und Fehler vollständig mit Timestamp persistieren.
- [ ] Log-Dateien mit Datum/Uhrzeit und Ergebnisstatus.
- [ ] Log-Retention/Bereinigung.
- [ ] Paket- und Windows-Update-Zusammenfassungen in diese Logging-Strategie integrieren.
- [ ] Optional erfolgreiche Wartungszusammenfassung.
- [ ] Optional nichtfatale Fehlerzusammenfassung.
- [ ] `-Verbose` nur ergänzen, wenn für reale Diagnosefälle erforderlich.
- [ ] Zusammenfassung der Änderungen eines Laufs nur ergänzen, wenn der Nutzen den Tracking-Aufwand rechtfertigt.

---

# 18. Dokumentation

## README

- [x] Installation.
- [x] `just`-Workflow.
- [x] Paket-/Standard-App-/G-HUB-Workflows soweit benutzerrelevant.
- [x] Aktueller produktiver Desktop.
- [ ] Third-Party-Icon-Attribution inklusive tatsächlich verwendeter Ersteller dokumentieren.
- [ ] Nach größeren Änderungen am Benutzerworkflow aktualisieren.

## Roadmap

- [x] Source of Truth für Architekturentscheidungen, offenen Stand und Akzeptanzkriterien.
- [x] Historische Detailprotokolle und doppelte abgeschlossene Checklisten zugunsten des aktuellen Zustands verdichtet.
- [ ] Bei größeren Architekturentscheidungen aktualisieren.

## Weitere Dokumentation

- [ ] Separate technische Projektdokumentation erstellen; README bleibt kompakte Benutzerübersicht.

---

# 19. Bewusst verworfene Ansätze

Diese Punkte nicht erneut vorschlagen, solange kein neuer konkreter technischer Grund vorliegt:

- Seelen UI als produktive Desktop-Shell.
- FluentFlyout oder eigenes Volume-/Media-/System-OSD.
- Windhawk als allgemeine Desktop-/Shell-Anpassungsschicht.
- Files als produktiver Dateimanager.
- Nushell oder Warp als produktive Shell-/Terminalbasis.
- Vivaldi-Custom-HTML/CSS/JS.
- Repositoryverwaltetes Zen-Custom-CSS / Catppuccin-Webseiten-Styling.
- Systemweite Resource-Redirects für rein optische Icons.
- Hardlinks für VS Code oder Windows Terminal `settings.json`.
- Automatische Manipulation geschützter Windows-`UserChoice`-Dateizuordnungen.
- Automatische eM-Client-Kontenerzeugung durch Datenbankmanipulation.
- Automatische G-HUB-Datenbanksynchronisierung bei jedem Bootstrap.
- Persistente Windows-Update-/Treiber-/Winget-Inventarcaches zwischen Bootstrap-Läufen.
- Automatisches BIOS-/Firmware-Flashing.
- Direkter ASUS-`file.idx`-Installationspfad parallel zu Armoury Crate.
- Teilweiser Dry-Run / WhatIf ohne vollständige `ShouldProcess`-Architektur.
- Dauerhafte Lockerung der PowerShell Execution Policy.
- Automatische Bootstrap-Self-Elevation.
- Automatische Git-Commits/Pushes oder Windows-Neustarts.

---

# 20. Aktuelle offene Arbeit

Priorisierung erfolgt nach Nutzen, Stabilität und Abhängigkeiten. Ereignisabhängige Tests werden erst durchgeführt, wenn der benötigte reale Zustand eintritt.

## Priorität 1 – Logging / Wartungsdiagnose

- [x] Zentrale persistente Logging-Strategie für komplette Bootstrap-Läufe definieren und praktisch bestätigen.
- [ ] Warnungen/Fehler mit Timestamp und Laufstatus persistieren.
- [ ] Log-Retention implementieren.
- [ ] Paket- und Windows-Update-Zusammenfassungen integrieren.
- [ ] Paketfehler am Laufende gesammelt ausgeben.

## Priorität 2 – Entwicklerworkflow

- [ ] VS-Code-Next.js-/TypeScript-Workflow vervollständigen.
- [ ] VS-Code-Go-Workflow vervollständigen.
- [ ] Extension-Liste bereinigen.
- [ ] npm-/pnpm-/Yarn-Updatepfad bei real verfügbarer neuer Version bestätigen.
- [ ] Neovim-Remote-Update mit lokalen Änderungen bei realem neuen Remote-Commit bestätigen.

## Priorität 3 – System / Hardware

- [ ] Kompakte Hardware-Zusammenfassung.
- [ ] Lock-Screen optisch angleichen.
- [ ] NanaZip-Kontextmenü praktisch prüfen.
- [ ] Wallpaper-Clone-Ausfall auf Neuinstallation praktisch testen.
- [ ] ASUS-/Firmware-Ereignisfälle bei realem Auftreten testen.
- [ ] Monitor-/Peripherie-Firmware nur bei belastbarem Weg automatisieren.
- [ ] Brightness nur bei einem neuen, praktisch funktionierenden Hardware-/Softwarepfad erneut prüfen; WMI/DDC/VCP waren auf dem aktuellen System nicht brauchbar.

## Bei konkretem Bedarf

- [ ] Weitere Datenschutz-/Telemetry-Einstellungen.
- [ ] Weitere CLI-Tools / Shell-UX.
- [ ] Codex-Zusatzkonfiguration.
- [ ] Agfeo / weitere interne Home-Office-Tools.
- [ ] Catppuccin für NanaZip nur bei stabiler Unterstützung.
- [ ] Keybindings/Profile für Terminal/VS Code.
- [ ] Separate technische Projektdokumentation.
- [ ] Third-Party-Icon-Attribution vervollständigen.

---

# 21. Regeln für KI-Arbeit

## Vor jeder Änderung

1. Aktuellen Default-Branch und neuesten Commit prüfen.
2. Vollständige aktuelle `roadmap.md` lesen.
3. Betroffene Dateien im aktuellen Repository-Stand lesen.
4. Prüfen, ob der Punkt bereits teilweise implementiert ist.
5. Bestehende Helper, Architektur und Workflows wiederverwenden.
6. Externe APIs, Programme und Formate bei Bedarf anhand aktueller Quellen verifizieren.
7. Keine Secrets in das Repository schreiben.
8. Widerspricht eine Benutzeranweisung einer bestehenden Entscheidung, vor der Umsetzung darauf hinweisen.

## Änderungen bereitstellen

1. Niemals direkt in das Benutzer-Repository schreiben, committen, pushen oder einen PR erstellen.
2. Änderungen an bestehenden Dateien als herunterladbaren `.ps1`-Patch bereitstellen.
3. Patch aus dem Repository-Root ausführbar machen.
4. Erwarteten Ausgangszustand prüfen und bei Abweichung verständlich abbrechen.
5. Patch möglichst idempotent/defensiv gestalten.
6. Keine globale oder benutzerspezifische Execution Policy verändern.
7. Standardausführung:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "<Pfad-zum-Patch.ps1>"
```

## Implementierung

1. Änderungen klein und gezielt halten.
2. Bestehende funktionierende Logik nicht ohne technischen Grund ändern.
3. Desired State und bestehende Installationen erkennen.
4. Laufende Anwendungen nur bei tatsächlichem Drift stoppen/neustarten.
5. Generierte Inhalte unter `.generated/`.
6. Dateien standardmäßig Hardlink, Verzeichnisse Junction; Symlink nur dokumentierter Kompatibilitätsfallback.
7. Bestehende unmanaged Konfiguration nicht ohne Backup überschreiben.
8. PowerShell-Code muss PSScriptAnalyzer-kompatibel bleiben.
9. `Justfile` enthält keine Setup-Logik.
10. Geschützte Windows-Standard-App-Zuordnungen nur über den generischen interaktiven Settings-Workflow.
11. Einmalige Interaktionen erst nach Erfolg per State-Marker abschließen.

## Test-Workflow

Nach einem Patch:

1. Patch lokal anwenden.
2. `just check`.
3. `just test`, sofern Tests betroffen oder sinnvoll sind.
4. Funktionale Bootstrap-Änderungen mit `sudo just update-log` testen.
5. Performance nur mit `sudo just update-performance` messen.
6. Änderung praktisch testen.
7. `git status` prüfen.
8. Erst nach bestätigtem praktischem Test darf ein Punkt `[x]` werden.
9. Roadmap und bei benutzerrelevanten Workflowänderungen README aktualisieren.

---

# 22. Definition of Done

Ein Roadmap-Punkt darf nur `[x]` werden, wenn:

- Implementierung vollständig ist,
- bestehende Architektur eingehalten wurde,
- Änderung auf dem aktuellen System praktisch getestet wurde,
- Wiederholung keinen unerwarteten Fehler erzeugt,
- erforderliche statische Tests erfolgreich sind,
- Desktop-nahe Änderungen zusätzlich Fullscreen, Alt+Tab und Fokus berücksichtigen,
- Konfiguration reproduzierbar ist,
- keine unnötigen manuellen Schritte oder Anwendungsneustarts entstehen,
- keine Secrets im Repository landen,
- Roadmap und bei Bedarf README aktualisiert sind.

---

# 23. Langfristiges Endergebnis

Ein frisch installiertes Windows 11 soll mit möglichst wenig manueller Interaktion zu einem stabilen, aktuellen und reproduzierbaren Arbeits-, Entwicklungs-, Home-Office- und Gaming-System werden.

Der dauerhafte Kern bleibt:

- zentraler idempotenter Bootstrap
- `just` als Bedienoberfläche
- deklarative Paket- und Windows-Konfiguration
- native Windows-11-Shell + PowerToys FancyZones
- Windows File Explorer
- Raycast + Everything
- Windows Terminal + PowerShell 7 + Starship
- Git / VS Code / Neovim / moderne Development-Toolchains
- Dev Drive + Games Drive
- Browser, iCloud, Home Office und Gaming
- kontrollierte Treiber-/Updatepflege
- G-HUB-Snapshotworkflow
- wöchentliche Wartung
- aussagekräftige Diagnose und Benachrichtigungen
- keine unnötigen manuellen Nacharbeiten, Neustarts oder Sicherheitsabschwächungen
