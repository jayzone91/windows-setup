# Windows Setup

Automatisiertes, reproduzierbares und weitgehend idempotentes Setup für meine Windows-11-Arbeitsumgebung.

Das Repository dient sowohl zur Einrichtung eines frisch installierten Windows-Systems als auch zur regelmäßigen Wartung eines bereits eingerichteten Rechners. Derselbe zentrale `bootstrap.ps1` wird für Neuinstallation, manuelle Setup-Durchläufe und automatische Wartung verwendet.

Ein zweites wichtiges Ziel ist eine Windows-Desktop-Umgebung, die sich funktional und optisch an meiner Arch-/Hyprland-Workstation orientiert. Dafür werden komorebi, whkd, masir, Zebar und OneCommander kombiniert und mit Catppuccin Mocha gestaltet.

## Aktueller Stand

Der Kern des Setups ist produktiv nutzbar und weitgehend reproduzierbar.

Bereits umgesetzt sind unter anderem:

- Paketinstallation und Updates über `winget`, Microsoft Store, Chocolatey und Scoop
- Chocolatey und Scoop werden bei Bedarf automatisch installiert und bei jedem Bootstrap selbst aktualisiert
- Scoop-Buckets werden aus den Paketdefinitionen abgeleitet; pro Scoop-Paket ist der gewünschte Bucket explizit definiert
- Paketmanager-Cleanup für Chocolatey und Scoop bei jedem Bootstrap-Lauf
- eigene Home-Office-Paketgruppe mit Remote Desktop Manager und FileZilla
- PCVisit Supporter Modul mit Installation-bei-Bedarf und PCVisit-eigenem Auto-Update
- Versions-Pinning einzelner Pakete
- Windows-Debloat und Grundkonfiguration
- Windows- und Microsoft-Updates
- Treiberlogik für NVIDIA und Intel
- PowerShell-, Node.js-, Bun- und Go-Entwicklungsumgebung
- Git, GitHub CLI und GitHub Desktop
- Visual Studio Code inklusive Extensions und Settings
- Windows Terminal, Nushell und Starship
- Neovim Nightly über Scoop `versions`
- extern gepflegte Neovim-Konfiguration aus `jayzone91/nvim` als Submodule unter `external/nvim`
- automatische Aktualisierung des Neovim-Submodules auf `main` bei jedem Bootstrap
- automatische Stash/Pull/Restore-Behandlung für lokale Änderungen im Neovim-Submodule
- `tree-sitter-cli` über Scoop und Zig als C/C++-Toolchain für `nvim-treesitter`
- moderne CLI-Werkzeuge: ripgrep, eza, fd, bat, fzf, jq und zoxide
- Fish-artige PowerShell-Abbreviations über PSReadLine
- Zoxide-Integration für schnelle Verzeichnisnavigation
- dynamische Git-Root-basierte Projektcommands für `windows-setup`
- Zen Browser und Google Chrome Beta
- Logitech G HUB mit einmaliger Initialisierung sowie bewusstem Backup/Restore
- ReFS Dev Drive und separates Games-Laufwerk
- Microsoft Defender Dev Drive Performance Mode
- automatische wöchentliche Wartung
- Desktop-Benachrichtigungen
- PSScriptAnalyzer-Codeprüfung
- `just` als einheitliche Bedienoberfläche für manuelle Projektaktionen
- `just update` für den vollständigen manuellen Wartungs-/Setup-Lauf
- `just check` für die rekursive PSScriptAnalyzer-Prüfung
- `just desktop-restart` für einen definierten Neustart von komorebi, whkd, masir und Zebar
- `just ghub-backup` und `just ghub-restore` für bewusste G-HUB-Konfigurations-Snapshots
- Bootstrap-Ausführung mit `ExecutionPolicy Bypass` ausschließlich auf Prozessebene
- komorebi + whkd als Tiling Window Manager
- masir für Focus Follows Mouse
- Raycast als primärer Launcher über `Win + Space`, inklusive Catppuccin-Mocha-Theme und reproduzierbarem Desired-State-/Backup-/Restore-Workflow
- Everything als schneller Datei-/Ordnerindex für die Raycast-Extension
- PowerToys Command Palette und PowerToys Run deaktiviert; PowerToys bleibt für weiterhin verwendete Module installiert
- Zebar als eigene interaktive Desktop-Bar
- Zebar-Akkuanzeige für die Logitech G502 X Plus über eine lokale PowerShell-Bridge zur G-HUB-WebSocket-API, inklusive Wireless-/USB-Erkennung, Lade-/Vollgeladen-Status und Catppuccin-Farbzuständen
- definierter Desktop-Neustart nach dem Bootstrap zur Wiederherstellung der korrekten Zebar-Z-Order
- OneCommander als Explorer-Ersatz
- OneCommander-Desired-State-Precheck: Neustart nur bei tatsächlichem Konfigurations-Drift
- Catppuccin-Mocha-Theme für OneCommander
- Catppuccin-Mocha-Folder-Icons für OneCommander
- automatisch generiertes Catppuccin-Mocha-File-Icon-Pack aus `catppuccin/vscode-icons`
- NanaZip als Archivmanager
- interaktive Initialisierung von Windows-Standard-Apps
- direkte Navigation zur anwendungsspezifischen Standard-App-Konfiguration, sofern Windows eine passende App-ID bereitstellt
- Fallback auf die allgemeine Windows-Standard-App-Seite
- Bootstrap wartet bei interaktiver Standard-App-Konfiguration auf das Schließen der Windows-Einstellungen
- persistenter Initialisierungsstatus unter `.generated/state/default-apps/`
- Datei-Dotfiles werden standardmäßig als NTFS-Hardlinks eingebunden
- Verzeichnis-Dotfiles werden als NTFS-Junctions eingebunden
- Symbolic Links werden nur als dokumentierter Kompatibilitäts-Fallback verwendet; VS Code settings.json nutzt diese Ausnahme
- Catppuccin Mocha als gemeinsame Designsprache
- zentrale Catppuccin-Mocha-Palette unter `config/theme.psd1`
- gemeinsame Desktop-Hauptfläche `Base #1e1e2e` für VS Code, Windows Terminal, Zebar und die Windhawk-Taskbar
- Windows 11 Taskbar Styler über Windhawk mit RosePine als Basis und Catppuccin-Mocha-Farboverrides
- kompakter Mauve-Punkt unter dem aktiven Taskbar-Fenster statt des RosePine-Aktivrahmens
- Windows 11 Start Menu Styler über Windhawk mit RosePine als Layout-Basis und Catppuccin-Mocha-Farboverrides
- Startmenü und Suchansicht mit `Base #1e1e2e`, dezentem `Surface1 #45475a`-Außenrahmen und Mauve-Fokusakzent
- präzisere Reboot-Erkennung mit Auswertung konkreter Ursachen
- Zen-Mod-Precheck: Browser-Neustart nur, wenn konfigurierte Mods tatsächlich fehlen

