# Tasks und Testszenarien: DiveDown 1.0

> Phase 40, Schritt 1 · Stand: 2026-11-18
> Quellen: `design.md`, `security.md` (§9, §10), `ui-spec.md`, ADR 0003, 0004, 0006
> Jede Zeile wird zu mindestens einem Test. Die Spalte **Rot gesehen** wird ausgefüllt, sobald der Test geschrieben wurde und **aus dem richtigen Grund** fehlschlägt (Phase-40-Gate). Erst dann wird implementiert.
> Notation: **A** = Angenommen (Given), **W** = Wenn (When), **D** = Dann (Then). Werte in SI-Einheiten.

## Testebenen und Orte
| Ebene | Ort | Werkzeug |
|---|---|---|
| Domäne (reines Dart) | `test/domain/…` | `package:test` |
| Datenbank | `test/data/local/…` | Drift mit In-Memory-SQLite |
| Import-Adapter | `test/data/import/…` | Fixtures unter `test/fixtures/` |
| UI | `test/features/…` | `flutter_test` (Widget-Tests) |
| Plugin (nativ) | `packages/libdivecomputer_plugin/android/src/test` | JUnit (übernommen) |
| Katalog-Skript | `tool/test_build_site_catalogue.py` | Python `unittest` |

---

## T0: App-Gerüst (`lib/app/`, ADR 0005, ui-spec §1, §2, §7, §8)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T0.1 | Theme hell und dunkel | gebaut | Farb-Tokens aus ui-spec §1 in `ColorScheme` bzw. `DiveColors`, Material 3 | ✅ 2026-11-20: rot, Tokens fehlten (Standardfarben, `DiveColors` null) |
| T0.2 | Theme | gebaut | alle Textstile mit `FontFeature.tabularFigures()` | ✅ 2026-11-20: rot, `fontFeatures` war null |
| T0.3 | App-Start, Handy-Breite | angezeigt | untere Leiste „Logbuch · Importieren · Einstellungen“, Logbuch aktiv | ✅ 2026-11-20: rot, keine `NavigationBar` |
| T0.4 | App-Start | auf „Einstellungen“ getippt | Tab 3 aktiv, Titel „Einstellungen“ | ✅ 2026-11-20: rot, Text nicht gefunden |
| T0.5 | Breite ≥ 840 dp | angezeigt | seitliche `NavigationRail` statt unterer Leiste | ✅ 2026-11-20: rot, keine `NavigationRail` |
| T0.6 | App-Start | Locale geprüft | `de` | ✅ 2026-11-20: rot, kein `Scaffold` (App leer) |
| T0.7 | App-Start | Semantics-Prüfung | Touch-Ziele und Textkontrast erfüllt | ⚠️ 2026-11-20: sofort grün, weil die leere App nichts zu prüfen hatte. Mit der Navigation aussagekräftig. |

Nachweis: `flutter test test/app`, `flutter analyze`, `flutter build apk --debug`

## T1: Plausibilitätsprüfung (`domain/import/plausibility.dart`, security G1/A1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T1.1 | ein `ImportedDive` mit max. Tiefe 18,4 m, Dauer 47 min, Temp. 21 °C | geprüft | gültig, keine Warnungen | |
| T1.2 | max. Tiefe 351 m | geprüft | **abgelehnt** mit Grund `depthOutOfRange` | |
| T1.3 | max. Tiefe −1 m | geprüft | abgelehnt `depthOutOfRange` | |
| T1.4 | Dauer 24 h + 1 s | geprüft | abgelehnt `durationOutOfRange` | |
| T1.5 | Startzeit 10 min in der Zukunft (laut `clock`) | geprüft | abgelehnt `startInFuture` | |
| T1.6 | 3 Samples mit Temperatur 80 °C zwischen gültigen | geprüft | Tauchgang gültig, **diese 3 Samples verworfen**, Warnung `samplesDropped(3)` | |
| T1.7 | Sample mit Druck 450 bar | geprüft | Druckwert verworfen (Sample bleibt), Warnung | |
| T1.8 | 100.001 Samples | geprüft | abgelehnt `tooManySamples` | |
| T1.9 | Samples mit nicht steigender Zeit (t = 10, 10, 5) | geprüft | Samples nach Zeit sortiert, Duplikate entfernt, Warnung | |
| T1.10 | genau an den Grenzen (0 m, 350 m, 24 h, −5 °C, 45 °C, 0 bar, 400 bar) | geprüft | gültig (Grenzen sind inklusiv) | |

