---
name: 10-architektur
description: Komponentengrenzen, Datenflüsse und Entscheidungen (ADRs) für ein DiveDown-Feature festlegen. Greift nach abgenommener Recherche, vor jeder Codezeile.
---

## Wann diese Skill greift
- `research.md` eines Features ist abgenommen und es soll gebaut werden.

## Voraussetzungen (Gate rein)
- `specs/<feature>/research.md` existiert.
- Alle offenen Fragen darin sind vom Menschen beantwortet.
- Wenn nicht: STOP. Zurück zu `00-recherche`.

## Vorgehen
1. Komponentengrenzen festlegen. Standard-Schichten in DiveDown:
   - `lib/features/<feature>/` — UI (Widgets, State)
   - `lib/domain/` — Modelle und Regeln, ohne Flutter-Abhängigkeit
   - `lib/data/local/` — SQLite (Quelle der Wahrheit)
   - `lib/data/sync/` — Abgleich mit dem NAS-Backend
   - `lib/divecomputer/` — `dart:ffi`-Brücke zu `libdivecomputer`
   Abweichungen begründen.
2. Datenflüsse skizzieren — immer zwei Varianten: **offline** und **wieder online**
   (inkl. Konflikte bei gleichzeitiger Änderung auf zwei Geräten).
3. Für jede nicht-triviale Entscheidung ein ADR unter `docs/adr/NNNN-titel.md`
   (Kontext, Optionen, Entscheidung, Konsequenzen). Pflicht-ADRs früh im Projekt:
   State-Management, Backend auf dem NAS (Supabase self-hosted vs. PocketBase),
   Sync-/Konfliktstrategie, LGPL-konforme Einbindung von `libdivecomputer` auf iOS,
   Erreichbarkeit des NAS von unterwegs.
4. Gegen `docs/constitution.md` prüfen (offline-first, Deutsch, keine Fremd-Kopien, Lizenzen).

## Ergebnis (Artefakt)
- Datei: `specs/<feature>/design.md` plus ein ADR pro nicht-trivialer Entscheidung.
- Muss enthalten: Komponenten, Schnittstellen, Datenmodell-Änderungen,
  Datenflüsse offline/online, Verweise auf ADRs.

## Red Flags — Abbruch und Neustart
- Komponentengrenzen sind vage („die Logik kommt irgendwo dazwischen").
- Eine Entscheidung mit Tragweite hat keinen ADR, weil sie „offensichtlich" war.
- Ein Datenfluss funktioniert nur mit Netz.
- Geschäftslogik liegt in Widgets oder in der FFI-Schicht.

## Gate raus
- Komponentengrenzen und Datenflüsse vom Menschen bestätigt? Sonst nicht weiter.
