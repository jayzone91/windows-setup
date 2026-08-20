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

Das Hauptziel ist ein **stabiles, wartbares und reproduzierbares Windows-11-System**.

Optische Anpassungen sind nachrangig. Native Windows-Komponenten werden bevorzugt, wenn Drittsoftware in Shell, Fensterverwaltung, Fullscreen, Fokus, Grafikdarstellung oder Updates eingreift.

## Verbindliche Stabilitätsregel

- Systemstabilität hat immer Vorrang vor Design.
- Rein optische Vorteile rechtfertigen keine zusätzliche Shell-, Hook-, Compositor-, Resource-Redirect- oder Browser-UI-Schicht.
- Neue tief in die Desktop-/Fenster-/Grafikpipeline eingreifende Software wird nur übernommen, wenn ein klarer funktionaler Nutzen besteht.
- Fullscreen, Borderless, Alt+Tab, Fokuswechsel, Gaming und normale Fensterbedienung gehören zu den Pflicht-Akzeptanztests jeder Desktop-nahen Änderung.
- Bei wiederkehrenden Stabilitätsproblemen wird auf native Windows-Funktionalität zurückgefallen.

## Aktueller Desktop

| Bereich                     | Lösung                                                     |
| --------------------------- | ---------------------------------------------------------- |
| Desktop / Taskleiste        | Windows 11                                                 |
| Window Management           | Windows Snap + PowerToys FancyZones                        |
| Launcher / Search           | Raycast + Everything                                       |
| Dateimanager                | Windows File Explorer                                      |
| Archivmanager               | NanaZip                                                    |
| Volume / Media / System-OSD | Windows 11                                                 |
| Browser                     | Vivaldi ohne Custom-UI; Zen als Firefox-WebDev-Testbrowser |
| Terminal                    | Windows Terminal + PowerShell 7 + Starship                 |

Entfernt und nicht Teil des produktiven Zielbilds: Seelen UI, FluentFlyout, Windhawk, Files, Nushell, Warp sowie repositoryverwaltetes Vivaldi-Custom-HTML/CSS/JS.

---
# 3. Grundprinzipien und feste Architekturentscheidungen

## Stabilität

- [x] **Systemstabilität ist die oberste Architekturvorgabe**
- [x] native Windows-Komponenten werden gegenüber rein optisch motivierten Drittanbieter-Schichten bevorzugt
- [x] Fullscreen, Borderless, Alt+Tab und Fokusverhalten sind Pflichtkriterien für Desktop-nahe Software
- [x] Seelen UI, FluentFlyout, Windhawk, Files, Nushell und Warp nach wiederkehrenden Stabilitäts-/Nutzenproblemen aus dem Zielbild entfernt
- [x] Vivaldi-Custom-HTML/CSS/JS vollständig verworfen; Vivaldi bleibt im nativen UI-Zustand
- [x] Bereinigten nativen Desktop nach Deinstallation und vollständigem `just update-log` praktisch getestet
- [x] Fullscreen-Video in Vivaldi nach Rückkehr zum nativen UI praktisch getestet
- [x] Alt+Tab aus mindestens einem Spiel sowie Rückkehr ins Spiel praktisch getestet
- [x] normalen Fensterfokus, Maximieren, Verschieben und Windows Snap praktisch getestet
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
- [x] frühere Bootstrap-Self-Elevation nach praktisch bestätigtem Windows-`sudo`-Workflow entfernt
- [x] nicht erhöhte direkte Bootstrap-Aufrufe brechen verständlich ab statt selbstständig UAC anzufordern
- [x] Globale Benutzer-/System-Execution-Policy wird nicht verändert
- [x] Execution-Policy-Fix auf dem aktuellen Windows-System erfolgreich getestet
- [x] laufende Anwendungen werden bei wiederholten Läufen nur geschlossen, wenn eine tatsächliche Änderung dies erfordert

## Just / manueller Workflow

- [x] `Justfile` als einheitliche Bedienoberfläche
- [x] `just` als Base-Abhängigkeit über `Casey.Just`
- [x] manuelle Bootstrap-Läufe werden über `sudo just update`, `sudo just update-warning`, `sudo just update-log` und `sudo just update-performance` erhöht gestartet
- [x] die Recipes selbst verwenden weiterhin `-NoProfile -ExecutionPolicy Bypass`; `sudo` liefert ausschließlich den erhöhten Prozesskontext
- [x] `just update` ist der normale stille Lauf ohne reguläre Konsolenausgabe
- [x] `just update-warning` zeigt ausschließlich Warnungen und Fehler; fehlerfreier Lauf auf dem aktuellen System praktisch ohne Ausgabe bestätigt
- [x] `just update-log` zeigt die vollständige Bootstrap-Ausgabe und ist der verbindliche Modus für funktionale Bootstrap-Tests
- [x] `just update-performance` führt über `scripts/Measure-BootstrapPerformance.ps1` denselben parameterlosen/stillen Bootstrap aus und misst reproduzierbar die Laufzeit
- [x] Performance-Tests werden ohne reguläre Bootstrap-Ausgabe durchgeführt; funktionale Tests verwenden `-Log`
- [x] `just check` und Bootstrap verwenden denselben zentralen `Test-PowerShellCode`-Workflow; `just check` führt PSScriptAnalyzer für PowerShell und den Compilecheck für verwaltete C#-Dateien aus und aktualisiert danach den Git-basierten Source-Codezustand, während der Bootstrap den vollständigen Check nur bei geändertem Source-Code ausführt
- [x] interaktive Bootstrap-Kommunikation wird zentral über `Write-WindowsSetupInteractive` und `Read-WindowsSetupPrompt` geführt, wenn sie unabhängig vom gewählten Ausgabemodus sichtbar bleiben muss
- [x] interne PSScriptAnalyzer-Runtimefehler einzelner Dateien werden einmal in einem frischen `pwsh -NoProfile`-Prozess erneut geprüft
- [x] `just ghub-backup` sichert die G-HUB-Konfiguration bewusst ins Repository
- [x] `just ghub-restore` stellt die G-HUB-Konfiguration bewusst wieder her
- [x] `just update` auf dem aktuellen System erfolgreich getestet
- [x] `just check` auf dem aktuellen System erfolgreich getestet
- [x] Das `Justfile` enthält keine eigentliche Setup-Logik
- [x] Neue wiederkehrende manuelle Aktionen dürfen als Recipes ergänzt werden, wenn die Implementierung in PowerShell verbleibt

### Bootstrap-Performance – Stand 2026-08-19

Die Performance des wiederholten Bootstrap-/Wartungslaufs wurde gezielt vermessen und optimiert. Ausgangspunkt waren reproduzierbare Laufzeiten um etwa 58–65 Sekunden; einzelne Läufe lagen durch Windows-Update-Varianz deutlich darüber. Nach den lokalen Optimierungen liegt ein normaler Lauf auf dem aktuellen System typischerweise bei ungefähr 40 Sekunden. Schwankungen darüber werden überwiegend durch externe Windows-/Microsoft-Update-Abfragen verursacht und sind kein sinnvoller Anlass für zusätzliche lokale Komplexität.

Umgesetzte und praktisch getestete Optimierungen:

- [x] `just update-performance` um detaillierte Bootstrap-Phasenmessung erweitert
- [x] Performance-Trace nur für den aktuellen Messlauf aktivieren; normale Bootstrap-Läufe bleiben davon unbeeinflusst
- [x] Paket-, Treiber-, Windows- und Development-Bereiche in ausreichend feine Messphasen zerlegt, um reale Bottlenecks statt Vermutungen zu optimieren
- [x] Windows-Softwareupdates und Windows-Treiberupdates verwenden innerhalb eines Bootstrap-Laufs einen gemeinsamen WUA-/Microsoft-Update-Scan
- [x] der spätere Windows-Softwareupdate-Schritt verwendet das bereits vorhandene Scan-Ergebnis und führt keinen zweiten vollständigen Update-Scan aus
- [x] Winget-Installationsstatus pro Source über einen laufzeitlokalen Inventar-Cache prüfen statt für jedes Paket einen eigenen `winget list --id ...`-Prozess zu starten
- [x] Winget-Inventarcache wird ausschließlich im aktuellen Bootstrap-Prozess gehalten und nicht zwischen Läufen persistiert
- [x] `msstore`-Pakete erhalten bei einem Cache-Miss einen gezielten `winget list --name ... --exact`-Fallback, da Microsoft-Store-Produkt-IDs im allgemeinen Inventar nicht für alle Pakete zuverlässig als Paket-ID erkannt werden
- [x] NVIDIA App wird über diesen Store-Fallback auf dem aktuellen System korrekt als installiert erkannt
- [x] Winget-Installationsbatch behandelt ExitCode `-1978335189` als bestätigten No-Op statt als fatalen Bootstrap-Fehler; andere unbekannte ExitCodes bleiben Fehler
- [x] Wallpaper-Repository verwendet bei einem normalen Wartungslauf keinen mehrstufigen Git-Retry mit festen 2-/4-Sekunden-Wartezeiten mehr; bei nicht erreichbarem Remote wird ohne künstliche Wartezeit mit dem vorhandenen lokalen Stand weitergearbeitet
- [x] `fnm env` wird vor der Node-Versionsprüfung in die aktuelle PowerShell-Session geladen, damit eine bereits installierte aktive Node-LTS-Version nicht fälschlich als fehlend erkannt wird
- [x] `just check`, `sudo just update-log` und `sudo just update-performance` nach den Performance-Änderungen erfolgreich ausgeführt
- [x] wiederholte funktionale Bootstrap-Läufe nach den Optimierungen vollständig erfolgreich
- [x] gemessener optimierter Lauf auf dem aktuellen System bei ungefähr 40 Sekunden bestätigt

