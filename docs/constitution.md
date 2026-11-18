# DiveDown — Constitution

> Dauerhafte Regeln für dieses Projekt. Wird in jeder Session gelesen — kurz halten.
> Feature-Details gehören in `specs/<feature>/`, Entscheidungen in `docs/adr/`.

## Worum es geht
DiveDown ist eine private Tauch-App für mich, Freunde und Familie (iOS + Android):
Tauchgänge loggen, Tauchplätze auf einer Karte anzeigen, Ausrüstung verwalten,
Tauchgänge teilen — und Tauchgänge direkt vom Tauchcomputer übertragen.

## Tech-Stack
- **App:** Flutter 3.47 (Dart), eine Codebasis für iOS (≥ 15) und Android (minSdk 26).
  Riverpod, go_router, fl_chart (ADR 0005).
- **Lokale Daten:** Drift/SQLite, die lokale DB ist die Quelle der Wahrheit. UUIDs, Soft Delete, SI-Einheiten (ADR 0004).
- **Tauchcomputer:** `libdivecomputer` über das native Plugin `packages/libdivecomputer_plugin`
  (aus Submersion übernommen, Pigeon + Kotlin/Swift, BLE). Importwege: BLE, FIT, Apple Health, manuell (ADR 0002, 0003).
- **Build:** Android lokal (Windows). iOS über GitHub Actions (macOS-Runner) → TestFlight. Es gibt keinen Mac (ADR 0005).
- **Karte:** OpenStreetMap-basiert, Kacheln offline vorab herunterladbar.
- **Backend / Sync:** selbst gehostet auf dem eigenen Home-NAS (24/7):
  Asustor Drivestor 2 Gen2 — ARM64, **1 GB RAM**. Backend muss sparsam sein
  (Richtwert < 150 MB RAM). Favorit: PocketBase (ARM64-Binary, SQLite).
  Supabase self-hosted ist wegen RAM ausgeschlossen. Finale Entscheidung per ADR in Phase 10.

## Nicht verhandelbar
1. **Offline-first.** Jede Kernfunktion (loggen, ansehen, Tauchcomputer auslesen,
   Ausrüstung, Karte für vorab geladene Gebiete) funktioniert ohne Netz.
   Sync ist ein Bonus, nie eine Voraussetzung.
2. **Sprache:** Oberfläche komplett Deutsch. Code, Bezeichner, Commits auf Englisch.
3. **Kein Kopieren proprietärer Apps.** DiveMate dient nur als Vorbild für Funktionen
   (Features, Abläufe, Datenfelder). Kein Dekompilieren, kein Übernehmen von
   Code, Grafiken, Texten oder Markenelementen. Eigener visueller Stil.
   Code aus **Submersion (GPL-3)** darf übernommen werden, aber nur mit Herkunftsangabe im Dateikopf
   und Eintrag in `THIRD_PARTY.md`. Name und Logo „Submersion“ werden nicht verwendet (ADR 0001).
4. **Lizenz:** DiveDown steht unter **GPL-3.0-or-later** und ist Open Source.
   Neue Abhängigkeiten nur mit geprüfter, GPL-3-kompatibler Lizenz.
5. **Keine Tauchsicherheits-Berechnungen als verbindlich darstellen.**
   Werte (z. B. Deko, Sättigung) sind Anzeige vom Tauchcomputer, keine Planung.
6. **Daten von Freunden und Familie sind privat.** Teilen nur explizit und gezielt;
   kein Tracking, keine Werbung, keine Drittanbieter-Analytics.
   Der NAS wird nicht ungeschützt ins Internet gestellt (Details: Phase 20).
7. **Wartbarkeit vor Features.** Ziel ist ein solides Gerüst, das nur bei
   Tauchcomputer-Updates (neue `libdivecomputer`-Version) Pflege braucht.

## Konventionen
- `flutter analyze` ohne Warnungen; Formatierung via `dart format`.
- Tests vor Code (Phase 40). Ein Task = ein Commit.
- Entscheidungen mit Tragweite → ADR unter `docs/adr/NNNN-titel.md`.

## Workflow (Phasen)
Jede Phase liegt unter `.agents/skills/<phase>/SKILL.md` und hat ein Gate.
Nächste Phase erst nach Abnahme durch den Menschen.

`00-recherche` → `10-architektur` → `20-security` → `30-ui-design` → `40-tests`
→ `50-implementierung` → `60-review` → `70-doku-code` → `80-doku-entwickler`

Kleine Änderungen (Bugfix, Text): nur `40-tests` → `50-implementierung` → `60-review`.
