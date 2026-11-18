# ADR 0001: Submersion als Codequelle, eigener Kern

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18
- Bezug: `specs/tauchcomputer-import/research.md`, Abschnitt 8

## Kontext
Submersion (GPL-3.0, Flutter) deckt den Großteil der geplanten DiveDown-Funktionen ab.
Die Codebasis ist allerdings sehr groß: über 200 Datenbanktabellen, etwa 60 Feature-Module und rund 380 MB Checkout.
Das Ziel von DiveDown ist ein **schlankes, wartbares** Produkt mit eigenem Stil, Deutsch als Standardsprache und Familien-Sync über den NAS.

## Optionen
- **F: Fork.** Sofort alle Funktionen. Dafür muss bei jeder Upstream-Änderung abgeglichen werden, und bei vielen eigenen Anpassungen gibt es dauerhaft Merge-Konflikte.
- **G: eigener Kern, gezielte Übernahme.** Mehr Aufwand am Anfang, dafür nur der Code, den wir brauchen.

## Entscheidung
**Option G.** DiveDown ist eine eigenständige Flutter-App unter **GPL-3.0-or-later**. Teile aus Submersion übernehmen wir nach diesen Regeln:

1. **Ganze Module statt Schnipsel**, wo ein Modul in sich geschlossen ist (z. B. das Tauchcomputer-Plugin, siehe ADR 0002).
   Code, der eng mit dem Rest von Submersion verwoben ist, übernehmen wir **nicht**, sondern bauen ihn schlanker neu.
   Beispiel: Das Profildiagramm hat rund 8.200 Zeilen und über 50 interne Importe. Es dient nur als Vorlage.
2. **Herkunft kennzeichnen.** Jede übernommene Datei bekommt einen Kopfkommentar:
   `// Derived from Submersion (https://github.com/submersion-app/submersion), commit <hash>, GPL-3.0. Modified for DiveDown.`
3. **`THIRD_PARTY.md`** im Repo-Wurzelverzeichnis listet alle übernommenen Teile mit Quell-Commit und Lizenz.
   Das gilt auch für mitgelieferte Drittbibliotheken, z. B. usb-serial-for-android (MIT) und libdivecomputer (LGPL-2.1).
4. Name, Logo und Marke „Submersion“ werden **nicht** verwendet.
5. Referenz-Checkout liegt unter `submersion-referenz/` (per `.gitignore` ausgeschlossen); Referenzstand: Commit `e78a87cb` (17.11.2026).

## Konsequenzen
- DiveDown muss Open Source bleiben. Der Quellcode ist öffentlich, z. B. auf GitHub.
- Wenn Upstream Fehler behebt, übernehmen wir das **gezielt und bei Bedarf**, nicht laufend.
- Offen für Phase 20: Verträgt sich die GPL-3 mit den Bedingungen von App Store und TestFlight?
  Optional fragen wir dazu bei den Submersion-Maintainern nach.