Feste Performance-Entscheidungen:

- Ein persistenter Windows-Update-, Treiber- oder Winget-Inventarcache zwischen Bootstrap-Läufen wird **nicht** eingeführt.
- Der reguläre Wartungs-Bootstrap läuft ungefähr einmal pro Woche. Ein persistenter Cache würde Aktualität, Invalidierungslogik und Fehlerpotenzial verschlechtern, während die eingesparte Laufzeit für diesen Ausführungsrhythmus keinen relevanten Nutzen bringt.
- Laufzeitlokale Wiederverwendung innerhalb desselben Bootstrap-Prozesses ist erwünscht, wenn dadurch identische externe Scans oder Prozesse sicher vermieden werden können.
- Windows-/Microsoft-Update-Laufzeiten sind extern variabel. Insbesondere der gemeinsame WUA-Scan kann je nach Zustand der Update-Dienste und Microsoft-Server mehrere Sekunden bis deutlich länger benötigen.
- Diese externe Varianz wird akzeptiert und nicht durch persistente Cache-, Timeout- oder Skip-Logik kaschiert.
- Weitere Mikrooptimierungen an lokalen Schritten im Bereich weniger Sekunden werden aktuell bewusst nicht verfolgt. Stabilität, Aktualität, Reproduzierbarkeit und Wartbarkeit haben Vorrang vor einer niedrigeren Benchmark-Zahl.
- Weitere Performance-Arbeit wird erst wieder aufgenommen, wenn ein konkreter Schritt im realen Weekly-Workflow störend langsam wird oder eine reproduzierbare lokale Regression messbar ist.

## Konfigurationsdateien

Projektweite Regel:

- [x] **Dateien werden standardmäßig als NTFS-Hardlinks eingebunden**
- [x] **Verzeichnisse werden als NTFS-Junctions eingebunden**
- [x] Symbolic Links sind ausschließlich als expliziter Kompatibilitäts-Fallback erlaubt, wenn eine Anwendung Hardlinks technisch nicht zuverlässig unterstützt
- [x] VS Code `settings.json` verwendet einen Symbolic Link, da VS Code beim Speichern die Datei ersetzt und dadurch einen NTFS-Hardlink auftrennt
- [x] Windows Terminal `settings.json` verwendet ebenfalls den Symbolic-Link-Kompatibilitätsfallback; ein Hardlink wurde beim Speichern über die Settings-GUI praktisch als ungeeignet bestätigt
- [x] `Set-FileHardLink` zentral als Standard-Helper
- [x] korrekte NTFS-Hardlinks vor Änderungen auf ihr tatsächliches Ziel prüfen und bei unverändertem Desired State nicht löschen oder neu erzeugen
- [x] `Set-FileSymbolicLink` zentral als Kompatibilitäts-Helper
- [x] `Set-DirectoryJunction` zentral als Helper

Begründung:

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

## Desktop-/Design-Entscheidung

- [x] kein globales macOS-/Liquid-Glass-Ziel mehr
- [x] keine zusätzliche Desktop-Shell
- [x] keine zusätzlichen Lock-Key-/Volume-/Media-OSD-Schichten
- [x] keine systemweiten Resource-Redirects für rein optische Icons
- [x] Windows File Explorer ist der produktive Dateimanager
- [x] Windows Terminal ist das produktive Terminal-Frontend
- [x] Vivaldi bleibt Hauptbrowser, verwendet aber ausschließlich sein natives UI
- [x] Zen bleibt Firefox-basierter Testbrowser für Webentwicklung
- [x] VS Code und Windows Terminal dürfen weiterhin anwendungseigene, stabile Themes verwenden
- [x] Funktionalität, Windows-Integrität, Stabilität und Wartbarkeit haben Vorrang vor Styling

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
- [x] größere PowerShell-Bereiche fachlich in Unterordner mit lokalem `index.ps1` aufgeteilt; übergeordnete Loader importieren nur den jeweiligen Index
- [x] keine manuell gepflegte Repository-Source-Datei überschreitet 500 Zeilen; generierte Build-Artefakte und externe/vendorisierte Inhalte sind von dieser Source-Regel ausgenommen
- [x] `bootstrap.ps1` bleibt der zentrale Einstiegspunkt und lädt die gesplittete Bootstrap-Implementierung über `bootstrap/index.ps1`
- [x] Paketkonfiguration unter `config/packages/` nach Paketgruppen aufgeteilt und zentral über `config/packages/index.ps1` geladen
- [x] ehemaliges eigenes Volume-OSD nach erfolgreichem Wechsel auf Seelen vollständig entfernt
- [x] verwaiste Funktionen und Dateien nach repositoryweiter Prüfung einschließlich `Justfile`, `scripts/` und indirekter Nutzung entfernt
- [x] Refactor mit `just check` und vollständigen `just update-log`-Läufen praktisch bestätigt

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
- [x] `just update-warning`
- [x] `just update-log`
- [x] `just update-performance`
- [x] `just check`
- [x] `just ghub-backup`
- [x] `just ghub-restore`
- [x] direkter Bootstrap-Fallback dokumentiert
- [x] Just als Base-Paket
- [x] Just-Workflow im README dokumentiert

## Ausgabe / Logging

- [x] parameterloser Bootstrap läuft ohne reguläre Konsolenausgabe
- [x] `-Warning` zeigt nur Warnungen und Fehler
- [x] `-Log` zeigt die vollständige Konsolenausgabe
- [x] Weekly-Maintenance-Task ruft den Bootstrap weiterhin ohne Ausgabeparameter auf
- [x] interaktive Hinweise und Benutzerabfragen werden über zentrale Always-Output-Helper unabhängig von `silent` / `-Warning` / `-Log` sichtbar ausgegeben
- [x] Always-Output-Verhalten praktisch mit `just update`, `just update-warning` und `just update-log` getestet
- [x] funktionale Bootstrap-Tests verwenden `-Log`
- [x] Performance-Tests verwenden den stillen `just update-performance`-Pfad
- [ ] zentrale persistente Logging-Strategie für komplette Bootstrap-Läufe
- [x] fatalen Bootstrap-Fehler strukturiert mit Timestamp unter `.generated/logs/bootstrap-last-error.log` speichern; Fehlerpfad praktisch zur Diagnose des Raycast-Problems bestätigt
- [ ] Warnungen und Fehler vollständig mit Timestamp in Log-Dateien speichern
- [ ] automatische Log-Retention bzw. Bereinigung, damit Logs nicht unbegrenzt wachsen
- [ ] Log-Dateien mit Datum/Uhrzeit und Ergebnisstatus
- [ ] optionaler `-Verbose`-Modus für detailliertere Diagnose
- [ ] optionaler `-DryRun` / `-WhatIf`-Modus
- [x] ein maschinenlesbarer Abschlussstatus des Bootstrap-Laufs
- [ ] optional eine Zusammenfassung der Änderungen eines Durchlaufs

### Akzeptanzkriterien

Ein frisches Windows-System soll mit möglichst wenigen manuellen Schritten über `init.ps1` bis zu einer arbeitsfähigen Umgebung gelangen.

Nach der Erstinstallation sollen wiederkehrende manuelle Aktionen über kurze, dokumentierte `just`-Recipes möglich sein.

## Bootstrap-Performance / Desired-State-Optimierung

Ausgangsmessung auf dem vollständig eingerichteten System vor dieser Optimierungsrunde:

```text
03:41.67
221,67 Sekunden
```

Praktisch bestätigter Stand nach der ersten Optimierungsrunde:

```text
01:10.73
70,73 Sekunden
```

Praktisch bestätigter Stand nach der zweiten Desired-State-/Idempotenz-Runde:

```text
00:58.36
58,36 Sekunden
```

Aktueller offener Performance-Befund nach dem großen Strukturrefactor:

```text
01:33.23
93,24 Sekunden
```

Die `93,24 Sekunden` sind **keine neue akzeptierte Baseline**, sondern eine zu untersuchende Regression von `34,88 Sekunden` bzw. rund `59,8 %` gegenüber dem zuletzt bestätigten Stand von `58,36 Sekunden`.

- [ ] Performance-Regression nach dem Strukturrefactor mit phasenweiser Messung lokalisieren und auf Basis realer Laufzeitdaten optimieren

Damit wurde die gemessene Laufzeit gegenüber dem ursprünglichen Stand von 221,67 Sekunden um rund **73,7 %** reduziert. Gegenüber dem 70,73-Sekunden-Zwischenstand reduziert die zweite Runde die Laufzeit nochmals um rund **17,5 %**.

Feste Architekturentscheidungen:

