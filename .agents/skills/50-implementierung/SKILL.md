---
name: 50-implementierung
description: DiveDown-Feature in kleinen, einzeln nachweisbaren Tasks implementieren, bis die roten Tests grün sind.
---

## Wann diese Skill greift
- Nach `40-tests`, für jeden einzelnen Task.

## Voraussetzungen (Gate rein)
- Fehlschlagende Tests für den aktuellen Task existieren und ihr Fehlschlagsgrund ist in `tasks.md` notiert.
- Wenn nicht: STOP. Zurück zu `40-tests`.

## Vorgehen
1. Task-Liste in `specs/<feature>/tasks.md` in Einheiten von wenigen Minuten zerlegen,
   mit exakten Dateipfaden.
2. Für jeden Task ein **Nachweis-Kommando** festlegen, z. B.
   `flutter test test/domain/dive_log_test.dart` oder `flutter analyze`.
   Ohne Kommando ist es kein Task.
3. Minimalen Code schreiben, der den Test grün macht.
4. Refaktorieren; `dart format .` und `flutter analyze` ohne Warnungen.
5. Ein Task, ein Commit (englische Commit-Message).
6. Neue Abhängigkeit nötig? Erst Lizenz prüfen und Mensch fragen — nicht still hinzufügen.

## Ergebnis (Artefakt)
- Commits im Repo.
- `tasks.md` mit abgehakten Tasks und jeweils ausgeführtem Nachweis-Kommando.

## Red Flags — Abbruch und Neustart
- Task ohne automatisiertes Nachweis-Kommando als erledigt markiert.
- Mehrere Tasks in einem Commit.
- Stub-Code: `TODO`, `return null`, leere Listen/Objekte, `UnimplementedError`,
  die den Test nur technisch grün machen.
- Funktion setzt plötzlich Netz voraus (Verstoß gegen offline-first).
- Englische Texte in der UI.

## Gate raus
- Alle Tasks abgehakt, jeder mit erfolgreich ausgeführtem Nachweis-Kommando? Sonst kein Review.