Die nächsten größeren Arbeitspakete sind weitere Windhawk-Mods für das Notification Center, Taskbar-Auto-Hide-Tuning, Lock Keys Notifier sowie weiterer Catppuccin-Polish.

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
- führt erforderliche einmalige Benutzerinteraktionen aus,
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

## Desktop-Umgebung neu starten

```powershell
just desktop-restart
```

Die Recipe beendet Zebar und die komorebi-Komponenten kontrolliert. Anschließend werden komorebi, whkd und masir gestartet; erst danach startet Zebar. Derselbe Ablauf wird am Ende des Bootstrap verwendet, damit die Bar nach Änderungen wieder zuverlässig in der korrekten Z-Order liegt.

## Logitech G HUB sichern und wiederherstellen

```powershell
just ghub-backup
just ghub-restore
```

Die G-HUB-`settings.db` wird nicht mehr bei jedem Bootstrap automatisch synchronisiert. G HUB verändert die SQLite-Datenbank auch ohne bewusste Konfigurationsänderungen laufend. Auf einem neuen System erfolgt deshalb nur eine einmalige Initialisierung.

Danach bleibt G HUB bei normalen `just update`-Läufen unangetastet. Ein Backup oder Restore wird bewusst über die beiden Recipes ausgelöst; dafür darf G HUB kontrolliert beendet und anschließend wieder gestartet werden.

## Direkter Bootstrap-Aufruf

Falls `just` nicht verfügbar ist, kann der Bootstrap weiterhin direkt gestartet werden:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Der direkte PowerShell-Aufruf bleibt der technische Fallback. Für normale manuelle Nutzung ist `just update` der bevorzugte Einstiegspunkt.

---