- [x] teure Prüfungen und externe CLI-Schreiboperationen nur wiederholen, wenn Input oder Desired State dies erfordern
- [x] lokaler Performance-/Initialisierungszustand darf unter `.generated/state/` liegen und wird nicht committed
- [x] Source-Codezustand basiert im Git-Repository auf HEAD plus tatsächlich geänderten/gestagten/untracked PowerShell- und C#-Dateien; saubere getrackte Dateien werden für den schnellen Preflight nicht vollständig neu gehasht
- [x] unveränderter Source-Code überspringt den vollständigen Qualitätscheck; geänderter PowerShell-Code muss weiterhin PSScriptAnalyzer bestehen und verwaltete C#-Dateien müssen den Compilecheck bestehen
- [x] `just check` aktualisiert nach erfolgreichem vollständigem Analyzer-Lauf denselben Codezustand
- [x] normale WinGet-Installationen und Updates werden pro Source gebündelt; verarbeitet werden ausschließlich in `config/packages/` deklarierte Pakete
- [x] `Update = $false` und versionsgepinnte Pakete werden nicht in den normalen Winget-Upgrade-Batch aufgenommen
- [x] korrekte Hardlinks werden bei wiederholten Läufen nicht neu erzeugt
- [x] Dev-Drive-Paketcache-Konfiguration wird nur bei geändertem Desired State erneut geschrieben
- [x] Zebar führt `npm ci` nur bei Dependency-Drift bzw. fehlendem `node_modules` aus
- [x] VS Code ermittelt die installierten Extensions pro Bootstrap nur einmal
- [x] Node.js wird über fnm gegen die aktuelle LTS-Version geprüft
- [x] npm, pnpm und Yarn werden gegen ihre aktuellen Registry-Versionen geprüft und bei unverändertem Stand nicht neu installiert
- [ ] tatsächlichen Updatepfad von npm/pnpm/Yarn bei zukünftig vorhandener neuer Version praktisch bestätigen
- [x] Bun-Updates bleiben im zentralen deklarativen Winget-Paketpfad
- [x] Neovim ruft `origin/main` per Fetch ab und führt bei identischem lokalen/Remote-HEAD keinen Stash, Checkout oder Pull aus
- [ ] optimierten Neovim-Pfad bei einem zukünftig tatsächlich vorhandenen neuen Remote-Commit einschließlich lokaler Änderungen erneut praktisch bestätigen
- [x] Wiederherstellungspunkt wird vor der eigentlichen Setup-Logik erstellt; Erstellung auf dem aktuellen System praktisch bestätigt
- [x] Erkennung eines bereits frischen Wiederherstellungspunkts korrigiert; Abfrage erfolgt über Windows PowerShell 5.1 / `Get-ComputerRestorePoint`, vorhandener Restore Point innerhalb des 24h-Fensters wurde auf dem aktuellen System praktisch erkannt und kein neuer Restore Point angelegt

Zweite Performance-/Desired-State-Runde:

- [x] Windhawk-Mod-Settings vor dem Schreiben gegen den tatsächlichen Runtime-Zustand vergleichen
  - Boolean-Settings werden entsprechend Windhawks Runtime-Repräsentation semantisch normalisiert
  - wiederholter `just update-log` bestätigt für alle verwalteten Mods unveränderte Settings und Enable-Zustände als `CURRENT`
- [x] Scheduled Tasks nur bei tatsächlichem Drift von Action, Trigger, Principal oder Settings neu registrieren
  - Weekly Maintenance normalisiert Weekly-Trigger vor dem Vergleich auf lokale Wall-Clock-Zeit, damit UTC-/Offset-Darstellungen desselben Zeitpunkts keinen False Positive erzeugen
  - Benutzeridentitäten in Principal und Logon-Trigger werden für den Vergleich auf stabile SIDs normalisiert; nach einer Computerumbenennung wird ein gespeicherter alter `COMPUTER\Benutzer`-Wert für dasselbe lokale Konto über die lokale Benutzer-SID kanonisiert
- [x] Windows-Shell-/Theme-/Power-/Wallpaper-Konfiguration nur bei Drift schreiben; Debloat bleibt bewusst bei jedem Bootstrap aktiv
- [x] Explorer-Neustart auf tatsächliche Shell-Änderungen begrenzen
  - der bisherige Restart diente der zuverlässigen Übernahme von Shell-/Taskleistenänderungen; bei unverändertem Shell-Desired-State bleibt Explorer nun geöffnet
- [x] Zig-`cc`-/`c++`-Shims vor dem Neuschreiben auf den gewünschten Zustand prüfen
  - gewünschtes Zig-Ziel/Argumente und tatsächlicher Shim-Zustand werden verglichen
  - wiederholter `just update-log` bestätigt beide Shims als `CURRENT`
- [x] Browser-Policies nur bei tatsächlichem Drift neu schreiben
  - Chromium-Extension-Policies und Zen-`policies.json` bleiben bei identischem Desired State unangetastet
- [x] zweiter unmittelbar folgender `just update-log` bestätigt die Desired-State-Runde ohne unnötige Task-/Explorer-/Zig-/Browser-Schreiboperationen bzw. Neustarts
- [x] finaler strikter `just check` mit 68 PowerShell-Dateien ohne PSScriptAnalyzer-Probleme
- [x] finaler stiller Performance-Lauf mit `58,36 Sekunden` praktisch bestätigt
---

# 5. Phase 2 – Paketverwaltung


## Gemeinsame Paketarchitektur

`config/packages/` bleibt die zentrale deklarative Paketliste. Paketgruppen sind weiterhin fachlich organisiert; die Eigenschaft `Source` entscheidet über den Installationsweg.

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
- [x] Paketkonfiguration in `config/packages/` mit Beispielen und unterstützten Quellen dokumentieren
- [x] `just check` nach dem Paketmanager-Umbau ohne relevante Analyzer-Warnungen
- [x] wiederholter `just update` mit Chocolatey/Scoop ohne erneute Installation der Paketmanager

## Generische Winget-Logik

- [x] Paketgruppen über `config/packages/`
- [x] Installation über `winget`
- [x] Microsoft-Store-Quelle unterstützen
- [x] zusätzlich alle über die `msstore`-Source angebotenen App-Updates sourceweit per `winget upgrade --all --source msstore` installieren
- [x] Microsoft-Store-Quelle vor dem sourceweiten Update-Lauf aktualisieren
- [x] ExitCode für bereits aktuellen Store-Zustand störungsarm behandeln
- [x] Microsoft-Store-Update-Lauf im vollständigen `just update-log` praktisch bestätigt- [x] installierte Pakete erkennen
- [x] Updates durchführen
- [x] normale Winget-/MS-Store-Pakete pro Source gesammelt aktualisieren statt einen Updateprozess pro Paket zu starten
- [x] ausschließlich deklarierte Pakete aktualisieren; kein unkontrolliertes `winget upgrade --all`
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
- [x] NanaZip in `config/packages/` aufgenommen
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

- [x] Retry-Mechanismus bei temporären Paketmanager-/Download-Fehlern
  - Chocolatey- und Scoop-Aufrufe verwenden einen gezielten Retry mit maximal zwei Versuchen und kurzer Wartezeit
  - erfolgreiche paketmanagerspezifische ExitCodes werden weiterhin korrekt akzeptiert
  - nach dem letzten fehlgeschlagenen Versuch bleibt der Fehler fatal
  - Verhalten mit Pester für Soforterfolg, Retry-Erfolg, finalen Fehler und mehrere erfolgreiche ExitCodes abgedeckt
  - vollständiger `sudo just update-log` nach Einführung des Retry-Mechanismus erfolgreich
- [x] bessere maschinenlesbare Update-Zusammenfassung
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
- [x] systemweite Akzentfarbe `#0A84FF` deklarativ über `config/windows.psd1` verwalten
- [x] DWM-/Explorer-Akzentwerte nur bei Drift setzen; wiederholter `just update-log` bleibt idempotent
- [x] Power-Einstellungen
- [x] HDR
- [x] Wallpaper Slideshow
- [x] Windows Snap war während des früheren Tiling-Manager-Workflows deaktiviert; diese Entscheidung wird nach Entfernung des Tiling Managers bewusst revidiert
- [x] Windows Snap wieder deklarativ/idempotent aktivieren und praktisch testen
- [x] native Windows-Snap-Funktionen und FancyZones so konfigurieren, dass beide ohne konkurrierendes Verhalten sinnvoll zusammenarbeiten
- [x] PowerToys FancyZones als produktiven Window-Management-Workflow vollständig konfigurieren
  - [x] eigenes zum aktuellen Desktop-Workflow passendes FancyZones-Layout erstellen und reproduzierbar als Desired State verwalten
  - [x] mindestens ein alternatives Layout für unterschiedliche Arbeitsmodi definieren
  - [x] schnellen Wechsel zwischen den vorgesehenen Layouts per Tastenkombination implementieren
  - [x] Layout-/Hotkey-Konfiguration nur bei tatsächlichem Drift ändern
  - [x] Verhalten gemeinsam mit wieder aktiviertem Windows Snap praktisch testen
  - [x] wiederholten `just update-log` ohne unnötige PowerToys-Neustarts oder Settings-Schreiboperationen bestätigen
- [x] geschützte Registry-Werte dürfen Bootstrap nicht abbrechen
- [x] Computername deklarativ über `config/windows.psd1` verwalten
- [x] Computername nur bei tatsächlichem Drift über `Rename-Computer` setzen
- [x] nach einer Computerumbenennung keinen automatischen Neustart auslösen; Wirksamkeit nach bewusstem Benutzer-Neustart
- [x] Computerumbenennung auf dem aktuellen System praktisch getestet und nach Neustart als Desired State erkannt
- [x] wiederholter `just update-log` nach der Computerumbenennung ohne erneute Umbenennung erfolgreich
- [x] finaler `just check` nach der Computername-Integration erfolgreich
- [x] Windows-Taskbar-AutoHide für den Seelen-Workflow deaktiviert

### Priorität 1 – Windows-Entwickler-/Terminal-Grundzustand

Diese Punkte werden vor weiterem größeren Komfort-/Mail-Ausbau umgesetzt:

