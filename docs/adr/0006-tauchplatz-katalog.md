# ADR 0006: Tauchplatz-Katalog in der App mitliefern

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18
- Bezug: `docs/roadmap.md` (Tauchplatz-Katalog), ADR 0001 (Übernahme aus Submersion), ADR 0004 (Datenmodell)

## Kontext
Tauchcomputer, FIT-Dateien und Apple Health liefern keine Tauchplatz-Namen. Damit man Tauchplätze schnell eintragen kann, soll die App sie vorschlagen.
Submersion hat einen Katalog (`assets/data/site_catalogue.json`, Format 2, Stand 17.11.2026) mit 20.988 Einträgen. Davon sind 5.425 echte Tauchplätze aus OSM, Wikidata und kuratierten Quellen, komprimiert ca. 220 KB.
Diskutiert wurde, die Daten pro Land vom eigenen Server (NAS) herunterzuladen.

## Optionen
1. **Katalog in der App mitliefern** (Asset)
2. Pro Land vom NAS herunterladen
3. Pro Land als statische Dateien von GitHub Releases herunterladen

## Entscheidung
**Option 1.**
- Mitgeliefert werden **nur** Einträge der Quellen `osm`, `wikidata`, `curated` und `research`, also ODbL-1.0 bzw. CC0.
  Die Register (UKHO, NOAA, FWC usw.) und die Quellen mit eigenen Bedingungen (NJDEP, Hawaii, Texas: nicht-kommerziell) fallen weg.
- Ein Build-Skript `tool/build_site_catalogue.dart` (bzw. ein Python-Skript im Ordner `tool/`) filtert den Katalog aus `submersion-referenz`, repariert offensichtliche Kodierungsfehler und schreibt `assets/data/dive_sites.json.gz`.
  Dazu legt es eine Datei `assets/data/dive_sites.version` mit Quell-Commit und Zeitstempel an.
- Die App lädt den Katalog beim ersten Start in eine **eigene, nur lesbare Tabelle** `catalogue_sites` (id, name, region, country_code, lat, lon, max_depth_m, types).
  Diese Tabelle gehört **nicht** zum Logbuch: keine Sicherung, kein Sync. Sie wird neu befüllt, wenn sich die Versionsdatei ändert.
- Am Tauchgang (`dives`) speichern wir zusätzlich `site_catalogue_id`, `site_lat` und `site_lon`. Der Name bleibt in `site_name` erhalten (Freitext, ADR 0004), auch wenn der Katalog sich ändert.
- **Vorschläge** im Feld „Tauchplatz“ (Formular und „Tauchplatz für Ausgewählte setzen“):
  1. zuerst eigene, bereits verwendete Namen
  2. dann Katalog-Treffer, mit diesen Regeln: Suche nach Namensanfang und Wortanfang, ohne Akzente und Groß-/Kleinschreibung, höchstens 8 Treffer.
     Liegt eine Position vor (z. B. GPS aus einer FIT-Datei), werden nähere Treffer bevorzugt. Ohne Position haben Länder Vorrang, in denen der Taucher schon getaucht ist.
  3. Freitext ist immer möglich („‚Walensee, Quinten‘ als neuen Tauchplatz verwenden“).

## Konsequenzen
- **ODbL-Pflichten:** Unter „Über DiveDown → Open-Source-Lizenzen“ steht der Hinweis „Enthält Daten von OpenStreetMap, verfügbar unter der Open Database License (ODbL)“ plus die Liste der Quellen aus `metadata.notice`.
  Der gefilterte Datensatz ist öffentlich im Repo verfügbar, ebenfalls unter ODbL. Das erfüllt die Pflicht zur Weitergabe unter gleichen Bedingungen.
- Die App braucht **kein Internet**, der NAS muss nicht erreichbar sein, und der Katalog funktioniert offline ab dem ersten Start.
- App-Größe: etwa +220 KB komprimiert, entpackt in der Datenbank ca. 1 MB.
- Aktualisiert wird der Katalog mit App-Updates. Wenn wir ihn neu bauen, übernehmen wir den aktuellen Stand aus Submersion.
- Der Katalog ist unvollständig (z. B. fehlt „Shark Reef, Ras Mohammed“). Eigene Tauchplätze sind deshalb gleichwertig. Sie werden später über den Sync in der Familie geteilt (eigenes Feature).
- Security: Der Katalog ist geprüfte, mitgelieferte Datei und keine Eingabe von außen. Namen werden trotzdem nur als Text angezeigt (nie als HTML oder Markdown) und auf 120 Zeichen gekürzt.
