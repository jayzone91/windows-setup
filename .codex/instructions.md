# Codex Instructions

## Projektverständnis

Du arbeitest an einem PowerShell-basierten Windows Setup Framework.

Vor Änderungen:
1. Bestehende Struktur prüfen
2. Vorhandene Module und Helper wiederverwenden
3. Keine parallelen Lösungen erstellen

# Arbeitsweise

## Vor Änderungen

Immer relevante Dateien lesen.

## Änderungen

Änderungen:
- klein halten
- nachvollziehbar machen
- bevorzugt als Diff darstellen

# Architektur beachten

## bootstrap.ps1

Darf nur:
- Reihenfolge steuern
- Module aufrufen
- Konfiguration laden

## config/*.psd1

Enthält nur Daten.

## modules/*.ps1

Enthält Funktionen.

Neue Funktionen müssen:
- eine einzelne Aufgabe erfüllen
- vorhandene Helper nutzen
- mit Verb-Noun benannt sein

# Paketmanagement

Neue Software immer über die vorhandenen Paket-Helper integrieren.

Vor neuen Installern prüfen, ob ein Helper existiert.

# PowerShell Qualität

Nach Änderungen prüfen:
- PSScriptAnalyzer
- ungenutzte Variablen
- falsche Scopes
- unnötige Wiederholungen

# Kommunikation

Bei Architekturänderungen:
1. Problem erklären
2. Lösungsvorschlag machen
3. Änderungen durchführen

# Git

Keine Commits ohne vorherigen Diff-Check.

# Priorität

1. Bestehende Architektur erhalten
2. Stabilität
3. Wartbarkeit
4. Automatisierung
5. Komfort