- [x] Warp als Windows-Standardterminal geprüft: kein offiziell unterstützter Registrierungspfad für Warp vorhanden; deshalb bewusst nicht als systemweite Standard-Terminalanwendung verwalten
- [x] Windows `sudo` deklarativ/idempotent über die offizielle Policy `HKLM\SOFTWARE\Policies\Microsoft\Windows\Sudo\EnableSudo = 3` im Inline-Modus (`normal`) aktivieren
- [x] Windows-`sudo` praktisch mit erhöhtem PowerShell-Prozess bestätigt
- [x] manuelle Projektläufe auf `sudo just update`, `sudo just update-warning`, `sudo just update-log` und `sudo just update-performance` umgestellt
- [x] Bootstrap-Self-Elevation nach bestätigtem `sudo`-Workflow entfernt
- [x] Negativtest eines nicht erhöhten `just update-log` bestätigt den definierten Abbruch
- [x] Windows-Entwicklermodus deklarativ/idempotent aktiviert
- [x] lange Win32-Pfade (`LongPathsEnabled`) deklarativ/idempotent aktiviert
- [x] erster erhöhter `sudo just update-log`, praktischer Sudo-Test, wiederholter Drift-freier Lauf und `just check` erfolgreich
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
- [x] vor der eigentlichen Setup-Logik einen Windows-Systemwiederherstellungspunkt anlegen; Erstellung auf dem aktuellen System praktisch bestätigt
- [x] BitLocker-Status prüfen
  - Status des Systemlaufwerks wird in der Abschlussphase über `Get-BitLockerVolume` ermittelt
  - `VolumeStatus`, `ProtectionStatus` und `EncryptionMethod` werden ausgegeben
  - deaktivierter Schutz erzeugt eine Warnung, wird aber nicht automatisch aktiviert
  - praktisch auf dem aktuellen System bestätigt: `C:` ist `FullyDecrypted`, `ProtectionStatus = Off`, `EncryptionMethod = None`
- [x] Secure-Boot-Status in Abschlussprüfung anzeigen
  - Status wird über `Confirm-SecureBootUEFI` ermittelt
  - aktiver Secure Boot wird als `[OK]` ausgegeben; deaktivierter oder nicht ermittelbarer Status erzeugt eine Warnung
  - praktisch auf dem aktuellen System getestet: zunächst korrekt als deaktiviert erkannt, anschließend im UEFI aktiviert und danach durch Bootstrap als aktiv bestätigt
- [x] Firewall-Status in Abschlussprüfung anzeigen
  - Status der Profile `Domain`, `Private` und `Public` wird über `Get-NetFirewallProfile` ermittelt
  - alle Profile werden mit `On`/`Off` ausgegeben
  - sobald mindestens ein Profil deaktiviert ist, erzeugt der Bootstrap eine Warnung
  - praktisch auf dem aktuellen System bestätigt: `Domain`, `Private` und `Public` jeweils `On`
- [x] Windows-Hello-Status detaillierter ausgeben
  - bestehende `dsregcmd /status`-Prüfung gibt `AzureAdJoined`, `DomainJoined`, `WorkplaceJoined` und `NgcSet` explizit aus
  - bei lokalen Konten wird `NgcSet = NO` weiterhin nicht fälschlich als fehlende Windows-Hello-Einrichtung bewertet
  - praktisch auf dem aktuellen lokalen Konto bestätigt: alle vier Werte `NO`; lokales Konto korrekt erkannt
- [x] Security-Baseline um Microsoft-Defender-Status erweitert
  - Status wird über `Get-MpComputerStatus` ermittelt
  - `AntivirusEnabled`, `AntispywareEnabled`, `RealTimeProtectionEnabled` und `BehaviorMonitorEnabled` werden explizit ausgegeben
  - sobald mindestens eine dieser Schutzkomponenten deaktiviert ist, erzeugt der Bootstrap eine Warnung
  - praktisch auf dem aktuellen System bestätigt: alle vier Schutzkomponenten aktiv

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

## C# / .NET / WPF

Feste Entscheidung:

- moderne C#-Entwicklung erfolgt in Visual Studio Code mit dem Microsoft `C# Dev Kit`
- produktiver SDK-Track ist `.NET 10` LTS
- WPF-Entwicklung verwendet moderne SDK-Style-Projekte mit `Microsoft.NET.Sdk`, Windows-TFM und `UseWPF = true`
- klassisches `.NET Framework` ist nicht Teil des Standard-Workflows und wird nur bei einem konkreten Legacy-Projekt ergänzt
- der vorhandene Repository-Compilecheck für lose verwaltete `.cs`-Dateien bleibt als eigener Qualitätscheck bestehen und wird nicht durch Projekt-Builds ersetzt

Umsetzung / Teststatus:

- [x] `.NET 10 SDK` über den bestehenden deklarativen Development-Paketworkflow installieren und aktualisieren
- [x] vorhandenes `ms-dotnettools.csdevkit` als VS-Code-C#-Workflow praktisch mit installiertem System-SDK bestätigen
- [x] `dotnet --info` nach dem Bootstrap prüfen
- [x] neues C#-Console-Projekt mit `dotnet new console`, `dotnet build` und `dotnet run` praktisch testen
- [x] neues WPF-Projekt mit `dotnet new wpf`, `dotnet build` und Start der Anwendung praktisch testen
- [x] WPF-Projekt in VS Code öffnen und C#-Bearbeitung, Solution Explorer und Debugging praktisch bestätigen
- [x] `just check` und vollständigen `just update-log` nach der Integration erfolgreich ausführen
## Node.js

- [x] fnm installieren
- [x] Node immer gegen die aktuelle LTS-Version prüfen und nur bei Versions-Drift über fnm aktualisieren
- [x] npm separat gegen `npm@latest` prüfen und bei unverändertem Stand nicht neu installieren
- [x] pnpm separat gegen `pnpm@latest` prüfen und bei unverändertem Stand nicht neu installieren
- [x] Yarn separat gegen `yarn@latest` prüfen und bei unverändertem Stand nicht neu installieren
- [ ] tatsächliche npm-/pnpm-/Yarn-Updateinstallation bei einer zukünftig vorhandenen neueren Version erneut praktisch bestätigen
- [x] PATH / `PNPM_HOME`
- [x] npm während desselben Bootstrap-Laufs verfügbar machen

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
- [x] Submodule bei jedem Bootstrap synchronisieren und bei Bedarf initialisieren
- [x] `origin/main` bei jedem Bootstrap per Fetch prüfen
- [x] `git pull --ff-only origin main` nur ausführen, wenn der Remote-Commit tatsächlich neuer ist und ein Fast-Forward möglich ist
- [x] bei identischem lokalen/Remote-HEAD ohne Stash, Checkout oder Pull fortfahren
- [x] neue Commits des extern verwalteten Submodules durch `ignore = all` nicht als lokale Änderung von `windows-setup` behandeln
- [x] Änderungen am extern verwalteten Neovim-Repository nicht automatisch in die Git-History von `windows-setup` übernehmen

### Lokale Änderungen im Neovim-Submodule

- [x] lokale Änderungen einschließlich untracked Dateien nur dann vorübergehend sichern, wenn ein tatsächliches Remote-Update einen Pull erfordert
- [x] Bootstrap-Stash mit eindeutiger Nachricht erzeugen
- [ ] optimierten Updatepfad mit neuem Remote-Commit und vorhandenen lokalen Änderungen erneut praktisch bestätigen
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
- [x] npm-/pnpm-/Yarn-Cacheziele und Bun-/Go-Umgebungswerte über lokalen State nur bei geändertem Desired State erneut konfigurieren

---

# 13. Phase 10 – PowerShell und Codequalität

- [x] PowerShell 7
- [x] verwaltete C#-Quelldateien als Teil desselben Source-Code-Qualitätsworkflows kompilieren; Compilerwarnungen gelten als Fehler
- [x] Git-basierter Source-Code-Fingerprint berücksichtigt PowerShell- und C#-Dateien
- [x] `just check` nach C#-Integration praktisch mit PSScriptAnalyzer und C#-Compilecheck bestätigt
- [x] PowerShell-Module automatisiert installieren
- [x] PSScriptAnalyzer
- [x] BurntToast
- [x] PSWindowsUpdate
- [x] fingerprint-gesteuerte strikte Codeprüfung vor der eigentlichen Setup-Logik; unveränderter Code überspringt PSScriptAnalyzer, geänderter Code muss den vollständigen Preflight bestehen
- [x] Fehler, Warnungen und Hinweise getrennt zählen
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
- [x] Projektcommands beim Verlassen des Repositories wieder vollständig entfernen
- [x] dynamische Projektcommands mit `zoxide`-Verzeichniswechsel praktisch getestet
- [x] CLI-Installation und Wiederholung über `just update` getestet
- [ ] `just check` nach Profilanpassungen ausführen

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
- [x] früheres Catppuccin-Mocha/Mauve-Custom-CSS vollständig entfernt
- [x] Zen wieder auf das native Standard-Theme zurückgeführt und praktisch bestätigt
- [x] `userChrome.css` vollständig entfernt; keine leere Platzhalterdatei im Repository
- [x] `userContent.css` vollständig entfernt
- [x] Catppuccin-Zen-Logo vollständig entfernt
- [x] hostbezogene Website-Styles für GitHub, ChatGPT, YouTube, Google Search, PayPal und Reddit vollständig entfernt
- [x] frühere Website-Style-Junction aus dem aktiven Zen-Profil entfernt
- [x] alter lokaler Catppuccin-State unter `.generated/state/zen/` wird bereinigt
- [x] `Set-ZenTheme` verwaltet als Desired State ausschließlich die Abwesenheit der früheren repositoryverwalteten Custom-CSS-Artefakte
- [x] Zen wird bei tatsächlichem Cleanup-Drift kontrolliert neu gestartet; ein wiederholter Lauf ohne Altbestand bleibt störungsarm

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

# 18. Phase 15 – Native Windows Desktop

## Aktueller produktiver Zustand

