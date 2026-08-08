# Windows Setup

Automatisiertes und reproduzierbares Setup für meine Windows-Arbeitsumgebung.

Das Repository installiert und konfiguriert unter anderem:

- Basissoftware und System-Tools
- Entwicklungswerkzeuge
- Treiber und Treiber-Tools
- PowerShell, Nushell und Windows Terminal
- Git
- Node.js, Bun und Go
- Visual Studio Code
- Codex CLI
- Chrome Beta
- Zen Browser
- Browser-Erweiterungen und Zen Mods
- Windows-Einstellungen
- HDR und Wallpaper
- Apple-Passwort-Voraussetzungen

## Installation

Eine **PowerShell als Administrator** öffnen und folgenden Befehl ausführen:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

`init.ps1` übernimmt anschließend automatisch:

1. Prüfung von `winget`
2. Installation von Git, falls erforderlich
3. Download des Repositories nach:

   ```text
   %USERPROFILE%\windows-setup
   ```

4. Aktualisierung eines bereits vorhandenen Repositories
5. Ausführung von `bootstrap.ps1`

## Erneuter Setup-Durchlauf

Nach der ersten Installation kann das Setup direkt aus dem Repository erneut gestartet werden:

```powershell
cd ~/windows-setup
.\bootstrap.ps1
```

Alternativ kann erneut der Installationsbefehl verwendet werden:

```powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

In diesem Fall wird das vorhandene Repository zuerst per Git aktualisiert und anschließend der Bootstrap gestartet.

## Projektstruktur

```text
windows-setup/
├── bootstrap.ps1
├── init.ps1
├── config/
├── modules/
├── dotfiles/
├── assets/
├── AGENTS.md
└── .codex/
```

### `init.ps1`

Minimaler Einstiegspunkt für ein frisch installiertes Windows.

Installiert die Voraussetzungen, lädt das Repository und startet den eigentlichen Bootstrap.

### `bootstrap.ps1`

Orchestriert den Setup-Durchlauf.

Die eigentliche Installations- und Konfigurationslogik befindet sich nicht im Bootstrap, sondern in den Modulen.

### `config/`

Enthält ausschließlich Konfigurationsdaten wie:

- Paketgruppen
- Browser-Konfiguration
- VS-Code-Erweiterungen
- PowerShell-Module

### `modules/`

Enthält die eigentliche PowerShell-Logik.

## Entwicklung

Der Bootstrap installiert `PSScriptAnalyzer` automatisch.

Am Ende eines Setup-Durchlaufs wird der PowerShell-Code geprüft.

Die Analyse dient aktuell als Hinweis und bricht das Setup bei Warnungen nicht ab.
