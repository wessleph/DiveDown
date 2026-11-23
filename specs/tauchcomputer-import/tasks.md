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
| T1.1 | ein `ImportedDive` mit max. Tiefe 18,4 m, Dauer 47 min, Temp. 21 °C | geprüft | gültig, keine Warnungen | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.2 | max. Tiefe 351 m | geprüft | **abgelehnt** mit Grund `depthOutOfRange` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.3 | max. Tiefe −1 m | geprüft | abgelehnt `depthOutOfRange` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.4 | Dauer 24 h + 1 s | geprüft | abgelehnt `durationOutOfRange` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.5 | Startzeit 10 min in der Zukunft (laut `clock`) | geprüft | abgelehnt `startInFuture` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.6 | 3 Samples mit Temperatur 80 °C zwischen gültigen | geprüft | Tauchgang gültig, **diese 3 Samples verworfen**, Warnung `samplesDropped(3)` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.7 | Sample mit Druck 450 bar | geprüft | Druckwert verworfen (Sample bleibt), Warnung | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.8 | 100.001 Samples | geprüft | abgelehnt `tooManySamples` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.9 | Samples mit nicht steigender Zeit (t = 10, 10, 5) | geprüft | Samples nach Zeit sortiert, Duplikate entfernt, Warnung | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |
| T1.10 | genau an den Grenzen (0 m, 350 m, 24 h, −5 °C, 45 °C, 0 bar, 400 bar) | geprüft | gültig (Grenzen sind inklusiv) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkPlausibility`), Testaufbau ok |

Tests: `test/domain/import/plausibility_test.dart`. Ergänzt: negative Dauer (T1.4), Tiefe außerhalb der Grenzen verwirft das Sample (T1.6), Duplikate zählen als verworfene Samples (T1.9).
Festlegung T1.5: Mit UTC-Zeitpunkt wird genau verglichen. Ohne (Gerät kennt seine Zeitzone nicht, T4.2) wird die Wandzeit gegen „jetzt“ in UTC geprüft, mit **14 h Spielraum** für die größte Zeitzone. 10 h voraus geht, 15 h voraus nicht.

## T2: Duplikaterkennung (`domain/import/import_service.dart`, ADR 0003, security A2)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T2.1 | DB leer | 1 Tauchgang importiert | `Saved` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.2 | Tauchgang mit `source=diveComputer`, `sourceId=X`, gleiche Daten existiert | gleicher erneut importiert | `SkippedDuplicate`, nicht in Vorschau auswählbar | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.3 | gleiche `source` + `sourceId`, aber **andere max. Tiefe** | importiert | `NeedsConfirmation(reason: sameIdDifferentContent)`, **kein** stilles Überspringen | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.4 | anderer `sourceId`, Start ±90 s und max. Tiefe ±0,3 m zu bestehendem | importiert | `NeedsConfirmation(reason: similar)` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.5 | Start +3 min Abstand | importiert | `Saved` (außerhalb ±2 min) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.6 | ähnlicher Tauchgang existiert, aber bei **anderem Taucher** | importiert | `Saved` (Duplikate nur pro Taucher) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.7 | ähnlicher Tauchgang ist soft-gelöscht | importiert | `Saved` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.8 | 5 Tauchgänge, Speichern von Nr. 3 schlägt fehl (DB-Fehler simuliert) | importiert | 1, 2, 4, 5 gespeichert; 3 `Failed`; jeder Tauchgang in **eigener Transaktion** | ✅ 2026-11-20: rot wegen `UnimplementedError` (`ImportService.importDives`), Testaufbau ok |
| T2.9 | 2 Tauchgänge, einer mit 400 m / zweimal derselbe in einem Download | importiert | `Rejected(depthOutOfRange)`, der andere `Saved` / der zweite `SkippedDuplicate` | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T2.10 | bekannter Tauchcomputer `dc-1` | importiert | gespeicherter Tauchgang verweist auf `dc-1` | ✅ 2026-11-20: rot wegen `UnimplementedError` |

Tests: `test/domain/import/import_service_test.dart` (In-Memory-Drift, für T2.8 ein Repository, das genau ein Speichern scheitern lässt). `preview` liefert dieselben Ergebnisse ohne zu speichern (T2.2).
Toleranzen nach ADR 0003: Start ±2 min **und** max. Tiefe ±0,5 m. Plausibilität läuft zentral im `ImportService` (security §9.2). Neue Abfragen `findBySource`, `listStartingBetween` im `DiveRepository`.

## T3: Fingerprint und Geräte-Identität (`domain/import/dive_computer_registry.dart`, security A1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T3.1 | Gerät mit Seriennummer S unbekannt | Download mit 3 Tauchgängen, alle gespeichert | Gerät angelegt, `last_fingerprint` = Fingerprint des **neuesten** Tauchgangs | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.2 | Gerät S bekannt mit Fingerprint F | neuer Download startet | Plugin bekommt `sinceFingerprint = F` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.3 | Download liefert 2 Tauchgänge, dann Abbruch | Abbruch | 2 Tauchgänge in Vorschau, `last_fingerprint` **unverändert** | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.4 | gespeicherte Seriennummer S, Gerät meldet per `DEVINFO` S′ ≠ S bei gleichem Namen bzw. gleicher Adresse | Download | `SerialMismatch`-Ereignis, **kein** Fingerprint geschrieben, UI-Warnung | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.5 | wie T3.4, Nutzer wählt „Als neues Gerät verwenden“ | bestätigt | neues Gerät S′ angelegt, Fingerprint von S unberührt | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.6 | Speichern in Vorschau abgebrochen (Nutzer wählt nichts) | Vorschau verlassen | Fingerprint **nicht** gesetzt | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerRegistry`), Testaufbau ok |
| T3.7 | Gerät S bekannt, neues Handy (andere BLE-Adresse) | Download, Seriennummer S | dasselbe Gerät, Adresse aktualisiert, neuer Fingerprint | ✅ 2026-11-20: rot wegen `UnimplementedError` |

Tests: `test/domain/import/dive_computer_registry_test.dart` (In-Memory-Drift, `DriftDiveComputerRepository`). Die Seriennummer meldet das Plugin erst am Ende (`DownloadCompleteEvent.serialNumber`), deshalb wird in `finish` geprüft. „Neuester“ Fingerprint = der des gespeicherten Tauchgangs mit dem spätesten Start.

## T4: Adapter ParsedDive → ImportedDive (`data/import/divecomputer/`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T4.1 | `ParsedDive` mit Datum 2026-11-14 10:42:00, TZ-Offset +7200 s | übersetzt | `startTime` = 10:42 Ortszeit, `startInstant` = 08:42 UTC | ✅ 2026-11-20: rot wegen `UnimplementedError` (`importedFromParsedDive`), Testaufbau ok |
| T4.2 | `ParsedDive` ohne TZ-Offset | übersetzt | `startTime` = Gerätezeit, `startInstant` = null | ✅ 2026-11-20: rot wegen `UnimplementedError` (`importedFromParsedDive`), Testaufbau ok |
| T4.3 | Sample mit `tankPressuresBar = [200.0, null, 180.0]` | übersetzt | 2 Druckwerte mit `tankIndex` 0 und 2 | ✅ 2026-11-20: rot wegen `UnimplementedError` (`importedFromParsedDive`), Testaufbau ok |
| T4.4 | Gasgemisch O₂ 0,32 / He 0 | übersetzt | Gas „EAN32“ | ✅ 2026-11-20: rot wegen `UnimplementedError` (`importedFromParsedDive`), Testaufbau ok |
| T4.5 | **Fixtures** `test/fixtures/divecomputer/eon_core/*.bin` (3 echte EON-Core-Tauchgänge, aufgenommen am 2026-11-20 per BLE, Seriennummer genullt, siehe README dort) | über `parseRawDiveData` geparst | erwartete Tiefe, Dauer und Sample-Anzahl laut `…expected.json` | ✅ 2026-11-20 auf dem S25 Ultra: libdivecomputer liest alle 3 Tauchgänge wie erwartet (sofort grün, prüft den übernommenen Parser). Adapter und Plausibilität rot wegen `UnimplementedError` (`importedFromParsedDive`) |
| T4.6 | `avgDepthMeters` = 0,0 (EON Core) | übersetzt | Ø-Tiefe zeitgewichtet aus den Samples; ohne Samples `null`, nie 0 | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T4.7 | keine Min./Max.-Temperatur | übersetzt | aus den Sample-Temperaturen | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T4.8 | Fingerprint `5576006a` | übersetzt | `source=diveComputer`, `sourceId` = `EON Core:5576006a`, Fingerprint als Bytes | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T4.9 | Ereignisse mit und ohne Daten | übersetzt | Zeit und Typ bleiben, Daten als Text `mix=1` | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T4.10 | Samples mit NDL (decoType 0) und Dekostopp (decoType 2) | übersetzt | `ndlS` bzw. `decoCeilingM`/`decoTimeS`, Temperatur, Puls, Gas-Index | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T4.11 | Teil-Samples mit derselben Zeit (EON Core: erst Tiefe, dann Temperatur) | übersetzt | zu einem Sample zusammengeführt, spätere Werte gewinnen, fehlende bleiben, Druck pro Flasche vereint | ✅ 2026-11-20: rot, 4 statt 2 Samples. Gefunden mit T4.5: die Plausibilitätsprüfung verwarf 3–5 Samples pro echtem Tauchgang und damit Temperaturen |

Tests: `test/data/import/divecomputer/parsed_dive_adapter_test.dart` (PC). T4.5: `integration_test/eon_core_parse_test.dart` (auf dem Handy: `flutter test integration_test/eon_core_parse_test.dart`). Die Fixtures stecken eingebettet in `integration_test/eon_core_fixtures.g.dart`, erzeugt mit `dart run tool/embed_fixtures.dart`. `test/tool/embed_fixtures_test.dart` schlägt fehl, wenn die Datei nicht zu den Fixtures passt.
Neue Dev-Abhängigkeit: `integration_test` (Teil des Flutter-SDK, BSD-3).
Nicht in diesem Paket: die Import-Oberfläche (T12.4–T12.11) und das Zusammenspiel mit dem Plugin-Download. Sie folgen als nächster Schritt.

**Umgesetzt (Phase 50, 2026-11-20), T1–T4:**
- [x] T1 `checkPlausibility` → T1.1–T1.10 grün
- [x] T2 `ImportService` (+ `findBySource`, `listStartingBetween`) → T2.1–T2.10 grün. Bestätigte T2.3-Fälle ersetzen die Messdaten, Nummer, Tauchplatz, Notizen und Bewertung bleiben.
- [x] T3 `DiveComputerRegistry`, `DriftDiveComputerRepository` → T3.1–T3.7 grün
- [x] T4 `importedFromParsedDive` → T4.1–T4.4, T4.6–T4.11 grün (PC). **T4.5 auf dem S25 Ultra grün (9/9):** alle 3 echten Tauchgänge bestehen die Plausibilitätsprüfung ohne Änderung, Ø-Tiefe und Temperatur werden aus den Samples ergänzt. Die T4.5-Erwartung zur Sample-Anzahl zählt seit T4.11 Zeitpunkte statt Rohsamples.
- Gesamt: `flutter test` 195/195, `flutter analyze` ohne Befund.

## T17: BLE-Import von der Übertragung bis ins Logbuch (`domain/import/dive_computer_import.dart`, design §4.1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T17.1 | EON Core bekannt mit Fingerprint F | Download mit 2 Tauchgängen | Plugin bekommt F. Tauchgänge in Reihenfolge, Seriennummer und Firmware im Ergebnis, Fortschritt und Tauchgänge gehen an die Oberfläche | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DiveComputerImport.download`) |
| T17.2 | Gerät unbekannt | 2 Tauchgänge gespeichert | Gerät angelegt, Tauchgänge verweisen darauf (auch beim **ersten** Import), nächster Download startet nach dem neuesten | ✅ 2026-11-20: rot, wie T17.1 |
| T17.3 | 2 Tauchgänge, dann Abbruch durch Nutzer | gespeichert | beide gespeichert, Fingerprint unverändert | ✅ 2026-11-20: rot, wie T17.1 |
| T17.4 | 1 Tauchgang, dann `download_error` | gespeichert | Ende `connectionLost`, Tauchgang gespeichert, Fingerprint unverändert | ✅ 2026-11-20: rot, wie T17.1 |
| T17.5 | `download_crashed` | Download | Ende `failed` mit Code | ✅ 2026-11-20: rot, wie T17.1 |
| T17.6 | bekannte Seriennummer S, Gerät meldet S′ | Download / „Als neues Gerät verwenden“ | Abweichung steht **vor** der Vorschau im Ergebnis. Danach neues Gerät S′, Fingerprint von S unberührt, Tauchgänge verweisen auf S′ | ✅ 2026-11-20: rot, wie T17.1 |
| T17.7 | Download fertig | nichts ausgewählt, gespeichert | nichts gespeichert, Fingerprint unverändert (T3.6) | ✅ 2026-11-20: rot, wie T17.1 |
| T17.8 | 1 exaktes und 1 ähnliches Duplikat | Vorschau, dann ähnliches bestätigt | `SkippedDuplicate`, `NeedsConfirmation`, `Saved`. Bestätigtes wird gespeichert | ✅ 2026-11-20: rot, wie T17.1 |
| T17.9 | PIN angefordert, keine neuen Tauchgänge | Code eingegeben | Code geht ans Gerät, Ende `completed` ohne Tauchgänge | ✅ 2026-11-20: rot, wie T17.1 |

Tests: `test/domain/import/dive_computer_import_test.dart` (In-Memory-Drift, Fake-Quelle).

