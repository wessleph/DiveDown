---
name: 70-doku-code
description: Das Warum im DiveDown-Code dokumentieren — öffentliche Schnittstellen und nicht offensichtliche Entscheidungen, ohne Kommentar-Rauschen.
---

## Wann diese Skill greift
- Nach dem Review, bevor die Entwicklerdoku aktualisiert wird.

## Voraussetzungen (Gate rein)
- `specs/<feature>/review.md` existiert, kritische Befunde sind behoben.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen
1. Dartdoc (`///`) für das **Warum** schreiben, nicht das Was.
2. Öffentliche Schnittstellen vollständig dokumentieren — besonders `lib/domain/`,
   die Sync-Schnittstelle und die FFI-Brücke `lib/divecomputer/`
   (Speicherverwaltung, Threading, welche `libdivecomputer`-Version vorausgesetzt wird).
3. Interne Helfer nur kommentieren, wenn ihr Zweck nicht aus dem Code ersichtlich ist.
4. Wo eine Entscheidung aus einem ADR stammt: kurz auf `docs/adr/NNNN-…` verweisen.
5. Kommentare auf Englisch (wie der Code).

## Ergebnis (Artefakt)
- Dartdoc-Kommentare im Code selbst, keine separate Datei.

## Red Flags — Abbruch und Neustart
- Kommentare beschreiben nur, was die nächste Zeile ohnehin zeigt.
- Öffentliche Klassen/Methoden in `lib/domain/` oder `lib/divecomputer/` ohne Dartdoc.

## Gate raus
- Öffentliche Schnittstellen dokumentiert und vom Menschen kurz gesichtet? Sonst nicht weiter.