# Neovim

Neovim selbst wird als Nightly-Version über den Scoop-Bucket `versions` installiert. Die eigentliche Neovim-Konfiguration wird dagegen in einem eigenen Repository gepflegt:

```text
https://github.com/jayzone91/nvim
```

Dieses Repository ist als Git-Submodule unter folgendem Pfad eingebunden:

```text
external/nvim
```

Der Bootstrap verbindet anschließend:

```text
%LOCALAPPDATA%\nvim
```

per NTFS-Junction mit `external/nvim`.

Das Neovim-Repository wird bewusst **extern** gepflegt. Neue Commits oder lokale Änderungen innerhalb dieses Submodules sollen nicht als normale Änderungen von `windows-setup` behandelt oder automatisch in dessen Git-History übernommen werden. Das Submodule verwendet deshalb `branch = main` und `ignore = all`.

Bei jedem Bootstrap wird das Submodule synchronisiert und bei Bedarf initialisiert. Danach wird das externe Repository mit:

```powershell
git pull --ff-only origin main
```

aktualisiert.

Enthält `external/nvim` lokale Änderungen, sichert der Bootstrap diese vor dem Pull automatisch per Git-Stash einschließlich untracked Dateien. Nach dem Pull wird der Stash wiederhergestellt. Scheitert die Wiederherstellung wegen eines Konflikts, wird der Zustand nicht automatisch verworfen. Der Stash bleibt erhalten und am Ende des Bootstrap werden die relevanten Stash- und Git-Informationen sowie Diagnosebefehle ausgegeben.

## Tree-sitter unter Windows

Für `nvim-treesitter` werden folgende Abhängigkeiten reproduzierbar über den Bootstrap bereitgestellt:

- Neovim `0.12.0` oder neuer
- `tar`
- `curl`
- `tree-sitter-cli` `0.26.1` oder neuer über Scoop `main`
- Zig über Scoop `main`
- C-Compiler-Kommando `cc`
- C++-Compiler-Kommando `c++`

`tree-sitter-cli` wird bewusst **nicht über npm** installiert.

Zig stellt die eigentliche Compiler-Toolchain bereit. Der Bootstrap erzeugt dafür Scoop-Shims:

```text
cc  -> zig cc
c++ -> zig c++
```

Zusätzlich werden folgende Benutzer-Umgebungsvariablen verwaltet:

```text
CC=cc
CXX=c++
CRATE_CC_NO_DEFAULTS=1
```

`CRATE_CC_NO_DEFAULTS=1` ist unter Windows notwendig, weil der von Tree-sitter verwendete `cc-rs`-Buildpfad andernfalls für den Windows-Host automatisch das Target `x86_64-pc-windows-msvc` an den Compiler übergibt. Dieses Target wird von Zig in diesem Aufrufpfad nicht akzeptiert.

Die Kombination aus Scoop-Shims und diesen Umgebungsvariablen wurde praktisch mit der vollständigen Parser-Liste der verwendeten Neovim-Konfiguration getestet; alle angeforderten Tree-sitter-Parser wurden erfolgreich kompiliert.

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
├── external/
│   └── nvim/        # Git-Submodule: jayzone91/nvim
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

# Zentrale Theme-Konfiguration

Catppuccin Mocha ist die gemeinsame Designsprache der verwalteten Desktop-Umgebung. Die zentrale Palette liegt in:

```text
config/theme.psd1
```

Für die wichtigsten Desktop-Flächen gelten semantische Rollen:

| Rolle      | Catppuccin Mocha | Verwendung                       |
| ---------- | ---------------- | -------------------------------- |
| `Base`     | `#1e1e2e`        | gemeinsame Hauptfläche           |
| `Surface0` | `#313244`        | abgesetzte Controls und Flächen  |
| `Surface1` | `#45475a`        | Borders und Hover-Zustände       |
| `Text`     | `#cdd6f4`        | primärer Text                    |
| `Subtext0` | `#a6adc8`        | sekundärer Text                  |
| `Mauve`    | `#cba6f7`        | Akzent und aktiver Taskbar-Punkt |

Aktuell verwenden VS Code, Windows Terminal, Zebar und die über Windhawk gestaltete Windows-Taskbar `Base #1e1e2e` als Hauptfläche.

