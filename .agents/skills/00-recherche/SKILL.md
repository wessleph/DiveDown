---
name: 00-recherche
description: Kontext und Optionen für ein neues DiveDown-Feature sammeln, ohne eine Lösung festzulegen. Greift zu Beginn jedes neuen Features oder jeder nicht-trivialen Änderung.
---

## Wann diese Skill greift
- Neues Feature (z. B. Logbuch, Tauchplatz-Karte, Ausrüstung, Teilen, Tauchcomputer-Import, NAS-Sync).
- Nicht-triviale Änderung an bestehendem Verhalten.
- Neue `libdivecomputer`-Version oder neues Tauchcomputer-Modell soll unterstützt werden.

## Voraussetzungen (Gate rein)
- Es gibt eine grobe Aufgabenbeschreibung (Wunsch, Notiz, Issue).
- Es ist noch **keine** Lösung festgelegt.
- `docs/constitution.md` ist gelesen.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen
1. Bestehenden Code, `specs/` und `docs/adr/` zum betroffenen Bereich lesen.
2. **Funktionale Vorlage DiveMate auswerten** — nur öffentlich sichtbares Verhalten
   (Store-Beschreibung, Screenshots, eigene Nutzung): Welche Bildschirme, Felder,
   Abläufe gibt es? Was davon braucht DiveDown wirklich? Kein Dekompilieren,
   kein Übernehmen von Code/Grafiken/Texten.
3. Optionen sammeln (Flutter-Pakete, Architekturmuster, `libdivecomputer`-APIs,
   Supabase self-hosted vs. PocketBase o. Ä.), jeweils mit Lizenz.
4. Trade-offs pro Option kurz benennen — immer auch: *Funktioniert das offline?*
   *Läuft das auf dem NAS?* *Wie viel Pflege erzeugt das?*
5. Offene Fragen auflisten, die nur der Mensch beantworten kann
   (Priorität, wer darf was sehen, welche Tauchcomputer besitzen wir, NAS-Modell/Ressourcen).
6. **Keine Entscheidung treffen.** Das ist Aufgabe von Phase 10.

## Ergebnis (Artefakt)
- Datei: `specs/<feature>/research.md`
- Muss enthalten: Kontext, Optionen, Trade-offs, Lizenzen, offene Fragen.

## Red Flags — Abbruch und Neustart
- Das Dokument enthält bereits eine finale Architekturentscheidung → zurück auf Optionen.
- Offene Fragen wurden vom Agenten selbst beantwortet statt dem Menschen vorgelegt.
- Inhalte stammen aus dekompiliertem oder kopiertem Fremdcode.
- Eine Option setzt dauerhaft Netz voraus, ohne dass das als Trade-off markiert ist.

## Gate raus
- Mensch hat die offenen Fragen beantwortet? Sonst nicht weiter zu `10-architektur`.
