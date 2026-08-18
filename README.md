# Windows Setup

Automatisiertes Windows-11-Setup für Entwicklung, Gaming, Alltag und Home Office.

Das Repository richtet einen Rechner nicht nur ein, sondern verwaltet große Teile der Installation und Konfiguration anschließend weiter als **Desired State**. Ein erneuter Bootstrap prüft den aktuellen Zustand und ändert möglichst nur das, was tatsächlich abweicht.

> [!WARNING]
> Dieses Repository ist für **meine persönliche Windows-Umgebung** gebaut. Es installiert Software, verändert Windows-Einstellungen, richtet Scheduled Tasks ein, verwaltet Dotfiles, konfiguriert Laufwerke und passt Teile der Desktop-Oberfläche an.
>
> Vor einer Verwendung auf einem anderen Rechner sollten mindestens `config/`, `secrets/`, Laufwerkspfade und Paketgruppen geprüft werden. Blindes `irm | iex` aus fremden Repositories bleibt eine bemerkenswert effiziente Methode, seinen Nachmittag zu ruinieren.

## Zielbild

Der Desktop orientiert sich optisch an macOS 26 / Liquid Glass, ohne Windows-Systemdateien dauerhaft zu patchen.

| Bereich | Lösung |
| --- | --- |
| Top Bar / Dock | Seelen UI |
| Window Management | PowerToys FancyZones |
| Launcher | Raycast + Everything |
| Dateimanager | Files |
| Archivmanager | NanaZip |
| Browser | Vivaldi (Hauptbrowser) / Zen (Firefox-WebDev-Testbrowser) |
| Lock-Key-OSD | FluentFlyout |
| Volume / Media | Seelen UI |
| Systemicons | Windhawk Resource Redirect |
| Editor | VS Code / Neovim |
| Terminal | Windows Terminal / Nushell / Starship |

Vivaldi ist der Hauptbrowser und erhält über versionierte `window.html`, `safari.js` und CSS-Dotfiles ein Safari-/macOS-26-orientiertes Layout mit Liquid-Glass-Material. Zen bleibt bewusst installiert und konfiguriert und dient als Firefox-basierter Testbrowser für Webentwicklung. Zen verwendet weiterhin sein natives Standard-Theme. Catppuccin ist keine globale Designvorgabe und bleibt nur dort erhalten, wo es bewusst für einzelne Entwicklungswerkzeuge eingesetzt wird.

## Was der Bootstrap verwaltet

Der Bootstrap deckt unter anderem folgende Bereiche ab:

- Windows-Grundkonfiguration, Debloat, Updates und Treiber
- Paketinstallation über Winget, Microsoft Store, Chocolatey und Scoop
- Entwicklungsumgebung für PowerShell, Node.js, Bun, Go und .NET/C#
- Git, GitHub CLI, VS Code und Neovim
- Terminal- und CLI-Werkzeuge
- Desktop, Launcher, Dateimanager und Systemicons
- Gaming-Launcher und vorbereitete Game-Libraries
- Home-Office-Werkzeuge
- Browser
- eM Client inklusive verschlüsseltem Restore-Artefakt
- Logitech G HUB Backup/Restore
- ReFS Dev Drive und Games-Laufwerk
- Windows-Standard-Apps
- automatische wöchentliche Wartung

Die vollständigen technischen Details und offenen Arbeiten stehen derzeit in [`roadmap.md`](roadmap.md).

## Wichtige Regeln

### Repository ist Source of Truth

Versionierbare Konfiguration soll aus diesem Repository reproduzierbar wiederhergestellt werden können. Manuelle Änderungen an verwalteten Dateien können beim nächsten Bootstrap erkannt oder überschrieben werden.

### Wiederholbare Ausführung

`bootstrap.ps1` ist der zentrale Setup- und Wartungseinstieg. Derselbe Workflow wird für Neuinstallation und spätere Aktualisierungen verwendet.

Der Bootstrap:

- führt keine automatischen Git-Commits oder Pushes aus
- startet Windows nicht automatisch neu
- schließt laufende Anwendungen möglichst nur bei tatsächlichem Konfigurations-Drift
- verändert die globale PowerShell Execution Policy nicht

### Administratorrechte

