Moin, arbeite bitte mit diesem Repository:

https://github.com/jayzone91/windows-setup

Lies **vor jeder Arbeit zuerst das Repository und vollständig die aktuelle `roadmap.md`**.

## Verbindliche Regeln

Die `roadmap.md` ist für diese Unterhaltung die **verbindliche Source of Truth und Arbeitsanweisung**.

Alle darin dokumentierten Regeln, Architekturentscheidungen, Workflows, Konventionen, bereits getroffenen Entscheidungen, verworfenen Ansätze und Akzeptanzkriterien sind als feste Vorgaben zu behandeln.

Das bedeutet insbesondere:

* Bereits getroffene Entscheidungen nicht ohne konkreten technischen Grund ändern oder erneut infrage stellen.
* Keine alternativen Vorgehensweisen vorschlagen, wenn die Roadmap dafür bereits einen Workflow festlegt.
* Bestehende Projektarchitektur und vorhandene Helper wiederverwenden statt Sonderlösungen einzubauen.
* Vor Änderungen immer den aktuellen Stand der betroffenen Dateien im Repository lesen.
* Nichts anhand von Vermutungen implementieren. Externe APIs, Programme, Konfigurationsformate und Einstellungen bei Bedarf zuerst anhand aktueller Quellen verifizieren.
* Änderungen müssen reproduzierbar und mit dem bestehenden Bootstrap-/`just`-Workflow kompatibel sein.
* Die in der Roadmap definierten Tests und Akzeptanzkriterien gehören zur jeweiligen Aufgabe.
* Ein Punkt wird erst als abgeschlossen betrachtet und in der Roadmap als `[x]` markiert, nachdem wir ihn praktisch getestet haben.
* Wenn eine neue Entscheidung während unserer Arbeit getroffen wird, muss geprüft werden, ob sie als dauerhafte Architekturentscheidung in der Roadmap dokumentiert werden sollte.
* Wenn meine aktuelle Anweisung einer Regel aus der Roadmap widerspricht oder eine bestehende Entscheidung verändern würde, weise mich **vor der Umsetzung** darauf hin.

## Änderungen am Repository

**Niemals direkt in mein GitHub-Repository schreiben, committen, pushen oder einen PR erstellen.**

Wenn Dateien geändert werden müssen:

1. Ermittle zuerst den aktuellen Stand der betroffenen Dateien.
2. Plane die Änderungen passend zur bestehenden Architektur.
3. Erstelle anschließend **einen herunterladbaren `.ps1`-Patch**, der alle notwendigen Änderungen automatisch auf meine lokale Repository-Kopie anwendet.
4. Der Patch muss möglichst idempotent bzw. defensiv sein und darf nicht stillschweigend eine unerwartete Dateiversion überschreiben.
5. Nenne mir danach die Befehle, mit denen ich die Änderung gemäß Projektworkflow testen soll.
6. Nach meinem Testergebnis erstellen wir bei Bedarf einen weiteren Patch, insbesondere für die abschließende Aktualisierung der `roadmap.md`.

Codeblöcke zum manuellen Copy-&-Paste in einzelne Projektdateien sind **nicht der normale Änderungsweg**. Für Repository-Änderungen möchte ich den `.ps1`-Patch als Download.

## Aktuelle Aufgabe

Als Nächstes ist dran:

**Windows 11 Notification Center Styler**

Vorgabe:

* `Matter` als Standardtheme verwenden.
* Das bestehende Matter-Design und Layout möglichst unangetastet lassen.
* Nur die notwendigen Farben auf unsere Catppuccin-Mocha-Farben anpassen.
* Vor der Implementierung die tatsächlichen aktuellen Einstellungen und Möglichkeiten des Windhawk-Mods bzw. des Matter-Themes verifizieren.

Arbeite von dort aus selbstständig nach den Regeln der Roadmap weiter.


---

Windows 11 Notification Center Styler => Theme Matter als Standard und nur noch Farben anpassen
Taskbar auto-hide speed
Lock Keys Notifier



Für nvim:
tree-sitter-cli
zusätzlich repo jayzone91/nvim in windows-Setup einbinden!

Für Windows:
- Wir versuchen die Treiber Updates über Armory Crate von ASUS. Prüfen wir überhaupt, ob armory crate installiert ist? falls ja: installieren wir es, falls es noch nicht da ist? was ist mit updates von armory crate
- Für Windwows Einstellungen:
  - Taskleiste
    - Verhalten der Taskleiste:
      - Taskleiste automatisch ausblenden: AN
      - Rest: Standard
  - Start
    - Zuletzt Hinzugefügte Apps anzeigen: Aus
    - Empfohlene Dateien im Startmenü, zuletzt verwendete Dateien im Datei-Explorer und Elemete in Sprunglisten anzeigen: Aus
    - Empfehlungen für Tipps, Verknüpfungen, neue Apps und Mehr anzeigen: Aus
    - Meistverwendete Apps anzeigen: An
    - Rest: Standard
- Für alle Fenster:
  - Wäre nett, wenn wir die Close, Minimize, Maximize Buttons für alle Fenster global ändern könnten.
    - Idee: MacOS ähnliche Pills jedoch mit Catppuccin farben.
- Programme:
  - ChatGPT App

Für Zebar:
Neues Widget: Aktueller Akku Stand der Logitech Maus (falls auslesbar)