Windows Terminal verwendet das Catppuccin-Mocha-Farbschema ohne Acrylic und mit 100 Prozent Opazität, damit der tatsächliche Hintergrund exakt der gemeinsamen Base entspricht.

Die Taskbar wird durch den Windhawk-Mod **Windows 11 Taskbar Styler** gestaltet. Das integrierte Theme **RosePine** bleibt dabei die Layout-Basis; eigene `controlStyles` überschreiben gezielt die relevanten Farben mit Catppuccin Mocha. Der RosePine-Rahmen für das aktive Fenster wird zusätzlich durch einen kleinen Mauve-Punkt unter dem aktiven Icon ersetzt.

Das Startmenü wird durch **Windows 11 Start Menu Styler** ebenfalls auf Basis von **RosePine** gestaltet. Eigene Farb-Overrides setzen Hauptflächen auf Catppuccin `Base #1e1e2e`, abgesetzte Flächen auf `Surface0 #313244` und die Außenrahmen von Startmenü und Suchansicht auf `Surface1 #45475a`. Das fokussierte Suchfeld behält `Mauve #cba6f7` als gezielten Aktivitätsakzent.

Zebar besitzt derzeit weiterhin eigene CSS-Variablen für die Palette, und die Windhawk-Mod-Settings enthalten die benötigten Hex-Werte. Die spätere direkte Ableitung dieser Werte aus `config/theme.psd1` ist als Folgearbeit in der Roadmap dokumentiert.

---
# Konfigurations-Synchronisierung

Das Repository ist die Quelle der Wahrheit für verwaltete Konfigurationsdateien.

Es gilt projektweit folgende Regel:

- **Dateien** werden standardmäßig als NTFS-Hardlinks eingebunden.
- **Verzeichnisse** werden als NTFS-Junctions eingebunden.
- **Symbolic Links** sind ausschließlich als expliziter Kompatibilitäts-Fallback erlaubt, wenn eine Anwendung Hardlinks technisch nicht zuverlässig unterstützt.
- VS Code settings.json verwendet bewusst einen Symbolic Link, weil VS Code die Datei beim Speichern ersetzt und dadurch einen Hardlink auftrennt.

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
%USERPROFILE%\.glzr\zebar\settings.json
```

Beispiel für eine Junction:

```text
%USERPROFILE%\.glzr\zebar\windows-setup-bar
```

Kompatibilitätsausnahme für VS Code:

```text
%APPDATA%\Code\User\settings.json
    -> %USERPROFILE%\windows-setup\dotfiles\vscode\settings.json