Manuelle Bootstrap-Läufe werden mit Windows `sudo` gestartet.

Die PowerShell Execution Policy wird ausschließlich für den jeweiligen Prozess mit `-ExecutionPolicy Bypass` gesetzt. Es gibt bewusst kein globales `Set-ExecutionPolicy`.

### Dotfiles

Standard:

- einzelne Dateien: **NTFS-Hardlinks**
- Verzeichnisse: **NTFS-Junctions**
- Symbolic Links: nur als dokumentierter Kompatibilitäts-Fallback

VS Code, Windows Terminal und Seelen verwenden für ihre `settings.json` bewusst Symbolic Links, weil diese Anwendungen beim Speichern Hardlinks auftrennen können.

### Lokaler Zustand

Generierte und lokale Zustände liegen unter `.generated/` und werden nicht committed.

Dazu gehören unter anderem Initialisierungsmarker, Fingerprints, temporäre Exporte und andere reproduzierbare Laufzeitdaten.

### Secrets

Secrets gehören ausschließlich in die dafür vorgesehenen verschlüsselten Dateien unter `secrets/`.

Unverschlüsselte Zugangsdaten dürfen nicht committed werden.

## Installation

Voraussetzungen:

- Windows 11
- funktionierendes `winget`
- Internetzugang
- Administratorrechte
- Repository-spezifische Konfiguration geprüft

PowerShell als Administrator:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

`init.ps1` installiert bei Bedarf Git, klont das Repository nach:

```text
%USERPROFILE%\windows-setup
```

und startet anschließend den Bootstrap in einem eigenen PowerShell-Prozess.

## Manuelle Wartung

Repository:

```powershell
cd ~/windows-setup
```

Normaler stiller Lauf:

```powershell
sudo just update
```

Nur Warnungen und Fehler:

```powershell
sudo just update-warning
```

Vollständige Ausgabe für Tests und Diagnose:

```powershell
sudo just update-log
```

Performance-Messung:

```powershell
sudo just update-performance
```

Codeprüfung:

```powershell
just check
```

Desktop kontrolliert neu starten:

```powershell
just desktop-restart
```

Verfügbare Recipes:

```powershell
just --list
```

## Wichtige Pfade

| Pfad | Zweck |
| --- | --- |
| `init.ps1` | Erstinstallation und Repository-Bootstrap |
| `bootstrap.ps1` | zentraler Setup-/Wartungseinstieg |
| `bootstrap/` | interne Bootstrap-Implementierung |
| `config/` | deklarative Konfiguration und Paketdefinitionen |
| `modules/` | fachliche Setup-Module |
| `dotfiles/` | versionierte Anwendungskonfiguration |
| `assets/` | statische Projektressourcen |
| `scripts/` | eigenständige Hilfs- und Wartungsskripte |
| `secrets/` | SOPS-verschlüsselte Secrets und Restore-Artefakte |
| `external/` | externe Repository-Abhängigkeiten/Submodule |
| `.generated/` | lokaler, nicht versionierter Laufzeit-/State-Bereich |
| `Justfile` | Bedienoberfläche für wiederkehrende Aktionen |
| `roadmap.md` | Architekturentscheidungen, Projektstatus und offene Arbeiten |
| `notes.md` | ergänzende Projektnotizen |

## Wiederherstellungs- und Übergabepfade

Einige Konfigurationen werden bewusst über lokale Übergabedateien oder externe Backups in den Bootstrap eingespielt.