## T18: Plugin als `DiveComputerSource` (`data/import/divecomputer/plugin_dive_computer_source.dart`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T18.1 | Plugin meldet dasselbe Gerät zweimal, eins ohne Namen | Suche | nur BLE, jede Adresse einmal, ohne Namen steht das Produkt da, Stream endet mit der Suche | ✅ 2026-11-20: rot wegen `UnimplementedError` (`PluginDiveComputerSource.discover`) |
| T18.2 | Gerät mit Modell −1 (z. B. Ocean) | Suche, dann Stopp | sichtbar, `supported = false` | ✅ 2026-11-20: rot, wie T18.1 |
| T18.3 | Fingerprint `5576006a` | Download | Plugin bekommt Hex-Text, ohne Uhrzeit-Abgleich; ohne Fingerprint `null` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`…download`) |
| T18.4 | Fortschritt, 1 Tauchgang, Ende | Download | über `importedFromParsedDive` übersetzt (`sourceId`, Ø-Tiefe), Ende mit Seriennummer und Firmware | ✅ 2026-11-20: rot, wie T18.3 |
| T18.5 | BLE-Download läuft | Abbrechen | `cancelDownload`, `TransferCancelled`, Stream endet, **obwohl das Plugin bei BLE nach Abbruch nichts mehr meldet** | ✅ 2026-11-20: rot, wie T18.3 |
| T18.6 | USB: Plugin schickt nach Abbruch noch Tauchgänge und `onDownloadComplete` | Abbrechen | kein `TransferCompleted` | ✅ 2026-11-20: rot, wie T18.3 |
| T18.7 | Fehlercodes | Download | `connect_failed`, `bond_failed`, `not_found`, `download_error` = Verbindungsproblem, sonst unerwarteter Fehler | ✅ 2026-11-20: rot, wie T18.3 |
| T18.8 | PIN angefordert | Code eingegeben | `PinRequested`, Code geht an `submitPinCode` | ✅ 2026-11-20: rot, wie T18.3 |
| T18.9 | Adresse `…:3F:7A` bzw. iOS-UUID `…3A2B` | Kurzkennung | „3F7A“ bzw. „3A2B“ | ✅ 2026-11-20: rot wegen `UnimplementedError` (`shortId`) |

Tests: `test/data/import/divecomputer/plugin_dive_computer_source_test.dart` (Fake-`DiveComputerHostApi`, Rückrufe direkt am `DiveComputerService`).
Nicht am PC testbar: Laufzeit-Berechtigungen und Bluetooth-Zustand (`permission_handler`), Bildschirm anlassen und „Bluetooth einschalten“ (eigener Plattform-Kanal). Prüfung auf dem S25 Ultra mit dem echten EON Core.

**Umgesetzt (Phase 50, 2026-11-20), BLE-Import T12.4–T12.11, T12.14 (Import), T12.16–T12.25, T17, T18:**
- [x] `DiveComputerImport` (Download → `ImportService` → `DiveComputerRegistry`), neu `DiveComputerRegistry.ensure`, damit Tauchgänge schon beim ersten Import auf ihr Gerät verweisen → T17.1–T17.9 grün. Gespeichert wird **chronologisch**, damit die Nummern stimmen, auch wenn der Tauchcomputer den neuesten zuerst schickt.
- [x] `PluginDiveComputerSource` → T18.1–T18.9 grün. T18.6 umbenannt: Nach einem Abbruch endet der Stream sofort, späte Ereignisse (USB-Flush) werden nicht abgewartet. Aussage des Tests unverändert.
- [x] Oberfläche `ImportScreen`, `DiveComputerScreen` (Suche, Übertragung, PIN-Dialog, Seriennummer-Warnung, Vorschau), Texte in `app_de.arb` → alle T12-Import-Zeilen grün.
- [x] Plattform: `permission_handler` 13.0.2 (MIT, auch die 5 Plattformpakete), `PermissionBluetoothAccess`, Kanal `io.github.wessleph.divedown/device` (Android: Bluetooth an/aus, System-Dialog, SDK-Stufe, Bildschirm an; iOS: Bildschirm an). Manifest nach security §4 (`neverForLocation`, Standort und alte Bluetooth-Rechte nur bis SDK 30), `NSBluetoothAlwaysUsageDescription`.
- [x] Plugin (`// DiveDown:`): Suunto Ocean und Nautic werden mit Modell −1 gemeldet (`UnsupportedComputers.kt`, `BleScanner.swift`), JUnit `UnsupportedComputersTest` grün. **Ungeprüft:** der echte BLE-Name der Ocean.
- Gesamt: `flutter test` 242/242, `flutter analyze` ohne Befund.
- Noch offen aus §5.9: „Vergleichen“, „Tauchplatz für Ausgewählte setzen“, Sparkline und Info-Zeile „unplausible Messwerte entfernt“. Aus §5.7: „Logs senden“ (kommt mit T10). Aus §5.5: Untertitel „Zuletzt: EON Core, vor 3 Tagen“.
- **Auf dem S25 Ultra (Android 17) mit dem echten EON Core geprüft, 2026-11-20:** Vorab-Erklärung, System-Dialog nur „Geräte in der Nähe“ (kein Standort), Suche stoppt nach 30 s, bei laufender Suunto-App „Kein Tauchcomputer gefunden“ mit Suunto-Hinweis. Nach Deaktivieren der Suunto-App gefunden, **71 Tauchgänge in ca. 4,5 min** übertragen, alle plausibel, Nummern #1–#71 chronologisch, Bildschirm blieb an, kein PIN nötig (Kopplung bestand). Zweiter Download mit Fingerprint nach ca. 3 s „Alles auf dem neuesten Stand“, Gerät als „Bekannt“ markiert.
- Gefunden auf dem Handy und behoben (T12.26, T12.27): Der Import-Tab behielt nach dem Speichern die alte Vorschau. Der Tauchcomputer-Ablauf läuft jetzt über dem Tab-Gerüst (Root-Navigator), der Import-Tab öffnet immer bei der Quellenwahl. `flutter test` 244/244.
- Nicht auf dem Handy geprüft: PIN-Dialog (EON Core war gekoppelt), Abbrechen, Verbindungsabbruch, Seriennummer-Warnung. Diese Fälle decken nur die Widget-Tests ab.
- iOS: `permission_handler` braucht im Podfile `PERMISSION_BLUETOOTH=1`. Das kommt mit der iOS-Pipeline (KW 49), Swift ist ohne Mac nicht gebaut.

## T5: FIT-Import (`data/import/fit/`, security A2/R3)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T5.1 | gültige FIT-Datei eines Tauchgangs (Fixture, Suunto Ocean) | geparst | 1 `ImportedDive` mit Profil, Temperatur, `sourceId` aus `file_id` || ✅ 2026-11-20: rot, wie T5.2. Fixture vorerst Submersions Garmin-Datei, eine Ocean-Datei folgt (README im Fixture-Ordner). Ergänzt: T5.1b mit synthetischer Suunto-Datei |
| T5.2 | Datei > 10 MB | geparst | `FileTooLarge`, ohne Parser-Aufruf || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok |
| T5.3 | Datei ohne `.FIT`-Signatur im Header | geparst | `NotAFitFile`, ohne Parser-Aufruf || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok |
| T5.4 | Header gültig, CRC falsch | geparst | `CorruptFile` || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok |
| T5.5 | gültige Datei, nach 50 % abgeschnitten | geparst | `CorruptFile`, **kein Absturz** || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok |
| T5.6 | FIT einer Laufaktivität | geparst | `NoDiveInFile` || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok (Laufen synthetisch erzeugt) |
| T5.7 | Parser hängt (simuliert) | 30 s vergangen (`fake_async`) | `Timeout`, Isolate beendet || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok. Ergänzt: T5.7b, ein werfender Parser ergibt `corrupt` |
| T5.8 | Fuzz: 200 zufällig veränderte Varianten der Fixture (fester Seed) | jeweils geparst | jede liefert Ergebnis **oder** definierten Fehler, nie eine ungefangene Exception || ✅ 2026-11-20: rot wegen `UnimplementedError` (`FitDiveParser.parse`), Testaufbau ok. Bei jeder dritten Variante wird die CRC neu berechnet, damit der Parser selbst kaputte Daten sieht |
| T5.9 | Dateiname `../../databases/x.fit` | über „Teilen“ empfangen | Name nur angezeigt, nie als Pfad verwendet. Kein Schreiben außerhalb des Cache. || ✅ 2026-11-20: rot wegen `UnimplementedError` (`readSharedFile`). Dazu: Datei im Cache wird gelesen und gelöscht, > 10 MB, fehlende Datei |

Tests: `test/data/import/fit/fit_dive_parser_test.dart`, `test/data/import/fit/shared_file_reader_test.dart`. Synthetische FIT-Dateien baut `test/support/fit_builder.dart` (aus Submersion) mit `fit_tool`.
Festlegungen: `sourceId` = `<file_id.serial_number>:<time_created in Unix-Sekunden>`. Größenlimit **10 MB** wie A2 und ui-spec §5.8 (security G2 nennt noch 20 MB). Gasgemische ohne Flaschen-Infos werden je eine Flasche, wie beim BLE-Adapter. Der Parser läuft in einem Isolate, das bei Zeitüberschreitung beendet wird. Die Ablaufsteuerung ist für T5.7 austauschbar.
Neue Abhängigkeiten (Lizenzen am 2026-11-20 an den eingesetzten Versionen geprüft): `fit_tool` 1.0.5 (BSD-3, dazu `csv` 5.1.1 und `logger` 1.4.0, beide MIT), `file_picker` 13.4.0 (MIT, Plattformpakete MIT; `cross_file`, `win32`, `ffi_leak_tracker` BSD-3; `dbus` 0.8.1 MPL-2.0 ohne Vermerk „Incompatible With Secondary Licenses“, nur Linux; `xml`, `petitparser` MIT), `receive_sharing_intent` 1.8.1 (Apache-2.0), Dev: `fake_async` (Apache-2.0).