## T2: Duplikaterkennung (`domain/import/import_service.dart`, ADR 0003, security A2)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T2.1 | DB leer | 1 Tauchgang importiert | `Saved` | |
| T2.2 | Tauchgang mit `source=diveComputer`, `sourceId=X`, gleiche Daten existiert | gleicher erneut importiert | `SkippedDuplicate`, nicht in Vorschau auswählbar | |
| T2.3 | gleiche `source` + `sourceId`, aber **andere max. Tiefe** | importiert | `NeedsConfirmation(reason: sameIdDifferentContent)`, **kein** stilles Überspringen | |
| T2.4 | anderer `sourceId`, Start ±90 s und max. Tiefe ±0,3 m zu bestehendem | importiert | `NeedsConfirmation(reason: similar)` | |
| T2.5 | Start +3 min Abstand | importiert | `Saved` (außerhalb ±2 min) | |
| T2.6 | ähnlicher Tauchgang existiert, aber bei **anderem Taucher** | importiert | `Saved` (Duplikate nur pro Taucher) | |
| T2.7 | ähnlicher Tauchgang ist soft-gelöscht | importiert | `Saved` | |
| T2.8 | 5 Tauchgänge, Speichern von Nr. 3 schlägt fehl (DB-Fehler simuliert) | importiert | 1, 2, 4, 5 gespeichert; 3 `Failed`; jeder Tauchgang in **eigener Transaktion** | |

## T3: Fingerprint und Geräte-Identität (`domain/import/dive_computer_registry.dart`, security A1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T3.1 | Gerät mit Seriennummer S unbekannt | Download mit 3 Tauchgängen, alle gespeichert | Gerät angelegt, `last_fingerprint` = Fingerprint des **neuesten** Tauchgangs | |
| T3.2 | Gerät S bekannt mit Fingerprint F | neuer Download startet | Plugin bekommt `sinceFingerprint = F` | |
| T3.3 | Download liefert 2 Tauchgänge, dann Abbruch | Abbruch | 2 Tauchgänge in Vorschau, `last_fingerprint` **unverändert** | |
| T3.4 | gespeicherte Seriennummer S, Gerät meldet per `DEVINFO` S′ ≠ S bei gleichem Namen bzw. gleicher Adresse | Download | `SerialMismatch`-Ereignis, **kein** Fingerprint geschrieben, UI-Warnung | |
| T3.5 | wie T3.4, Nutzer wählt „Als neues Gerät verwenden“ | bestätigt | neues Gerät S′ angelegt, Fingerprint von S unberührt | |
| T3.6 | Speichern in Vorschau abgebrochen (Nutzer wählt nichts) | Vorschau verlassen | Fingerprint **nicht** gesetzt | |

## T4: Adapter ParsedDive → ImportedDive (`data/import/divecomputer/`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T4.1 | `ParsedDive` mit Datum 2026-11-14 10:42:00, TZ-Offset +7200 s | übersetzt | `startTime` = 10:42 Ortszeit, `startInstant` = 08:42 UTC | |
| T4.2 | `ParsedDive` ohne TZ-Offset | übersetzt | `startTime` = Gerätezeit, `startInstant` = null | |
| T4.3 | Sample mit `tankPressuresBar = [200.0, null, 180.0]` | übersetzt | 2 Druckwerte mit `tankIndex` 0 und 2 | |
| T4.4 | Gasgemisch O₂ 0,32 / He 0 | übersetzt | Gas „EAN32“ | |
| T4.5 | **Fixture** `test/fixtures/divecomputer/eon_core_dump.bin` (echter EON-Core-Dump, auf dem PC aufzuzeichnen) | über `parseRawDiveData` geparst | erwartete Tiefe, Dauer und Sample-Anzahl laut `…expected.json` | |

