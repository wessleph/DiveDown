# Drittanbieter-Code und -Daten

Liste aller übernommenen Teile (ADR 0001). Jede übernommene Datei trägt zusätzlich einen Herkunftskopf.

| Teil | Herkunft | Stand | Lizenz | Ziel in DiveDown |
|---|---|---|---|---|
| Tauchplatz-Katalog (gefiltert, 5.401 Plätze) | Submersion `assets/data/site_catalogue.json`, Commit `e78a87cb` (Katalog vom 2026-11-17), nur Quellen OSM, Wikidata, curated, research | 2026-11-18 | ODbL-1.0 (OSM, Submersion) / CC0-1.0 (Wikidata) | `assets/data/dive_sites.json.gz`, erzeugt mit `tool/build_site_catalogue.py` |

## Geplant (siehe ADR 0002, 0003, 0006)
| Teil | Herkunft | Lizenz |
|---|---|---|
| `libdivecomputer_plugin` | Submersion `packages/libdivecomputer_plugin`, Commit `e78a87cb` | GPL-3.0 |
| libdivecomputer (Submodul) | Eigener Fork, Basis: `submersion-app/libdivecomputer` `fbd2c42` | LGPL-2.1+ |
| usb-serial-for-android | im Plugin eingebettet | MIT |
| FIT-Extraktoren, HealthKit-Adapter | Submersion `lib/features/dive_import/…` | GPL-3.0 |
