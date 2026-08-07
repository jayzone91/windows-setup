# Windows Setup Project

## Zweck

Dieses Repository automatisiert die Einrichtung und Konfiguration einer Windows-Arbeitsumgebung.

Das Ziel ist eine reproduzierbare Installation mit installierten Programmen, konfigurierten Systemeinstellungen und eingerichteter Entwicklungsumgebung.

# Architektur

## bootstrap.ps1

`bootstrap.ps1` ist ausschließlich der Orchestrator.

Aufgaben:
- Module laden
- Konfiguration laden
- Reihenfolge der Setup-Schritte steuern

Der Bootstrap enthält keine spezifische Installationslogik.

## config/

Der Ordner `config/` enthält ausschließlich Daten.

Beispiele:
- Paketlisten
- Paketgruppen
- Einstellungen

Keine Logik in Konfigurationsdateien.

## modules/

Der Ordner `modules/` enthält die eigentliche PowerShell-Logik.

Jedes Modul besitzt eine klar abgegrenzte Aufgabe.

# Entwicklungsregeln

## Neue Software

Neue Software wird immer über die Konfigurationsdateien hinzugefügt.

Keine fest codierten Installationen in Modulen.

## Paketquellen

Für Pakete verwenden wir:

```powershell
Source = "winget"
```

oder:

```powershell
Source = "msstore"
```

Keine eigene Property `Type` verwenden.

## Module

Module sollen:
- eine klare Verantwortung besitzen
- keine anderen Module direkt laden
- keine globale Logik ausführen

## PowerShell Regeln

Änderungen müssen:
- PSScriptAnalyzer sauber bestehen
- keine ungenutzten Variablen enthalten
- PowerShell Standardbenennung verwenden

Funktionen verwenden:

```powershell
Verb-Noun
```

# Änderungen am Projekt

Vor Änderungen:

```powershell
git status
```

Nach Änderungen:

```powershell
git diff
```

# Ziel

Eine vollständig reproduzierbare Windows-Installation mit minimaler manueller Nacharbeit.