## T5: FIT-Import (`data/import/fit/`, security A2/R3)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T5.1 | gültige FIT-Datei eines Tauchgangs (Fixture, Suunto Ocean) | geparst | 1 `ImportedDive` mit Profil, Temperatur, `sourceId` aus `file_id` | |
| T5.2 | Datei > 10 MB | geparst | `FileTooLarge`, ohne Parser-Aufruf | |
| T5.3 | Datei ohne `.FIT`-Signatur im Header | geparst | `NotAFitFile`, ohne Parser-Aufruf | |
| T5.4 | Header gültig, CRC falsch | geparst | `CorruptFile` | |
| T5.5 | gültige Datei, nach 50 % abgeschnitten | geparst | `CorruptFile`, **kein Absturz** | |
| T5.6 | FIT einer Laufaktivität | geparst | `NoDiveInFile` | |
| T5.7 | Parser hängt (simuliert) | 30 s vergangen (`fake_async`) | `Timeout`, Isolate beendet | |
| T5.8 | Fuzz: 200 zufällig veränderte Varianten der Fixture (fester Seed) | jeweils geparst | jede liefert Ergebnis **oder** definierten Fehler, nie eine ungefangene Exception | |
| T5.9 | Dateiname `../../databases/x.fit` | über „Teilen“ empfangen | Name nur angezeigt, nie als Pfad verwendet. Kein Schreiben außerhalb des Cache. | |

## T6: Apple Health (`data/import/health/`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T6.1 | Fake-Health liefert Unterwasser-Workout mit Tiefe, Temp. und Puls | `fetch` | 1 `ImportedDive`, `source=appleHealth`, `sourceId`=Workout-UUID, kein Druck | |
| T6.2 | Berechtigung verweigert | `requestPermission` | `false`, kein `fetch` | |
| T6.3 | Workout ohne Tiefen-Samples | `fetch` | übersprungen | |
| T6.4 | Zeitraum ohne Workouts | `fetch` | leere Liste | |

## T7: Luftverbrauch (`domain/metrics/sac_calculator.dart`, design §6)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T7.1 | Flasche 12 l, 200 → 50 bar, Dauer 50 min, mittlere Tiefe 10 m (Salzwasser) | Ø-SAC berechnet | (150 × 12) / (50 × 2,0) = **18,0 l/min** (±0,1) |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.2 | wie T7.1, Süßwasser | berechnet | Umgebungsdruck mit 9,81 kPa/m statt 10,05 kPa/m, Ergebnis entsprechend |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.3 | Druckverlauf in Samples | Kurve berechnet | 1-min-Abschnitte. Abschnitt ohne Druckänderung = 0. Kein Abschnitt negativ. | |
| T7.4 | kein Druck | berechnet | `null` |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.5 | Druck vorhanden, kein Flaschenvolumen | berechnet | `null` mit Grund `missingVolume` |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.6 | 2 Flaschen (Gaswechsel) | berechnet | SAC pro Flasche über deren Nutzungszeit | |
| T7.7 | Dauer 0 | berechnet | `null`, kein Division-durch-0 |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.8 | Druck und Volumen da, keine Ø-Tiefe | berechnet | ohne Samples `null` mit Grund `depth`. Mit Samples: zeitgewichtetes Mittel der Samples | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |

Tests: `test/domain/metrics/sac_calculator_test.dart`. Annahme: Oberflächendruck **1,0 bar** (mit 1,013 bar läge T7.1 bei 17,84 und damit außerhalb ±0,1). Unbekannter Wassertyp zählt als Salzwasser. T7.3 (Kurve) und T7.6 (Gaswechsel) kommen mit dem Profil-Diagramm (KW 49).

## T8: Datenbank (`data/local/`, ADR 0004/0006)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T8.1 | leere DB | Tauchgang mit 1.800 Samples gespeichert und gelesen | identisch (Rundung ≤ 1e-6) | ✅ 2026-11-20: rot wegen `UnimplementedError` (Repository fehlt), Testaufbau ok |
| T8.2 | Tauchgang gespeichert | gelöscht | `deleted_at` gesetzt, nicht mehr in Liste, über „Rückgängig“ wiederherstellbar | ✅ 2026-11-20: rot wegen `UnimplementedError` (Repository fehlt), Testaufbau ok |
| T8.3 | IDs | neue Datensätze | UUID v4, nie Autoincrement | ✅ 2026-11-20: rot wegen `UnimplementedError` (Repository fehlt), Testaufbau ok |
| T8.4 | Schema v1 mit Daten | Migration auf v2 (sobald es eine gibt) | Daten unverändert. Vor der Migration existiert eine Kopie. | ⏸ entfällt bis Schema v2: Es gibt noch keine Migration. Test entsteht zusammen mit v2. |
| T8.5 | Taucher mit `first_dive_number = 101`, keine Tauchgänge | 2 Tauchgänge importiert | Nummern 101, 102 | ✅ 2026-11-20: rot wegen `UnimplementedError` (Repository fehlt), Testaufbau ok |
| T8.6 | Tauchgänge #1–#5 | manuell #3 doppelt vergeben | gespeichert, Hinweis `duplicateNumber`, nicht blockiert | ✅ 2026-11-20: rot wegen `UnimplementedError` (Repository fehlt), Testaufbau ok |
| T8.7 | Katalog-Datei Version V1 geladen | App-Start mit gleicher Version | `catalogue_sites` nicht neu befüllt | ✅ 2026-11-20: rot wegen `UnimplementedError` (CatalogueLoader fehlt), Testaufbau ok |
| T8.8 | Katalog-Datei Version V2 | App-Start | `catalogue_sites` neu befüllt, `dives.site_name` unverändert | ✅ 2026-11-20: rot wegen `UnimplementedError` (CatalogueLoader fehlt), Testaufbau ok |

