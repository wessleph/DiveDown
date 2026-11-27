# ADR 0004: Lokales Datenmodell (Drift/SQLite)

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18

## Kontext
Die lokale Datenbank ist die Quelle der Wahrheit (Constitution: offline-first).
Submersion hat über 200 Tabellen. Für DiveDown reicht ein kleiner Kern, der später um Tauchplätze, Ausrüstung und Teilen erweitert wird.
Der Sync mit dem NAS kommt später, die IDs müssen aber jetzt schon geräteübergreifend eindeutig sein.

## Optionen für Profil-Samples
- **Eine Zeile pro Sample:** einfach abzufragen, gut zu testen. Ein Tauchgang von einer Stunde bei 2 bis 10 Sekunden Intervall ergibt etwa 360 bis 1.800 Zeilen.
- **Samples als Blob pro Tauchgang:** kompakt, aber schlecht abzufragen und schwer zu migrieren.

## Entscheidung
- **Drift** über SQLite, wie bei Submersion. So lässt sich übernommener Code leicht anpassen.
- **IDs sind UUIDs** (Text), keine Autoincrement-IDs. Das ist Voraussetzung für den späteren Sync.
- Jede Tabelle hat `created_at`, `updated_at` und `deleted_at`. Gelöschte Einträge werden nur markiert (Soft Delete), auch das ist Voraussetzung für den Sync.
- **Eine Zeile pro Sample.**
- Alle Werte werden **in SI-Einheiten gespeichert** (Meter, bar, °C, Sekunden, Liter). Umgerechnet wird nur in der Oberfläche.

### Kern-Tabellen (erste Ausbaustufe)
| Tabelle | Inhalt |
|---|---|
| `divers` | Taucher (ich, Schwester, Bruder, Freund), eigenes Profil, `first_dive_number` (Startwert der Nummerierung) |
| `dive_computers` | Gerät: Hersteller, Modell, Seriennummer, Firmware, **letzter Fingerprint** |
| `dives` | Tauchgang: Taucher, **Nummer** (`dive_number`, pro Taucher), **Tauchplatz-Name** (`site_name`, Freitext), Gerät (optional), Quelle + `source_id`, Start, Dauer, max./mittlere Tiefe, Temperaturen, Wassertyp, Notizen, Bewertung |
| `dive_samples` | Zeit, Tiefe, Temperatur, Druck pro Flasche (über `tank_index`), Puls, NDL/Deko, Gas-Index |
| `dive_tanks` | Flasche: Volumen, Start- und Enddruck, Gasgemisch (O₂/He), Index |
| `dive_events` | Ereignisse: Gaswechsel, Warnungen, Aufstieg zu schnell … |

**Luftverbrauch (SAC/RMV)** wird **nicht gespeichert**, sondern aus Samples und Flaschen berechnet (`lib/domain/metrics/`).
So bleibt die Berechnung austauschbar und testbar.

## Konsequenzen
- Migrationen über Drift-`schemaVersion`. Jede Änderung am Schema bekommt einen Migrationstest.
- Tauchplätze, Ausrüstung und Teilen kommen als eigene Features mit eigenem ADR dazu.
- Ob die Datenbank verschlüsselt wird (Submersion nutzt SQLCipher), entscheidet Phase 20.

## Nachtrag 2026-11-18 (Mockup-Review): Nummer und Tauchplatz
- `dives.dive_number`: Die Nummer wird beim Speichern **automatisch** vergeben (höchste Nummer des Tauchers + 1, Start bei `divers.first_dive_number`). Der Nutzer kann sie ändern. Sie ist **nicht** eindeutig erzwungen: Bei doppelter Nummer zeigt die App einen Hinweis, blockiert aber nicht.
  Importiert man ältere Tauchgänge nachträglich, ändern sich die Nummern bestehender Tauchgänge **nicht** automatisch. Eine Funktion „Neu durchnummerieren“ kommt später.
- `dives.site_name`: In v1.0 ist das **Freitext**. Kommt später das Feature Tauchplätze mit Karte, wird daraus ein Verweis auf die Tabelle `dive_sites`. Die Migration legt pro eindeutigem Namen einen Tauchplatz an.
- Datenschutz: `site_name` gilt als persönliche Angabe und wird **nie geloggt** (security.md §3, „Tauchplatz-Namen“).
- **Ergänzung (ADR 0006):** `dives.site_catalogue_id`, `dives.site_lat` und `dives.site_lon` sind optional und werden gesetzt, wenn ein Katalog-Vorschlag gewählt wird. Dazu kommt die nur lesbare Tabelle `catalogue_sites`. Sie gehört **nicht** zur Sicherung und nicht zum Sync.

## Nachtrag 2026-11-20: Schema v1 (Phase 40, T8)
- **Flaschendruck** liegt in einer eigenen Tabelle `dive_tank_pressures` (dive_id, time_s, tank_index, pressure_bar), weil ein Sample mehrere Flaschen haben kann (Plugin: `tankPressuresBar`, T4.3). `dive_samples` hat deshalb keine Druckspalte.
- **Kindzeilen** eines Tauchgangs (`dive_samples`, `dive_tanks`, `dive_tank_pressures`) haben keine eigene UUID und keine Zeitstempel. Ihr Schlüssel ist (`dive_id`, Zeit bzw. Index). Sie werden mit dem Tauchgang gespeichert, ersetzt und per `ON DELETE CASCADE` entfernt. Der spätere Sync überträgt den ganzen Tauchgang. `dive_events` bekommt eine UUID, weil Zeit und Typ nicht eindeutig sind.
- `(diver_id, source, source_id)` ist **kein** Unique-Index in der Datenbank. Sonst ließe sich ein soft-gelöschter Tauchgang nicht erneut importieren (T2.7). Die Duplikaterkennung übernimmt der `ImportService`.
- Zusätzliche Tabelle `app_meta` (Schlüssel/Wert), z. B. für die geladene Katalog-Version. Wie `catalogue_sites` gehört sie nicht zur Sicherung.
- Drift-Zeilenklassen enden auf `Row` (`DiveRow`, `DiverRow` …), damit sie nicht mit dem Domänenmodell (`Dive`, `Diver`) kollidieren.

## Nachtrag 2026-11-27: Schema-Versionen und Regel für Änderungen
- **v1** (2026-11-20): Grundschema. **v2** (2026-11-23, ADR 0007): `dives.weight_kg`, Tabellen `equipment`, `dive_equipment`. **v3** (2026-11-27, T40): `dives.visibility`, `dives.current_strength`, `dives.kinds` (Enum-Namen; Arten durch Komma getrennt, unbekannte Namen werden beim Lesen übersprungen).
- Migrationen fügen nur hinzu (nullbare Spalten, neue Tabellen) und laufen schrittweise in `AppDatabase.migration` (`from < 2`, `from < 3`, …).
- **Regel für jede Schemaänderung:** vorher das bisherige Schema als `test/fixtures/db/schema_vN.sql` aus dem Code erzeugen, dazu ein Migrationstest (Datei im alten Schema öffnen, Daten unverändert, neue Felder speicherbar, `user_version`) und ein Test, der eine Sicherung im alten Schema wiederherstellt (`logbook_backup_test.dart`). Sicherungen aus einem neueren Schema lehnt die App ab (T11.4).