```

Änderungen an den VS-Code-User-Settings werden dadurch direkt in der versionierten Repository-Datei gespeichert. Der Symbolic Link wurde gewählt, weil VS Code einen NTFS-Hardlink beim Speichern der Settings durch das Ersetzen der Datei auftrennt.

Bestehende verwaltete Verknüpfungen werden beim nächsten Setup-Durchlauf auf die für die jeweilige Anwendung vorgesehene Link-Art migriert. Standardmäßig sind das Hardlinks für Dateien und Junctions für Verzeichnisse; dokumentierte Kompatibilitätsausnahmen wie VS Code verwenden einen Symbolic Link.

Generierte Inhalte liegen unter `.generated/` und werden nicht committed. Generator-Code selbst bleibt versioniert.

Neben tatsächlich generierten Dateien enthält `.generated/state/` lokale Zustandsmarker für einmalige oder bewusst interaktive Initialisierungsschritte. Diese Marker verhindern, dass bereits abgeschlossene Benutzerinteraktionen bei jedem `just update` erneut ausgeführt werden.

---

# Paketverwaltung

Die deklarative Paketliste liegt in `config/packages.psd1`. Paketgruppen bleiben nach ihrem fachlichen Zweck organisiert; `Source` bestimmt, welcher Paketmanager verwendet wird.

Unterstützt werden:

- `winget`
- `msstore`
- `chocolatey`
- `scoop`

Chocolatey und Scoop werden vom Bootstrap bei Bedarf automatisch installiert und bei jedem Lauf selbst aktualisiert.

Für Scoop wird der Bucket direkt am Paket angegeben. Dadurch ist auch bei Paketen, die in mehreren Buckets vorkommen, eindeutig definiert, welche Variante verwendet werden soll. Eigene Buckets können zusätzlich eine `BucketUrl` angeben. Benötigte Buckets werden aus allen Scoop-Paketen der Konfiguration abgeleitet und vor der Paketinstallation bereitgestellt.

Nach der Paketphase bereinigt der Bootstrap unterstützte Paketmanager-Caches. Bei Scoop werden außerdem alte App-Versionen entfernt. Die Cleanup-Logik läuft in einem `finally`-Block und wird damit auch ausgeführt, wenn innerhalb der Paketphase ein Fehler auftritt.

## Home Office

Die Home-Office-Paketgruppe stellt die benötigten lokalen Clients bereit:

- Remote Desktop Manager über Winget
- FileZilla Client über Chocolatey
- PCVisit Supporter Modul über einen eigenen Installationsworkflow
- OpenVPN als bereits vorhandene Abhängigkeit

Remote Desktop Manager verwendet eine externe Datenbank als zentrale Quelle für RDP-, VPN-, FTP-/SFTP- und weitere Verbindungsziele. Diese Verbindungsdaten und Credentials werden deshalb nicht im Repository verwaltet.

PCVisit wird nur installiert, wenn das Supporter Modul fehlt. Updates werden vollständig dem eingebauten PCVisit-Updater überlassen.

FileZilla wird in komorebi vollständig ignoriert. Das ist erforderlich, weil Remote Desktop Manager FileZilla zunächst als externes Fenster startet und anschließend in einen RDM-Tab einbettet. Ohne die Ignore-Regel würde komorebi einen verwaisten Tiling-Slot zurücklassen.

---

## PowerToys und Command Palette

PowerToys wird über die zentrale Paketverwaltung installiert. Der gewünschte PowerToys-Zustand liegt deklarativ in `config/powertoys.psd1` und wird vom Bootstrap angewendet.

Als primärer Launcher dient die PowerToys Command Palette mit `Alt + Space`. Für die Datei- und Ordnersuche wird Everything über die Command-Palette-Erweiterung verwendet; der eingebaute Files-Provider ist deaktiviert, damit keine doppelten Suchergebnisse entstehen. Die Command Palette verwendet Acrylic mit der Catppuccin-Mocha-Base `#1E1E2E` bei 100 % Farbintensität.

Aktiv bleiben gezielt:

- Command Palette
- Advanced Paste
- Color Picker
- File Locksmith
- Find My Mouse
- PowerRename

Advanced Paste verwendet `Ctrl + Shift + V` für Nur-Text und `Ctrl + Shift + M` für Markdown. Find My Mouse wird durch zweimaliges Drücken der linken `Ctrl`-Taste aktiviert.

Nicht benötigte PowerToys-Module werden deklarativ deaktiviert. Bei wiederholten Bootstrap-Läufen wird PowerToys nur dann beendet und neu gestartet, wenn tatsächlich verwalteter Konfigurations-Drift vorliegt.

---
# CLI-Tools und PowerShell-Workflow

Die Windows-Shell orientiert sich an den Abbreviations der Fish-Konfiguration der Linux-Workstation.

Installiert und über `config/packages.psd1` verwaltet werden:

- Neovim Nightly über Scoop aus dem Bucket `versions`
- ripgrep (`rg`)
- eza
- fd
- bat
- fzf
- jq
- zoxide

Neovim Nightly dient gleichzeitig als realer Akzeptanztest für die Scoop-Bucket-Logik. Der Bootstrap erkennt den benötigten `versions`-Bucket und stellt ihn bei Bedarf bereit.

## Fish-artige Abbreviations

Das PowerShell-Profil verwendet PSReadLine, um kurze Eingaben beim Drücken von Space oder Enter sichtbar in ihre Langform zu expandieren. Dadurch bleibt die History verständlich und das Verhalten ähnelt Fish `shellAbbrs`.

Beispiele:

```text
ls   -> eza --icons --group-directories-first
ll   -> eza -lah --icons --group-directories-first
la   -> eza -a --icons --group-directories-first
lt   -> eza --tree --icons --group-directories-first

cat  -> bat
grep -> rg
find -> fd

gs   -> git status
gaa  -> git add --all
gcm  -> git commit -m
glog -> git log --oneline --graph --decorate --all
```

Auch `..`, `...` und `....` werden wie in der Fish-Konfiguration expandiert.

## Projektspezifische Commands

Das PowerShell-Profil erkennt den Git-Root des aktuellen Arbeitsverzeichnisses. Innerhalb von `~/windows-setup` wird dynamisch das Modul `WindowsSetupProjectCommands` bereitgestellt.

