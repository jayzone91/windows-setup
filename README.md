# Windows Setup

Automatisiertes, reproduzierbares und weitgehend idempotentes Setup für
meine Windows-Arbeitsumgebung.

Das Repository dient sowohl zur Einrichtung eines frisch installierten
Windows-Systems als auch zur regelmäßigen Wartung eines bereits
eingerichteten Rechners. Derselbe `bootstrap.ps1` wird für beide Fälle
verwendet. Bereits erledigte oder vorhandene Konfigurationen werden --
soweit vorgesehen -- erkannt und übersprungen beziehungsweise
aktualisiert.

## Funktionsumfang

Das Setup installiert, aktualisiert und konfiguriert unter anderem:

-   Basissoftware und System-Tools über `winget` und den Microsoft Store
-   Entwicklungswerkzeuge
-   PowerShell 7, Nushell und Windows Terminal
-   Git, GitHub CLI und GitHub Desktop
-   Visual Studio Code inklusive Erweiterungen und Settings
-   Node.js-Umgebung über `fnm`
-   Bun und Go
-   npm, pnpm und Yarn
-   Codex CLI
-   Zen Browser und Google Chrome Beta
-   Browser-Erweiterungen und Zen Mods
-   NVIDIA App und weitere Treiber-Logik
-   Windows-Einstellungen, Theme, HDR und Wallpaper
-   Windows-Debloat
-   Apple-Passwort-Voraussetzungen
-   Logitech G HUB inklusive Sicherung der Konfiguration
-   ReFS Dev Drive und separates Games-Laufwerk
-   Microsoft Defender Dev Drive Performance Mode
-   Package- und Build-Caches auf dem Dev Drive
-   normale Windows- und Microsoft-Updates
-   automatische wöchentliche Wartung über die Windows-Aufgabenplanung
-   Desktop-Benachrichtigungen bei erforderlichem Neustart oder
    Git-Änderungen
-   abschließende Code-Prüfung mit PSScriptAnalyzer

## Installation

Eine **PowerShell als Administrator** öffnen und folgenden Befehl
ausführen:

``` powershell
irm https://raw.githubusercontent.com/jayzone91/windows-setup/master/init.ps1 | iex
```

`init.ps1` übernimmt automatisch:

1.  Prüfung von `winget`
2.  Installation von Git, falls erforderlich
3.  Download des Repositories nach `%USERPROFILE%\windows-setup`
4.  Aktualisierung eines bereits vorhandenen Repositories
5.  Ausführung von `bootstrap.ps1`

## Erneuter Setup-Durchlauf

``` powershell
cd ~/windows-setup
.\bootstrap.ps1
```

Alternativ kann erneut der Installationsbefehl verwendet werden. Bei
einem erneuten Lauf werden vorhandene Komponenten erkannt und
übersprungen beziehungsweise aktualisiert.

Der Bootstrap versucht außerdem zu Beginn, das Repository zu
aktualisieren. Enthält das Working Tree lokale Änderungen, wird ein
automatisches `git pull` aus Sicherheitsgründen übersprungen.

## Automatische wöchentliche Wartung

Der Bootstrap richtet die Windows-Aufgabe
`Windows Setup Weekly Maintenance` ein.

Sie startet den vollständigen `bootstrap.ps1` **wöchentlich am Sonntag
um 12:00 Uhr**. Es existiert bewusst kein separater
Maintenance-Workflow: Neuinstallation, manuelle Aktualisierung und
automatische Wartung verwenden dieselbe Logik.

Die Aufgabe läuft im interaktiven Benutzerkontext mit erhöhten Rechten.
Dadurch können administrative Änderungen vorgenommen und gleichzeitig
Desktop-Benachrichtigungen angezeigt werden.

Der Wartungslauf umfasst unter anderem:

-   Aktualisierung des Repositories, sofern keine lokalen Änderungen
    vorliegen
-   Aktualisierung der konfigurierten `winget`-/Store-Pakete
-   Aktualisierung der Entwicklungswerkzeuge
-   Treiberprüfung und Treiberupdates
-   normale Windows- und Microsoft-Updates
-   Synchronisierung der Logitech-G-HUB-Konfiguration
-   erneute Anwendung der gewünschten Windows- und
    Entwicklungs-Konfiguration
