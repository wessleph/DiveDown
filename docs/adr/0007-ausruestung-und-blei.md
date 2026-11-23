# ADR 0007: Ausrüstung und Blei (Schema v2)

- Status: **angenommen** (2026-11-23)
- Datum: 2026-11-23
- Bezug: ADR 0004 (Datenmodell, „Ausrüstung kommt mit eigenem ADR“), `docs/roadmap.md` Punkt 10, `ui-spec.md` §5.3, §5.4, §5.11

## Kontext
Der Nutzer möchte (Wunsch vom 2026-11-23):
- seine **Ausrüstung** im Profil (Einstellungen, Abschnitt nach „Taucher“) anlegen,
- sie **Tauchgängen zuordnen**, wobei als „Standard“ markierte Teile neue Tauchgänge automatisch bekommen,
- pro Tauchgang das **Blei in kg** eintragen, mit dem Hinweis „Zuletzt hier: 6 kg“ vom letzten Tauchgang am selben Platz.

Entschieden im Gespräch am 2026-11-23: einfache Felder (Art, Bezeichnung, Notiz, keine Wartungstermine), Standard-Set, Blei mit Tauchplatz-Hinweis.
Es ist die erste Änderung am Schema seit v1.

## Optionen
1. **Eigene Tabellen** `equipment` und `dive_equipment` (n:m), Blei als Spalte in `dives`.
2. Ausrüstung als JSON-Text am Tauchgang: einfacher, aber Umbenennen und Auswerten („wie oft getaucht mit …“) gehen dann nicht, und der Sync müsste Texte zusammenführen.
3. Blei als Teil der Ausrüstung (Teil „Blei“ mit Gewicht): Das Gewicht ändert sich aber von Tauchgang zu Tauchgang.

## Entscheidung
**Option 1, Schema v2.**
- Neue Tabelle **`equipment`** mit `SyncColumns` (UUID, `created_at`, `updated_at`, `deleted_at`):
  `diver_id` (→ `divers`), `kind` (Text: `suit`, `bcd`, `regulator`, `computer`, `tank`, `mask`, `fins`, `light`, `other`), `name` (Pflicht, höchstens 60 Zeichen), `notes` (optional), `is_default` (bool, Standard `false`).
- Neue Tabelle **`dive_equipment`** (`dive_id`, `equipment_id`), Schlüssel aus beiden, `ON DELETE CASCADE` am Tauchgang. Wie die anderen Kindzeilen eines Tauchgangs ohne eigene UUID; der Sync überträgt sie mit dem Tauchgang (ADR 0004, Nachtrag 2026-11-20).
- **Löschen** eines Teils ist Soft Delete. Es verschwindet aus der Liste und aus der Auswahl für neue Tauchgänge; bei bisherigen Tauchgängen bleibt es eingetragen und sichtbar.
- **Standard-Set:** Beim Anlegen eines Tauchgangs (manuell und Import) werden alle nicht gelöschten Teile mit `is_default` verknüpft. Ersetzt ein Import einen vorhandenen Tauchgang (gleiche Kennung, anderer Inhalt), bleiben dessen Verknüpfungen. Bearbeiten ändert nur, was der Nutzer auswählt.
- Neue Spalte **`dives.weight_kg`** (real, optional), in kg wie alle Werte in SI. Grenzen 0–40 kg, Schritte von 0,5 kg im Formular.
- **„Zuletzt hier“:** der neueste andere Tauchgang desselben Tauchers mit Blei und gleichem Platz. Gleich heißt: gleiche `site_catalogue_id`, sonst gleicher `site_name` ohne Groß-/Kleinschreibung und Leerzeichen am Rand. Wird nicht gespeichert, sondern abgefragt.
- **Migration v1 → v2** in `AppDatabase.migration` (`onUpgrade`): zwei Tabellen anlegen, eine Spalte hinzufügen, sonst nichts. Mit Migrationstest aus einer echten v1-Datei (ADR 0004, Konsequenzen).
- **Sicherung:** Beide Tabellen gehören zum Logbuch und kommen in die Sicherung (die Datenbankdatei wird ganz kopiert). Eine v1-Sicherung lässt sich weiter wiederherstellen und wird beim Öffnen migriert; eine v2-Sicherung lehnt eine v1-App wie bisher ab (T11.4).
- **Datenschutz:** Bezeichnungen und Notizen der Ausrüstung werden wie Tauchplatz-Namen **nie geloggt**.

## Konsequenzen
- Erste Migration: `latestSchemaVersion` wird 2, Drift-Code neu erzeugen (`dart run build_runner build`).
- Die Domäne bekommt `Equipment` und am `Dive` die Felder `weightKg` und `equipmentIds`.
- Spätere Auswertungen (Tauchgänge pro Teil, Wartung nach Anzahl Tauchgängen) sind ohne weitere Schemaänderung möglich.