Tests: `test/data/local/dive_repository_test.dart` (T8.1–T8.6, zusätzlich: Nummern zählen pro Taucher), `test/data/local/catalogue_loader_test.dart` (T8.7, T8.8). In-Memory-SQLite (3.53.4) läuft unter Windows, Schema v1 mit 9 Tabellen wird angelegt.
Nachweis: `flutter test test/data`

**Umgesetzt (Phase 50, 2026-11-20):**
- [x] Repositories (`lib/data/local/drift_dive_repository.dart`) → T8.1–T8.3, T8.5, T8.6 grün. Nachweis: `flutter test test/data/local/dive_repository_test.dart` (6/6)
- [x] Katalog-Loader (`lib/data/local/catalogue_loader.dart`) → T8.7, T8.8 grün. Nachweis: `flutter test test/data/local/catalogue_loader_test.dart` (2/2). Zusätzlich einmalig mit dem echten Katalog geprüft: 5.401 Plätze in 177 ms (In-Memory, PC).

## T9: Tauchplatz-Vorschläge (`domain/sites/site_suggestions.dart`, ADR 0006)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T9.1 | eigener Name „Walensee, Quinten“ verwendet, Katalog enthält „Walchensee“ | Eingabe „wal“ | zuerst „Walensee, Quinten“ (eigen), dann Katalog | |
| T9.2 | Katalog enthält „SS Thistlegorm“ (EG) | Eingabe „thistle“ | Treffer „SS Thistlegorm · …, Ägypten“ | |
| T9.3 | Eingabe „sha'ab el erg“ vs. Katalog „Sha’ab El Erg“ | gesucht | Treffer (ohne Akzente, Groß-/Kleinschreibung und Apostroph-Varianten) | |
| T9.4 | 20 Treffer möglich | gesucht | höchstens 8 | |
| T9.5 | Position bekannt (27,81 N / 33,92 O) | Eingabe „reef“ | nähere Treffer zuerst | |
| T9.6 | beliebige Eingabe | gesucht | letzte Zeile „‚…‘ als neuen Tauchplatz verwenden“ | |
| T9.7 | Name > 120 Zeichen im Katalog | angezeigt | auf 120 gekürzt, als reiner Text | |

## T10: Diagnose-Logs (`data/diagnostics/`, security A4, design §9)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T10.1 | Log-Eintrag Kategorie `ble.connect`, Text mit MAC `AA:BB:CC:DD:EE:FF` | geschrieben | gespeichert als `••:EE:FF` | |
| T10.2 | Eintrag mit `serial=12345678` | geschrieben | `serial=••5678` | |
| T10.3 | libdivecomputer-HEXDUMP-Zeile | geschrieben (Release) | **verworfen** | |
| T10.4 | „Unmatched device … (Annas AirPods)“ | geschrieben (Release) | verworfen | |
| T10.5 | Eintrag mit Koordinaten „27.8123, 33.9201“ | geschrieben | Koordinaten durch `[Ort entfernt]` ersetzt | |
| T10.6 | Eintrag mit E-Mail bzw. Pfad `C:\Users\anna\…` | geschrieben | ersetzt durch `[entfernt]` | |
| T10.7 | Eintrag einer Kategorie, die **nicht** auf der Positivliste steht | geschrieben | verworfen | |
| T10.8 | Log > 5 MB | neuer Eintrag | älteste Einträge entfernt, Datei ≤ 5 MB | |
| T10.9 | Einträge älter als 7 Tage | App-Start | entfernt | |
| T10.10 | Export | erzeugt | Kopf mit App-Version, Build, OS, Gerätemodell, libdivecomputer-Version. Danach Einträge. Kein Tauchplatz-Name, kein Taucher-Name. | |