Dadurch stehen dort zusätzlich die kurzen Commands zur Verfügung:

```text
update          -> just update
check           -> just check
desktop-restart -> just desktop-restart
```

Beim Verlassen des Repositories wird das dynamische Modul wieder entfernt. Die Commands stehen damit nicht global in anderen Projekten zur Verfügung.

Die Aktualisierung erfolgt über den Prompt-Zyklus und funktioniert dadurch unabhängig davon, ob das Verzeichnis über `z`, `cd`, `Set-Location` oder einen anderen Mechanismus gewechselt wurde.

---
# Standard-Apps und Dateizuordnungen

Windows schützt benutzerspezifische Standard-App-Zuordnungen und erlaubt deren direkte Änderung durch normale Skripte nicht zuverlässig.

Das Setup automatisiert deshalb nicht die geschützten `UserChoice`-Registry-Einträge, sondern verwendet einen interaktiven Initialisierungsworkflow.

Für Anwendungen mit konfigurierbaren Standard-Dateizuordnungen gilt:

1. Das Setup ermittelt nach Möglichkeit die Windows-App-ID der Anwendung.
2. Die anwendungsspezifische Seite unter **Einstellungen → Apps → Standard-Apps** wird geöffnet.
3. Falls keine passende App-ID ermittelt werden kann, wird die allgemeine Standard-App-Seite geöffnet.
4. Der Bootstrap wartet, bis das Einstellungsfenster tatsächlich geschlossen wurde.
5. Anschließend wird die Konfiguration als initialisiert markiert.
6. Bei späteren `just update`-Läufen wird die interaktive Konfiguration übersprungen.

Die Erkennung des geöffneten Einstellungsfensters berücksichtigt auch von Windows gehostete `SystemSettings`-Child-Windows. Dadurch läuft der Bootstrap erst weiter, wenn das sichtbare Windows-Einstellungsfenster tatsächlich geschlossen wurde.

Der Initialisierungsstatus wird unter:

```text
.generated/state/default-apps/
```

gespeichert.

Beispiel:

```text
.generated/state/default-apps/nanazip.initialized
```

Soll die Standard-App-Konfiguration einer Anwendung erneut durchgeführt werden, kann der entsprechende Marker gelöscht werden.

Für NanaZip beispielsweise:

```powershell
Remove-Item `
    ".\.generated\state\default-apps\nanazip.initialized"
```

Beim nächsten `just update` wird die Konfiguration erneut geöffnet.

Dieser Mechanismus ist bewusst generisch aufgebaut und kann auch für weitere Anwendungen verwendet werden, deren Standard-Dateizuordnungen beim ersten Setup durch den Benutzer bestätigt werden müssen.

## NanaZip

NanaZip wird über `winget` installiert und als bevorzugter Archivmanager verwendet.

Beim ersten Setup versucht der Bootstrap, NanaZips AppX-/MSIX-Registrierung dynamisch zu ermitteln. Dazu werden der NanaZip-ProgID und die zugehörige `AppUserModelID` aus der Windows-Registrierung bestimmt.

Kann die `AppUserModelID` ermittelt werden, öffnet der Bootstrap direkt:

```text
Einstellungen
└── Apps
    └── Standard-Apps
        └── NanaZip