- [x] Seelen UI vollständig verworfen
- [x] FluentFlyout vollständig verworfen
- [x] Windhawk vollständig verworfen
- [x] Windows 11 übernimmt Desktop, Taskleiste und native System-OSDs
- [x] PowerToys FancyZones bleibt als optionale, klar abgegrenzte Window-Management-Erweiterung
- [x] Windows Snap bleibt aktiviert
- [x] Fullscreen-/Borderless-Verhalten nach der Bereinigung praktisch bestätigt
- [x] Alt+Tab und Fokuswechsel mit Spielen praktisch bestätigt
- [x] normalen Desktop-/Fensterworkflow nach der Bereinigung praktisch bestätigt

## Feste Entscheidung

Keine zusätzliche Desktop-Shell oder rein optisch motivierte Windows-Hook-Schicht wird erneut eingeführt, solange kein konkreter funktionaler Bedarf und ein praktisch belegter Stabilitätsgewinn bestehen.

---
# 19. Phase 16 – ehemaliges masir / Focus Follows Mouse

- [x] masir war implementiert und praktisch getestet
- [x] masir im Zuge des Seelen-Architekturwechsels bewusst entfernt
- [x] Focus-follows-mouse ist kein aktuelles Desktop-Ziel mehr

---

# 20. Phase 17 – ehemalige Desktop-Bar-Experimente

- [x] Zebar war implementiert und wurde später verworfen
- [x] Seelen UI war anschließend produktiv und wurde wegen Stabilitätsproblemen ebenfalls verworfen
- [x] aktuelle Desktop-/Taskleisten-Zuständigkeit liegt ausschließlich bei Windows 11
- [x] kein separates Desktop-Bar-/Dock-System mehr

---
# 21. Phase 18 – Windows File Explorer

## Aktueller produktiver Zustand

- [x] Files als produktiven Dateimanager verworfen und aus dem Setup entfernt
- [x] Windows File Explorer wieder als alleinigen produktiven Dateimanager festgelegt
- [x] keine Explorer-Ersatzsoftware als Voraussetzung des Setups
- [x] `Win + E` bleibt beim nativen Windows Explorer

## Feste Entscheidung

Ein alternativer Dateimanager wird nur wieder aufgenommen, wenn ein klarer funktionaler Bedarf besteht und der Nutzen den zusätzlichen Integrations- und Stabilitätsaufwand rechtfertigt.

---
# 22. Phase 19 – Native Windows OSD / Shell-Personalisierung

## Aktueller produktiver Zustand

- [x] FluentFlyout verworfen
- [x] Windhawk verworfen
- [x] Lock-Key-, Volume-, Media- und sonstige Systemanzeigen werden nicht mehr durch zusätzliche Overlay-/Hook-Software ersetzt
- [x] keine systemweiten Resource-Redirects mehr
- [x] Windows-Shell-Personalisierung beschränkt sich auf stabile, dokumentierte Windows-Einstellungen
- [x] `config/windows.psd1` bleibt Desired State für Taskleisten-/Start-/Windows-Einstellungen
- [x] Windows übernimmt die native Desktop-, Taskleisten- und OSD-Zuständigkeit

---

# 23. Phase 20 – System-OSD

- [x] eigenes Volume-/Mute-OSD verworfen
- [x] Seelen-OSD verworfen
- [x] FluentFlyout verworfen
- [x] Windows übernimmt Volume-, Media- und System-OSD nativ
- [x] kein zusätzlicher OSD-Prozess oder Scheduled Task

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
- [x] wiederholter `just update` verursacht keine unerwartete Neuinstallation
- [x] sensible Verbindungsdaten bleiben außerhalb des Repositories

## E-Mail / Konten-Automatisierung

Ziel ist eine reproduzierbare Mail-Einrichtung, ohne Klartext-Zugangsdaten im Repository abzulegen.

### Secrets

- [ ] verschlüsseltes Secrets-Konzept für Mail-Zugangsdaten entwerfen, vergleichbar mit dem Prinzip von `sops-nix` + `age`
- [ ] ausschließlich verschlüsselte Daten dürfen versioniert werden; private Entschlüsselungsschlüssel bleiben außerhalb des Repositories
- [ ] Bootstrap darf Secrets nur für den unmittelbar benötigten Konfigurationsschritt entschlüsseln und keine Klartext-Credentials dauerhaft in `.generated/`, Logs oder Git-Artefakten hinterlassen
- [ ] OAuth-Tokens und anwendungsspezifische Tokens nur über offiziell unterstützte Client-/Provider-Mechanismen verwalten
- [ ] Secrets-Architektur vor Implementierung anhand aktueller Windows-/Client-Schnittstellen verifizieren

### Mail-Client: eM Client

Die Mail-Client-Auswahl wurde am 2026-08-18 nach praktischen Tests mit Thunderbird, Outlook Classic, Canary Mail und eM Client abgeschlossen. **eM Client ist der produktive Mail-Client.**

#### Verbindliche Entscheidung

- [x] eM Client über Winget-Paket `eMClient.eMClient` installieren und aktualisieren
- [x] Exchange/EWS mit dem vorhandenen On-Premises-Exchange praktisch erfolgreich getestet
- [x] klassische IMAP-/SMTP-Konten praktisch erfolgreich getestet
- [x] vollständige Account-/Client-Konfiguration über den offiziellen eM-Client-Settings-Export sichern
- [x] Account-Passwörter werden ausschließlich über den von eM Client selbst erzeugten verschlüsselten Export wiederhergestellt; keine eigene Credential-Erzeugung und kein Reverse Engineering interner eM-Client-Datenbanken oder Assemblies
- [x] vollständigen Settings-Export zusätzlich mit SOPS verschlüsseln und als `secrets/emclient-settings.sops.xml` versionieren
- [x] Export-/Import-Passwort verschlüsselt unter `emclient.import_password` in `secrets/mail.sops.json` verwalten
- [x] Import derselben Konfiguration über SHA-256-State unter `.generated/state/emclient/settings.sha256` idempotent überspringen
- [x] kompletter Bootstrap mit eM-Client-Backup-/Restore-Integration auf dem aktuellen System fehlerfrei getestet

#### Manueller Backup-Workflow

Für Änderungen an Accounts oder relevanten eM-Client-Einstellungen existiert bewusst ein manueller Snapshot-Einstieg, während Verschlüsselung und Versionierung wieder automatisiert erfolgen:

1. In eM Client einen vollständigen Settings-Export inklusive gespeicherter Account-Passwörter erstellen.
2. Den Export mit dem definierten eM-Client-Exportpasswort schützen.
3. Die Datei exakt als `%USERPROFILE%\windows-setup\.generated\emclient\settings.xml` speichern.
4. Beim nächsten Bootstrap erkennt `Protect-EMClientSettings` diese Datei automatisch.
5. SOPS verschlüsselt zuerst in eine temporäre Zieldatei.
6. Nur nach erfolgreicher Verschlüsselung wird `secrets\emclient-settings.sops.xml` atomar ersetzt.
7. Erst danach wird die Klartextdatei unter `.generated\emclient\settings.xml` gelöscht.
8. Schlägt SOPS fehl, bleiben sowohl das bisherige verschlüsselte Backup als auch der neue Klartext-Export erhalten.

Damit ist `.generated\emclient\settings.xml` ausschließlich ein lokaler Übergabepunkt für einen bewusst erzeugten neuen Snapshot und niemals ein versioniertes Secret-Artefakt.

#### Restore-Workflow

- [x] `Restore-EMClientSettings` entschlüsselt den SOPS-Export ausschließlich temporär nach `%TEMP%\emclient-settings.xml`
- [x] das Import-Passwort wird aus SOPS gelesen, aber nicht auf stdout/stderr geschrieben
- [x] das Passwort wird ausschließlich temporär in die Windows-Zwischenablage gelegt
- [x] der eM-Client-Settings-Import wird automatisch gestartet
- [x] Benutzer fügt das Passwort einmal per `Strg+V` in den eM-Client-Passwortdialog ein
- [x] nach Benutzerbestätigung wird die Zwischenablage geleert
- [x] Passwortvariablen werden verworfen und die temporäre Klartext-XML wird gelöscht
- [x] Restore mit zwei entfernten und anschließend vollständig wiederhergestellten Accounts praktisch bestätigt; beide Accounts funktionierten danach ohne erneute Account-Passworteingabe

#### Dokumentierte verworfene Ansätze

**Thunderbird 153 ESR**

- Ein umfangreicher Provisionierungsprototyp für IMAP, Gmail OAuth und Exchange/EWS wurde umgesetzt und getestet.
- Die dafür entstandene Marionette-/Account-Provisionierungslogik war deutlich komplexer als der gewünschte stabile Restore-Workflow.
- Thunderbird ist deshalb nicht mehr Bestandteil des Zielbilds; `Thunderbird.ps1`, `Provisioning.ps1` und `Provisioning.State.ps1` werden vollständig entfernt.

**Outlook Classic**

- Outlook Classic wurde über das Office Deployment Tool gezielt als einzig benötigte Microsoft-365-Anwendung installiert.
- Die automatisierte Account-Provisionierung über Outlooks interne `IOlkAccountManager`-/COM-Schnittstellen und den klassischen Account-Wizard wurde praktisch untersucht.
- Die relevanten APIs erwiesen sich für den gewünschten stabilen, wartbaren Setup-Pfad als ungeeignet bzw. undokumentiert; UI-Automation des Wizards war ebenfalls nicht zuverlässig.
- Dieser Ansatz wird nicht erneut verfolgt. `Outlook.ps1`, `config/outlook.psd1` und die Office-Deployment-Tool-Abhängigkeit werden entfernt.