## T11: Sichern und Wiederherstellen (`data/backup/`, security O1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T11.1 | Logbuch mit 3 Tauchern, 10 Tauchgängen | Sicherung erstellt | `.divedown`-ZIP mit DB-Kopie und Manifest (App-Version, Schema-Version, Zeit, SHA-256) | |
| T11.2 | Sicherung aus T11.1 | in leere App wiederhergestellt | identische Daten | |
| T11.3 | Sicherung mit falscher Prüfsumme | wiederhergestellt | `CorruptBackup`, aktuelle DB unverändert | |
| T11.4 | Sicherung mit Schema-Version > aktuell | wiederhergestellt | `BackupFromNewerVersion` | |
| T11.5 | ZIP mit Eintrag `../evil` | wiederhergestellt | `InvalidBackup`, nichts außerhalb des Zielordners geschrieben | |
| T11.6 | gültige Sicherung, Ersetzen schlägt fehl (simuliert) | wiederhergestellt | alte DB aus automatischer Kopie zurück, `RestoreFailed` | |
| T11.7 | Datei > 200 MB | gewählt | `FileTooLarge` | |
| T11.8 | letzte Sicherung vor 31 Tagen | Logbuch geöffnet | Erinnerung sichtbar. Nach „✕“ 7 Tage unsichtbar. | |
| T11.9 | DB-Datei | Pfad geprüft (iOS) | `NSURLIsExcludedFromBackupKey` gesetzt (Integrationstest auf iOS bzw. Prüfung der Plattform-Methode) |  ✅ 2026-11-20: rot wegen `UnimplementedError` (`BackupExclusion`, `openAppDatabase` fehlen), Testaufbau ok. Geprüft wird der Aufruf aus Dart, die Swift-Seite läuft erst auf iOS (CI/TestFlight) |
| T11.10 | DB-Datei | Android-Manifest geprüft | `dataExtractionRules` schließt den Ordner `db/` aus `cloud-backup` **und** `device-transfer` aus, `fullBackupContent` (Android 8–11, minSdk 26) aus dem Voll-Backup. Kein Kanalaufruf unter Android | ✅ 2026-11-20: rot, Manifest-Attribute und `res/xml/*.xml` fehlen bzw. `UnimplementedError` |

Tests T11.9/T11.10: `test/data/platform/backup_exclusion_test.dart`, `test/app/startup_test.dart`. Die DB liegt in einem **eigenen Ordner** `db/`, damit auch die `-wal`/`-journal`-Dateien vom Ausschluss erfasst sind. Der Ausschluss wird bei jedem Start erneut gesetzt.

## T12: UI-Zustände (Widget-Tests, `ui-spec.md`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T12.1 | keine Tauchgänge | Logbuch | Leerzustand mit „Importieren“ und „Manuell eintragen“ |  ✅ 2026-11-20: rot, Leerzustand fehlt (Text nicht gefunden) |
| T12.2 | Tauchgang ohne Tauchplatz | Logbuch-Zeile | „Ohne Tauchplatz“ |  ✅ 2026-11-20: rot, Liste fehlt (Text nicht gefunden) |
| T12.3 | Tauchgang #42 | Logbuch-Zeile | Semantics-Label beginnt mit „Tauchgang 42“ |  ✅ 2026-11-20: rot, Liste fehlt (`#42` nicht gefunden) |
| T12.4 | Bluetooth aus | Gerätesuche | Text „Bluetooth ist ausgeschaltet.“ + Knopf | |
| T12.5 | Berechtigung dauerhaft verweigert | Gerätesuche | „Einstellungen öffnen“ | |
| T12.6 | 30 s ohne Fund | Gerätesuche | Checkliste + „Erneut suchen“ | |
| T12.7 | Suunto Ocean gefunden | Gerätesuche | ausgegraut + Link zur FIT-Anleitung | |
| T12.8 | `SerialMismatch` | Gerätesuche | Warn-Dialog, Primärknopf „Abbrechen“ | |
| T12.9 | PIN angefordert von „EON Core ••3F7A“ | Dialog | Gerätename sichtbar. Nach 60 s „Zeit abgelaufen“. | |
| T12.10 | Vorschau mit 1 Duplikat | Vorschau | Duplikat nicht ausgewählt, Knopf „2 Tauchgänge importieren“ | |
| T12.11 | nichts ausgewählt | Vorschau | Knopf deaktiviert „Nichts ausgewählt“ | |
| T12.12 | Detail ohne Druck | Detail | SAC „—“ + Info-Text |  ✅ 2026-11-20: rot, `DiveDetailScreen` wirft `UnimplementedError` |
| T12.13 | Textskalierung 200 % | Logbuch, Detail | kein Overflow (`tester.takeException() == null`) |  ✅ 2026-11-20: rot, Inhalt fehlt (Liste, Detail, Formular). Der Test verlangt vorher sichtbaren Inhalt, damit er nicht leer grün wird |
| T12.14 | alle Bildschirme | Semantics-Prüfung | jedes tippbare Element ≥ 48 dp (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `textContrastGuideline`) |  ✅ 2026-11-20: rot, Inhalt fehlt, wie T12.13. Abgedeckt: Logbuch (leer und Liste), Detail, Formular. Import-Bildschirme folgen mit dem Import |
| T12.15 | Manuelles Formular, Tiefe 400 | Speichern | Fehler „Tiefe muss zwischen 0 und 350 m liegen.“, Fokus springt hin |  ✅ 2026-11-20: rot, Formular fehlt (kein FAB) |