-   PSScriptAnalyzer-Codeprüfung
-   Prüfung auf erforderlichen Neustart
-   Prüfung auf lokale Git-Änderungen und noch nicht gepushte Commits

Der Rechner wird **nicht automatisch neu gestartet**.

### Desktop-Benachrichtigungen

Für Desktop-Benachrichtigungen wird `BurntToast` verwendet.

Nach einem Wartungslauf wird eine Benachrichtigung angezeigt, wenn:

1.  Windows beziehungsweise ein installiertes Update einen Neustart
    benötigt.
2.  das `windows-setup`-Repository lokale Änderungen oder noch nicht
    gepushte Commits enthält.

Änderungen am Repository werden bewusst **nicht automatisch committed
oder gepusht**. Sie sollen zunächst geprüft werden.

## Windows Updates

Normale Windows- und Microsoft-Updates werden über `PSWindowsUpdate`
installiert. Dazu gehören beispielsweise kumulative Windows-Updates,
Security Updates, .NET-Updates und Microsoft Defender Security
Intelligence Updates.

Treiber werden separat durch die vorhandene Treiberlogik behandelt.

Ein erforderlicher Neustart wird erkannt, aber nicht automatisch
ausgeführt.

## Software und Updates

Software wird gruppiert über `config/packages.psd1` verwaltet.

### Basis

-   JetBrainsMono Nerd Font

### System-Tools

-   Windows HDR Calibration
-   iCloud
-   OpenVPN
-   Logitech G HUB

OpenVPN ist bewusst auf Version `2.7.101` festgelegt und wird nicht
automatisch auf eine andere Version aktualisiert.

### Browser

-   Zen Browser
-   Google Chrome Beta

### Entwicklung

-   fnm
-   Go
-   Bun
-   Git
-   GitHub CLI
-   GitHub Desktop
-   Visual Studio Code
-   PowerShell 7
-   Nushell
-   Starship

Pakete mit aktivierter Update-Option werden bei späteren
Bootstrap-Durchläufen automatisch aktualisiert.

## Development Storage

Das Setup kann automatisch eine vollständig leere, geeignete interne SSD
für Entwicklungs- und Spieldaten einrichten. Die System-/Bootdisk sowie
ungeeignete Datenträger werden dabei ausgeschlossen. Vor destruktiven
Änderungen werden der erkannte Datenträger und die geplante
Partitionierung angezeigt und müssen vom Benutzer bestätigt werden.

  Laufwerk            Größe Dateisystem      Label     Zweck
  ---------- -------------- ---------------- --------- -------------
  `D:`               100 GB ReFS Dev Drive   `Dev`     Entwicklung
  `G:`         Rest der SSD NTFS             `Games`   Spiele

Für das Games-Laufwerk müssen mindestens 100 GB zur Verfügung stehen.
Existieren die Laufwerke bereits in der erwarteten Form, wird die
Partitionierung nicht erneut durchgeführt.

### Dev-Drive-Verzeichnisse und Caches

``` text
D:\
├── Projects\
├── Build\
└── Cache\
    ├── npm\
    ├── pnpm\
    ├── yarn\
    ├── bun\
    └── go\
        ├── build\
        └── modules\
```

Die Entwicklungs-Caches werden auf das Dev Drive verschoben:

  Tool              Pfad
  ----------------- -----------------------
  npm               `D:\Cache\npm`
  pnpm              `D:\Cache\pnpm`
  Yarn              `D:\Cache\yarn`
  Bun               `D:\Cache\bun`
  Go Build Cache    `D:\Cache\go\build`
  Go Module Cache   `D:\Cache\go\modules`

Für das ReFS Dev Drive wird außerdem der Microsoft Defender Dev Drive
Performance Mode aktiviert. Der Echtzeitschutz bleibt grundsätzlich
aktiv.

## Windows Debloat

Der Bootstrap entfernt beziehungsweise deprovisioniert eine definierte
Auswahl nicht benötigter Windows-AppX-Pakete und deaktiviert
verschiedene Consumer- und Content-Delivery-Funktionen.

Die Debloat-Logik ist wiederholbar aufgebaut. Bereits entfernte Pakete
werden erkannt und übersprungen. Gaming-, Entwicklungs- und für Windows
Hello relevante Funktionen sollen erhalten bleiben.

## Logitech G HUB

