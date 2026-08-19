# Windows Setup

Automatisiertes Windows-11-Setup für Entwicklung, Gaming, Alltag und Home Office.

Das Repository verwaltet Installation und Konfiguration als **Desired State**. Stabilität, Wartbarkeit und native Windows-Kompatibilität haben Vorrang vor optischen Anpassungen.

> [!WARNING]
> Dieses Repository ist für meine persönliche Windows-Umgebung gebaut. Vor einer Verwendung auf einem anderen Rechner müssen mindestens `config/`, `secrets/`, Laufwerkspfade und Paketgruppen geprüft werden.

## Zielbild

Das System bleibt so nah wie möglich an stabilen, nativen Windows-Komponenten.

| Bereich                     | Lösung                                             |
| --------------------------- | -------------------------------------------------- |
| Desktop / Taskleiste        | Windows 11                                         |
| Window Management           | Windows Snap + PowerToys FancyZones                |
| Launcher                    | Raycast + Everything                               |
| Dateimanager                | Windows File Explorer                              |
| Archivmanager               | NanaZip                                            |
| Browser                     | Vivaldi (nativ) / Zen (Firefox-WebDev-Testbrowser) |
| Volume / Media / System-OSD | Windows 11                                         |
| Editor                      | VS Code / Neovim                                   |
| Terminal                    | Windows Terminal + PowerShell 7 + Starship         |

Bewusst entfernt wurden Seelen UI, FluentFlyout, Windhawk, Files, Nushell und Warp. Vivaldi verwendet keine repositoryverwalteten Custom-HTML-/CSS-/JS-Modifikationen mehr.

## Was der Bootstrap verwaltet

- Windows-Grundkonfiguration, Debloat, Updates und Treiber
- Paketinstallation über Winget, Microsoft Store, Chocolatey und Scoop
- Entwicklungsumgebung für PowerShell, Node.js, Bun, Go und .NET/C#
- Git, GitHub CLI, VS Code und Neovim
- Windows Terminal und CLI-Werkzeuge
- Raycast, Everything und PowerToys
- Gaming-Launcher und Game-Libraries
- Home-Office-Werkzeuge
- Vivaldi, Zen und Chrome Beta
- eM Client inklusive verschlüsseltem Restore-Artefakt
- Logitech G HUB Backup/Restore
- ReFS Dev Drive und Games-Laufwerk
- Windows-Standard-Apps
- automatische wöchentliche Wartung

Die vollständigen technischen Details und offenen Arbeiten stehen in [`roadmap.md`](roadmap.md).

## Verbindliche Grundregel

**Systemstabilität steht über Design, Animationen und optischer Annäherung an andere Betriebssysteme.**

Zusätzliche Shells, Compositoren, UI-Hooks, Resource-Redirects und Browser-UI-Modifikationen werden nur eingesetzt, wenn ein konkreter funktionaler Nutzen besteht und Stabilität praktisch nachgewiesen wurde. Rein optische Änderungen rechtfertigen kein zusätzliches Stabilitätsrisiko.

## Wichtige Regeln

### Repository ist Source of Truth

Versionierbare Konfiguration soll aus diesem Repository reproduzierbar wiederhergestellt werden können.

### Wiederholbare Ausführung

`bootstrap.ps1` ist der zentrale Setup- und Wartungseinstieg.

Der Bootstrap:

- führt keine automatischen Git-Commits oder Pushes aus
- startet Windows nicht automatisch neu
- schließt laufende Anwendungen möglichst nur bei tatsächlichem Konfigurations-Drift
- verändert die globale PowerShell Execution Policy nicht

### Administratorrechte

Manuelle Bootstrap-Läufe werden mit Windows `sudo` gestartet.

Die PowerShell Execution Policy wird ausschließlich für den jeweiligen Prozess mit `-ExecutionPolicy Bypass` gesetzt.

### Dotfiles

Standard:

- einzelne Dateien: **NTFS-Hardlinks**
- Verzeichnisse: **NTFS-Junctions**
- Symbolic Links: nur als dokumentierter Kompatibilitäts-Fallback

VS Code und Windows Terminal verwenden für ihre `settings.json` bewusst Symbolic Links, weil diese Anwendungen beim Speichern Hardlinks auftrennen können.

### Lokaler Zustand

Generierte und lokale Zustände liegen unter `.generated/` und werden nicht committed.

### Secrets

Secrets gehören ausschließlich in die dafür vorgesehenen verschlüsselten Dateien unter `secrets/`.

## Installation

Voraussetzungen:

- Windows 11
- funktionierendes `winget`
- Internetzugang
- Administratorrechte

PowerShell als Administrator:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

## Manuelle Wartung

```powershell
cd ~/windows-setup
sudo just update
```

Diagnose:

```powershell
sudo just update-warning
sudo just update-log
sudo just update-performance
just check
```

Weitere Recipes:

```powershell
just --list
```

## Wichtige Pfade

| Pfad            | Zweck                                                        |
| --------------- | ------------------------------------------------------------ |
| `init.ps1`      | Erstinstallation und Repository-Bootstrap                    |
| `bootstrap.ps1` | zentraler Setup-/Wartungseinstieg                            |
| `bootstrap/`    | interne Bootstrap-Implementierung                            |
| `config/`       | deklarative Konfiguration und Paketdefinitionen              |
| `modules/`      | fachliche Setup-Module                                       |
| `dotfiles/`     | versionierte Anwendungskonfiguration                         |
| `assets/`       | statische Projektressourcen                                  |
| `scripts/`      | Hilfs- und Wartungsskripte                                   |
| `secrets/`      | SOPS-verschlüsselte Secrets und Restore-Artefakte            |
| `external/`     | externe Repository-Abhängigkeiten/Submodule                  |
| `.generated/`   | lokaler, nicht versionierter Laufzeit-/State-Bereich         |
| `Justfile`      | Bedienoberfläche                                             |
| `roadmap.md`    | Architekturentscheidungen, Projektstatus und offene Arbeiten |

## Wiederherstellungs- und Übergabepfade

| Zweck                            | Pfad / Ort                                            |
| -------------------------------- | ----------------------------------------------------- |
| SOPS/age Private Key             | `%APPDATA%\sops\age\keys.txt`                         |
| age Recovery Key                 | Apple Passwords: `mac-config age recovery key`        |
| Raycast Backups                  | `BackupPath` aus `config/raycast.psd1`                |
| Raycast Erstimport               | `.generated\raycast\raycast-import.rayconfig`         |
| eM Client neuer Settings-Export  | `.generated\emclient\settings.xml`                    |
| eM Client verschlüsseltes Backup | `secrets\emclient-settings.sops.xml`                  |
| eM Client Import-Passwort        | `secrets\mail.sops.json` → `emclient.import_password` |
| Raycast Desired State            | `dotfiles\raycast\config.json`                        |

## Laufwerke

- Repository: `%USERPROFILE%\windows-setup`
- Dev Drive: `D:`
- Games: `G:`
- Game Libraries: `G:\Games\`

## Entwicklung

Vor Änderungen:

```powershell
just check
```

Nach Änderungen:

```powershell
just check
sudo just update-log
```

Ein Roadmap-Punkt gilt erst als abgeschlossen, wenn die Änderung praktisch getestet wurde.
