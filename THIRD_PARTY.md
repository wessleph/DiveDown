# Drittanbieter-Code und -Daten

Liste aller übernommenen Teile (ADR 0001). Jede übernommene Datei trägt zusätzlich einen Herkunftskopf.

| Teil | Herkunft | Stand | Lizenz | Ziel in DiveDown |
|---|---|---|---|---|
| Tauchplatz-Katalog (gefiltert, 5.401 Plätze) | Submersion `assets/data/site_catalogue.json`, Commit `e78a87cb` (Katalog vom 2026-11-17), nur Quellen OSM, Wikidata, curated, research | 2026-11-18 | ODbL-1.0 (OSM, Submersion) / CC0-1.0 (Wikidata) | `assets/data/dive_sites.json.gz`, erzeugt mit `tool/build_site_catalogue.py` |
| `libdivecomputer_plugin` (ohne `linux/`, `windows/` und die reinen macOS-Teile) | Submersion `packages/libdivecomputer_plugin`, Commit `e78a87cb` | 2026-11-20 | GPL-3.0 | `packages/libdivecomputer_plugin/` |
| libdivecomputer (Git-Submodul, fest auf Commit gepinnt) | Eigener Fork [`wessleph/libdivecomputer`](https://github.com/wessleph/libdivecomputer), Commit `fbd2c42` (= `submersion-app/libdivecomputer`, Branch `submersion-patches`, mit den Patches aus `patches/`) | 2026-11-20 | LGPL-2.1+ | `packages/libdivecomputer_plugin/third_party/libdivecomputer` |
| usb-serial-for-android v3.9.0 (`e1018ab`) | über Submersion eingebettet, unverändert, siehe `VENDORED.md` | 2026-11-20 | MIT | `packages/libdivecomputer_plugin/android/src/main/java/com/hoho/android/usbserial/` |

Ohne Herkunftskopf bleiben nur Dateien, in die kein Kommentar passt oder die unverändert eingebettet sind: Binär-Fixtures (`*.bin`), die libdivecomputer-Patches (`patches/*.patch`, ein Kopf würde `git am` stören), die Symlinks unter `ios/Classes/` und die usb-serial-Quellen.

## Geplant (siehe ADR 0003, 0006)
| Teil | Herkunft | Lizenz |
|---|---|---|
| FIT-Extraktoren, HealthKit-Adapter | Submersion `lib/features/dive_import/…` | GPL-3.0 |