Tests: `test/features/logbook/` (Liste, Detail, Formular). In diesem Paket nur die Logbuch-Zeilen T12.1–T12.3 und T12.12–T12.15. T12.4–T12.11 gehören zum Import (BLE, Vorschau) und kommen mit T3/T4.

## T13: Katalog-Skript (`tool/build_site_catalogue.py`, ADR 0006). Kann sofort auf dem Laptop umgesetzt werden.
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T13.1 | Einträge der Quellen `osm`, `ukho`, `njdep`, `wikidata` | gefiltert | nur `osm`, `wikidata` (und `curated`, `research`) bleiben | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.2 | Eintrag ohne Name, oder Lat > 90, oder Lon > 180 | gefiltert | entfernt | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.3 | Name mit Mojibake „ZÃ¼richsee“ | bereinigt | „Zürichsee“ | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.4 | Name mit U+FFFD | bereinigt | Eintrag entfernt und im Bericht gezählt | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.5 | Name mit führenden bzw. doppelten Leerzeichen, > 120 Zeichen | bereinigt | getrimmt, Leerzeichen zusammengefasst, auf 120 gekürzt | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.6 | zwei Einträge mit gleichem Namen und Koordinaten < 50 m auseinander | dedupliziert | einer bleibt (Priorität: curated > research > osm > wikidata) | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.7 | Ausgabe | geschrieben | nur Felder `id, name, region, country_code, lat, lon, max_depth_m, types`. Koordinaten auf 5 Nachkommastellen. Sortiert nach Land, Name. | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.8 | gleiche Eingabe zweimal | gebaut | **byte-identische** `.json.gz` (gzip `mtime=0`) | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |
| T13.9 | Ausgabe | Metadaten | `notice` mit ODbL-Hinweis und Quellenliste, `source_commit`, `generated_at` aus der Eingabe | ✅ 2026-11-18: rot wegen `NotImplementedError` (Funktion fehlt), Testaufbau ok |

## T14: Plugin-Härtung (Phase 50, Kotlin/Swift, security A4/A5)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T14.1 | Release-Build | Download-Session erstellt | `dc_context_set_loglevel(…, DC_LOGLEVEL_WARNING)` | |
| T14.2 | Release-Build | `NativeLogger.d` | kein `Log.d`-Aufruf (logcat) | |
| T14.3 | Access-Code gespeichert | gelesen | aus Keystore bzw. Keychain, nicht aus `SharedPreferences` (JUnit mit Fake-Speicher) | |
| T14.4 | Android-Manifest der App (merged) | geprüft | kein `INTERNET`, `ACCESS_FINE_LOCATION` nur mit `maxSdkVersion=30`, `BLUETOOTH_SCAN` mit `neverForLocation` (Test über `aapt dump`/Manifest-Parser in CI) | |