```

Kann die ID nicht zuverlässig ermittelt werden, wird stattdessen die allgemeine Standard-App-Seite geöffnet. Der Benutzer kann dort manuell nach NanaZip suchen.

In beiden Fällen wartet der Bootstrap auf das Schließen der Windows-Einstellungen.

NanaZip soll insbesondere klassische Archivformate wie ZIP, 7z, RAR, TAR und verwandte Formate übernehmen.

Windows-Image- und Datenträgerformate wie ISO, VHD/VHDX und WIM werden bewusst nicht pauschal NanaZip zugeordnet, da Windows dafür eigene Mount- und Image-Funktionen bereitstellt.

Nach erfolgreicher Initialisierung wird:

```text
.generated/state/default-apps/nanazip.initialized
```

angelegt.

Dadurch bleibt `just update` bei späteren Durchläufen nicht unnötig interaktiv.

# Raycast

Raycast ersetzt die PowerToys Command Palette als primären Launcher. Der globale Hotkey ist:

```text
Win + Space
```

PowerToys bleibt installiert, wird aber nicht mehr als Launcher verwendet. Command Palette und PowerToys Run sind deaktiviert; weiterhin genutzt werden unter anderem Advanced Paste, File Locksmith, Find My Mouse und PowerRename.

Everything bleibt als eigenständiger Index/Service installiert und wird über die Raycast-Extension `everything-search` verwendet. Der frühere Command-Palette-spezifische Everything-Provider wird nicht mehr verwaltet.

## Installation und Updates

Raycast wird über den Microsoft Store mit der Produkt-ID:

```text
9PFXXSHC64H3
```

installiert und über den normalen Paketworkflow bei `just update` auf Updates geprüft.

## Versionierter Desired State

Die generische, nicht sensible Raycast-Konfiguration liegt unter:

```text
dotfiles/raycast/config.json
```

Versioniert werden ausschließlich bewusst erlaubte, reproduzierbare Bereiche:

- allgemeine Launcher-/UI-Einstellungen einschließlich `Win + Space`
- `navigationBindings` und `pageNavigationKeys`
- das vollständige Catppuccin-Mocha-Theme
- installierte Raycast-Store-Extensions anhand ihrer UUID
- Enabled-State der Store-Extensions
- relevante Command-Einstellungen der versionierten Store-Extensions

Nicht versioniert werden insbesondere AI-Inhalte, Clipboard History, Notes, MCP-Server, Quicklinks, Snippets, User Activity oder andere persönliche Laufzeitdaten. Bekannte Secret-/Credential-Felder werden durch den Sanitizer zusätzlich abgelehnt.

Aktuell umfasst der Desired State die Extensions:

- Everything Search
- Visual Studio Code
- ChatGPT
- Google Search
- Shell
- Zen Browser
- Lucide Icons Search

Die Liste ist dynamisch. Weitere später installierte Store-Extensions werden bei einem zukünftigen erfolgreichen Export automatisch in den generischen Desired State aufgenommen.

## Lokale Backup-Konfiguration

Der lokale Raycast-Transportworkflow wird in:

```text
config/raycast.psd1
```

konfiguriert.

Dort werden festgelegt:

- `ExportPassword`: frei änderbares Passwort für das lokale `.rayconfig`-Transportformat
- `BackupPath`: der in Raycast konfigurierte Backup-Ordner

Der Backup-Pfad wird ausdrücklich aus dieser Datei gelesen, da Raycast den Speicherort frei wählen lässt. Umgebungsvariablen wie `%USERPROFILE%` können verwendet werden.

Das konfigurierte Exportpasswort ist in diesem Projekt bewusst **kein Repository-Secret**. Sicherheit entsteht dadurch, dass nur der sanitizte Desired State committed wird. Vollständige `.rayconfig`-Archive können persönliche und sensible Daten enthalten und werden von diesem Setup als **lokale Archive** behandelt.

Was ein Benutzer außerhalb dieses Setups später mit dem lokalen Archivordner macht, ist nicht Bestandteil des Sicherheitsmodells dieses Repositories.

## Erstinitialisierung

Bei der ersten Raycast-Initialisierung weist der Bootstrap auf das lokale Archivmodell hin und verlangt eine ausdrückliche Bestätigung.

Der lokale Statusmarker lautet:

```text
.generated/state/default-apps/raycast.initialized
```

Existiert bereits ein lokales Raycast-Backup, wird dieses entschlüsselt, sanitiziert und als Ausgangszustand übernommen.

Auf einem frischen System ohne vorhandenes Backup erzeugt der Bootstrap einmalig ein lokales Importarchiv unter:

```text
.generated/raycast/raycast-import.rayconfig
```

Der Benutzer wird anschließend durch den Raycast-Import sowie die Einrichtung von Daily Backup, Backup Location und Auto-Delete geführt. Erst nach erfolgreicher Bestätigung wird der Initialisierungsmarker gesetzt.

Nach erfolgreicher Initialisierung wird bei normalen `just update`-Läufen **kein neues Restore-Archiv** erzeugt. Der Bootstrap:

1. prüft Raycast über den Paketworkflow auf Updates,
2. liest das neueste `.rayconfig` aus dem konfigurierten `BackupPath`,
3. entschlüsselt und sanitiziert ausschließlich die erlaubten Einstellungen,
4. aktualisiert `dotfiles/raycast/config.json` nur bei relevantem Drift.

Ein wiederholter Lauf wurde praktisch verifiziert und meldet bei unverändertem Zustand:

```text
[OK] Raycast wurde bereits initialisiert.
[OK] Raycast Desired State unverändert.
```

---
# Desktop Experience

## Zielbild

```text
Arch                           Windows
────────────────────────────────────────────────
Hyprland                       komorebi
Waybar                         Zebar
Focus follows mouse            masir
Fuzzel                         Raycast
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
├── Archive Manager
│   └── NanaZip
│
├── Launcher / Search
│   ├── Raycast
│   └── Everything
│
├── Windows Shell Styling (teilweise umgesetzt)
│   └── Windhawk
│       ├── Taskbar Styler (umgesetzt)
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
- App-Shortcuts über whkd:
  - Win + B startet Zen Browser
  - Win + T startet Windows Terminal
  - Win + Shift + T startet Windows Terminal erhöht und löst die Windows-UAC-Abfrage aus
