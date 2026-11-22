# DiveDown: Roadmap bis Weihnachten 2026

> Ziel: Die App **zu Weihnachten an Familie und Freunde verschenken** (TestFlight-Link für iPhone, APK für Android).
> Danach werden Fehler nach und nach behoben. Grundlage für Rückmeldungen ist der fest eingebaute Export der Diagnose-Logs.
> Stand: 2026-11-18 · noch **5 Wochen**

## Harte Termine (Apple)
| Wann | Was | Warum |
|---|---|---|
| **diese Woche** | Apple-Entwicklerkonto beantragen (Einzelperson, ca. 99 €/Jahr) | Die Prüfung durch Apple dauert oft 1–2 Tage, manchmal länger. |
| bis **07.12.** | Erster iOS-Build auf TestFlight, intern | GitHub-Actions-Pipeline und Zertifikate einrichten, Testfreund mit iPhone einladen |
| bis **14.12.** | Erstes „Beta App Review“ einreichen | Externe Tester per Link brauchen eine einmalige Freigabe durch Apple, meist 1–2 Tage. |
| bis **19.12.** | Weihnachts-Build auf TestFlight freigegeben | Apple prüft rund um die Feiertage erfahrungsgemäß langsamer oder gar nicht. |
| bis **19.12.** | Datenschutzerklärung gegen die fertige App 1.0 prüfen (Berechtigungen, TestFlight-Daten) | Phase 60, URL: https://wessleph.github.io/DiveDown/datenschutz/ |
| **24.12.** | Link verschenken 🎁 | |

## Umfang

### Muss bis Weihnachten (Version 1.0)
1. **Logbuch:** Liste, Detail und manuelle Eingabe (für den Bruder und alle anderen)
2. **Tauchcomputer-Import per BLE:** Suunto EON Core
3. **FIT-Import:** Suunto Ocean über die Suunto-App
4. **Import aus Apple Health:** Apple Watch
5. **Profil-Diagramm:** Tiefe, Temperatur, Flaschendruck, Luftverbrauch (SAC)
6. ~~**Taucherprofile:** mehrere Taucher pro App~~ entfällt (2026-11-22): ein Taucher pro App, umbenennbar, mit Startnummer
7. **Diagnose-Logs teilen:** fest eingebaut, siehe `specs/tauchcomputer-import/design.md` §9
8. Oberfläche auf Deutsch, eigener Stil, App-Icon
9. **Logbuch sichern und wiederherstellen** als Datei, weil die Datenbank nicht im iCloud- bzw. Google-Backup liegt (security.md O1)
9a. **Tauchplatz-Vorschläge aus dem mitgelieferten Katalog** (ca. 5.400 Plätze, ohne Karte), siehe ADR 0006

### Soll, wenn Zeit bleibt
10. **Ausrüstung:** einfache Liste mit Zuordnung zum Tauchgang
11. **Tauchplätze:** Platz pro Tauchgang und Karte (OSM), offline-Regionen

#### Tauchplatz-Katalog (geprüft am 2026-11-18, **entschieden: in der App mitliefern**, ADR 0006)
- Submersion liefert `assets/data/site_catalogue.json` mit: **20.988 Einträgen in 188 Ländern**, Stand 17.11.2026.
  Davon sind rund **17.000 Wrack- und Hindernisregister** (UKHO, NOAA, Florida usw., fast nur USA und UK). Echte Tauchplätze sind **5.425** (OpenStreetMap, Wikidata, kuratiert).
  Beispiele: Ägypten 336, Schweiz 359, Deutschland 685, Kroatien 67. **Lücken:** „Shark Reef“ (Ras Mohammed) und Walensee fehlen, SS Thistlegorm und Yolanda Reef sind drin. Teilweise gibt es Kodierungsfehler und merkwürdige Namen.
- Lizenz: überwiegend **ODbL 1.0**. Wir müssen die Quelle nennen („Enthält Daten von OpenStreetMap …“), und Änderungen am Datensatz stehen wieder unter ODbL. Wir übernehmen **nur** die Quellen OSM, Wikidata und Submersion, weil die Register aus New Jersey, Hawaii und Texas eigene Bedingungen bzw. „nur nicht-kommerziell“ haben.
- Größe: Die 5.425 Tauchplätze sind komprimiert nur **ca. 220 KB groß** (alle 20.988 Einträge: ca. 670 KB). Ein Land wiegt 2–11 KB.
- **Vorschlag:** Den Katalog **direkt in die App packen**, statt ihn pro Land vom Server zu laden. So funktioniert er sofort offline, die App braucht keine Internet-Berechtigung, und der NAS muss nicht offen erreichbar sein. Aktualisiert wird mit jedem App-Update.
  Eigene Tauchplätze (z. B. Walensee) legen die Nutzer selbst an. Später werden sie über den Sync in der Familie geteilt.
- Mögliche Nutzung schon in v1.0, **ohne Karte**: Vorschläge beim Feld „Tauchplatz“ aus dem Katalog (Name, Region, Land), dazu Koordinaten und `catalogue_id` am Tauchgang speichern. Aufwand: ca. 1 Tag.

### Nach Weihnachten
12. **Teilen und Sync über den NAS** (PocketBase, Tailscale). Bewusst nach hinten gestellt, weil hier das größte Sicherheitsrisiko liegt (Heimnetz, fremde Daten).
13. Nicht gelistete App im App Store statt TestFlight
13a. **Vor der Verlängerung des Apple-Kontos (ca. Nov. 2027):** prüfen, ob eine Web-App für die iPhones reicht (ADR 0005, Nachtrag)
14. Suunto Ocean per BLE, sobald libdivecomputer den Treiber hat

## Vorgehen unter Zeitdruck
- Die Phasen-Gates **gelten weiter**. Damit es schneller geht, bündeln wir die Phasen 20 (Security) und 30 (UI-Design) für den ganzen Umfang der Version 1.0, statt sie pro Feature einzeln zu machen.
- Grob pro Woche:
  - **KW 47:** Phase 20 und 30, Projekt anlegen, Plugin übernehmen, Android-Build läuft
  - **KW 48:** Datenmodell, Logbuch, manuelle Eingabe, BLE-Import auf Android (EON Core)
  - **KW 49:** FIT- und Health-Import, Diagramme, Diagnose-Logs, iOS-Pipeline, erster TestFlight-Build
  - **KW 50:** Test durch den Freund mit iPhone, Fehler beheben, Beta-Review einreichen, ggf. Ausrüstung und Tauchplätze
  - **KW 51:** nur noch Fehler beheben, Weihnachts-Build bis 19.12.
- Bleibt etwas aus dem Muss-Block hängen, fällt zuerst der Soll-Block weg, nicht die Tests.

## Änderungen
- **2026-11-18:** Das Repo `wessleph/DiveDown` ist **öffentlich** (früher als in research.md 8.3 geplant). Damit gelten ab sofort die CI-Regeln aus security.md G6/A3 für jeden neuen Workflow. Die Datenschutzerklärung erscheint über GitHub Pages aus `/docs`.