**Umgesetzt (Phase 50, 2026-11-20), FIT-Import T5.1–T5.9, T12.28–T12.34, T12.14 (FIT):**
- [x] `FitDiveParser`: Größe, `.FIT`-Header und Datei-CRC vor dem Parsen, dann `importedFromFit` in einem eigenen Isolate mit 30 s Zeitlimit (wird bei Zeitüberschreitung beendet). Sechs Extraktoren aus Submersion übernommen (`lib/data/import/fit/`, Herkunftskopf, seit `e78a87cb` unverändert): Profil mit Deko-Werten, Flaschendruck, Gase, Zeit. Ohne GPS-Spur, Gewebe-Werte, Gaswechsel und Gerätenamen (keine Felder in DiveDown). Einstiegsposition kommt als `siteLat`/`siteLon` mit → T5.1–T5.8 grün, Fuzz 200/200.
- [x] **Teilen ohne `receive_sharing_intent`:** Das Plugin (1.8.1) schreibt geteilte Dateien unter Android nach `File(cacheDir, <Name der sendenden App>)`. Ein Name mit `../` schreibt also außerhalb des Cache, bevor DiveDown die Datei sieht (security A2). Außerdem baute es hier nicht (JVM-Ziel). Ersetzt durch `SharedFileIntake.kt` und `MainActivity.kt`: Inhalt per `ContentResolver` direkt in den Speicher, höchstens 10 MB, der Name ist nur Anzeige. JUnit `SharedFileIntakeTest` 5/5. Dart: `ChannelSharedFiles`. `readSharedFile` (T5.9) bleibt für iOS, wo Dateien als Pfad im Inbox-Ordner ankommen. Abhängigkeit entfernt.
- [x] Dateiauswahl über `file_picker` (`SystemFilePicker`). Das Plugin prüft Path-Traversal selbst (`PickerPaths.uniqueCachedFile`). Gelesen wird in den Speicher, der Cache wird danach geleert.
- [x] Vorschau als gemeinsames Widget `ImportPreview` für BLE und FIT. `FitImportScreen` mit „Datei wird gelesen …“ ab 300 ms (§4) und den Fehlertexten aus §5.8. Geteilte Dateien öffnen die FIT-Vorschau von jedem Tab aus.
- Testaufbau T12.34: wartet mit `pumpAndSettle`, weil der Seitenwechsel aus einem anderen Tab länger dauert. Aussage unverändert.
- Gesamt: `flutter test` 275/275, `flutter analyze` ohne Befund, Debug-APK baut, Manifest ohne neue Rechte.
- **Auf dem S25 Ultra geprüft, 2026-11-20:** Datei-Dialog mit der Fixture: Vorschau „Aus Datei: …“, 26.03.2026 11:02, 58,9 m, 75 min, gespeichert. Ein FIT-Export der Suunto-App (EON-Core-Tauchgang vom 13.11.) kam als `VIEW` mit `application/octet-stream` an und wurde gelesen. Die Vorschau warnte „Ähnlicher Tauchgang vorhanden“ (gleicher Tauchgang schon per BLE da), der Haken war aus. Ein `adb`-Teilen ohne Leserechte zeigte richtig „konnte nicht gelesen werden“ statt abzustürzen.
- Beobachtet: Die Suunto-App schreibt keine Seriennummer in `file_id`, die `sourceId` lautet dann `0:<time_created>`. Sie kennt den Zeitversatz (hier +7 h), der EON Core per BLE nicht. Die Wandzeit stimmt trotzdem überein. Ältere Tauchgänge bekommen die nächste freie Nummer (#72 für März 2026), nicht eine Nummer nach Datum.
- Offen: echte Ocean-Fixture, iOS (Dokumenttyp FIT und „Öffnen in“, kommt mit der iOS-Pipeline), „Logs senden“ (T10).

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
| T7.1 | Flasche 12 l, 200 → 50 bar, Dauer 50 min, mittlere Tiefe 10 m (Salzwasser) | Ø-SAC berechnet | (150 × 12) / (50 × 2,0) = **18,0 l/min** (±0,1) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.2 | wie T7.1, Süßwasser | berechnet | Umgebungsdruck mit 9,81 kPa/m statt 10,05 kPa/m, Ergebnis entsprechend | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.3 | Druckverlauf in Samples | Kurve berechnet | 1-min-Abschnitte. Abschnitt ohne Druckänderung = 0. Kein Abschnitt negativ. | |
| T7.4 | kein Druck | berechnet | `null` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.5 | Druck vorhanden, kein Flaschenvolumen | berechnet | `null` mit Grund `missingVolume` | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
| T7.6 | 2 Flaschen (Gaswechsel) | berechnet | SAC pro Flasche über deren Nutzungszeit | |
| T7.7 | Dauer 0 | berechnet | `null`, kein Division-durch-0 | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SacCalculator.average` fehlt), Testaufbau ok |
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
| T9.1 | eigener Name „Walensee, Quinten“ verwendet, Katalog enthält „Walchensee“ | Eingabe „wal“ | zuerst „Walensee, Quinten“ (eigen), dann Katalog | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.2 | Katalog enthält „SS Thistlegorm“ (EG) | Eingabe „thistle“ | Treffer „SS Thistlegorm“ mit „South Sinai, Ägypten“ (Region aus dem Katalog, Land deutsch). Ohne Region nur das Land, ohne beides nichts | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.3 | Eingabe „sha'ab el erg“ vs. Katalog „Sha’ab El Erg“ | gesucht | Treffer (ohne Akzente, Groß-/Kleinschreibung und Apostroph-Varianten) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.4 | 20 Treffer möglich | gesucht | höchstens 8 (eigene und Katalog zusammen) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.5 | Position bekannt (27,81 N / 33,92 O) | Eingabe „reef“ | nähere Treffer zuerst | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.6 | beliebige Eingabe | gesucht | letzte Zeile „‚…‘ als neuen Tauchplatz verwenden“ | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.7 | Name > 120 Zeichen im Katalog | angezeigt | auf 120 gekürzt, als reiner Text | ✅ 2026-11-20: rot wegen `UnimplementedError` (`SiteSuggester` fehlt), Testaufbau ok |
| T9.8 | Tauchgänge mehrerer Taucher mit Namen, ohne Namen, nur Leerzeichen, gelöscht | `ownSites` | jeder Name einmal, zuletzt benutzt zuerst, mit Verknüpfung und Position der letzten Nutzung. Leere und gelöschte fallen weg | ✅ 2026-11-20: rot wegen `UnimplementedError` (`DriftSiteRepository`) |
| T9.9 | Anna taucht an `osm_1` (EG), Ben an `osm_2` (DE) | `visitedCountries` | Anna {EG}, Ben {DE} | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T9.10 | 2 Katalog-Einträge | `catalogue` | beide mit allen Feldern | ✅ 2026-11-20: rot wegen `UnimplementedError` |
| T9.11 | Formular-Entwurf mit Katalog-Verknüpfung | `toDive` / `fromDive` | `site_catalogue_id`, `site_lat`, `site_lon` gespeichert bzw. übernommen. Der Entwurf entscheidet: ohne Verknüpfung wird sie gelöscht, auch bei gleichem Namen | ✅ 2026-11-20: rot, Felder werden nicht übernommen (Expected `osm_1`, Actual null) |
| T9.12 | Formular, Katalog geladen | „thistle“ getippt, Vorschlag gewählt | Feld „SS Thistlegorm“, Liste zu. Gespeichert mit `osm_1` und Position | ✅ 2026-11-20: rot, keine Vorschläge im Feld |
| T9.13 | Formular | „Walensee, Quinten“ getippt | Zeile „‚Walensee, Quinten‘ als neuen Tauchplatz verwenden“, gespeichert ohne Verknüpfung | ✅ 2026-11-20: rot, keine Vorschläge |
| T9.14 | Katalog-Platz gewählt | Name danach überschrieben | gespeichert ohne Verknüpfung und Position | ✅ 2026-11-20: rot, keine Vorschläge |
| T9.15 | früherer Tauchgang „Walensee, Quinten“ | „wal“ getippt | eigener Name über „Walchensee“. Ein eigener Name mit Katalog-Verknüpfung erscheint nur einmal. Stimmt die Eingabe mit einem eigenen Namen überein, keine „neu“-Zeile | ✅ 2026-11-20: rot (Domäne `UnimplementedError`, UI keine Vorschläge) |
| T9.16 | frühere Plätze | leeres Feld angetippt | die zuletzt benutzten eigenen Namen (höchstens 8), keine „neu“-Zeile | ✅ 2026-11-20: rot, keine Vorschläge |
| T9.17 | Tauchgang mit Katalog-Verknüpfung | nur Tiefe geändert, gespeichert | Verknüpfung und Position bleiben | ⚠️ 2026-11-20: sofort grün, weil das heute über den Namensvergleich in `toDive` schon gilt. Bleibt als Absicherung, weil T9.11 genau diesen Weg umbaut |
| T9.18 | eigener Platz mit Verknüpfung | gewählt | einmal angezeigt, Verknüpfung wird mitgespeichert | ✅ 2026-11-20: rot, keine Vorschläge |
| T9.19 | Ländercodes | übersetzt | `EG` → Ägypten, `CH` → Schweiz, `US` → Vereinigte Staaten usw.; jedes Land im mitgelieferten Katalog hat einen deutschen Namen; unbekannt → Code | ✅ 2026-11-20: rot wegen `UnimplementedError` (`countryNameDe`) |
| T9.20 | App | Einstellungen → „Open-Source-Lizenzen“ | Lizenzseite mit Eintrag „Tauchplatz-Katalog“: ODbL, OpenStreetMap, Wikidata (ADR 0006) | ✅ 2026-11-20: rot, `registerCatalogueLicence` wirft `UnimplementedError`, Eintrag in den Einstellungen fehlt |
| T9.21 (=T12.14) | Vorschlagsliste offen | Semantics-Prüfung | Touch-Ziele und Kontrast erfüllt | ✅ 2026-11-20: rot, keine Vorschläge |

Tests: `test/domain/sites/site_suggestions_test.dart`, `test/data/local/site_repository_test.dart`, `test/domain/dive/manual_dive_draft_test.dart` (T9.11), `test/features/logbook/site_field_test.dart`, `test/app/licenses_test.dart`.
Festlegungen: Eigene Namen kommen von **allen Tauchern auf dem Gerät**. Leere Eingabe zeigt nur eigene Namen. Rangfolge im Katalog: mit Position nach Entfernung, sonst besuchte Länder zuerst, dann Namensanfang vor Wortanfang, dann alphabetisch. Deutsche Ländernamen als feste Tabelle im Code (Ländernamen sind Fakten, keine neue Abhängigkeit). Position aus FIT-Dateien gibt es erst mit T5. Bis dahin wirkt T9.5 nur in der Domäne.

**Umgesetzt (Phase 50, 2026-11-20):**
- [x] Domäne: `SiteSuggester`, `normalizeSiteName`, deutsche Ländernamen (`country_names_de.dart`) → T9.1–T9.7, T9.15–T9.19 grün. Nachweis: `flutter test test/domain/sites` (17/17)
- [x] Daten: `DriftSiteRepository`, Katalog-Verknüpfung im `ManualDiveDraft` → T9.8–T9.11 grün
- [x] Oberfläche: `SiteField` mit Vorschlagsliste unter dem Feld (kein Overlay), Einstellungen → „Open-Source-Lizenzen“ mit ODbL-Hinweis → T9.12–T9.18, T9.20, T9.21 grün
- Gesamt: `flutter test` 146/146, `flutter analyze` ohne Befund, `flutter build apk --debug` ok.

## T10: Diagnose-Logs (`data/diagnostics/`, security A4, design §9)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T10.1 | Eintrag mit MAC `AA:BB:CC:DD:EE:FF` bzw. klein geschrieben | gefiltert | `••:EE:FF` | ✅ 2026-11-23: rot wegen `UnimplementedError` (`sanitizeLogEntry`) |
| T10.2 | `serial=12345678`, `serial=0x2219801234`, `serial=123` | gefiltert | `serial=••5678`, `••1234`, `••` | ✅ 2026-11-23: rot, wie T10.1 |
| T10.3 | libdivecomputer-HEXDUMP-Zeile (Kategorie `LDC`) | gefiltert (Release / Debug) | verworfen / bleibt | ✅ 2026-11-23: rot, wie T10.1 |
| T10.4 | „Unmatched device … (Annas AirPods)“ | gefiltert (Release / Debug) | verworfen / bleibt | ✅ 2026-11-23: rot, wie T10.1 |
| T10.5 | „27.8123, 33.9201“, `lat=-8.27512 lon=115.59341`; „18.4 m 47 min fw 1.2.3“ | gefiltert | Koordinaten → `[Ort entfernt]`, Tiefe/Zeit/Versionen bleiben | ✅ 2026-11-23: rot, wie T10.1 |
| T10.6 | E-Mail, `C:\Users\anna\…`, `/Users/anna/…`, `/home/anna/…` | gefiltert | `[entfernt]` | ✅ 2026-11-23: rot, wie T10.1 |
| T10.7 | Kategorie `health` bzw. `notes`; alle erlaubten | gefiltert | verworfen; erlaubte bleiben (Positivliste `BLE`, `SER`, `LDC`, `app`, `import`, `backup`, `error`) | ✅ 2026-11-23: rot, wie T10.1 |
| T10.8 | Grenze 2.000 Bytes, 100 Einträge | geschrieben | Datei ≤ Grenze, älteste weg, neuester da (Standard 5 MB) | ✅ 2026-11-23: rot wegen `UnimplementedError` (`FileDiagnosticLog.log`) |
| T10.9 | Einträge vom 1.11. und 20.11. | `prune` am 23.11. | nur der vom 20.11. bleibt (7 Tage) | ✅ 2026-11-23: rot, wie T10.8 |
| T10.10 | ein Eintrag bzw. leeres Log | Export | Kopf „DiveDown 1.0.0 (Build 42)“, System, Gerät, libdivecomputer, dann die Einträge | ✅ 2026-11-23: rot, wie T10.8 |
| T10.11 | Plugin meldet `BLE INFO connected`, ein „Unmatched device“, `LDC WARN timeout` | `connectPluginLogs` | zwei Zeilen, das fremde Gerät fehlt | ✅ 2026-11-23: rot wegen `UnimplementedError` (`connectPluginLogs`) |
| T10.12 | Absturz `StateError` mit Stack in `C:/Users/anna/…` | `recordError` | `ERROR error Bad state: boom` mit Stack, ohne „anna“ | ✅ 2026-11-23: rot wegen `UnimplementedError` (`recordError`) |
| T10.13 | 250 Zeilen bzw. leeres Log | Einstellungen → HILFE → „Diagnose-Logs teilen“ | Info-Text, Vorschau der ersten 200 Zeilen, „… 50 weitere Zeilen“, „Am besten per Mail.“, „Teilen“ teilt `DiveDown-Diagnose-JJJJ-MM-TT.txt` mit Kopf und allen Zeilen; leer: „Noch keine Einträge im Protokoll.“, „Teilen“ gesperrt | ✅ 2026-11-23: rot, Abschnitt HILFE fehlt |
| T10.14 | Tauchcomputer-Fehlerkarte bzw. „Wiederherstellen fehlgeschlagen“ | „Logs an Entwickler senden“ | öffnet „Diagnose-Logs teilen“ | ✅ 2026-11-23: rot, Knopf fehlt |
| T10.15 | `….txt`, `….divedown`, sonstige | `shareMimeType` | `text/plain`, `application/zip`, `application/octet-stream` | ✅ 2026-11-23: rot wegen `UnimplementedError`. Gefunden auf dem Handy: das Diagnose-Log wurde als ZIP angeboten |

Abgenommen am 2026-11-23. Tests: `test/data/diagnostics/log_sanitizer_test.dart` (T10.1–T10.7), `test/data/diagnostics/file_diagnostic_log_test.dart` (T10.8–T10.12), `test/features/settings/diagnostics_test.dart` (T10.13), T10.14 in `dive_computer_screen_test.dart` und `backup_test.dart`. Stubs: `DiagnosticLog`, `sanitizeLogEntry`, `FileDiagnosticLog`, `connectPluginLogs`, `recordError`, Provider `diagnosticLogProvider`, `diagnosticHeaderProvider`. Widget-Tests bekommen über `pumpTestApp` ein `MemoryDiagnosticLog`.
Festlegungen: Das Log liegt im **Cache** der App (`<cache>/logs/diagnostic.log`) und ist damit in keinem Backup. Positivliste nach **Kategorie** plus Filter für Inhalte (MAC, Seriennummer, Koordinaten, E-Mail, Pfade); HEXDUMP und fremde BLE-Geräte nur im Release verworfen, damit Debug-Builds beim Entwickeln alles zeigen. Gesundheitswerte, Namen und Notizen schreibt die App gar nicht erst ins Log (keine Kategorie dafür).
Neue Abhängigkeit (Lizenz am 2026-11-23 geprüft): `device_info_plus` 13.3.0 (BSD-3, `device_info_plus_platform_interface` 8.1.0 BSD-3, `win32_registry` 3.0.3 BSD-3) für Gerätemodell und Systemversion im Kopf.

## T11: Sichern und Wiederherstellen (`data/backup/`, security O1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T11.1 | Logbuch mit 1 Taucher, 10 Tauchgängen (ein Taucher pro App, 2026-11-22) | Sicherung erstellt | `.divedown`-ZIP mit genau `manifest.json` und `divedown.sqlite` (SQLite-Kopf); Manifest mit Format 1, App-Version, Schema-Version, Zeit (UTC), SHA-256 der DB, Anzahl Tauchgänge | ✅ 2026-11-22: rot wegen `UnimplementedError` (`LogbookBackup.create`) |
| T11.2 | Sicherung aus T11.1 | in leere App wiederhergestellt | gleicher Taucher (Name, Startnummer 101), 10 Tauchgänge mit Nummern, Plätzen und Samples; die DB wurde vorher geschlossen | ✅ 2026-11-22: rot, wie T11.1 |
| T11.3 | Sicherung mit falscher Prüfsumme | geprüft bzw. wiederhergestellt | `corrupt`, die DB wird nicht geschlossen, aktuelle DB unverändert | ✅ 2026-11-22: rot, wie T11.1 |
| T11.4 | Sicherung mit Schema-Version > aktuell | geprüft | `newerVersion` | ✅ 2026-11-22: rot, wie T11.1 |
| T11.5 | ZIP mit Eintrag `../evil`; kein ZIP; ZIP ohne Manifest | wiederhergestellt bzw. geprüft | `invalid`, nichts außerhalb des Ordners geschrieben | ✅ 2026-11-22: rot wegen `UnimplementedError` (`create` bzw. `inspect`) |
| T11.6 | gültige Sicherung, Schreiben bricht nach einem Drittel ab (simuliert) | wiederhergestellt | `RestoreFailed`, die vorherige DB (Lena, 1 Tauchgang) ist wieder da | ✅ 2026-11-22: rot, wie T11.1 |
| T11.7 | Datei > Grenze (200 MB, im Test 1.000 Bytes) | geprüft | `tooLarge`, ohne zu entpacken | ✅ 2026-11-22: rot wegen `UnimplementedError` (`inspect`) |
| T11.8 | letzte Sicherung vor 31/29 Tagen; nie gesichert, erster Start vor 34/3 Tagen; ✕ bis morgen; ohne Tauchgänge | `backupReminderDue` | fällig / nicht / fällig / nicht / nicht / nicht | ✅ 2026-11-22: rot wegen `UnimplementedError` (`backupReminderDue`) |
| T11.9 | DB-Datei | Pfad geprüft (iOS) | `NSURLIsExcludedFromBackupKey` gesetzt (Integrationstest auf iOS bzw. Prüfung der Plattform-Methode) | ✅ 2026-11-20: rot wegen `UnimplementedError` (`BackupExclusion`, `openAppDatabase` fehlen), Testaufbau ok. Geprüft wird der Aufruf aus Dart, die Swift-Seite läuft erst auf iOS (CI/TestFlight) |
| T11.10 | DB-Datei | Android-Manifest geprüft | `dataExtractionRules` schließt den Ordner `db/` aus `cloud-backup` **und** `device-transfer` aus, `fullBackupContent` (Android 8–11, minSdk 26) aus dem Voll-Backup. Kein Kanalaufruf unter Android | ✅ 2026-11-20: rot, Manifest-Attribute und `res/xml/*.xml` fehlen bzw. `UnimplementedError` |

| T11.11 | Einstellungen | angezeigt | Abschnitt DATEN mit „Logbuch sichern“ und „Logbuch wiederherstellen“ | ✅ 2026-11-22: rot, Abschnitt fehlt |
| T11.12 | „Logbuch sichern“ | „Sicherung erstellen“ | Info- und Warntext (§5.12), Teilen-Dialog mit `DiveDown-Sicherung-….divedown`, „Sicherung erstellt“, Zeitpunkt gemerkt | ✅ 2026-11-22: rot, Eintrag fehlt |
| T11.13 | gültige Sicherung (20.12.2026, 128 Tauchgänge) | „Logbuch wiederherstellen“ | „Sicherung vom 20.12.2026 · 128 Tauchgänge“, Ersetzen-Hinweis, „Wiederherstellen“ → „Wiederhergestellt“; „Abbrechen“ bzw. kein Dateiwahl ändert nichts | ✅ 2026-11-22: rot, Eintrag fehlt |
| T11.14 | ungültig / beschädigt / neuere Version / über 200 MB / Ersetzen schlägt fehl | wiederherstellen | die Texte aus §5.12, ersetzt wird nur im letzten Fall versucht | ✅ 2026-11-22: rot, Eintrag fehlt |
| T11.15 | nie gesichert, erster Start vor 40 Tagen; Sicherung vor 34 Tagen; Sicherung heute | Logbuch | „Noch keine Sicherung.“ + „Jetzt sichern“, ✕ blendet 7 Tage aus; „Letzte Sicherung vor 34 Tagen.“, „Jetzt sichern“ öffnet Sichern; keine Karte | ✅ 2026-11-22: rot, Karte fehlt bzw. `UnimplementedError` (`setLastBackupAt`) |
| T11.16 | geteilte Sicherung; Name `../../evil.divedown`; App-Start | `prepareShareFile`, `clearShareFolder` | Datei bleibt in `<cache>/share/`, bis zum nächsten Teilen oder App-Start; nur der Dateiname zählt | ✅ 2026-11-22: rot wegen `UnimplementedError`. Gefunden auf dem Handy: die Datei wurde gelöscht, sobald der Teilen-Dialog zurückkehrte, Drive oder Gmail lesen sie aber evtl. erst danach |

Abgenommen am 2026-11-22. Tests T11.1–T11.8: `test/data/backup/logbook_backup_test.dart` (echte DB-Dateien in einem Temp-Ordner), T11.11–T11.15: `test/features/settings/backup_test.dart`. Stubs: `LogbookBackup`, `backupReminderDue`, `BackupActions`, Einstellungen `lastBackupAt`, `backupBaseline`, `backupReminderSnoozedUntil`, Provider `backupActionsProvider`, `shareFileProvider`, `backupFilePickerProvider`. T23.6 prüft „sichern“ nicht mehr (kam mit T11).
Neue Abhängigkeiten (Lizenzen am 2026-11-22 geprüft): `archive` 4.7.1 (MIT, dazu `posix` 6.5.4 MIT), `crypto` 3.0.6 (BSD-3, war schon transitiv), `share_plus` 13.3.1 (BSD-3, `share_plus_platform_interface` 7.2.0 BSD-3; `mime`, `file`, `cross_file` BSD-3 schon vorhanden).
Tests T11.9/T11.10: `test/data/platform/backup_exclusion_test.dart`, `test/app/startup_test.dart`. Die DB liegt in einem **eigenen Ordner** `db/`, damit auch die `-wal`/`-journal`-Dateien vom Ausschluss erfasst sind. Der Ausschluss wird bei jedem Start erneut gesetzt.

## T12: UI-Zustände (Widget-Tests, `ui-spec.md`)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T12.1 | keine Tauchgänge | Logbuch | Leerzustand mit „Importieren“ und „Manuell eintragen“ | ✅ 2026-11-20: rot, Leerzustand fehlt (Text nicht gefunden) |
| T12.2 | Tauchgang ohne Tauchplatz | Logbuch-Zeile | „Ohne Tauchplatz“ | ✅ 2026-11-20: rot, Liste fehlt (Text nicht gefunden) |
| T12.3 | Tauchgang #42 | Logbuch-Zeile | Semantics-Label beginnt mit „Tauchgang 42“ | ✅ 2026-11-20: rot, Liste fehlt (`#42` nicht gefunden) |
| T12.4 | Bluetooth aus | Gerätesuche | Text „Bluetooth ist ausgeschaltet.“ + Knopf || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.5 | Berechtigung dauerhaft verweigert | Gerätesuche | „Einstellungen öffnen“ || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.6 | 30 s ohne Fund | Gerätesuche | Checkliste + „Erneut suchen“ || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.7 | Suunto Ocean gefunden | Gerätesuche | ausgegraut + Link zur FIT-Anleitung || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.8 | `SerialMismatch` | Gerätesuche | Warn-Dialog, Primärknopf „Abbrechen“ || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.9 | PIN angefordert von „EON Core ••3F7A“ | Dialog | Gerätename sichtbar. Nach 60 s „Zeit abgelaufen“. || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.10 | Vorschau mit 1 Duplikat | Vorschau | Duplikat nicht ausgewählt, Knopf „2 Tauchgänge importieren“ || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.11 | nichts ausgewählt | Vorschau | Knopf deaktiviert „Nichts ausgewählt“ || ✅ 2026-11-20: rot, `DiveComputerScreen` wirft `UnimplementedError` |
| T12.12 | Detail ohne Druck | Detail | SAC „—“ + Info-Text | ✅ 2026-11-20: rot, `DiveDetailScreen` wirft `UnimplementedError` |
| T12.13 | Textskalierung 200 % | Logbuch, Detail | kein Overflow (`tester.takeException() == null`) | ✅ 2026-11-20: rot, Inhalt fehlt (Liste, Detail, Formular). Der Test verlangt vorher sichtbaren Inhalt, damit er nicht leer grün wird |
| T12.14 | alle Bildschirme | Semantics-Prüfung | jedes tippbare Element ≥ 48 dp (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `textContrastGuideline`) | ✅ 2026-11-20: rot, Inhalt fehlt, wie T12.13. Abgedeckt: Logbuch (leer und Liste), Detail, Formular. Import-Bildschirme folgen mit dem Import. **Import (Quelle, Geräteliste, Vorschau):** ✅ 2026-11-20 rot, Karte „Tauchcomputer“ fehlt |
| T12.15 | Manuelles Formular, Tiefe 400 | Speichern | Fehler „Tiefe muss zwischen 0 und 350 m liegen.“, Fokus springt hin | ✅ 2026-11-20: rot, Formular fehlt (kein FAB) |

| T12.16 | Importieren-Tab, Android | angezeigt | „Importieren für: Anna“, Karten „Tauchcomputer · Per Bluetooth übertragen“ und „FIT-Datei“, **kein** Apple Health. Tippen auf „Tauchcomputer“ öffnet die Suche | ✅ 2026-11-20: rot, Text nicht gefunden (Tab ist leer) |
| T12.17 | Bluetooth bereit | Gerätesuche geöffnet | Suche startet von selbst, „Suche nach Tauchcomputern …“, Koppel-Hinweis EON Core, „Stopp“ beendet die Suche | ✅ 2026-11-20: rot, `UnimplementedError` (`DiveComputerScreen`) |
| T12.18 | Übertragung läuft, 2 Tauchgänge da, Fortschritt 100/400 | angezeigt, dann „Abbrechen“ | „2 neue Tauchgänge gefunden …“, Balken 25 %, Hinweis „Halte den Tauchcomputer in der Nähe …“, Bildschirm bleibt an. Nach Abbruch „Übertragung abgebrochen.“, Vorschau mit beiden, Bildschirm wieder frei | ✅ 2026-11-20: rot, wie T12.17 |
| T12.19 | Download ohne neue Tauchgänge | beendet | „Alles auf dem neuesten Stand. …“, „Fertig“ führt zurück zu „Importieren“ | ✅ 2026-11-20: rot, wie T12.17 |
| T12.20 | Verbindung bricht nach 2 Tauchgängen ab | angezeigt | „Die Verbindung wurde unterbrochen.“, „2 Tauchgänge wurden übertragen.“, „Übertragene prüfen“ (→ Vorschau), „Erneut verbinden“ | ✅ 2026-11-20: rot, wie T12.17 |
| T12.21 | Vorschau mit 3 neuen Tauchgängen | „3 Tauchgänge importieren“ | zurück im Logbuch, Snackbar „3 Tauchgänge importiert“, 3 Tauchgänge gespeichert, Gerät mit Seriennummer und neuestem Fingerprint | ✅ 2026-11-20: rot, wie T12.17 |
| T12.22 | Berechtigung noch nicht erteilt | Gerätesuche | Vorab-Erklärung, erst „Weiter“ öffnet den System-Dialog, danach startet die Suche | ✅ 2026-11-20: rot, wie T12.17 |
| T12.23 | EON Core schon bekannt | gefunden | Kennzeichnung „Bekannt“ | ✅ 2026-11-20: rot, wie T12.17 |
| T12.24 | unerwarteter Fehler `download_crashed` | Übertragung | Fehlerkarte mit „Erneut versuchen“ und dem Code | ✅ 2026-11-20: rot, wie T12.17 |
| T12.25 | Tauchgang exakt schon im Logbuch | Vorschau | „Bereits im Logbuch“, Checkbox nicht bedienbar, zählt nicht mit | ✅ 2026-11-20: rot, wie T12.17 |
| T12.26 | Import gespeichert, zurück im Logbuch | Tab „Importieren“ | Quellenwahl, nicht die alte Vorschau | ✅ 2026-11-20: rot, Ort blieb `/import/divecomputer`. Gefunden auf dem Handy |
| T12.27 | Tauchcomputer-Ablauf offen | angezeigt | keine Tab-Leiste (ein Tab-Wechsel würde die Übertragung abbrechen) | ✅ 2026-11-20: rot, `NavigationBar` sichtbar |
| T12.28 | Importieren-Tab | „So exportierst du aus der Suunto-App“ | Anleitung mit den 3 Schritten aus §5.8 | ✅ 2026-11-20: rot, Link fehlt |
| T12.29 | Datei-Dialog | ohne Datei geschlossen | bleibt auf „Importieren“, nichts geparst | ✅ 2026-11-20: rot, Dialog nicht geöffnet (Karte zeigt „Kommt bald“) |
| T12.30 | Parser arbeitet | FIT-Bildschirm | „Datei wird gelesen …“, danach weg | ✅ 2026-11-20: rot, kein Wechsel nach `/import/fit` |
| T12.31 | FIT-Datei mit 1 Tauchgang | Vorschau, dann importieren | „Aus Datei: Tauchgang.fit“, „Importieren für: Anna“, gespeichert mit `source=fit`, ohne Tauchcomputer, Snackbar, Logbuch | ✅ 2026-11-20: rot, wie T12.30 |
| T12.32 | gleiche Datei schon importiert | Vorschau | „Bereits im Logbuch“, „Nichts ausgewählt“ | ✅ 2026-11-20: rot, wie T12.30 |
| T12.33 | zu groß / keine FIT / kaputt / unlesbar / kein Tauchgang / Zeitüberschreitung | FIT-Bildschirm | Text aus §5.8 mit Dateiname, nichts gespeichert. Zu groß schon im Dialog: Parser wird nicht aufgerufen | ✅ 2026-11-20: rot, wie T12.30 |
| T12.34 | App im Logbuch | Datei aus anderer App geteilt | öffnet direkt die FIT-Vorschau (§2) | ✅ 2026-11-20: rot, bleibt auf `/logbook` |

Tests: `test/features/logbook/` (Liste, Detail, Formular). In diesem Paket nur die Logbuch-Zeilen T12.1–T12.3 und T12.12–T12.15. T12.4–T12.11 und T12.16–T12.25 (Import) liegen in `test/features/import/dive_computer_screen_test.dart`, mit Fakes für Plugin, Berechtigungen und Bildschirm (`test/support/fake_dive_computer.dart`).

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
| T14.1 | Release-Build | Download-Session erstellt | `dc_context_set_loglevel(…, DC_LOGLEVEL_WARNING)`, im Debug-Build `ALL` | ohne eigenen Test (C-Code, hier nicht testbar); abgesichert durch T10.3, geprüft am Handy über das Diagnose-Log |
| T14.2 | Release-Build bzw. Debug-Build | `NativeLogger.d/i/w/e` | nichts nach logcat bzw. alles (JUnit `NativeLoggerTest` mit ersetzbarem logcat-Ziel) | ✅ 2026-11-23: rot, im Release kamen alle vier Zeilen in logcat an |
| T14.3 | BLE-Zugangscode gespeichert / unbekanntes Gerät / alter Klartext-Eintrag / unlesbarer Eintrag (anderes Handy) | `AccessCodeStore.set/get` | verschlüsselt gespeichert und zurückgelesen / `null` / einmal übernommen, alter Eintrag gelöscht / verworfen, PIN wird neu abgefragt (JUnit `AccessCodeStoreTest` mit Fake-Speicher und Fake-Verschlüsselung) | ✅ 2026-11-23: rot wegen `NotImplementedError` (`AccessCodeStore`) |
| T14.3b | `data_extraction_rules.xml`, `backup_rules.xml` | geprüft | `ble_access_codes.xml` und `ble_access_codes_v2.xml` aus Cloud-Backup, Geräte-Transfer und Voll-Backup ausgeschlossen | ✅ 2026-11-23: rot, Ausschluss fehlt |
| T14.4 | Beispiel-Manifeste | `checkAndroidManifest` | M1 kein `INTERNET`; M2 Standort und alte Bluetooth-Rechte nur mit `maxSdkVersion` ≤ 30; M3 `BLUETOOTH_SCAN` mit `neverForLocation`; M4 nie Hintergrund-Standort, Kamera, Kontakte, Mikrofon, Speicher; M5 Backup-Regeln gesetzt | ✅ 2026-11-23: rot wegen `UnimplementedError` (`checkAndroidManifest`) |

Abgenommen am 2026-11-23. Tests T14: `packages/libdivecomputer_plugin/android/src/test/.../AccessCodeStoreTest.kt`, `NativeLoggerTest.kt`, `test/app/startup_test.dart` (T14.3b), `test/tool/android_manifest_policy_test.dart` (T14.4). Stubs: `AccessCodeStore`, `KeyValueStore`, `SecretCipher`, `checkAndroidManifest`.
Ansatz T14.3 **ohne neue Abhängigkeit**: Android verschlüsselt mit AES-GCM, der Schlüssel liegt im Android Keystore (verlässt das Gerät nie, ist in keinem Backup); die Werte stehen in `ble_access_codes_v2` und alte Klartext-Werte werden beim ersten Lesen übernommen. iOS: Keychain mit `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` statt `UserDefaults`, Übernahme alter Werte genauso; dafür gibt es hier keinen Test (Swift im Plugin, nur über den CI-Build geprüft). `flutter_secure_storage` wird damit nicht gebraucht.
Ansatz T14.4: Die CI erzeugt im Job `android` das zusammengeführte Release-Manifest (`./gradlew :app:processReleaseMainManifest`, ohne ganzen Release-Build) und prüft es mit `dart run tool/check_android_manifest.dart`.

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

**Umgesetzt (Phase 50, 2026-11-20), Logbuch-Paket T7 (Ø-SAC), T11.9, T11.10, T12 (Logbuch-Zeilen), T15, T16:**
- [x] Domäne: `UnitFormatter`, `SacCalculator.average`, `ManualDiveDraft` → T7.1, T7.2, T7.4, T7.5, T7.7, T7.8, T15.1, T15.18, T15.19 grün. Nachweis: `flutter test test/domain` (33/33)
- [x] Daten und App-Start: `openAppDatabase`, `BackupExclusion` (iOS über `AppDelegate.swift`), Android-Regeln in `res/xml/`, `loadBundledCatalogue`, `nextNumber`, `DiverRepository.list`, `DriftAppSettings` → T11.9, T11.10, T15.23–T15.25, T16.1–T16.3 grün. Nachweis: `flutter test test/data test/app/startup_test.dart` (25/25)
- [x] Oberfläche: Willkommen, Logbuch, Detail, Formular, `AppStartupGate`, Texte in `app_de.arb` → T12.1–T12.3, T12.12–T12.15, T15.2–T15.17, T15.20–T15.22, T16.4 grün
- Gesamt: `flutter test` 111/111, `flutter analyze` ohne Befund, `flutter build apk --debug` ok, Backup-Attribute im zusammengeführten Manifest geprüft.
- Zwei Testaufbauten korrigiert, ohne die Aussage zu ändern: T0 „starts in the logbook“ sucht die Tab-Namen jetzt in der `NavigationBar`, weil der Leerzustand einen zweiten Knopf „Importieren“ hat. T12.13 (Liste) prüft die erste Zeile `#43` mit dem langen Namen, weil `#42` bei 200 % unterhalb des Bildschirms liegt.
- Noch nicht geprüft: iOS-Seite von T11.9 (kein Mac, kommt mit der CI-Pipeline), Bedienung auf einem echten Handy.

## T19: CI-Richtlinie (`tool/workflow_policy.dart`, security G6/A3, ADR 0005)
Prüft jede Datei unter `.github/workflows/`. Regeln W1–W9 stehen im Dateikopf von `tool/workflow_policy.dart`.
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T19.1 | Workflow hält alle Regeln ein | geprüft | keine Verstöße | ✅ 2026-11-20: rot wegen `UnimplementedError` (`checkWorkflow`) |
| T19.2 | `uses: actions/checkout@v4` bzw. kurzer SHA; lokale Action `./…` | geprüft | W1; lokale Action erlaubt | ✅ 2026-11-20: rot, wie T19.1 |
| T19.3 | `pull_request_target` bzw. `workflow_run` | geprüft | W2 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.4 | `permissions:` fehlt, `write-all` oben oder am Job | geprüft | W3 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.5 | `secrets.*` in Job ohne `environment: release`; `secrets.GITHUB_TOKEN` | geprüft | W4; `GITHUB_TOKEN` erlaubt | ✅ 2026-11-20: rot, wie T19.1 |
| T19.6 | Secret in einem Workflow mit `pull_request` | geprüft | W4, auch mit Environment | ✅ 2026-11-20: rot, wie T19.1 |
| T19.7 | Release-Job ohne `if:`, ohne Ref- oder ohne Repo-Bedingung | geprüft | W5 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.8 | `actions/checkout` ohne `persist-credentials: false` | geprüft | W6 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.9 | `${{ github.event.… }}` bzw. `${{ github.head_ref }}` in `run:`; dasselbe über `env:` | geprüft | W7 je Fundstelle; über `env:` erlaubt | ✅ 2026-11-20: rot, wie T19.1 |
| T19.10 | `git clone --branch 3.47.0 …flutter.git` bzw. `flutter-version: '3.47.0'` | geprüft | W8 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.11 | Job ohne `timeout-minutes` | geprüft | W9 | ✅ 2026-11-20: rot, wie T19.1 |
| T19.12 | Repo | geprüft | `.github/flutter-version.txt` = 3.47.0. `ci.yml` (Push und PR, ohne Secrets, Job `ios` auf macOS nur `main` oder manuell) und `ios-release.yml` (Tags `v*`, manuell, monatlich, nie PR; Jobs mit Secrets nur in `release`) existieren und halten W1–W9 ein | ✅ 2026-11-20: rot, Dateien fehlen |

Tests: `test/tool/workflow_policy_test.dart`. Neue Dev-Abhängigkeit (Lizenz am 2026-11-20 geprüft): `yaml` 3.1.4 (MIT; `source_span`, `string_scanner`, `term_glyph`, `collection`, `path` BSD-3), bisher schon transitiv.

## T20: iOS-Konfiguration und Swift-Seite (security §4, A2, A3, O1)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T20.1 | `Info.plist` | geprüft | I1: `NSBluetoothAlwaysUsageDescription` auf Deutsch, nirgends „Submersion“ | sofort grün (sichert den Stand aus T12) |
| T20.2 | `Info.plist` | geprüft | I2: kein `NSLocation*`, `NSHealthUpdateUsageDescription`, Kamera, Kontakte, Mikrofon | sofort grün (sichert den Stand) |
| T20.3 | `Info.plist` | geprüft | I3: genau ein importierter Typ mit Endung `.fit`, konform zu `public.data` | ✅ 2026-11-20: rot, `UTImportedTypeDeclarations` fehlt |
| T20.4 | `Info.plist` | geprüft | I3: Dokumenttyp für diesen Typ, Rolle `Viewer`, Rang `Alternate` | ✅ 2026-11-20: rot, wie T20.3 |
| T20.5 | `Info.plist` | geprüft | I3: `LSSupportsOpeningDocumentsInPlace` = false (Kopie nach `Inbox/`), `UIFileSharingEnabled` nicht an | ✅ 2026-11-20: rot, Schlüssel fehlt |
| T20.6 | `Info.plist` | geprüft | I4: `ITSAppUsesNonExemptEncryption` = false | ✅ 2026-11-20: rot, Schlüssel fehlt |
| T20.7 | `ios/Podfile` | geprüft | I5: iOS 15.0, nur `PERMISSION_BLUETOOTH=1`; `Podfile.lock` eingecheckt (G6) | ✅ 2026-11-20: rot, Podfile fehlt. `Podfile.lock` entsteht beim ersten `pod install` in der CI |
| T20.8 | Xcode-Projekt, Podfile, Podspec | geprüft | I6: überall iOS 15.0 | ✅ 2026-11-20: rot, Podfile fehlt |
| T20.9 | Datei in `Documents/Inbox` | `SharedFileInbox.acceptedPath` | Pfad wird angenommen | rot erwartet (Stub gibt `nil`), in der CI nicht rot gesehen (siehe unten); grün seit Lauf 44950959040 |
| T20.10 | Datei außerhalb, `Inbox/../x.fit`, Symlink nach außen, Nachbarordner `InboxEvil` | `acceptedPath` | `nil` | im Stub schon `nil`, gilt erst mit T20.9 als Nachweis |
| T20.11 | `https://…`, Ordner, fehlende Datei | `acceptedPath` | `nil` | wie T20.10 |
| T20.12 | iOS-Simulator | `openAppDatabase`, dann `isExcludedFromBackup` | Ordner `db/` trägt `NSURLIsExcludedFromBackupKey` (Swift-Seite von T11.9) | rot erwartet (`isExcludedFromBackup` fehlt in `AppDelegate.swift`), in der CI nicht rot gesehen (siehe unten); grün seit Lauf 44950959040 |

Tests: `test/ios/ios_config_test.dart` (PC), `ios/RunnerTests/RunnerTests.swift` (XCTest, `xcodebuild test` in der CI), `integration_test/ios_platform_test.dart` (iOS-Simulator in der CI, auf Android übersprungen). Neue Dev-Abhängigkeit (Lizenz am 2026-11-20 geprüft): `xml` 7.0.1 (MIT, dazu `petitparser` 7.0.2 MIT, `meta` BSD-3), bisher schon transitiv über `file_picker`.
Stub: `ios/Runner/SharedFileInbox.swift` (im Runner-Target eingetragen), gibt immer `nil`.
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T20.13 | iOS meldet `{name, path}` für eine Kopie in `Documents/Inbox` bzw. einen Pfad außerhalb | `ChannelSharedFiles.incoming` | über `readSharedFile`: Bytes gelesen, Name nur angezeigt, Kopie gelöscht; außerhalb `unreadable`, Datei bleibt unberührt | ✅ 2026-11-20: rot, `{path}` wird als Fehler gelesen (`PickFailed` statt `Picked`). Der Fall „außerhalb“ ist schon grün. Ergänzt bei der Umsetzung, abgenommen am 2026-11-21 |

Test: `test/data/platform/share_channel_test.dart`.

**Umgesetzt (Phase 50, 2026-11-21), T20.13:**
- [x] `ChannelSharedFiles` liest `{name, path}` über `readSharedFile`, nur innerhalb von `inboxDirs` (ohne Ordner wird jeder Pfad abgelehnt). Der Name kommt von der Plattform und wird nur angezeigt. `sharedFilesProvider` gibt `Documents/Inbox` mit → T20.13 grün.
- Gesamt: `flutter test` 303/304 (rot nur T20.7 `Podfile.lock`, kommt aus der CI), `flutter analyze` ohne Befund, Debug-APK baut. Auf Android unverändert: dort kommen weiter Bytes, nie Pfade.

**Umgesetzt (Phase 50, 2026-11-20), iOS-Pipeline T19, T20.1–T20.12:**
- [x] `checkWorkflow` (W1–W9) → T19.1–T19.11 grün.
- [x] `.github/flutter-version.txt`, `.github/workflows/ci.yml`, `.github/workflows/ios-release.yml`, Hilfsskripte `tool/ci/` (Flutter per `git clone` des Tags, Xcode 26 wählen, Simulator starten) → T19.12 grün.
  - `ci.yml`: Job `checks` (gitleaks 8.30.1 mit SHA-256-Prüfung, Format, analyze, `flutter test`, Katalog-Skripttests), `android` (Debug-APK, signiert wird nur am PC), `ios` (Gerätebuild ohne Signatur, Integrationstests und XCTest auf dem Simulator, `Podfile.lock` als Artefakt). `ios` läuft auf `main`, manuell und auf Branches `ci/*` (nur der Projektinhaber kann sie pushen; nötig, damit Pipeline-Änderungen vor `main` auf macOS laufen).
  - `ios-release.yml`: ein Job in `release`, temporärer Schlüsselbund, p12 und Profil aus den Environment-Secrets, Team und Profilname aus dem Profil, `flutter build ipa` mit manueller Signierung, Upload mit `xcrun altool` über den API-Schlüssel, Aufräumen mit `if: always()`. Build-Nummer = `git rev-list --count HEAD`, der Git-SHA geht als `GIT_SHA` per `--dart-define` in die App (E5).
  - Actions per Commit-SHA (Lizenzen am 2026-11-20 geprüft, gebündelte Abhängigkeiten laut `.licenses`): `actions/checkout` v7.0.1 `3d3c42e` (MIT; gebündelt MIT, ISC, Apache-2.0), `actions/upload-artifact` v7.0.2 `cf430e0` (MIT; gebündelt MIT, BlueOak-1.0.0). gitleaks 8.30.1 (MIT) als Programmdatei. Kein fastlane, kein Ruby, kein `actions/cache` (Cache-Poisoning im Release-Job).
- [x] `ios/Podfile` (iOS 15.0, nur `PERMISSION_BLUETOOTH=1`, CocoaPods-Statistik aus), Pods-Includes in `Debug.xcconfig`/`Release.xcconfig`, manuelle Signierung für Release über `DIVEDOWN_TEAM_ID`/`DIVEDOWN_PROFILE_NAME` → T20.7 (Podfile), T20.8 grün.
- [x] `Info.plist`: importierter Typ `com.garmin.fit` (Endung `fit`), Dokumenttyp „FIT-Datei“ (`Viewer`, `Alternate`), `LSSupportsOpeningDocumentsInPlace` = false, `ITSAppUsesNonExemptEncryption` = false → T20.3–T20.6 grün.
- [x] Swift: `SharedFileInbox.acceptedPath`, `SharedFileReceiver` (über `registrar.addSceneDelegate`, also ohne Eingriff in den `FlutterSceneDelegate`), `isExcludedFromBackup` im Backup-Kanal → T20.9–T20.12, **erst in der CI geprüft**.
- Gesamt am PC: `flutter test` 301/302 (rot: T20.7 `Podfile.lock`, entsteht beim ersten `pod install` in der CI), `flutter analyze` ohne Befund, Debug-APK baut.
- Ungeprüft ohne Mac: ob Swift und das Podfile bauen, ob `com.garmin.fit` die Dateien aus der Suunto-App trifft, ob ein Kaltstart über „Öffnen in“ die Datei an `SharedFileReceiver` liefert (Scene-Verbindung vor der Plugin-Registrierung), ob `altool --upload-app` mit Xcode 26 noch hochlädt.
- **Erste CI-Läufe auf macOS (2026-11-20/21, Branch `ci/ios-pipeline`):** Gerätebuild ohne Signatur grün (Xcode 26.3, iOS SDK 26.2), Swift, Podfile und libdivecomputer kompilieren. `Podfile.lock` aus der CI übernommen → T20.7 grün. CocoaPods verwaltet nur Flutter und das Plugin, alle anderen Plugins baut Flutter über Swift Package Manager, ohne entfernte Pakete. Folge: Die Makros von `permission_handler` kommen nicht aus dem Podfile, sondern aus `Info.plist` (Bluetooth); Benachrichtigungen schaltet die CI per `PERMISSION_NOTIFICATIONS=0` ab, ein eigener Schritt prüft, dass nur `PERMISSION_BLUETOOTH` an ist.
- **CI-Lauf 44950959040 (2026-11-21, `8ff8204`) komplett grün:** Integrationstests auf dem iOS-Simulator (iPhone 17 Pro): T4.5 9/9 (alle drei EON-Core-Tauchgänge durch libdivecomputer, für iOS gebaut), T20.12 grün (Swift-Seite von T11.9). XCTest T20.9–T20.11 grün. Makros von `permission_handler`: nur `PERMISSION_BLUETOOTH=1`, alle anderen 0. Vorbehalte: (1) Der Hänger der Läufe 1–3 (App gestartet, keine Testausgabe) trat nicht mehr auf, die Ursache ist nicht geklärt; möglicherweise wackelig. (2) T20.9 und T20.12 wurden in der CI nie rot gesehen, weil die Umsetzung vor dem ersten erfolgreichen macOS-Lauf kam; der Stub hätte `nil` geliefert bzw. `isExcludedFromBackup` gefehlt.

## T21: Stil „Riff“, Logbuch und Detail (ui-spec §1, §5.2, §5.3, Änderung 2026-11-22)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T21.1 | helles Theme | gebaut | Riff-Tokens: `surface` `#F2F8F8`, `primary` `#0B7A80`, `accent` `#B9412A`, `temperature` `#A35C00` usw. (neu: `surfaceTint`, `outline`, `accent`, `ndl`) | ✅ 2026-11-22: rot, alte Farben („Tiefe“) |
| T21.2 | dunkles Theme | gebaut | Riff-Tokens dunkel (`surface` `#0D1E22`, `primary` `#4CC9CE` …) | ✅ 2026-11-22: rot, alte Farben |
| T21.3 | Theme, `pubspec.yaml`, `assets/fonts/` | geprüft | alle Textstile in **Manrope**; TTF-Dateien und `OFL.txt` liegen bei, Eintrag in `THIRD_PARTY.md` | ✅ 2026-11-22: rot, Systemschrift, kein Ordner `assets/fonts` |
| T21.4 | Karten-Theme | gebaut | 20 dp Ecken, Rand `outline`, keine Erhebung | ✅ 2026-11-22: rot, 12 dp ohne Rand |
| T21.5 | Summe der Dauer 0 / 40 min / 7 h 40 min / 9 h 59 min 40 s / 61 h 29 min / 61 h 31 min | `UnitFormatter.underwater` | „0 min“, „40 min“, „7 h 40 min“, „10 h“, „61 h“, „62 h“ | ✅ 2026-11-22: rot wegen `UnimplementedError` (`underwater`) |
| T21.6 | Anna mit 3 Tauchgängen à 47 min | Logbuch | Avatar „A“ (vorgelesen „Taucher Anna“), Kacheln „Tauchgänge 3“ und „unter Wasser 2 h 21 min“, nichts mit „tiefst…“ | ✅ 2026-11-22: rot, Kopf fehlt (kein „A“) |
| T21.7 | 2 Tauchgänge | Logbuch | je eine Karte mit Sparkline (`ValueKey('sparkline')`), Zeile „14.11.2026 · 10:42 · 47 min“ | ✅ 2026-11-22: rot, keine Sparkline |
| T21.8 | Logbuch | angezeigt | FAB „Manuell eintragen“ in `accent` | ✅ 2026-11-22: rot, FAB ohne eigene Farbe (`primary`) |
| T21.9 | alle libdivecomputer-Ereignistypen | `eventLabel`, `isWarningEvent` | deutscher Text für jeden Typ (`deepstop` → „Tiefenstopp“ …), unbekannt „Ereignis (xyz)“; Warnungen markiert | ✅ 2026-11-22: rot, „deepstop“ unübersetzt bzw. `UnimplementedError` (`isWarningEvent`) |
| T21.10 | 9 Ereignisse, teils innerhalb 60 s | `groupEvents` | 5 Gruppen mit Anzahl, Abstand > 60 s beginnt neue Gruppe | ✅ 2026-11-22: rot wegen `UnimplementedError` (`groupEvents`) |
| T21.11 | Tauchgang verweist auf Suunto EON Core mit Adresse `…:3F:7A` | Detail | Quelle „Suunto EON Core ••3F7A“ | ✅ 2026-11-22: rot, steht nur „Tauchcomputer“ |
| T21.12 | Beispiel #42 (200 → 50 bar, 12 l, ohne Druck-Samples) bzw. mit Druck-Samples | Detail | Kachel „Flasche“ mit „12 l“ und „200 → 50 bar“; Ø-SAC „19,1 l/min“ mit „geschätzt aus 200 → 50 bar“ bzw. „gemessen“ | ✅ 2026-11-22: rot, Kachel „Flasche“ und Herkunft fehlen |
| T21.13 | Ereignisse 2× `deepstop`, 3× `safetystop` | Detail | „Tiefenstopp“ „2×“, „Sicherheitsstopp“ „3×“, Zeit „22:19“, kein „deepstop“ | ✅ 2026-11-22: rot, „deepstop“ wird angezeigt |
| T21.14 | Tauchgang mit 11 Samples und einer ohne | `listForDiver` | Liste trägt Zeit und Tiefe der Samples für die Sparkline, der manuelle bleibt leer | ✅ 2026-11-22: rot (`Bad state: No element`), die Liste lud keine Samples. Gefunden auf dem Handy: alle Sparklines waren Schätz-Rechtecke |

Abgenommen am 2026-11-22. Tests: `test/app/theme_test.dart` (T21.1–T21.4, angepasst), `test/domain/units/unit_formatter_test.dart` (T21.5), `test/features/logbook/riff_screens_test.dart` (T21.6–T21.8, T21.11–T21.13), `test/features/logbook/dive_texts_test.dart` (T21.9, T21.10).
Stubs: `DiveColors` hat die neuen Tokens mit Platzhalterwerten, `UnitFormatter.underwater`, `groupEvents`, `isWarningEvent`.

## T22: Profil zum Antippen und Luft zum Zeitpunkt (ui-spec §6, Wunsch vom 2026-11-22)
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T22.1 | 60 min konstant 10 m, 200 → 50 bar, 12 l, ohne Druck-Samples | `AirProfile.at` | geschätzt; Start 200 bar/0 l, Hälfte ≈ 125 bar/900 l, Ende 50 bar/1.800 l | ✅ 2026-11-22: rot wegen `UnimplementedError` (`AirProfile.at`) |
| T22.2 | 30 min auf 20 m, 30 min auf 5 m | `at(30 min)` | verbraucht ≈ 1.800 × 3,01 / 4,5125 l (Zeit × Umgebungsdruck, Salzwasser wie `SacCalculator`) | ✅ 2026-11-22: rot, wie T22.1 |
| T22.3 | wie T22.2; Zeit vor 0 bzw. nach Ende | `at` | „Luft jetzt“ = Ø-SAC × Umgebungsdruck; Zeiten außerhalb werden auf Start/Ende begrenzt | ✅ 2026-11-22: rot, wie T22.1 |
| T22.4 | Druck-Samples 200 − 2,5 bar/min | `at(20 min)` | gemessen: 150 bar, 600 l, „Luft jetzt“ 30 l/min | ✅ 2026-11-22: rot, wie T22.1 |
| T22.5 | Druck-Samples ab 210 bar, Flasche sagt 200 | `at(0)` | Samples gewinnen (210 bar, gemessen) | ✅ 2026-11-22: rot, wie T22.1 |
| T22.6 | kein Druck / keine Flasche / kein Volumen / keine Samples | `at` | `AirMissing.pressure` bzw. `.volume` | ✅ 2026-11-22: rot, wie T22.1 |
| T22.7 | Beispiel #42 (Minuten-Samples) | Detail geöffnet | Werte-Feld (`profile-values`) steht beim tiefsten Sample: „23:00“, „18,0 m“ | ✅ 2026-11-22: rot, Werte-Feld fehlt |
| T22.8 | Beispiel #42 | Tippen bei 25 % bzw. 100 %, Ziehen 25 → 75 % auf `profile-plot` | nächstes Sample: „12:00“, „9,4 m“, „Umgebung 1,9 bar“; „47:00“; „35:00“, „10,0 m“ | ✅ 2026-11-22: rot, wie T22.7 |
| T22.9 | Beispiel #42 ohne Druck-Samples | Tippen bei 100 % | „Noch in der Flasche ca. 50 bar“, „Bisher verbraucht ca. 1.800 l“, Schätz-Zeile, „Luft jetzt“, Hinweis „… Luft ist geschätzt …“ | ✅ 2026-11-22: rot, wie T22.7 |
| T22.10 | mit Druck-Samples | Tippen bei 100 % | „50 bar“ ohne „ca.“, kein „geschätzt“; Chips „Luft“ und „SAC“ | ✅ 2026-11-22: rot, wie T22.7 |
| T22.11 | ohne Druck-Samples | Detail | Chips „Temperatur“, „Luft (geschätzt)“, „NDL“, kein „SAC“; Tippen schaltet um | ✅ 2026-11-22: rot, keine Chips |
| T22.12 | ohne Druck bzw. ohne Volumen | Detail | Link „Start- und Enddruck eintragen“ öffnet Bearbeiten bzw. „Flaschengröße eintragen“ | ✅ 2026-11-22: rot, wie T22.7 |
| T22.13 | Beispiel #42 | Bildschirmleser, „Als Tabelle anzeigen“ | Label „Tiefenprofil: max. 18,4 m nach 23 min, Dauer 47 min“; Tabelle mit „0:00“ … „47:00“ | ✅ 2026-11-22: rot, Label und Link fehlen |

Tests: `test/domain/metrics/air_profile_test.dart` (T22.1–T22.6), `test/features/logbook/profile_chart_test.dart` (T22.7–T22.13). Stub: `lib/domain/metrics/air_profile.dart`.
Vertrag für die Oberfläche: Zeichenfläche `ValueKey('profile-plot')` bildet 0 … Dauer auf ihre volle Breite ab, Tippen springt zum nächsten Sample; Werte-Feld `ValueKey('profile-values')`.
Nicht in diesem Paket: Vollbild mit Zoom, Merken der Chips über App-Starts, Ereignis-Tooltips im Diagramm, Taucher-Wechsel über den Avatar (kommt mit den Einstellungen).
Diagramm ohne neue Abhängigkeit: Der bestehende `CustomPainter` wird ausgebaut, statt `fl_chart` einzubinden (ADR 0005 nannte es). So lässt sich das Antippen genau testen, und es gibt keine weitere Lizenz.

**Umgesetzt (Phase 50, 2026-11-22), T21, T22:**
- [x] Theme „Riff“ (`lib/app/theme.dart`): Tokens hell/dunkel, `DiveColors` um `surfaceTint`, `outline`, `accent`, `ndl` erweitert, Karten mit 20 dp und Rand, FAB in `accent`. Schrift Manrope (Medium, SemiBold, Bold, ExtraBold) aus `googlefonts/manrope` Commit `468c0db`, OFL-1.1 in `assets/fonts/OFL.txt`, in `THIRD_PARTY.md` und auf der Lizenzseite → T21.1–T21.4 grün.
- [x] `UnitFormatter.underwater`, `groupEvents`, `isWarningEvent`, deutsche Texte für alle 25 Ereignistypen, `ambientPressureBar` (gemeinsam mit `SacCalculator`), `AirProfile` (gemessen aus Samples, sonst nach Zeit × Umgebungsdruck verteilt) → T21.5, T21.9, T21.10, T22.1–T22.6 grün.
- [x] Logbuch: Avatar, Kacheln „Tauchgänge“ und „unter Wasser“, Karten mit `DiveSparkline`, Datum · Uhrzeit · Dauer. Bei großer Schrift steht die Tiefe unter dem Text → T21.6–T21.8 grün.
- [x] Detail: Kopf mit Verlauf und „Suunto EON Core ••3F7A“ (`DiveComputerRepository.findById`, `computerLabel`), Kennzahlen 3-spaltig mit Kachel „Flasche“ und Ø-SAC über die volle Breite („gemessen“ bzw. „geschätzt aus …“), Ereignisse gruppiert. `ProfileChart` (eigener `CustomPainter`, kein `fl_chart`): Chips, Tippen und Ziehen, Werte-Feld, Hinweis, Minutentabelle, höchstens zwei rechte Achsen → T21.11–T21.13, T22.7–T22.13 grün.
- Testaufbau korrigiert, Aussage unverändert: T21.3 (Pfadvergleich war fehlerhaft), T15.2/T15.3 (Zeile jetzt „14.11.2026 · 10:42 · 47 min“, weil der Kopf ebenfalls „47 min“ zeigt), T15.7 (Link liegt seit T22.12 im Werte-Feld, der Test scrollt hin). Die Monatsüberschrift bleibt in normaler Schreibweise (ui-spec §5.2 angepasst).
- Gesamt: `flutter test` 337/337, `flutter analyze` ohne Befund, Debug-APK baut.
- **Auf dem S25 Ultra geprüft, 2026-11-22:** Riff-Farben und Manrope, Kopf „73 Tauchgänge · 52 h unter Wasser“, Karten mit Mini-Profil, Detail #71 mit „Suunto EON Core ••CC2D“, Diagramm mit Temperatur, Werte-Feld beim tiefsten Punkt (6:00, 24,0 m, 29,2 °C, NDL 16 min, 3,4 bar), ohne Druck der Link „Start- und Enddruck eintragen“.
- Gefunden auf dem Handy und behoben: Sparklines zeigten nur das Schätz-Rechteck (T21.14, `listForDiver` lädt jetzt Zeit und Tiefe), die Ø-SAC-Kachel war nur so breit wie ihr Inhalt, der Chip „Luft (geschätzt)“ erschien auch ohne jeden Druck (jetzt ausgeblendet), „0 min“ berührte die Tiefenbeschriftung. `flutter test` 338/338.

## T23: Einstellungen, ein Taucher pro App (ui-spec §2, §5.11, Änderung 2026-11-22b)
Entscheidungen vom 2026-11-22: **ein Taucher pro App** (kein Wechsel, kein Anlegen/Löschen weiterer Taucher, Roadmap Punkt 6 entfällt) · Importe vergeben die nächste freie Nummer, **„Nummern nach Datum neu vergeben“ nur auf Wunsch** · eine neue Startnummer **verschiebt alle Nummern** mit · **Einheiten** erst später (nur metrisch) · Links über **`url_launcher`**.
| ID | A | W | D | Rot gesehen |
|---|---|---|---|---|
| T23.1 | Taucher Anna, Startnummer 5 | `DiverRepository.update` mit Name Lena | Name Lena, Startnummer bleibt 5 | ✅ 2026-11-22: rot wegen `UnimplementedError` (`update`) |
| T23.2 | #1 (März), #2 (Mai) | `shiftNumbers(+100)`, Startnummer 101 | #101, #102; nächste Nummer 103 | ✅ 2026-11-22: rot wegen `UnimplementedError` (`shiftNumbers`) |
| T23.3 | #1, #2 (November), #3 (März); gelöschter Tauchgang; keine Tauchgänge | `renumberByDate(start: 1)`, `numbersFollowDates` | März #1, Nov #2, #3; Anzahl 3; gelöschte zählen nicht und stören nicht; leer = 0 und „in Ordnung“ | ✅ 2026-11-22: rot wegen `UnimplementedError` |
| T23.4 | frische DB | `themeMode`, `setThemeMode(dark)` | System als Vorgabe, dunkel gemerkt | ✅ 2026-11-22: rot wegen `UnimplementedError` |
| T23.5 | EON Core mit einem Tauchgang | `listAll`, `forget` | gelistet; danach weg (auch per Adresse), der Tauchgang bleibt | ✅ 2026-11-22: rot wegen `UnimplementedError` (`listAll`) |
| T23.6 | Einstellungen | angezeigt | Abschnitte TAUCHER, GERÄTE, DARSTELLUNG, ÜBER DIVEDOWN; nichts zu Einheiten, Sichern oder Taucher hinzufügen | ✅ 2026-11-22: rot, nur „Open-Source-Lizenzen“ vorhanden |
| T23.7 | Taucher Anna | Name antippen, „Lena“ bzw. Leerzeichen | gespeichert und angezeigt bzw. „Bitte gib einen Namen ein.“ und „Speichern“ gesperrt | ✅ 2026-11-22: rot, kein Eintrag „Anna“ |
| T23.8 | ohne bzw. mit #1, #2 | „Nummerierung beginnt bei“ → 101 | ohne Tauchgänge sofort, nächste Nummer 101; mit: „Nummern verschieben? Aus #1–#2 werden #101–#102.“ → „Verschieben“ ergibt #101, #102; „Abbrechen“ ändert nichts | ✅ 2026-11-22: rot, Eintrag fehlt |
| T23.9 | #1 November, #2 März bzw. schon in Reihenfolge | „Nummern nach Datum neu vergeben“ | Rückfrage „… Der älteste bekommt #1.“ → März #1, Nov #2, Snackbar „2 Tauchgänge neu nummeriert“, Eintrag verschwindet; in Reihenfolge gar nicht sichtbar | ✅ 2026-11-22: rot, Eintrag fehlt |
| T23.10 | EON Core mit Tauchgang vom 13.11. bzw. ohne | Geräte | „Suunto EON Core ••3F7A“, „Zuletzt: 13.11.2026“; „EON Core vergessen“ → Rückfrage → „Noch kein Tauchcomputer verbunden.“, Tauchgang bleibt; ohne Tauchgang „Noch keine Tauchgänge“ | ✅ 2026-11-22: rot, Abschnitt fehlt |
| T23.11 | Darstellung | „Dunkel“, dann „Hell“ | `MaterialApp.themeMode` dunkel bzw. hell, gemerkt | ✅ 2026-11-22: rot, Segmentknopf fehlt |
| T23.12 | App-Info 1.0.0, Build 42, libdivecomputer 0.9.0 | Über DiveDown | „Version 1.0.0 (Build 42)“, „libdivecomputer 0.9.0“, „Lizenz: GPL-3.0-or-later“, „Open-Source-Lizenzen“; „Datenschutzerklärung“ und „Quellcode“ öffnen die beiden Adressen | ✅ 2026-11-22: rot, Einträge fehlen |
| T23.13 | Logbuch bzw. Import | angezeigt | kein Avatar, kein „Importieren für: …“ (ein Taucher pro App) | ✅ 2026-11-22: rot, Avatar „A“ bzw. „Importieren für: Anna“ noch da (angepasst in T21.6, T12.10, T12.16, T12.31) |

Abgenommen am 2026-11-22. Tests: `test/data/local/settings_data_test.dart` (T23.1–T23.5), `test/features/settings/settings_test.dart` (T23.6–T23.12), T23.13 in den bestehenden Tests. Stubs: `DiverRepository.update`, `DiveNumbering` (`shiftNumbers`, `renumberByDate`, `numbersFollowDates`), `AppSettings.themeMode`/`setThemeMode`, `DiveComputerRepository.listAll`/`forget`, `appInfoProvider`, `urlOpenerProvider`.
Neue Abhängigkeiten (Lizenzen am 2026-11-22 an den eingesetzten Versionen geprüft): `url_launcher` 6.3.3 (BSD-3, ebenso `url_launcher_android` 6.3.35, `_ios` 6.4.2, `_platform_interface` 2.3.2 und die Desktop/Web-Pakete), `package_info_plus` 10.2.2 (BSD-3, `package_info_plus_platform_interface` 4.1.0 BSD-3, `http` 1.6.0 BSD-3; `web`, `win32`, `ffi` BSD-3 und `clock` Apache-2.0 waren schon da).

**Umgesetzt (Phase 50, 2026-11-22), T23:**
- [x] Daten: `DiverRepository.update`, `DiveNumbering` in `DriftDiveRepository` (`shiftNumbers` per SQL-Update, `renumberByDate` in einer Transaktion, `numbersFollowDates`), `AppSettings.themeMode` (Schlüssel `theme_mode` in `app_meta`), `DiveComputerRepository.listAll`/`forget` (Soft Delete) → T23.1–T23.5 grün.
- [x] Provider: `appInfoProvider` (`package_info_plus` und `getLibdivecomputerVersion`), `urlOpenerProvider` (`url_launcher`, externer Browser), `themeModeProvider` (wirkt auf `MaterialApp.themeMode`), `knownComputersProvider` (letzter Tauchgang je Gerät), `numbersFollowDatesProvider`.
- [x] `SettingsScreen` neu: Abschnitte TAUCHER (Name, Startnummer mit Rückfrage und Verschieben, Neu-Nummerieren nur wenn nötig), GERÄTE (mit „Vergessen“), DARSTELLUNG (Segmentknopf), ÜBER DIVEDOWN (Version, libdivecomputer, Lizenz, Open-Source-Lizenzen, Datenschutzerklärung, Quellcode) → T23.6–T23.12 grün.
- [x] Avatar im Logbuch und „Importieren für“ in Quellenwahl und Vorschau entfernt, Texte `importFor`/`diverAvatarSpoken` gelöscht → T23.13 grün.
- Gesamt: `flutter test` 357/357, `flutter analyze` ohne Befund, Debug-APK baut.
- **Auf dem S25 Ultra geprüft, 2026-11-22:** Abschnitte wie in §5.11; Name „Test“, Startnummer 1, „Nummern nach Datum neu vergeben“ wird angeboten (März-Tauchgang #72); „Suunto EON Core ••CC2D · Zuletzt: 13.11.2026“; „Version 1.0.0 (Build 1)“, „libdivecomputer 0.10.0“. „Datenschutzerklärung“ öffnet Chrome, „Zurück“ führt in die App zurück; dafür ist kein `<queries>`-Eintrag nötig. `url_launcher` und `package_info_plus` bringen keine Berechtigungen mit (INTERNET steht nur im Debug-Manifest der Flutter-Vorlage).

**Umgesetzt (Phase 50, 2026-11-22), T11.1–T11.8, T11.11–T11.15:**
- [x] `LogbookBackup`: `create` per `VACUUM INTO` (konsistente Kopie, auch mit WAL) plus Manifest, `inspect` liest nur die zwei bekannten Einträge in den Speicher (keine Pfade, Größe vor dem Entpacken), prüft Format, SHA-256, SQLite-Kopf und `AppDatabase.latestSchemaVersion`; `restore` schließt die DB, legt `before-restore.sqlite` neben die DB, entfernt `-wal`/`-shm`/`-journal` und spielt bei einem Fehler die Kopie zurück. `backupReminderDue` → T11.1–T11.8 grün.
- [x] Einstellungen speichern `last_backup_at`, `backup_baseline` (beim ersten Abruf gesetzt) und `backup_snoozed_until` in `app_meta`. `AppBackupActions` (Ordner `<support>/db/`, App-Version aus `package_info_plus`, Dateiname `DiveDown-Sicherung-JJJJ-MM-TT.divedown`), Teilen über `share_plus` aus `<cache>/share/` (Datei danach gelöscht), Dateiwahl mit 200-MB-Grenze (`SystemFilePicker(maxBytes:)`).
- [x] Oberfläche: Abschnitt DATEN, `showCreateBackup` und `runRestore` (Zusammenfassung, Rückfrage, Fehlertexte aus §5.12), Erinnerungskarte im Logbuch mit „Jetzt sichern“ und ✕ → T11.11–T11.15 grün.
- [x] Nach dem Wiederherstellen öffnet `AppStartupGate` die Datenbank neu (`restartAppProvider`, neuer `ProviderScope`), damit keine alten Daten in Providern hängen bleiben.
- Testaufbau korrigiert, Aussage unverändert: T9.20 scrollt zu „Open-Source-Lizenzen“ (liegt jetzt unter DATEN).
- Gesamt: `flutter test` 380/380, `flutter analyze` ohne Befund, Debug-APK baut.
- **Am S25 Ultra, 2026-11-22:** Abschnitt DATEN, Dialog „Logbuch sichern“ mit Hinweis und Warnung, Teilen-Dialog zeigt „DiveDown-Sicherung-2026-11-22.divedown“ (ohne Ziel geschlossen). Dabei T11.16 gefunden und behoben. `flutter test` 383/383.
- **Vom Nutzer am S25 Ultra geprüft, 2026-11-23:** Sicherung erstellt und geteilt, mit derselben Datei wiederhergestellt; die App startete neu und zeigte das vollständige Logbuch.

**Umgesetzt (Phase 50, 2026-11-23), T10, T14.1, T14.2:**
- [x] `sanitizeLogEntry`/`sanitizeLogText` (Positivliste der Kategorien, MAC, Seriennummer, Koordinaten auch als Paar, E-Mail, Benutzerpfade; HEXDUMP und fremde BLE-Geräte nur im Release verworfen), `FileDiagnosticLog` (eine Zeile pro Eintrag, Schreiben nacheinander, über 5 MB auf drei Viertel gekürzt, `prune` nach 7 Tagen, Export mit Kopf), `connectPluginLogs`, `recordError` (Stack auf 20 Zeilen, Pfade gefiltert) → T10.1–T10.12 grün.
- [x] App: Log in `<cache>/logs/diagnostic.log`, `main` öffnet es, kürzt es und hängt `FlutterError.onError` und `PlatformDispatcher.onError` an; `AppStartupGate` reicht es an `diagnosticLogProvider`; das Plugin schreibt über `connectPluginLogs` hinein; Sichern und Wiederherstellen schreiben Ergebnisse und Fehler. Kopf aus `package_info_plus`, `device_info_plus` (Hersteller und Modell, unter iOS `modelName`, nie der vom Nutzer vergebene Gerätename) und libdivecomputer.
- [x] Oberfläche: `DiagnosticsScreen` (`/diagnostics` über dem Tab-Gerüst) mit Info, Vorschau in eigenem Scrollbereich, „… N weitere Zeilen“, „Teilen“ (Datei `DiveDown-Diagnose-JJJJ-MM-TT.txt`), „Am besten per Mail.“; Einstellungen → HILFE; „Logs an Entwickler senden“ auf der Fehlerkarte des Tauchcomputer-Imports und bei „Wiederherstellen fehlgeschlagen“ → T10.13, T10.14 grün.
- [x] Plugin: `NativeLogger` schreibt nur in debuggable Builds nach logcat (Flag aus `ApplicationInfo` beim Anhängen, JUnit `NativeLoggerTest`) → T14.2 grün. libdivecomputer im Release (`NDEBUG`: Android RelWithDebInfo/Release, iOS Release/Profile über die Podspec) nur ab `WARNING` → T14.1 (ohne eigenen Test).
- Testaufbau korrigiert, Aussage unverändert: T9.20 scrollt mit `scrollUntilVisible` zu „Open-Source-Lizenzen“ (liegt jetzt unter DATEN und HILFE).
- Gesamt: `flutter test` 401/401, Plugin-JUnit 150/150, `flutter analyze` ohne Befund, Debug-APK baut.
- Noch offen: T14.3 (Zugangscodes in den sicheren Speicher), T14.4 (Manifest-Prüfung in der CI); die Swift-Seite des Plugins loggt weiter über `print`/`os_log` (nur in Xcode-Konsole sichtbar, nicht für andere Apps).
- **Am S25 Ultra geprüft, 2026-11-23:** HILFE → „Diagnose-Logs teilen“ zeigt die Einträge („App gestartet“), „Teilen“ bietet `DiveDown-Diagnose-2026-11-23.txt` an (ohne Ziel geschlossen). Gefunden und behoben: Zeilen waren abgeschnitten (jetzt Umbruch), der Kasten war auch bei einer Zeile 320 dp hoch (jetzt höchstens 320 dp), die Textdatei lief als ZIP (T10.15).

**Umgesetzt (Phase 50, 2026-11-23), T14.3, T14.4:**
- [x] `AccessCodeStore` (Plugin, Kotlin): AES-256-GCM, Schlüssel im Android Keystore, Werte in `ble_access_codes_v2`; alte Base64-Werte aus `ble_access_codes` werden beim ersten Lesen übernommen und gelöscht; unlesbare Werte verworfen. `BleIoStream.get/setAccessCode` nutzen ihn → JUnit `AccessCodeStoreTest` grün (Plugin-JUnit 154/154).
- [x] Beide Dateien aus `data_extraction_rules.xml` (Cloud-Backup, Geräte-Transfer) und `backup_rules.xml` ausgeschlossen → T14.3b grün.
- [x] iOS (`darwin/.../BleIoStream.swift`): Keychain, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, alte `UserDefaults`-Werte einmal übernommen. **Nicht testbar ohne Mac**, kompiliert erst im CI-Build.
- [x] `checkAndroidManifest` und `tool/check_android_manifest.dart`; Schritt „Check the release manifest“ im CI-Job `android` (`processReleaseMainManifest`, kein Release-Build, keine Signatur) → T14.4 grün. Am PC gegen das echte Release-Manifest geprüft: OK.
- Gesamt: `flutter test` 409/409, `flutter analyze` ohne Befund, Debug-APK startet auf dem S25 ohne Fehler. Die Übernahme alter Zugangscodes ließ sich am Handy nicht prüfen: der EON Core braucht keine PIN, es gab keinen gespeicherten Code.

## T24: App-Icon in den Riff-Farben (ui-spec §1, Feinschliff 2026-11-23)

| Nr. | Ausgangslage | Aktion | Erwartet | Status |
|---|---|---|---|---|
| T24.1 | Vorlagen in `assets/icon/` | gelesen | alle drei SVGs mit Kurve `#0B7A80`, keine alten Farben (`#0B1620`, `#3FA3E0`, `#5CB8E8`, `#2A3B4A`); Hauptvorlage mit Hintergrund `#F2F8F8` und Blase `#B9412A` | ✅ 2026-11-23: rot, Vorlagen noch in den alten Farben |
| T24.2 | Android 8+ (minSdk 26) | `mipmap-anydpi-v26/ic_launcher.xml` | adaptives Icon: Hintergrund `@color/ic_launcher_background` (`#F2F8F8`), Vordergrund als Vektor mit Kurve `#0B7A80` und Blase `#B9412A`, einfarbige Ebene für Android 13+ | ✅ 2026-11-23: rot, Dateien fehlen |
| T24.3 | alte Launcher | `mipmap-*dpi/ic_launcher.png` | 48/72/96/144/192 px, Hintergrund `#F2F8F8` | ✅ 2026-11-23: rot, noch das Flutter-Standard-Icon (transparent) |
| T24.4 | iOS `AppIcon.appiconset` | jede Größe aus `Contents.json` | Pixelgröße = Punkte × Faktor, RGB ohne Alphakanal (App Store lehnt Alpha im 1024er ab), Hintergrund `#F2F8F8` | ✅ 2026-11-23: rot, noch Flutter-Standard (Palette-PNG) |

Test: `test/app/app_icon_test.dart`. Keine neue Abhängigkeit: statt `flutter_launcher_icons` zeichnet `tool/render_app_icons.py` (Pillow, nur auf dem PC) die PNGs aus denselben Formen wie die SVG-Vorlagen; die Ergebnisse werden eingecheckt.

Abgenommen am 2026-11-23.

**Umgesetzt (Phase 50, 2026-11-23), T24:**
- [x] SVG-Vorlagen in Riff-Farben (Kurve `#0B7A80`, Blasen `#B9412A`, Hintergrund `#F2F8F8`, Fläche als Verlauf in `primary`) → T24.1 grün.
- [x] Adaptives Android-Icon: `mipmap-anydpi-v26/ic_launcher.xml`, Hintergrund `@color/ic_launcher_background`, Vordergrund und einfarbige Ebene als Vektor → T24.2 grün.
- [x] `tool/render_app_icons.py` zeichnet die alten Launcher-PNGs und alle 19 iOS-Größen (RGB ohne Alpha, unter 60 px die vereinfachte Variante) → T24.3, T24.4 grün.
- Gesamt: `flutter test` 414/414, `flutter analyze` ohne Befund, Debug-APK baut.
- **Auf dem S25 Ultra geprüft, 2026-11-23:** Icon im App-Menü hell mit Petrol-Kurve, Verlauf und Korallen-Blasen, nichts von der Samsung-Maske abgeschnitten. Themen-Icons (einfarbige Ebene) nicht eigens eingeschaltet.

## T25: Tauchplatz für Ausgewählte (ui-spec §5.9, Feinschliff 2026-11-23)

| Nr. | Ausgangslage | Aktion | Erwartet | Status |
|---|---|---|---|---|
| T25.1 | importierter Tauchgang, ggf. mit GPS vom Gerät | `withSite(Elphinstone)`, `withSite(Hausriff ohne Position)`, `withSite(null)` | Name, Katalog-Kennung und Position übernommen, `toDive` trägt sie weiter; ohne Position bleibt das GPS des Geräts; `null` entfernt Name und Kennung, GPS bleibt | ✅ 2026-11-23: rot wegen `UnimplementedError` (`withSite`) |
| T25.2 | Vorschlag eigener Platz / Katalog / neuer Name; getippter Text | `ChosenSite.fromSuggestion`, `ChosenSite.typed` | Kennung und Position aus eigenem bzw. Katalog-Platz, neuer Name ohne; Text getrimmt, leer = kein Platz, höchstens 120 Zeichen | ✅ 2026-11-23: rot wegen `UnimplementedError` |
| T25.3 | Import mit Tauchplatz; geänderter Tauchgang (gleiche Kennung) bestätigt | `importDives` | neuer Tauchgang mit Platz gespeichert; beim Ersetzen füllt der Platz nur einen leeren Platz, ein vorhandener bleibt | ✅ 2026-11-23: rot wegen `UnimplementedError` (`withSite`) |
| T25.4 | Vorschau mit 3 Tauchgängen, der erste abgewählt | „Tauchplatz für Ausgewählte setzen“ → „Hausriff“ → „Übernehmen“, dann alle importieren | Blatt „Tauchplatz für 2 Tauchgänge“; „Hausriff“ an den beiden Einträgen; im Logbuch nur diese beiden mit „Hausriff“ | ✅ 2026-11-23: rot, Aktion fehlt |
| T25.5 | Vorschau mit 3 Tauchgängen | leer bzw. nur Leerzeichen; „Tauchplatz entfernen“; alles abgewählt | „Übernehmen“ gesperrt; „Tauchplatz entfernen“ erst, wenn ein Ausgewählter einen Platz hat, danach kein Platz mehr; ohne Auswahl ist die Aktion gesperrt | ✅ 2026-11-23: rot, Aktion fehlt |

Tests: `test/domain/import/import_site_test.dart` (T25.1, T25.2), `import_service_test.dart` (T25.3), `test/features/import/dive_computer_screen_test.dart` (T25.4, T25.5; die FIT-Vorschau ist dasselbe Widget). Stubs: `ChosenSite.fromSuggestion`/`typed`, `ImportedDive.withSite`. `SaveSelected` reicht jetzt die Tauchgänge mit den gesetzten Plätzen an beide Import-Seiten weiter.

Abgenommen am 2026-11-23.

**Umgesetzt (Phase 50, 2026-11-23), T25:**
- [x] `ChosenSite` (`fromSuggestion`, `typed`) in `domain/sites/site_suggestions.dart` → T25.2 grün.
- [x] `ImportedDive.site` mit `withSite`; die Geräteposition wird getrennt gehalten, sodass „Tauchplatz entfernen“ sie zurückbringt; `toDive` und `copyWith` tragen den Platz weiter → T25.1 grün.
- [x] `ImportService`: beim Ersetzen füllt der Platz aus der Vorschau nur einen leeren → T25.3 grün.
- [x] Vorschau: Aktion unter der Liste, Blatt mit `SiteField`, „Übernehmen“, „Tauchplatz entfernen“, Platz mit Ort-Icon am Eintrag; `SaveSelected` reicht die Tauchgänge mit Platz an Tauchcomputer- und FIT-Seite → T25.4, T25.5 grün.
- Gesamt: `flutter test` 424/424, `flutter analyze` ohne Befund, Debug-APK baut.
- **Auf dem S25 Ultra geprüft, 2026-11-23:** Nutzer erlaubte, #72 (FIT-Testdatei, 26.03.) zu löschen und neu zu importieren. Bereits vorhandener Tauchgang → Aktion gesperrt. Nach dem Löschen: Blatt „Tauchplatz für 1 Tauchgang“, Katalog-Vorschlag „Elphinstone · Red Sea, Ägypten“, „Übernehmen“ erst mit Text, danach „Elphinstone“ am Eintrag und „Tauchplatz entfernen“ im Blatt; im Logbuch „Tauchgang 74, Elphinstone, 26. März“. Gefunden und behoben: Das Blatt lag unter der Navigationsleiste bzw. mit Tastatur unter der Statusleiste (`useSafeArea`, `SafeArea` unten); mit Tastatur ist „Übernehmen“ teils verdeckt, aber erreichbar (Blatt scrollt, Tastatur schließt nach Vorschlagswahl).

## T26: Vorschau-Extras: Mini-Profil und „Vergleichen“ (ui-spec §5.9, Feinschliff 2026-11-23)

| Nr. | Ausgangslage | Aktion | Erwartet | Status |
|---|---|---|---|---|
| T26.1 | Vorschau mit 3 Tauchgängen | angezeigt | jeder Eintrag mit Mini-Profil wie im Logbuch | ✅ 2026-11-23: rot, keine Sparkline in der Vorschau |
| T26.2 | Tauchgang vom 13.11. schon im Logbuch (18,7 m, 45 min), neu 18,4 m, 47 min | „Vergleichen“ → „Importieren“ | „Vergleichen“ nur am ähnlichen Eintrag; Blatt „Tauchgänge vergleichen“ mit Spalten „Neu“ und „Im Logbuch“ (Datum, Tiefe, Dauer …) und beiden Profilen in einem Diagramm; „Importieren“ wählt ihn aus | ✅ 2026-11-23: rot, „Vergleichen“ fehlt |
| T26.3 | wie T26.2, ähnlicher Eintrag ausgewählt | „Vergleichen“ → „Nicht importieren“ | wieder abgewählt, Knopf „2 Tauchgänge importieren“ | ✅ 2026-11-23: rot, „Vergleichen“ fehlt |

Tests: `test/features/import/dive_computer_screen_test.dart` (FIT nutzt dieselbe Vorschau). Keine Stubs nötig, nur Oberfläche.

Abgenommen am 2026-11-23.

**Umgesetzt (Phase 50, 2026-11-23), T26:**
- [x] Vorschau: `DiveSparkline` unter Tiefe und Dauer jedes Eintrags (ausgegraut, wenn nicht auswählbar) → T26.1 grün.
- [x] `CompareSheet` (`features/import/compare_sheet.dart`): Tabelle „Neu“/„Im Logbuch“ mit fetten Abweichungen und „–“ für fehlende Werte, beide Profile auf gemeinsamen Achsen (ohne Messpunkte die geschätzte Form); die Spaltenköpfe mit Farbmuster sind die Legende (eine eigene Legende hätte „Neu“ doppelt gezeigt); „Importieren“/„Nicht importieren“ → T26.2, T26.3 grün.
- Gesamt: `flutter test` 427/427, `flutter analyze` ohne Befund, Debug-APK baut.
- **Auf dem S25 Ultra geprüft, 2026-11-23:** Mini-Profil in der FIT-Vorschau; Abstand rechts ergänzt, die Kurve reichte bis an den Rand. Mit Zustimmung des Nutzers #74 (FIT-Testdatei) gelöscht und einen ähnlichen Tauchgang von Hand eingetragen (26.03., 11:03, 58,7 m, 74 min): Vorschau zeigt „Ähnlicher Tauchgang vorhanden (26.03., 58,7 m, 74 min)“ und „Vergleichen“; das Blatt zeigt Datei gegen Von Hand mit fetten Abweichungen und beide Profile; „Importieren“ wählt aus, „Nicht importieren“ wählt ab. Danach FIT-Tauchgang mit Elphinstone als #75 importiert und den Testtauchgang wieder gelöscht.
