---
name: 40-tests
description: Tests für ein DiveDown-Feature schreiben, bevor Implementierungscode entsteht, und bestätigen, dass sie aus dem richtigen Grund fehlschlagen.
---

## Wann diese Skill greift
- Vor jeder Implementierung — auch bei kleinen Änderungen und Bugfixes.

## Voraussetzungen (Gate rein)
- `specs/<feature>/design.md` (und ggf. `ui-spec.md`, `security.md`) existiert und ist abgenommen.
- Bei Bugfix: reproduzierbare Fehlerbeschreibung.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen (TDD-Zyklus)
1. Given/When/Then-Szenarien aus der Spec in `specs/<feature>/tasks.md` auflisten.
2. Test je Szenario schreiben, passend zur Ebene:
   - Domain/Logik: `test/` mit `package:test`
   - SQLite/Sync: Tests gegen In-Memory-DB, Sync gegen Fake-Backend
   - Tauchcomputer: **aufgezeichnete Rohdaten-Dumps** als Fixtures unter `test/fixtures/divecomputer/`
     — Parser-Tests laufen ohne echtes Gerät
   - UI: Widget-Tests (`flutter_test`) inkl. Offline- und Fehlerzustände aus `ui-spec.md`
3. `flutter test` ausführen.
4. **Bestätigen, dass jeder Test aus dem richtigen Grund rot ist** (fehlendes Feature,
   nicht Syntaxfehler, fehlender Import oder falscher Testaufbau). Grund in `tasks.md` notieren.

## Ergebnis (Artefakt)
- Testdateien im Projekt.
- `specs/<feature>/tasks.md`: welche Szenarien abgedeckt sind, mit beobachtetem Fehlschlagsgrund.

## Red Flags — Abbruch und Neustart
- Code wurde vor dem Test geschrieben.
- Test ist sofort grün (nie rot gesehen).
- Fehlschlagsgrund ist nicht erklärbar oder wurde nicht geprüft.
- Tauchcomputer-Tests brauchen ein echtes Gerät, um zu laufen.

## Gate raus
- Für jedes Szenario existiert ein Test, der nachweislich aus dem richtigen Grund rot war?
  Sonst kein Implementierungscode.
