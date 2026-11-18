# DiveDown

Tauch-Logbuch für iOS und Android, für mich, Familie und Freunde.
Tauchgänge vom Tauchcomputer (Bluetooth), aus FIT-Dateien und aus Apple Health übernehmen, Profile mit Tiefe, Temperatur, Flaschendruck und Luftverbrauch ansehen, alles offline.

> Status: **Planung abgeschlossen (Phasen 00–30)**, als Nächstes kommen Tests und Implementierung. Ziel: Version 1.0 zu Weihnachten 2026.

## Projektstruktur
| Pfad | Inhalt |
|---|---|
| `docs/constitution.md` | Feste Regeln des Projekts (Stack, No-Gos, Workflow) |
| `docs/roadmap.md` | Umfang und Zeitplan bis Weihnachten |
| `docs/adr/` | Architekturentscheidungen (ADR 0001–0006) |
| `specs/tauchcomputer-import/` | Recherche, Design, Security, UI-Spezifikation |
| `.agents/skills/` | Phasen des Entwicklungsablaufs (Recherche → Review → Doku) |

Der Referenz-Checkout von Submersion (`submersion-referenz/`) ist **nicht** Teil des Repos. Er lässt sich so neu anlegen:

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/submersion-app/submersion.git submersion-referenz
```

## Datenschutz
Die Datenschutzerklärung ist `docs/datenschutz.md` und erscheint über GitHub Pages unter **https://wessleph.github.io/DiveDown/datenschutz/** (Pages-Quelle: Branch `main`, Ordner `/docs`).
Vor jedem Release, das etwas am Umgang mit Daten ändert, wird sie geprüft und angepasst (Phase 60 bzw. 80). Recht: Schweizer DSG, ergänzend DSGVO.

## Lizenz
DiveDown steht unter der **GNU General Public License v3.0 oder später** (siehe `LICENSE`).
Teile stammen aus [Submersion](https://github.com/submersion-app/submersion) (GPL-3.0), siehe `THIRD_PARTY.md`.
Der Tauchplatz-Katalog enthält Daten von OpenStreetMap, verfügbar unter der Open Database License (ODbL).
