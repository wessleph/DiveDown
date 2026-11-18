# Drittanbieter-Code und -Daten

Liste aller übernommenen Teile (ADR 0001). Jede übernommene Datei trägt zusätzlich einen Herkunftskopf.

| Teil | Herkunft | Stand | Lizenz | Ziel in DiveDown |
|---|---|---|---|---|
| *(noch nichts übernommen)* | | | | |

## Geplant (siehe ADR 0002, 0003, 0006)
| Teil | Herkunft | Lizenz |
|---|---|---|
| `libdivecomputer_plugin` | Submersion `packages/libdivecomputer_plugin`, Commit `e78a87cb` | GPL-3.0 |
| libdivecomputer (Submodul) | Eigener Fork, Basis: `submersion-app/libdivecomputer` `fbd2c42` | LGPL-2.1+ |
| usb-serial-for-android | im Plugin eingebettet | MIT |
| FIT-Extraktoren, HealthKit-Adapter | Submersion `lib/features/dive_import/…` | GPL-3.0 |
| Tauchplatz-Katalog (gefiltert) | Submersion `assets/data/site_catalogue.json` (Quellen OSM, Wikidata, kuratiert) | ODbL-1.0 / CC0 |