**Canary Mail**

- Canary wurde als möglicher EWS-Client praktisch getestet.
- Die eingebettete Java-Runtime enthielt zunächst nicht die für den Exchange-Endpunkt benötigte aktuelle Certum-Zertifikatskette; ein separater Java-TLS-Test mit ergänztem Truststore bestätigte anschließend funktionierendes TLS.
- Danach antwortete Exchange korrekt mit `401` und `WWW-Authenticate: NTLM`; Canary schloss die für diesen Server benötigte Anmeldung dennoch nicht erfolgreich ab.
- Canary ist deshalb verworfen und erhält keine Setup-/Restore-Integration.

**eM-Client-Credential-Reverse-Engineering**

- Die lokale `accounts.dat` wurde ausschließlich diagnostisch als SQLite-Datenbank betrachtet; eM Client speichert Credentials intern als verschlüsselte Secrets.
- Ein Nachbau dieser Verschlüsselung wurde bewusst abgebrochen.
- Verbindliche Regel: keine internen Credential-Formate, privaten APIs oder Assemblies von eM Client reverse-engineeren. Wiederherstellung erfolgt ausschließlich über den offiziellen Settings-Export/-Import.

#### Besonderheit des eM-Client-CLI-Imports

Die dokumentierte Passwortübergabe per `-p PASS` wurde mit eM Client 10.4.5663 praktisch getestet, verhinderte den Passwortdialog jedoch nicht. Deshalb wird das Passwort bewusst nicht als CLI-Argument weitergereicht. Der sichere Fallback ist die einmalige Zwischenablage-Übergabe an den Benutzer. So erscheint das Secret weder im Warp-Terminal-Log noch in der Prozesskommandozeile.

#### Akzeptanzkriterien

- [x] eM Client reproduzierbar über Winget installiert
- [x] Exchange/EWS praktisch funktionsfähig
- [x] IMAP/SMTP praktisch funktionsfähig
- [x] vollständiger Settings-Export inklusive gespeicherter Account-Credentials erfolgreich wiederhergestellt
- [x] SOPS-Verschlüsselung eines neuen `.generated\emclient\settings.xml`-Snapshots erfolgreich getestet
- [x] Klartext-Snapshot wird erst nach erfolgreicher Verschlüsselung entfernt
- [x] verschlüsseltes Backup wird nur nach erfolgreicher Neuerzeugung ersetzt
- [x] Restore-Passwort erscheint nicht im Bootstrap-/Warp-Log
- [x] Zwischenablage wird nach dem manuellen Einfügen geleert
- [x] temporäre entschlüsselte XML wird nach Restore gelöscht
- [x] wiederholter Bootstrap überspringt unveränderten Import per State-Hash
- [x] vollständiger Bootstrap nach Integration fehlerfrei ausgeführt
# 26. Phase 23 – Gaming

## Ziel

Das System soll nach Neuinstallation auch als Gaming-PC möglichst schnell einsatzbereit sein.

## Bereits vorhanden / praktisch bestätigt

- [x] separates `G:`-Games-Laufwerk
- [x] Gaming-Funktionen im Debloat nicht aggressiv entfernen
- [x] NVIDIA-Treiber-/App-Workflow
- [x] eigene Paketgruppe `Gaming`
- [x] Steam installiert und angemeldet
- [x] Epic Games Launcher installiert und angemeldet
- [x] GOG GALAXY installiert und angemeldet
- [x] EA app installiert und angemeldet
- [x] Battle.net installiert und angemeldet
- [x] Ubisoft Connect installiert und angemeldet
- [x] Battle.net über den generischen Winget-`InstallLocation`-Pfad erfolgreich installiert

## Launcher-Installationspfade / Erstinitialisierung

Der Bootstrap erzwingt Launcher-Installationspfade nicht über undokumentierte interne Konfigurationsdateien. Stattdessen wird die bereits etablierte Strategie für einmalige Benutzerinteraktionen verwendet.

- [x] relevante Gaming-Launcher dynamisch aus `config/packages/` → `Gaming` ableiten
- [x] Launcher über `GameLibrary` deklarativ einem Eintrag aus `config/storage.psd1` → `GameLibraries` zuordnen
- [x] interaktive Launcher-Initialisierung erst starten, nachdem Games Drive und sämtliche konfigurierten Game-Library-Verzeichnisse vorhanden und verifiziert sind
- [x] nur tatsächlich installierte Gaming-Pakete initialisieren
- [x] Benutzer pro Launcher auffordern, den Launcher einmalig zu öffnen und den angezeigten Standard-Installationspfad zu setzen
- [x] Bootstrap pro Launcher bis zur ausdrücklichen Bestätigung des gesetzten Pfads warten lassen
- [x] pro Launcher eigenen Marker unter `.generated/state/gaming-launchers/` verwenden
- [x] Marker erst nach ausdrücklicher Benutzerbestätigung erzeugen
- [x] bereits initialisierte Launcher bei späteren `just update`-Läufen ohne Benutzerinteraktion überspringen
- [x] fehlende Launcher nicht markieren, damit eine spätere Installation weiterhin initialisiert wird
- [x] keine undokumentierten internen Launcher-Datenbanken oder privaten Konfigurationsformate manipulieren
- [x] `just check`, erster interaktiver `just update` und wiederholter störungsfreier `just update` praktisch getestet

Praktisch bestätigt wurde der vollständige Ablauf mit Steam, Epic Games Launcher, GOG GALAXY, EA app, Battle.net und Ubisoft Connect. Nach der Benutzerbestätigung wird für jeden Launcher ein eigener lokaler Marker angelegt. Ein zweiter `just update` erkennt die Marker und fragt die Installationspfade nicht erneut ab.
## Offen

