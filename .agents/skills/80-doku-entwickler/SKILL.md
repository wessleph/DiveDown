---
name: 80-doku-entwickler
description: Entwicklerdoku für DiveDown aktuell halten — Setup, Architekturüberblick, Runbooks für NAS-Betrieb und libdivecomputer-Updates.
---

## Wann diese Skill greift
- Ein Feature ist release-fertig (nach `70-doku-code`).
- Eine neue `libdivecomputer`-Version wurde eingebunden.
- Etwas am NAS-Betrieb (Backend, Backup, Erreichbarkeit) hat sich geändert.

## Voraussetzungen (Gate rein)
- Implementierung und Review sind abgeschlossen; Code-Doku ist erledigt.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen
1. `README.md` aktualisieren: Projekt muss in fünf Minuten lauffähig sein
   (Flutter-Version, `libdivecomputer` bauen, App auf iOS/Android starten).
2. Architekturüberblick in `docs/entwickler/architektur.md` aktualisieren; ADRs verlinken.
3. Runbooks in `docs/entwickler/runbooks/` pflegen — mindestens:
   - `libdivecomputer-update.md`: neue Version holen, bauen, Fixture-Tests, Release
   - `nas-backend.md`: Start/Stop, Updates, Backup und **Wiederherstellung**
   - `release.md`: App für iOS (TestFlight) und Android an Freunde/Familie verteilen
   Jeweils: Symptome, Diagnose-Schritte, Rollback.
4. Rückfrage: „Was wurde in diesem Feature erklärt (Chat, Reviews), das noch nicht im Repo steht?"

## Ergebnis (Artefakt)
- `README.md`, `docs/entwickler/` aktualisiert, Runbooks.

## Red Flags — Abbruch und Neustart
- README beschreibt einen Setup-Schritt, der beim Nachvollziehen nicht funktioniert.
- Backup-Anleitung ohne getestete Wiederherstellung.

## Gate raus
- Ein frischer Agent (oder du selbst in sechs Monaten) kann das Projekt anhand der Doku
  ohne Rückfragen aufsetzen und `libdivecomputer` aktualisieren? Sonst nicht abschließen.