Logitech G HUB wird über `winget` installiert und automatisch aktuell
gehalten.

Die aktuelle G-HUB-Konfiguration wird als `config\lghub\settings.db` im
Repository gesichert.

Auf einem frisch eingerichteten System wird die gespeicherte
Konfiguration einmalig nach G HUB übernommen. Bei späteren
Bootstrap-Durchläufen wird die aktuelle lokale G-HUB-Datenbank bei
Änderungen zurück ins Repository kopiert.

G HUB wird für den Zugriff auf die Datenbank kurz beendet und
anschließend wieder gestartet. Seine Konsolenausgaben werden umgeleitet.
Da G HUB die Datenbank auch intern verändern kann, kann `settings.db`
bei einem Wartungslauf als Git-Änderung erscheinen. Der abschließende
Repository-Check weist darauf per Desktop-Benachrichtigung hin.

## PowerShell-Module

Folgende PowerShell-Module werden automatisch verwaltet:

-   `PSScriptAnalyzer`
-   `BurntToast`
-   `PSWindowsUpdate`

## Projektstruktur

``` text
windows-setup/
├── bootstrap.ps1
├── init.ps1
├── config/
│   ├── browsers.psd1
│   ├── debloat.psd1
│   ├── packages.psd1
│   ├── powershell.psd1
│   ├── storage.psd1
│   ├── vscode.psd1
│   └── lghub/
│       └── settings.db
├── modules/
│   ├── Drivers/
│   ├── Windows/
│   ├── Browser.ps1
│   ├── Debloat.ps1
│   ├── Development.ps1
│   ├── Git.ps1
│   ├── Helpers.ps1
│   ├── Languages.ps1
│   ├── Logitech.ps1
│   ├── Notifications.ps1
│   ├── Nushell.ps1
│   ├── Packages.ps1
│   ├── PowerShell.ps1
│   ├── ScheduledTasks.ps1
│   ├── Security.ps1
│   ├── Storage.ps1
│   ├── Terminal.ps1
│   ├── VSCode.ps1
│   └── WindowsUpdate.ps1
├── dotfiles/
├── assets/
├── AGENTS.md
└── .codex/
```

### `init.ps1`

Minimaler Einstiegspunkt für ein frisch installiertes Windows.
Installiert die Voraussetzungen, lädt beziehungsweise aktualisiert das
Repository und startet `bootstrap.ps1`.

### `bootstrap.ps1`

Zentrale Orchestrierung für Erstinstallation, manuelle erneute
Setup-Durchläufe und automatische wöchentliche Wartung. Die eigentliche
Installations- und Konfigurationslogik befindet sich in den Modulen.

### `config/`

Enthält deklarative Konfigurationsdaten wie Paketgruppen,
Browser-Konfiguration, VS-Code-Erweiterungen, PowerShell-Module,
Debloat-, Storage- und G-HUB-Konfiguration.

### `modules/`

Enthält die eigentliche PowerShell-Logik. `modules/index.ps1` lädt die
einzelnen Module zentral.

## Entwicklung und Codequalität

`PSScriptAnalyzer` wird automatisch installiert.

``` powershell
. .\modules\index.ps1
Test-PowerShellCode .
```

Die Codeprüfung wird außerdem am Ende des Bootstraps ausgeführt. Ziel
ist ein sauberer Lauf ohne Fehler, Warnungen oder Hinweise:

``` text
[OK] Keine PSScriptAnalyzer-Probleme gefunden.
```

## Grundprinzipien

-   **Ein Bootstrap:** Keine getrennte Setup- und Maintenance-Logik.
-   **Idempotenz:** Bereits eingerichtete Komponenten werden erkannt und
    nicht unnötig neu erstellt.
-   **Konfiguration im Repository:** Relevante Einstellungen sollen
    reproduzierbar und nachvollziehbar sein.
-   **Keine automatischen Git-Pushes:** Änderungen werden gemeldet und
    vor Commit beziehungsweise Push geprüft.
-   **Keine automatischen Neustarts:** Ein erforderlicher Neustart wird
    gemeldet, aber nicht erzwungen.
-   **Sichere Storage-Einrichtung:** Destruktive Änderungen benötigen
    eine explizite Bestätigung.
-   **Automatische Wartung:** Derselbe Bootstrap hält das System
    regelmäßig aktuell.