| Zweck | Pfad / Ort | Verhalten |
| --- | --- | --- |
| SOPS/age Private Key | `%APPDATA%\sops\age\keys.txt` | Lokale age-Identity für SOPS. Darf niemals ins Repository committed werden. |
| age Recovery Key | Apple Passwords: Eintrag `mac-config age recovery key` | Enthält den vollständigen `AGE-SECRET-KEY-1...` zur Wiederherstellung der lokalen `keys.txt`. |
| Raycast Backups | `BackupPath` aus `config/raycast.psd1`; aktuell `%USERPROFILE%\Documents` | Der Bootstrap verarbeitet automatisch die neueste `*.rayconfig` in diesem Verzeichnis und aktualisiert daraus den bereinigten Desired State. |
| Raycast Erstimport | `%USERPROFILE%\windows-setup\.generated\raycast\raycast-import.rayconfig` | Wird auf einem frischen System aus dem versionierten Desired State erzeugt und einmalig manuell in Raycast importiert. |
| eM Client neuer Settings-Export | `%USERPROFILE%\windows-setup\.generated\emclient\settings.xml` | Hier muss ein neuer passwortgeschützter eM-Client-Settings-Export abgelegt werden. Der nächste Bootstrap verschlüsselt ihn automatisch mit SOPS. |
| eM Client verschlüsseltes Backup | `secrets\emclient-settings.sops.xml` | Versioniertes, SOPS-verschlüsseltes Restore-Artefakt. |
| eM Client Import-Passwort | `secrets\mail.sops.json` → `emclient.import_password` | Ausschließlich verschlüsselt versioniert; wird beim Restore temporär in die Zwischenablage gelegt. |
| Raycast Desired State | `dotfiles\raycast\config.json` | Bereinigte, versionierbare Konfiguration; vollständige persönliche `.rayconfig`-Backups bleiben lokal. |

### SOPS / age auf einem neuen Rechner

Der private age-Schlüssel muss lokal unter folgendem Pfad verfügbar sein:

```text
%APPDATA%\sops\age\keys.txt
```

Der Recovery-Key ist zusätzlich in **Apple Passwords** unter folgendem Eintrag hinterlegt:

```text
mac-config age recovery key
```

Gespeichert wird dort der vollständige Schlüssel im Format:

```text
AGE-SECRET-KEY-1...
```

Die lokale `keys.txt` und der private Schlüssel dürfen niemals committed werden.

### Raycast Backup-Workflow

Der überwachte Backup-Pfad wird in `config/raycast.psd1` über `BackupPath` festgelegt. Aktuell:

```text
%USERPROFILE%\Documents
```

Raycast muss seine Daily Backups als `.rayconfig` in dieses Verzeichnis schreiben. Der Bootstrap nimmt automatisch die **neueste** Datei und erzeugt daraus den sanitizten Desired State unter:

```text
dotfiles\raycast\config.json
```

Vollständige Raycast-Backups bleiben ausschließlich lokal.

### eM-Client Backup-Workflow

Nach Änderungen an Accounts oder relevanten eM-Client-Einstellungen einen vollständigen, passwortgeschützten Settings-Export exakt hier speichern:

```text
%USERPROFILE%\windows-setup\.generated\emclient\settings.xml
```

Beim nächsten Bootstrap wird die Datei automatisch nach:

```text
secrets\emclient-settings.sops.xml
```

SOPS-verschlüsselt übernommen. Erst nach erfolgreicher Verschlüsselung wird die lokale Klartextdatei entfernt.

---
## Laufwerke

Das Setup verwendet bewusst zusätzliche Laufwerke und ist deshalb nicht ohne Prüfung auf beliebige Rechner übertragbar.

Wichtige projektweite Annahmen:

- Repository: `%USERPROFILE%\windows-setup`
- Dev Drive: `D:`
- Games: `G:`
- Game Libraries: `G:\Games\`

Die tatsächlichen Definitionen in `config/` sind maßgeblich.

## Persönliche / interaktive Schritte

Nicht alles lässt sich sinnvoll automatisieren. Einige Schritte benötigen bewusst Benutzerinteraktion, beispielsweise:

- Auswahl von Windows-Standard-Apps
- erstmalige Konfiguration bestimmter Gaming-Launcher
- eM-Client-Import
- G-HUB-Konfigurationspflege
- einzelne anwendungsabhängige Initialisierungen

Erfolgreich abgeschlossene einmalige Schritte können über State-Marker unter `.generated/state/` gespeichert werden.

## Entwicklung

Vor Änderungen:

```powershell
just check
```

Nach Änderungen am Setup:

```powershell
sudo just update-log
just check
```

Ein Roadmap-Punkt gilt erst als abgeschlossen, wenn die Änderung praktisch getestet wurde.

Die detaillierten Architekturentscheidungen, verworfenen Ansätze, Akzeptanzkriterien und offenen Aufgaben stehen in [`roadmap.md`](roadmap.md).