- [x] Steam Library auf `G:\Games\Steam` praktisch einrichten
- [x] Launcher-spezifische Spielebibliotheken unter `G:\Games\` praktisch einrichten
- [x] Default-Spielpfade in Steam, Epic, GOG, EA, Battle.net und Ubisoft Connect über offiziell unterstützte Launcher-Einstellungen soweit möglich auf `G:` setzen
- [x] keine undokumentierten internen Launcher-Datenbanken oder privaten Konfigurationsformate manipulieren
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
- [x] initialisiertes Raycast ohne erneuten Restore behandeln und aktuellen lokalen Export in den generischen Desired State sanitizen
- [x] Volume-/Media-OSD bleibt beim nativen Windows-OSD; kein eigener OSD-Prozess oder Scheduled Task
- [x] Scheduled Tasks vor dem Schreiben gegen ihren tatsächlichen Desired State vergleichen
- [x] PSScriptAnalyzer nur bei geändertem PowerShell-Code über den gemeinsamen strikten Preflight ausführen
- [x] parameterloser/stiller Bootstrap für die automatische Wartung; Konsolenausgabe wird für den Hintergrundtask nicht benötigt
- [x] Rebootstatus
- [x] Git-Status
- [x] ungepushte Commits
- [x] kein automatischer Reboot

## Robustheit externer GitHub-/Content-Abhängigkeiten

- [ ] temporäre GitHub-Ausfälle dürfen nichtkritische Bootstrap-Schritte nicht abbrechen
  - vorhandene lokale Installationen, Repositories und Konfigurationen bei externen Ausfällen weiterverwenden, wenn ihr lokaler Zustand gültig ist
  - Neovim-Remote-Update bei vorhandenem lokalen Submodule mit Warnung überspringen
  - noch nicht initialisierte optionale GitHub-Abhängigkeiten bei Ausfall überspringen statt den Bootstrap abzubrechen
  - eigener Repository-`fetch` bleibt nichtfatal; initialer Clone von `windows-setup` bleibt zwingend
  - keine projektweite pauschale Retry-/Backoff-Schicht einführen; Retry-Verhalten nur dort einsetzen, wo ein konkreter technischer Nutzen besteht
  - lokale/strukturelle Fehler bleiben echte Fehler
  - verbleibende externe Abhängigkeiten gezielt praktisch testen, bevor der Gesamtpunkt als `[x]` markiert wird
- [x] vorhandenes Wallpaper-Repository bei temporärem Git-/GitHub-Ausfall ohne Bootstrap-Abbruch weiterverwenden
  - Remote-Abfrage bei einem normalen Wartungslauf nur einmal versuchen
  - keine festen 2-/4-Sekunden-Retry-Wartezeiten mehr
  - bei fehlgeschlagener Remote-Abfrage sofort mit dem vorhandenen gültigen lokalen Stand fortfahren
  - strukturelle lokale Fehler wie ungültiges Repository, fehlender Wallpaper-Unterordner oder fehlende Bilddateien bleiben echte Fehler
  - Verhalten mit real fehlgeschlagener Remote-Abfrage und anschließend erfolgreichem Bootstrap praktisch bestätigt
- [ ] Wallpaper-Verhalten auf einer Neuinstallation ohne vorhandenen lokalen Stand bei fehlgeschlagenem Clone praktisch testen
  - fehlgeschlagenen Clone als nichtkritischen Schritt mit Warnung überspringen
  - keinen unvollständigen Zielordner als gültigen lokalen Stand behandeln

## Benachrichtigungen

- [x] BurntToast
- [x] relevante Reboot-Meldung
- [x] Repository mit lokalen Änderungen melden
- [x] ungepushte Commits melden
- [x] keine Meldung für reine NSIS-Temp-Cleanup-Renames
- [ ] optional Wartungszusammenfassung auch bei erfolgreichem Lauf
- [ ] optional Fehlerzusammenfassung, wenn einzelne nichtkritische Schritte fehlschlagen

---

# 29. Phase 26 – Stabilitätsbereinigung

## Architekturentscheidung 2026-08-19

Nach wiederkehrenden Problemen mit Fullscreen, Fokus, Alt+Tab und tiefen UI-Anpassungen wird das macOS-/Liquid-Glass-Gesamtziel beendet.

Entfernt:

- [x] Seelen UI
- [x] FluentFlyout
- [x] Windhawk
- [x] Files
- [x] Nushell
- [x] Warp
- [x] Vivaldi Custom HTML/CSS/JS

Beibehalten:

- [x] native Windows-11-Shell und Windows File Explorer
- [x] Windows Terminal + PowerShell 7 + Starship
- [x] PowerToys/FancyZones, weil funktionaler Nutzen unabhängig vom Design besteht
- [x] Raycast + Everything
- [x] Vivaldi als Hauptbrowser im nativen UI
- [x] Zen als Firefox-basierter WebDev-Testbrowser

### Akzeptanzkriterien

- [x] vollständiger `just update-log` nach der Bereinigung erfolgreich
- [x] `just check` erfolgreich
- [x] zweiter `just update-log` ohne Drift-/Altbestandfehler erfolgreich
- [x] Vivaldi-Fullscreen-Video stabil
- [x] Alt+Tab aus Spiel und Rückkehr ins Spiel stabil
- [x] normale Fenster bleiben fokussierbar, verschiebbar und vollständig erreichbar
- [x] Windows Explorer ist wieder Standard für `Win + E`
- [x] entfernte Software ist auf dem System nicht mehr installiert

---
# 30. Phase 27 – Dokumentation

## README

Das README soll den **aktuellen produktiven Stand** erklären.

- [x] Installationsweg
- [x] Bootstrap-Grundidee
- [x] Execution-Policy-Verhalten
- [x] Just-Workflow
- [x] `just update`
- [x] `just update-warning`
- [x] `just update-log`
- [x] `just update-performance`
- [x] `just check`
- [x] `just ghub-backup`
- [x] `just ghub-restore`
- [x] störungsarme Zen-Mod-Prüfung dokumentiert
- [x] G-HUB-Initialisierung/Backup/Restore dokumentiert
- [x] Desktop-Zielbild
- [x] Windows File Explorer als produktiver Dateimanager dokumentiert
- [x] NanaZip
- [x] Raycast als primärer Launcher inklusive Desired-State-/Backup-/Restore-Workflow
- [x] generischer Standard-App-Initialisierungsworkflow
- [x] lokale State-Marker unter `.generated/state/default-apps/`
- [x] Hardlinks/Junctions
- [x] Windows-Terminal-Desired-State, Initialisierung und Symlink-Fallback dokumentiert
- [x] Catppuccin
- [x] Wartung
- [ ] macOSicons-/Third-Party-Icon-Attribution inklusive tatsächlich verwendeter Icon-Ersteller dokumentieren
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
- [x] Just-Workflow
- [x] Execution-Policy-Architektur
- [x] Desktop-Neustart-Architektur
- [x] Zen-Mod-Precheck
- [x] G-HUB-Snapshot-Strategie
- [x] Standard-App-Initialisierungsstrategie
- [x] NanaZip-Default-App-Workflow
- [x] Raycast ersetzt PowerToys Command Palette als primären Launcher; Desired-State-/Initialisierungsstrategie dokumentiert
- [x] Markdown-Ausgaberegel für vollständig kopierbare Dateien
- [x] klare nächste Prioritäten
- [ ] bei jeder größeren Designentscheidung aktualisieren

---

## Noch offen

- [ ] separate technische Projektdokumentation erstellen; README bleibt bewusst eine kompakte Benutzerübersicht

# 31. Bewusst verworfene oder nicht weiter zu verfolgende Ansätze

Eine KI soll diese Punkte **nicht erneut vorschlagen**, außer es gibt einen neuen technischen Grund.

## Stabilitätsbereinigung 2026-08-19

- [x] Seelen UI verworfen: Fokus-/Fullscreen-/Fensterprobleme und zusätzliche Shell-Komplexität
- [x] FluentFlyout verworfen: kein ausreichender funktionaler Nutzen für eine zusätzliche OSD-Schicht
- [x] Windhawk verworfen: systemweite Hook-/Resource-Redirect-Schicht für rein optische Änderungen nicht mehr gewünscht
- [x] Files verworfen: Windows Explorer reicht als stabiler nativer Dateimanager
- [x] Nushell verworfen: wird im tatsächlichen Workflow nicht genutzt
- [x] Warp verworfen: kein ausreichender Vorteil gegenüber Windows Terminal
- [x] Vivaldi-Custom-HTML/CSS/JS verworfen: Browser-Stabilität und Fullscreen-Verhalten haben Vorrang vor Safari-/Liquid-Glass-Styling
- [x] macOS-/Liquid-Glass-Gesamtziel verworfen: Windows soll funktional, stabil und wartbar sein statt ein anderes Betriebssystem optisch nachzubauen

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
- [x] eigene Catppuccin-CSS-Overrides für iCloud, Exchange OWA und Intrexx 11 weiterverfolgen
  - die drei Weboberflächen wurden praktisch mit hostbezogenen `userContent.css`-Regeln getestet
  - das Ergebnis war unvollständig bzw. nicht zuverlässig genug für einen wartbaren produktiven Desired State
  - die Styles wurden deshalb wieder entfernt
  - ein erneuter Versuch erfolgt nur bei einem neuen stabilen technischen Ansatz
- [x] Windhawk als Lock-Key-OSD erneut einführen
  - FluentFlyout liefert das gewünschte Verhalten stabiler und mit nativer Animation
  - eigener FluentFlyout-Fork erlaubt den erforderlichen Bottom-Offset oberhalb des Seelen-Docks
  - Windhawk und der eigene Windhawk-Mod wurden vollständig aus dem produktiven Setup entfernt

---


## Desktop-Architekturwechsel 2026-08-16

- [x] komorebi / whkd / masir als produktiven Desktop-Stack verworfen
- [x] Zebar als produktive Desktop Bar verworfen
- [x] eigenes Volume-/Mute-OSD verworfen
- [x] alte Windhawk Taskbar-/Start-/Notification-Styler verworfen
- [x] Seelen UI als zentrale Desktop-Shell gewählt
- [x] FancyZones als optionales Window Management gewählt
- [x] Windhawk auf Lock Keys Notifier reduziert
- [x] Legacy-Code nach erfolgreichem `just check` und `just update-log` entfernt
- [x] neues Hauptziel: maximale macOS-26-Nähe ohne Beschädigung der Windows-Integrität
---

# 32. Prioritäten / empfohlene nächste Schritte

## Aktuelle Hauptpriorität – Qualität / Robustheit

1. [x] Desktop-Bereinigung praktisch testen
2. [x] Fullscreen-/Alt+Tab-/Fokus-Probleme nach Entfernung der zusätzlichen UI-Schichten erneut testen
3. [x] Windows-Snap-/FancyZones-Konfiguration abschließen und praktisch bestätigen
4. [x] Bootstrap-Performance-Regression lokalisieren, beheben und dokumentieren
5. [x] lokale Testbasis mit Pester für kritische Helper aufbauen
   - Pester über den bestehenden PowerShell-Modulworkflow (`Install-PowerShellModules`) verwalten
   - `tests/` als zentrale lokale Teststruktur verwenden
   - `just test` als einheitlichen lokalen Test-Einstieg verwenden
   - initiale Smoke-Tests laden die zentralen Helper und prüfen die Verfügbarkeit kritischer Helper-Funktionen
   - `just check`, vollständiger `sudo just update-log` und `just test` praktisch erfolgreich
   - initialer Teststand: 3 Tests, 3 bestanden, 0 fehlgeschlagen
6. [x] Tests für Paket-Versionserkennung ergänzen
   - `Get-WingetInstalledVersion` isoliert mit gemocktem `winget` testen
   - exakte Paket-ID korrekt erkennen
   - ähnlich benannte Paket-IDs nicht verwechseln
   - ANSI-Terminalsequenzen vor der Auswertung korrekt entfernen
   - fehlgeschlagenes `winget list` liefert `$null`
   - nicht vorhandene Paket-ID liefert `$null`
   - `just test` praktisch erfolgreich: 8 Tests, 8 bestanden, 0 fehlgeschlagen
7. [x] Tests für Hardlink-/Junction-Migration ergänzen
   - Hardlink-Erstellung und Zielerkennung testen
   - normale Dateien ohne `-ReplaceExistingFile` nicht überschreiben
   - explizite Migration normaler Dateien auf Hardlinks testen
   - Hardlink-Idempotenz beim zweiten Lauf testen
   - Junction-Erstellung und Zielerkennung testen
   - Junctions mit falschem Ziel auf den gewünschten Zielzustand migrieren
   - echte Verzeichnisse nicht durch Junctions überschreiben
   - Junction-Idempotenz beim zweiten Lauf testen
   - tatsächliche NTFS-/PowerShell-Linkzustände auf dem aktuellen System praktisch verifiziert
   - `just test` praktisch erfolgreich: 15 Tests, 15 bestanden, 0 fehlgeschlagen
8. [x] Tests für Reboot-Erkennung ergänzen
   - Zustand ohne Reboot-Indikatoren testen
   - CBS `RebootPending` erkennen
   - Windows Update `RebootRequired` erkennen
   - relevante `PendingFileRenameOperations` erkennen
   - reine NSIS-/Installer-Temp-Cleanup-Renames weiterhin ignorieren
   - gemischte Pending-Rename-Listen korrekt auf relevante Einträge reduzieren
   - `Test-PendingReboot` als booleschen Wrapper testen
   - Reboot-Tests vollständig isoliert mit Pester-Mocks gegen Registryzugriffe ausführen
   - `just test` praktisch erfolgreich: 22 Tests, 22 bestanden, 0 fehlgeschlagen
9. [x] Logging / maschinenlesbare Abschluss- und Paket-Zusammenfassung weiter ausbauen
   - erfolgreichen Bootstrap-Lauf zusätzlich als `.generated/logs/bootstrap-last-summary.json` schreiben
   - versioniertes JSON-Schema über `SchemaVersion = 1` kennzeichnen
   - Status und ISO-8601-Zeitstempel erfassen
   - verwaltete Pakete nach Gesamtzahl, Source und Paketgruppe zusammenfassen
   - Pending-Reboot-, Windows-Update- und Treiber-Rebootstatus erfassen
   - Repository-Änderungen, geänderte Dateien und ungepushte Commits erfassen
   - Report ausschließlich unter `.generated/` erzeugen und nicht versionieren
   - Report-Erzeugung mit Pester auf Paketaggregation und parsebares JSON testen
   - `just check`, `just test` und vollständiger `sudo just update-log` praktisch erfolgreich
   - erzeugten Realreport praktisch geprüft: 47 verwaltete Pakete, konsistente Gruppen-/Source-Summen, kein Reboot erforderlich
10. [x] GitHub Actions erst nach belastbarer lokaler Testbasis ergänzen
    - CI läuft auf `windows-latest`
    - bestehende PowerShell-Codechecks werden ohne Fingerprint-Schreibzugriff ausgeführt
    - Pester-Tests laufen reproduzierbar mit der lokal verwendeten Pester-Version 3.4.0
    - kein Bootstrap-/System-Setup in CI
    - Workflow läuft bei Push und Pull Request auf `master`
    - lokaler `just check` und `just test` vor Aktivierung erfolgreich
    - realer GitHub-Actions-Push-Lauf auf `master` praktisch erfolgreich bestätigt
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
- [x] RDM-/FileZilla-Embedding praktisch getestet; frühere komorebi-Sonderregel ist mit dem Legacy-Stack entfallen
- [x] frühere Sticky-Notes-Tiling-Sonderregel ist mit dem komorebi-Stack entfallen

Noch offen aus dem Paketmanager-Umbau:

- [x] Scoop-Bucket-Autobereitstellung mit `versions` + `neovim-nightly` praktisch getestet
- [x] Retry-Mechanismus für temporäre Download-/Paketmanagerfehler
- [x] maschinenlesbare Paket-/Update-Zusammenfassung

## Desktop-Stabilität

- [x] zusätzliche Desktop-Shell entfernt
- [x] zusätzliche OSD-/Hook-/Resource-Redirect-Schichten entfernt
- [x] Windows File Explorer wieder als produktiven Dateimanager festgelegt
- [x] Vivaldi-Custom-UI verworfen
- [x] vollständigen nativen Desktop-Workflow praktisch getestet
- [x] Fullscreen-/Borderless-Verhalten praktisch getestet
- [x] Alt+Tab und Fokuswechsel mit mindestens einem Spiel praktisch getestet
- [x] Vivaldi-Fullscreen-Video praktisch getestet
- [ ] PowerToys `Find My Mouse` bei echten Vollbildanwendungen weiter prüfen, falls nach der Bereinigung noch Probleme bestehen
## Kürzlich abgeschlossen – CLI Tools / Shell UX

- [x] `ripgrep` (`rg`) installiert
- [x] `eza` installiert und `ls`-/`ll`-/`la`-/`lt`-Workflow umgesetzt
- [x] `fd`, `bat`, `fzf`, `jq` und `zoxide` installiert
- [x] Neovim Nightly über Scoop `versions` integriert
- [x] Scoop-Zusatz-Bucket `versions` praktisch getestet
- [x] Fish-artige PowerShell-Abbreviations über PSReadLine umgesetzt
- [x] `zoxide` in PowerShell integriert
- [x] Git-Root-basierte Projektcommands umgesetzt
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

1. [x] technische Architektur für Volume/Mute festlegen
2. [x] Volume/Mute produktiv umsetzen
3. [x] Catppuccin-Pill und flackerfreies Burst-Verhalten
4. [x] Bootstrap- und Scheduled-Task-Integration
5. [x] Windows-OSD-Doppelanzeige vermeiden
6. [x] echten `AtLogOn`-Start nach Ab-/Anmeldung oder Neustart praktisch bestätigt
7. [ ] Brightness nur bei neuem, praktisch funktionierendem Hardware-/Softwarepfad erneut prüfen

Lock Keys bleiben beim bereits getesteten Windhawk `Lock Keys Notifier`; ein eigenes Media-OSD ist nicht vorgesehen. Brightness ist auf dem aktuellen System nach WMI-/DDC-/VCP-Test vorerst zurückgestellt.

## Priorität 4 – Gaming

1. [x] Paketgruppe
2. [x] Steam und weitere benötigte Launcher
3. [x] Game-Library-Pfade auf `G:`
4. [ ] sinnvolle Windows-Gaming-Einstellungen
## Priorität 5 – Qualität

1. [x] Pester-Testbasis für kritische Helper
2. [x] Paket-Versionserkennung testen
3. [x] Hardlink-/Junction-Migration testen
4. [x] Reboot-Erkennung testen
5. [x] Logging und maschinenlesbaren Abschlussreport ausbauen
6. [x] GitHub Actions auf Basis der lokalen Tests ergänzen
7. [x] Package-Konfigurationsschema validieren
   - Pflichtfelder `Id`, `Name`, `Source` und `Update` beim Laden prüfen
   - nur unterstützte Paketquellen `winget`, `msstore`, `chocolatey` und `scoop` akzeptieren
   - Scoop-Pakete ohne expliziten `Bucket` ablehnen
   - `GameLibrary`-Referenzen gegen `config/storage.psd1` prüfen
   - reale Package-Konfiguration per Pester laden und validieren
   - `just check` und `just test` praktisch erfolgreich
   - Teststand nach Erweiterung: 27 Tests, 27 bestanden, 0 fehlgeschlagen
8. [x] Dry-Run / WhatIf nach den Kern-Tests bewertet
   - aktuell bewusst nicht implementiert
   - der Bootstrap orchestriert viele unterschiedliche mutierende Helper; ein belastbarer Dry-Run müsste Paketmanager, Updates, Treiber, Links, Registry, App-Konfiguration, Git und Initialisierungen vollständig abdecken
   - ein nur teilweise unterstütztes `-WhatIf` würde einen irreführenden Sicherheitszustand erzeugen und wird daher nicht eingeführt
   - die bestehende Prüfschicht aus `just check`, Pester-Tests und GitHub Actions ist für den aktuellen Projektstand die reproduzierbarere und wartbarere Absicherung
   - erneute Bewertung nur bei einem konkreten Bedarf für eine vollständige, durchgängige `ShouldProcess`-/`WhatIf`-Architektur

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

- [x] `bootstrap.ps1` vergleicht vor der Setup-Logik den Git-basierten PowerShell-Codezustand; nur bei geändertem Code läuft der strikte Preflight, der weiterhin bei Error, Warning oder Information abbricht
- [x] funktionale Bootstrap-Tests werden mit vollständiger Ausgabe über `just update-log` durchgeführt
- [x] Performance-Messungen werden ohne reguläre Bootstrap-Ausgabe über `just update-performance` durchgeführt

## Nach einer Implementierung

1. Funktion gezielt testen.
2. funktionale Bootstrap-Änderungen mit `just update-log` bzw. dem relevanten spezifischen Einstiegspunkt testen; Performance ausschließlich mit `just update-performance` messen.
3. Sicherstellen, dass für den finalen PowerShell-Codezustand ein erfolgreicher strikter Analyzer-Lauf vorliegt: entweder bewusst über `just check` oder automatisch durch den Bootstrap bei geändertem Codezustand.
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
- die Änderung die Systemstabilität nicht verschlechtert,
- bei Desktop-/Fenster-/Grafiknähe Fullscreen, Alt+Tab und Fokus praktisch geprüft wurden,
- sie auf dem aktuellen System getestet wurde,
- ein erneuter Lauf keinen unerwarteten Fehler erzeugt,
- die Umsetzung in den bestehenden Bootstrap integriert ist, sofern sie Teil des automatischen Setups sein soll,
- Konfigurationsdateien reproduzierbar sind,
- keine unnötigen manuellen Schritte bestehen,
- technisch notwendige Benutzerinteraktionen klar geführt, abgewartet und idempotent über lokalen Zustand behandelt werden,
- keine unnötigen Anwendungsneustarts oder Prozessabbrüche bei unverändertem Zustand bestehen,
- keine Secrets im Repository gelandet sind,
- für den finalen PowerShell-Codezustand ein erfolgreicher strikter PSScriptAnalyzer-Lauf vorliegt; dieser darf durch `just check` oder automatisch durch den fingerprint-gesteuerten Bootstrap-Preflight erfolgt sein,
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
- Git/VS Code/Windows Terminal/PowerShell/Starship
- Just als einheitliche manuelle Repository-Bedienoberfläche
- `just update` für Wartungs-/Setup-Läufe
- `just check` für statische Prüfung
- `just ghub-backup` / `just ghub-restore` für bewusste G-HUB-Snapshots
- Browser
- iCloud / Apple Passwords Voraussetzungen
- native Windows-11-Shell + PowerToys FancyZones
- Windows File Explorer als produktiver Dateimanager
- Raycast + Everything als primärer Launcher-/Suchworkflow
- natives Windows-OSD für Volume/Media
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