## T15: Logbuch (ui-spec §5.1–5.4, KW 48)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T15.1 | SI-Werte | formatiert (metrisch) | `18,4 m` · `47 min` · `21 °C` · `200 bar` · `12 l` · `18,0 l/min` · Gas `Luft` / `EAN32` / `Tx 21/35` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`UnitFormatter` fehlt) |
| T15.2 | Tauchgänge am 20.10., 02.11. und 14.11.2026, ein zweiter Taucher mit eigenem Tauchgang | Logbuch | Überschriften „November 2026“, „Oktober 2026“, neuester oben. Nur Tauchgänge des aktiven Tauchers | ✅ 2026-11-20: rot, Liste fehlt |
| T15.3 | #42, SS Thistlegorm, 14.11.2026, 18,4 m, 47 min, vom Tauchcomputer | Logbuch-Zeile | sichtbar `#42`, Platz, `18,4 m`, `14.11.2026`, `47 min`. Ein Semantics-Element „Tauchgang 42, SS Thistlegorm, 14. November, 18,4 Meter, 47 Minuten, vom Tauchcomputer“ | ✅ 2026-11-20: rot, Liste fehlt |
| T15.4 | Liste | Zeile angetippt | Detail des Tauchgangs | ✅ 2026-11-20: rot, Liste fehlt |
| T15.5 | wie T15.3, dazu Ø 10 m, 21 °C, 12 l 200 → 50 bar EAN32, Salzwasser | Detail | `#42`, Platz, Datum, `10:42`, Taucher. `18,4 m` · `47 min` · `10,0 m` · `21 °C` · `200 → 50 bar` · `19,1 l/min` · `EAN32` · `Salzwasser` | ✅ 2026-11-20: rot, `DiveDetailScreen` wirft `UnimplementedError` |
| T15.6 | ohne Tauchplatz | Detail | Link „Tauchplatz hinzufügen“ öffnet das Bearbeiten-Formular | ✅ 2026-11-20: rot, wie T15.5 |
| T15.7 | Druck, aber keine Flaschengröße | Detail | SAC „—“, Link „Flaschengröße eintragen“ öffnet das Formular | ✅ 2026-11-20: rot, wie T15.5 |
| T15.8 | keine Samples | Detail | Hinweis „Geschätztes Profil“. Mit Samples kein Hinweis | ✅ 2026-11-20: rot, wie T15.5 |
| T15.9 | Detail | Menü → „Löschen“ → bestätigt | Dialog „Tauchgang löschen?“, danach Logbuch ohne Eintrag, `findById` = null. „Rückgängig“ in der Snackbar stellt ihn wieder her | ✅ 2026-11-20: rot, wie T15.5 |
| T15.10 | Löschdialog | „Abbrechen“ | Detail bleibt, Tauchgang da | ✅ 2026-11-20: rot, wie T15.5 |
| T15.11 | Taucher mit #1–#5 | FAB „Manuell eintragen“ | Formular, „Nr.“ = `6`, Datum und Startzeit = jetzt. Zahlenfelder mit Ziffern-Tastatur | ✅ 2026-11-20: rot, kein FAB |
| T15.12 | leeres Formular | „Speichern“ | 2 × „Bitte ausfüllen.“ (Dauer, max. Tiefe), Fokus auf „Dauer“, nichts gespeichert | ✅ 2026-11-20: rot, kein FAB |
| T15.13 | Startdruck 200, Enddruck 210 | „Speichern“ | „Der Enddruck muss kleiner als der Startdruck sein.“, Fokus auf „Enddruck“ | ✅ 2026-11-20: rot, kein FAB |
| T15.14 | gültige Eingabe „47“, „18,4“, 12 l, 200/50 bar | „Speichern“ | zurück im Logbuch mit `#6`. DB: `manual`, 2.820 s, 18,4 m, Flasche gespeichert | ✅ 2026-11-20: rot, kein FAB |
| T15.15 | importierter Tauchgang mit 48 Samples | bearbeitet, Tiefe 19,5 | Detail zeigt `19,5 m`, Samples und Quelle bleiben | ✅ 2026-11-20: rot, `ManualDiveScreen` wirft `UnimplementedError` |
| T15.16 | Formular mit bzw. ohne Änderung | Zurück | mit: „Änderungen verwerfen?“, „Weiter bearbeiten“ bleibt, „Verwerfen“ speichert nichts. Ohne: kein Dialog | ✅ 2026-11-20: rot, kein FAB |
| T15.17 | #1–#5 | Nr. 3 vergeben, gespeichert | gespeichert, Snackbar „Die Nummer 3 gibt es schon. Der Tauchgang ist trotzdem gespeichert.“ | ✅ 2026-11-20: rot, kein FAB |
| T15.18 | Formular-Entwurf | geprüft | Pflicht: Dauer, max. Tiefe. Grenzen inklusiv wie G1: Tiefe 0–350 m, Ø ≤ max., Dauer 1–1.440 min, −5 bis 45 °C, 0–400 bar, Ende < Start, Flasche über 0 bis 30 l, O₂ 1–100 %, Start nicht in der Zukunft, Nr. leer oder ganze Zahl ≥ 1. Komma und Punkt erlaubt. Fehler in Bildschirm-Reihenfolge | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ManualDiveDraft.validate`) |
| T15.19 | Entwurf | in `Dive` übersetzt | neu: `manual`, SI, leere Felder null, keine leere Flasche. Bearbeiten: Samples, Ereignisse, Quelle, 2. Flasche und Katalog-Daten bleiben. **Unveränderte Felder behalten den genauen Wert** (2.827 s bleibt 2.827 s, nicht 2.820). Geleerte Felder werden null | ✅ 2026-11-20: rot wegen `UnimplementedError` (`fromDive`, `toDive`) |
| T15.20 | kein Taucher | App-Start | „Willkommen bei DiveDown“ ohne Navigationsleiste. Name leer oder nur Leerzeichen → „Los geht’s“ deaktiviert, „Bitte gib einen Namen ein.“ | ✅ 2026-11-20: rot, Start in `/logbook`, `WelcomeScreen` fehlt |
| T15.21 | Name „ Anna “ | „Los geht’s“ | Taucher „Anna“ angelegt und aktiv, leeres Logbuch | ✅ 2026-11-20: rot, `WelcomeScreen` fehlt |
| T15.22 | aktiver Taucher mit #42 | App-Start | Logbuch mit `#42`, kein Willkommen | ⚠️ 2026-11-20: zuerst sofort grün, weil die App ohnehin im Logbuch startet. Um `#42` verschärft, jetzt rot: Liste fehlt |
| T15.23 | Taucher mit `first_dive_number` 101 / #1–#5 / #7 und #8, #8 gelöscht | `nextNumber` | 101 / 6 (gleich der Nummer beim Speichern) / 8, pro Taucher | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T15.24 | Anna, Ben | `DiverRepository.list` | in Anlage-Reihenfolge | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T15.25 | leere DB | aktiven Taucher setzen | zuerst null, dann in `app_meta` (`active_diver_id`) gespeichert | ✅ 2026-11-20: rot wegen `UnimplementedError` |

