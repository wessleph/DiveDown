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
| T7.1 | Flasche 12 l, 200 → 50 bar, Dauer 50 min, mittlere Tiefe 10 m (Salzwasser) | Ø-SAC berechnet | (150 × 12) / (50 × 2,0) = **18,0 l/min** (±0,1) | |
| T7.2 | wie T7.1, Süßwasser | berechnet | Umgebungsdruck mit 9,81 kPa/m statt 10,05 kPa/m, Ergebnis entsprechend | |
| T7.3 | Druckverlauf in Samples | Kurve berechnet | 1-min-Abschnitte. Abschnitt ohne Druckänderung = 0. Kein Abschnitt negativ. | |
| T7.4 | kein Druck | berechnet | `null` | |
| T7.5 | Druck vorhanden, kein Flaschenvolumen | berechnet | `null` mit Grund `missingVolume` | |
| T7.6 | 2 Flaschen (Gaswechsel) | berechnet | SAC pro Flasche über deren Nutzungszeit | |
| T7.7 | Dauer 0 | berechnet | `null`, kein Division-durch-0 | |

## T8: Datenbank (`data/local/`, ADR 0004/0006)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T8.1 | leere DB | Tauchgang mit 1.800 Samples gespeichert und gelesen | identisch (Rundung ≤ 1e-6) | |
| T8.2 | Tauchgang gespeichert | gelöscht | `deleted_at` gesetzt, nicht mehr in Liste, über „Rückgängig“ wiederherstellbar | |
| T8.3 | IDs | neue Datensätze | UUID v4, nie Autoincrement | |
| T8.4 | Schema v1 mit Daten | Migration auf v2 (sobald es eine gibt) | Daten unverändert. Vor der Migration existiert eine Kopie. | |
| T8.5 | Taucher mit `first_dive_number = 101`, keine Tauchgänge | 2 Tauchgänge importiert | Nummern 101, 102 | |
| T8.6 | Tauchgänge #1–#5 | manuell #3 doppelt vergeben | gespeichert, Hinweis `duplicateNumber`, nicht blockiert | |
| T8.7 | Katalog-Datei Version V1 geladen | App-Start mit gleicher Version | `catalogue_sites` nicht neu befüllt | |
| T8.8 | Katalog-Datei Version V2 | App-Start | `catalogue_sites` neu befüllt, `dives.site_name` unverändert | |

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
| T11.9 | DB-Datei | Pfad geprüft (iOS) | `NSURLIsExcludedFromBackupKey` gesetzt (Integrationstest auf iOS bzw. Prüfung der Plattform-Methode) | |

## T12: UI-Zustände (Widget-Tests, `ui-spec.md`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T12.1 | keine Tauchgänge | Logbuch | Leerzustand mit „Importieren“ und „Manuell eintragen“ | |
| T12.2 | Tauchgang ohne Tauchplatz | Logbuch-Zeile | „Ohne Tauchplatz“ | |
| T12.3 | Tauchgang #42 | Logbuch-Zeile | Semantics-Label beginnt mit „Tauchgang 42“ | |
| T12.4 | Bluetooth aus | Gerätesuche | Text „Bluetooth ist ausgeschaltet.“ + Knopf | |
| T12.5 | Berechtigung dauerhaft verweigert | Gerätesuche | „Einstellungen öffnen“ | |
| T12.6 | 30 s ohne Fund | Gerätesuche | Checkliste + „Erneut suchen“ | |
| T12.7 | Suunto Ocean gefunden | Gerätesuche | ausgegraut + Link zur FIT-Anleitung | |
| T12.8 | `SerialMismatch` | Gerätesuche | Warn-Dialog, Primärknopf „Abbrechen“ | |
| T12.9 | PIN angefordert von „EON Core ••3F7A“ | Dialog | Gerätename sichtbar. Nach 60 s „Zeit abgelaufen“. | |
| T12.10 | Vorschau mit 1 Duplikat | Vorschau | Duplikat nicht ausgewählt, Knopf „2 Tauchgänge importieren“ | |
| T12.11 | nichts ausgewählt | Vorschau | Knopf deaktiviert „Nichts ausgewählt“ | |
| T12.12 | Detail ohne Druck | Detail | SAC „—“ + Info-Text | |
| T12.13 | Textskalierung 200 % | Logbuch, Detail | kein Overflow (`tester.takeException() == null`) | |
| T12.14 | alle Bildschirme | Semantics-Prüfung | jedes tippbare Element ≥ 48 dp (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `textContrastGuideline`) | |
| T12.15 | Manuelles Formular, Tiefe 400 | Speichern | Fehler „Tiefe muss zwischen 0 und 350 m liegen.“, Fokus springt hin | |

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