- reproduzierbare Konfiguration unter `dotfiles/komorebi/`
- Konfigurationsdateien als Hardlinks
- Autostart über die Windows-Aufgabenplanung
- erhöhte Ausführung, damit auch erhöhte Fenster getiled werden können

## Focus Follows Mouse mit masir

`LGUG2Z.masir` ergänzt komorebi um Focus Follows Mouse.

masir nutzt seine automatische komorebi-Integration und wird gemeinsam mit komorebi/whkd über den erhöhten Desktop-Scheduled-Task gestartet.

Der Desktop-Neustart ist zentral über `Stop-WindowsDesktopEnvironment`, `Start-WindowsDesktopEnvironment` und `Restart-WindowsDesktopEnvironment` orchestriert. Zebar besitzt weiterhin einen separaten, nicht erhöhten Scheduled Task.

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
- vollständigen Desired-State vor Änderungen prüfen
- OneCommander bei unverändertem Zustand geöffnet lassen

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
| Raycast             | natives Custom Theme + Desired State          |
| Taskbar             | Windhawk Taskbar Styler + RosePine/Catppuccin |
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
- ChatGPT
- Raycast
- OpenVPN
- Logitech G HUB
- komorebi
- whkd
- masir
- Zebar
- OneCommander
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
- Logitech G HUB auf einem neuen System einmalig initialisieren; danach keine automatische DB-Synchronisierung
- Windows- und Entwicklungs-Konfiguration erneut anwenden
- bereits initialisierte interaktive Standard-App-Konfigurationen überspringen
- Zebar-Abhängigkeiten und Build sicherstellen
- OneCommander-Desired-State prüfen und nur bei tatsächlichem Drift anwenden
- Raycast auf Updates prüfen und bei bereits erfolgter Initialisierung das neueste lokale Backup in den generischen Desired State sanitizen
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
- `just desktop-restart` als manueller Einstiegspunkt für die Desktop-Orchestrierung
- G-HUB-Datenbank nach der Erstinitialisierung nur bewusst über `just ghub-backup` / `just ghub-restore` behandeln
- laufende Anwendungen nur schließen, wenn eine tatsächliche Änderung dies erfordert
- Execution Policy nur auf Prozessebene setzen
- keine dauerhafte Änderung der globalen PowerShell Execution Policy
- Dateien per NTFS-Hardlink
- Verzeichnisse per NTFS-Junction
- keine Symbolic Links für verwaltete Dotfiles
- generierte Inhalte und lokaler Initialisierungsstatus ausschließlich unter `.generated/`
- einmalige Benutzerinteraktionen über lokale State-Marker idempotent machen
- geschützte Windows-Standard-App-Zuordnungen nicht durch inoffizielle `UserChoice`-Manipulation erzwingen
- für Standard-App-Konfiguration nach Möglichkeit direkt die anwendungsspezifische Windows-Einstellungsseite öffnen
- bei erforderlicher Benutzerinteraktion auf das tatsächliche Schließen des Einstellungsfensters warten
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

1. weitere Windhawk-Shell-Mods für Startmenü und Notification Center
2. Taskbar-Auto-Hide-Tuning
3. Lock Keys Notifier mit Catppuccin-Anpassung
4. verbleibendes Catppuccin-OSD für Volume, Mute, Brightness und Media
5. Gaming
6. Logging, Tests und weitere Qualitätssicherung