Tests: `test/domain/units/`, `test/domain/dive/manual_dive_draft_test.dart`, `test/data/local/logbook_queries_test.dart`, `test/features/logbook/`, `test/features/onboarding/`. Gemeinsamer Aufbau: `test/support/test_app.dart` (In-Memory-DB, aktiver Taucher).
Bewusst **nicht** in diesem Paket: Tauchplatz-Vorschläge (T9, bis dahin Freitext), Taucher-Wechsel über den Avatar, Einheiten und Farbe beim ersten Start, Sparkline und Profil-Diagramm (KW 49), Sicherungs-Erinnerung (T11.8), Schnellscroll ab 500 Einträgen, Hervorhebung nach Import.

## T16: App-Start und Datenbankdatei
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T16.1 | leerer Application-Support-Ordner | DB geöffnet, beschrieben, geschlossen, erneut geöffnet | Datei `<Support>/db/divedown.sqlite`, sonst nichts daneben. Daten bleiben | ✅ 2026-11-20: rot wegen `UnimplementedError` (`openAppDatabase`) |
| T16.2 | Backup-Ausschluss schlägt fehl | DB geöffnet | Logbuch öffnet trotzdem (offline-first geht vor) | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T16.3 | Katalog-Version „V1“ + Zeilenumbruch in den Assets | App-Start, danach gleiche Version | geladen (Version getrimmt), beim 2. Mal wird die `.json.gz` nicht gelesen. Die echten Assets sind in `pubspec.yaml` eingetragen und liefern über 5.000 Plätze | ✅ 2026-11-20: rot wegen `UnimplementedError` (`loadBundledCatalogue`) |
| T16.4 | Öffnen schlägt einmal fehl | App-Start | Fehlerkarte mit Icon, „Das Logbuch konnte nicht geöffnet werden.“ und „Erneut versuchen“. Der zweite Versuch öffnet die App. Kein Overflow bei 200 % | ✅ 2026-11-20: rot wegen `UnimplementedError` (`AppStartupGate`) |

Tests: `test/app/startup_test.dart`, `test/app/startup_gate_test.dart`. „Logs an Entwickler senden“ auf der Fehlerkarte kommt mit T10.
