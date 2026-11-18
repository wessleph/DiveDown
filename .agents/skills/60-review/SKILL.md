---
name: 60-review
description: Unabhängiges Review eines fertig implementierten DiveDown-Features gegen die Spec, durch einen frischen Agenten.
---

## Wann diese Skill greift
- Nach abgeschlossener Implementierung, vor dem Mergen oder einem Release-Build.

## Voraussetzungen (Gate rein)
- Alle Tasks in `specs/<feature>/tasks.md` sind abgehakt, mit Nachweis-Kommando.
- Wenn nicht: STOP. Zurück zu `50-implementierung`.

## Vorgehen
1. Review durch einen **frischen** Agenten/Subagenten, der den Implementierungsverlauf
   nicht kennt — idealerweise ein anderes Modell.
2. Gegen die Spec prüfen (`research.md`, `design.md`, `security.md`, `ui-spec.md`,
   `docs/constitution.md`), nicht gegen Geschmack. Speziell:
   offline-first eingehalten? UI vollständig Deutsch? Alle Zustände aus `ui-spec.md` umgesetzt?
   Autorisierung beim Teilen korrekt?
3. Stub-Detektor: Repo nach `TODO`, `FIXME`, `return null`, `UnimplementedError`,
   hartkodierten Leerantworten durchsuchen.
4. `flutter analyze` und `flutter test` selbst ausführen.
5. Befunde nach Schweregrad ordnen: kritisch / wichtig / nice-to-have.
6. Fragen: Was wurde im Chat erklärt, das eigentlich ins Repo gehört?

## Ergebnis (Artefakt)
- Datei: `specs/<feature>/review.md` mit Befunden nach Schweregrad.

## Red Flags — Abbruch und Neustart
- Review durch denselben Agenten bzw. dieselbe Session, die implementiert hat.
- Kritische Befunde ohne Begründung als „nice-to-have" eingestuft.
- Tests wurden nicht selbst ausgeführt, sondern dem Bericht geglaubt.

## Gate raus
- Kritische Befunde behoben oder bewusst und dokumentiert zurückgestellt — vom Menschen bestätigt?
  Sonst kein Merge.
