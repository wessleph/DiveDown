# Security: Version 1.0 (Tauchcomputer-Import, Logbuch, Diagnose-Logs)

> Phase 20 · Stand: 2026-11-18 · Status: **abgenommen (2026-11-18)**, inkl. Restrisiken R1–R5 und O1 = a)
> Grundlage: `design.md`, ADR 0001–0005, `docs/roadmap.md`
> Umfang: alles in Version 1.0 **ohne** Netzwerk-Sync und NAS (die bekommen eine eigene Security-Phase).

## 1. Zusammenfassung
Version 1.0 arbeitet **vollständig lokal**. Es gibt keinen Server, keine Konten und keinen Netzwerkverkehr der App selbst.
Damit entfallen die größten Risikoklassen (Kontoübernahme, Server-Lecks).
Die realistischen Risiken liegen in **vier Bereichen**:
1. **Nicht vertrauenswürdige Eingaben**: BLE-Daten, FIT-Dateien und geteilte Dateien können die App zum Absturz bringen oder bei Fehlern in nativem Code (C) mehr anrichten.
2. **Lieferkette**: übernommener Plugin-Code, das libdivecomputer-Submodul, pub-Pakete und die GitHub-Actions-Pipeline mit den Signier-Schlüsseln.
3. **Datenschutz**: Diagnose-Logs, Health-Daten, Backups.
4. **Lizenz**: GPL-3 bzw. LGPL im Verhältnis zu den Bedingungen von App Store und TestFlight.

## 2. Komponentengrenzen und Bedrohungen (STRIDE)

### G1: App ↔ Tauchcomputer (BLE)
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| S | Ein fremdes BLE-Gerät in der Nähe gibt sich als Tauchcomputer aus, z. B. auf dem Tauchboot. | Der Nutzer wählt das Gerät **explizit** aus der Liste, mit Name und Signalstärke. Es gibt **keine** automatische Verbindung zu unbekannten Geräten. Bekannte Geräte merkt sich die App (Seriennummer aus `dc_devinfo`). Meldet ein Gerät eine andere Seriennummer als gespeichert, warnt die App. |
| T | Manipulierte Rohdaten erzeugen falsche Tauchgänge. | Die Werte werden vor dem Speichern plausibilisiert: Tiefe 0–350 m, Dauer < 24 h, Temperatur −5 bis 45 °C, Druck 0–400 bar, Startzeit nicht in der Zukunft. Ungültige Samples werden verworfen und geloggt. |
| D | Ein Gerät sendet endlos Daten oder hängt sich auf. | Timeouts und **Abbrechen-Knopf** gibt es bereits (`cancelDownload`). Zusätzlich setzen wir Obergrenzen: maximal 2.000 Tauchgänge pro Download und 100.000 Samples pro Tauchgang. |
| E | Ein Speicherfehler im C-Parser (libdivecomputer) wird durch präparierte Daten ausgelöst. | Das Restrisiko akzeptieren wir (R1). Gegenmaßnahmen: das libdivecomputer-Submodul aktuell halten und Fixture-Tests mit beschädigten Dumps. Der native Code läuft in der Sandbox der App, und ohne INTERNET-Berechtigung (siehe 4.) gibt es keinen Weg, Daten nach außen zu schicken. |
| I | Mitlesen der BLE-Funkstrecke | Es werden nur Tauchprofile übertragen, keine Geheimnisse. Wir akzeptieren das als Restrisiko (R2). |

### G2: App ↔ Dateien (FIT-Import, „Teilen → DiveDown“)
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| T/D | Eine präparierte FIT-Datei, z. B. per WhatsApp, lässt den Parser abstürzen, hängen oder viel Speicher belegen. | **Größenlimit 20 MB**. Geparst wird in einem **eigenen Isolate** mit Timeout (30 s) und `try/catch` um alles. Fehler zeigt die App als Meldung an, die App stürzt nicht ab. **Fuzz-Tests** mit beschädigten bzw. abgeschnittenen Dateien (Phase 40). |
| T | `fit_tool` (BSD-3) wurde zuletzt **im November 2022** veröffentlicht und wird nicht mehr gepflegt. | Es ist reines Dart, daher gibt es keine Speicherfehler. Das Risiko beschränkt sich auf Abstürze und Hänger, die das Isolate abfängt. Bei Bedarf wird `fit_tool` geforkt bzw. als Paket übernommen (R3). |
| S | Eine Datei mit irreführendem Inhalt (falsche Gerätedaten) | Vor dem Speichern zeigt die App eine Vorschau, und der Nutzer bestätigt. Es gilt dieselbe Plausibilitätsprüfung wie bei G1. |
| E | Pfad-Tricks beim Empfang geteilter Dateien | Wir verarbeiten nur Bytes, keine Pfade aus fremden Quellen. Die App speichert die Datei nicht. |

### G3: App ↔ Apple Health (iOS)
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| I | Die App liest mehr Gesundheitsdaten als nötig. | Wir fragen **nur Lesezugriff** an, und nur auf Unterwasser-Workouts, Tiefe, Wassertemperatur und Puls. **Kein** Schreibzugriff: `NSHealthUpdateUsageDescription` entfällt. |
| I | Health-Werte landen in Logs oder Exporten. | Health-Werte werden nie geloggt (§3). |
| R | Apples Prüfung: Health-Daten dürfen nicht für Werbung oder an Dritte gehen. | Die App hat keine Werbung, kein Tracking und keine Übertragung. In der App-Datenschutzangabe tragen wir „Daten werden nicht erfasst“ ein. |

### G4: App ↔ lokale Datenbank und Backups
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| I | Eine andere App oder ein Dieb liest die Datenbank. | Die Datenbank liegt im privaten App-Verzeichnis, geschützt durch die Sandbox und die Geräteverschlüsselung von iOS und Android. Zusätzliche Verschlüsselung (SQLCipher) machen wir in v1.0 **nicht**, das ist ein bewusstes Restrisiko (R4). |
| I | Backups über iCloud oder Google enthalten die Datenbank. | Das ist erwünscht, damit Daten bei einem Handywechsel nicht verloren gehen. Die Backups sind durch das jeweilige Konto geschützt. Unter Android gilt `android:allowBackup` gezielt, über `dataExtractionRules`, nur für die Datenbank und nicht für Caches oder Logs. |
| I | Mehrere Taucher auf einem Gerät sehen sich gegenseitig. | Das ist **gewollt** (Familien-Handy). Die Taucherprofile sind keine Sicherheitsgrenze. In der Oberfläche schreiben wir das deutlich hin. |
| T | Eine Migration zerstört Daten. | Für jede Schema-Version gibt es einen Migrationstest (ADR 0004). Vor einer Migration legt die App automatisch eine Kopie der Datenbank an. |

### G5: Diagnose-Logs → Teilen-Dialog
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| I | Logs verraten persönliche Daten. | Zusätzlich zur **Positivliste** aus design.md §9 gilt: Das Plugin loggt `serial=…` (z. B. `DiveComputerHostApiImpl.kt:511`). Seriennummer und BLE-Adresse werden vor dem Schreiben **gekürzt** (letzte 4 Zeichen). Ein **zentraler Filter** in `FileDiagnosticLog` entfernt Koordinaten (Regex für Dezimalgrad), E-Mail-Adressen und Dateipfade mit Benutzernamen. Dafür gibt es Tests. |
| I | Logs gehen ungewollt an falsche Empfänger. | Es wird **nie automatisch gesendet**. Vor dem Senden zeigt die App eine Vorschau, dann öffnet sich der Teilen-Dialog des Systems. |
| D | Logs füllen den Speicher. | Ringpuffer mit 5 MB bzw. 7 Tagen. |

### G6: Lieferkette und Build-Pipeline
| STRIDE | Bedrohung | Gegenmaßnahme |
|---|---|---|
| T | Ein kompromittiertes Upstream-Update (Submersion-Plugin, libdivecomputer-Fork, pub-Paket) | Das Submodul wird auf einen **festen Commit** gepinnt, nicht auf einen Branch. Updates kommen nur per Pull Request mit Diff-Review. `pubspec.lock` wird eingecheckt. Dependabot liefert nur Warnungen, kein Auto-Merge. |
| E | Ein fremder Pull Request im öffentlichen Repo stiehlt Signier-Schlüssel aus GitHub Actions. | **Keine** Secrets in Workflows, die durch `pull_request` von Forks laufen. **Kein** `pull_request_target`. Die Signier- und TestFlight-Jobs laufen **nur** bei Tags bzw. auf `main`, in einer GitHub-**Environment** `release` mit manueller Freigabe. `permissions:` steht in jedem Workflow auf dem Minimum. Drittanbieter-Actions werden **per Commit-SHA gepinnt**. |
| I | Secrets landen im Repo. | `gitleaks` läuft in der CI und optional als Pre-commit-Hook. Keystore und `.p8`-Schlüssel liegen nur als GitHub Secrets vor, `*.jks`, `*.p8`, `*.mobileprovision` und `key.properties` stehen in `.gitignore`. |
| S | Gefälschte APK im Umlauf | Die APK wird nur über GitHub Releases verteilt und mit dem eigenen Keystore signiert. Den Fingerabdruck des Zertifikats geben wir in der README an. Obtainium prüft die Signatur bei Updates. |
| R | Unklar, welcher Code in einem Build steckt | Jeder Build wird per Tag gebaut, die Build-Nummer ist der Git-SHA, und `THIRD_PARTY.md` wird gepflegt. |

## 3. Was wird geloggt und was nie
| Erlaubt | Nie |
|---|---|
| App- und OS-Version, Gerätemodell, libdivecomputer-Version | GPS-Koordinaten, Tauchplatz-Namen |
| Fehlercodes, Stacktraces (ohne Pfade mit Benutzernamen) | Notizen, Namen von Tauchern und Buddys |
| BLE-Protokollschritte, Anzahl von Tauchgängen und Samples | Health-Werte (Puls, Tiefe aus Apple Health) |
| gekürzte Seriennummer bzw. BLE-Adresse (letzte 4 Zeichen) | vollständige Seriennummer, Signier-Schlüssel, Tokens |

## 4. Berechtigungen (minimal)
**Android**
- `BLUETOOTH_SCAN` (mit `neverForLocation`) und `BLUETOOTH_CONNECT`
- Für Android ≤ 11: `BLUETOOTH`, `BLUETOOTH_ADMIN` und `ACCESS_FINE_LOCATION`, alle mit `maxSdkVersion="30"`. Das Plugin fordert `ACCESS_FINE_LOCATION` **ohne** Begrenzung an. Das überschreiben wir im App-Manifest mit `tools:node="replace"`.
- **Kein `INTERNET`** im Release-Build von v1.0, solange es keine Karte gibt. Damit kann die App technisch keine Daten nach außen senden. Kommt die Karte dazu, wird das neu bewertet.
- Keine Kamera, keine Kontakte, kein Hintergrund-Standort (anders als Submersion).

**iOS**
- `NSBluetoothAlwaysUsageDescription` (auf Deutsch, ohne „Submersion“)
- `NSHealthShareUsageDescription` (nur Lesen)
- **Kein** Standortzugriff, **kein** `NSHealthUpdateUsageDescription`

## 5. Abhängigkeiten und Lizenzen (geprüft am 2026-11-18 über pub.dev)
| Paket | Version | Lizenz | GPL-3-kompatibel |
|---|---|---|---|
| flutter_riverpod / riverpod_annotation | 3.5.0 / 4.0.8 | MIT | ✅ |
| drift / sqlite3 | 2.35.4 / 3.9.1 | MIT | ✅ |
| go_router | 18.1.4 | BSD-3 | ✅ |
| fl_chart | 1.3.1 | MIT | ✅ |
| fit_tool | 1.0.5 (2022, ungepflegt) | BSD-3 | ✅ (R3) |
| health | 13.3.2 | MIT | ✅ |
| file_picker | 13.4.0 | MIT | ✅ |
| share_plus | 13.3.1 | BSD-3 | ✅ |
| receive_sharing_intent | 1.8.x (**< 1.9.0**, siehe Hinweis) | Apache-2.0 | ✅ |
| permission_handler | 13.0.2 | MIT | ✅ |
| uuid, logger, equatable | 4.6.0, 2.8.0, 3.0.0 | MIT | ✅ |
| intl, path_provider, package_info_plus, device_info_plus | aktuell | BSD-3 | ✅ |
| *Soll (Karte):* flutter_map, latlong2, flutter_map_tile_caching | 8.3.2, 0.10.1, 10.1.1 | BSD-3, Apache-2.0, **GPL-3** | ✅ |
| **Im Plugin:** libdivecomputer | Fork-Commit `fbd2c42` | **LGPL-2.1+** | ✅ |
| **Im Plugin:** usb-serial-for-android | eingebettet | MIT | ✅ |

Hinweis: `receive_sharing_intent` ab 1.9.0 funktioniert nur noch mit Swift Package Manager. Submersion pinnt deshalb `< 1.9.0`, und das übernehmen wir.
Hinweis für später (Karte): Die **Kachel-Richtlinie von OpenStreetMap verbietet es, Kacheln von `tile.openstreetmap.org` massenhaft herunterzuladen**. Für Offline-Regionen brauchen wir deshalb einen anderen Kachel-Anbieter. Das ist zu klären, bevor die Karte gebaut wird.

## 6. OWASP Mobile Top 10 (2024): kurzer Abgleich
| Risiko | Status v1.0 |
|---|---|
| M1 Unsachgemäßer Umgang mit Zugangsdaten | entfällt (keine Konten, keine Tokens in der App) |
| M2 Unzureichende Lieferketten-Sicherheit | G6 |
| M3 Unsichere Authentifizierung/Autorisierung | entfällt (lokal; Taucherprofile sind bewusst keine Sicherheitsgrenze) |
| M4 Unzureichende Eingabeprüfung | G1, G2 (Plausibilität, Limits, Isolate, Fuzz-Tests) |
| M5 Unsichere Kommunikation | Keine Netzwerkkommunikation. BLE ohne Geheimnisse (R2). |
| M6 Unzureichender Datenschutz | G3, G5, §3 |
| M7 Unzureichender Binärschutz | akzeptiert: Open Source, Verschleiern ist sinnlos |
| M8 Fehlkonfiguration | §4 Berechtigungen, `allowBackup`-Regeln, Release ohne Debug-Flags |
| M9 Unsichere Datenspeicherung | G4 (R4) |
| M10 Unzureichende Kryptografie | entfällt in v1.0 (keine eigene Kryptografie) |

## 7. Lizenz: GPL-3/LGPL und App Store/TestFlight
- Die Free Software Foundation hält die Nutzungsbedingungen von Apple für unvereinbar mit der GPL, weil sie zusätzliche Einschränkungen enthalten.
  Durchsetzen könnten das nur die **Rechteinhaber**: wir für unseren Code, die Submersion-Contributors für übernommenen Code und die Autoren von libdivecomputer.
- Für **unseren eigenen Code** erlauben wir den Vertrieb über Apple ausdrücklich, per Zusatzerlaubnis nach GPL-3 §7 in `LICENSE`/`README`.
- Für **Submersion-Code**: Submersion selbst vertreibt über den App Store und TestFlight. **Empfehlung:** einmal bei den Maintainern nachfragen (GitHub-Issue oder Diskussion), ob sie das für Ableger wie DiveDown ebenfalls erlauben. **Das muss der Projektinhaber selbst tun.**
  **Entscheidung des Projektinhabers (2026-11-18): keine Anfrage.** Der Projektinhaber sieht kein relevantes Risiko. R5 bleibt bewusst akzeptiert.
- Das Restrisiko für ein privates Familienprojekt ohne Einnahmen ist gering (R5).

## 8. Akzeptierte Restrisiken (bewusst entschieden, Abnahme erforderlich)
| # | Risiko | Warum akzeptiert |
|---|---|---|
| R1 | Speicherfehler im C-Code von libdivecomputer durch präparierte BLE-Daten | Der Angreifer muss physisch in der Nähe sein, und der Nutzer muss sich aktiv verbinden. Die Sandbox greift, und ohne INTERNET können keine Daten nach außen gehen. Das Upstream-Projekt ist seit Jahren im Einsatz. |
| R2 | Die BLE-Funkstrecke ist nicht verschlüsselt. | Übertragen werden nur Tauchprofile, das Gerät legt das Protokoll fest. |
| R3 | `fit_tool` wird nicht mehr gepflegt. | Es ist reines Dart, also gibt es keine Speicherfehler, und Abstürze fängt das Isolate ab. Bei Problemen wird geforkt. |
| R4 | Keine zusätzliche Verschlüsselung der Datenbank | Die Geräteverschlüsselung reicht, und es sind keine Hochrisiko-Daten. Das spart Komplexität beim Schlüsselmanagement. Wird bei Sync bzw. NAS neu bewertet. |
| R5 | Die GPL-3 ist mit den Apple-Bedingungen umstritten. | Privat und nicht kommerziell. Submersion vertreibt selbst über App Store und TestFlight. Für den eigenen Code gibt es die Zusatzerlaubnis. **Eine Anfrage bei den Rechteinhabern gibt es bewusst nicht (Entscheidung vom 2026-11-18).** Folge im schlimmsten Fall: Apple entfernt die App aus TestFlight, Android ist nicht betroffen. |

## 9. Ergebnis des Angreifer-Reviews (frischer Agent, 2026-11-18)
Die Code-Stellen habe ich im Referenz-Checkout selbst nachgeprüft (✔ = bestätigt).

### 9.1 Angriffspfade
| # | Pfad | Einschätzung | Gegenmaßnahme (verbindlich für v1.0) |
|---|---|---|---|
| A1 | **Gefälschte „EON Core“** auf dem Tauchboot (ESP32 sendet den passenden Namen). Der Scanner prüft nur den Namen (`BleScanner.kt`). Mögliche Folgen: falsche Tauchgänge, oder ein **gefälschter Fingerprint** überschreibt den echten, sodass beim nächsten echten Download Tauchgänge still fehlen. | niedrig | Ein Gerät wird **an die Seriennummer gebunden**, die libdivecomputer meldet (`DC_EVENT_DEVINFO`). Bei abweichender Seriennummer wird **kein Fingerprint geschrieben**, und die App warnt. Dazu kommen Plausibilitätsprüfung und Obergrenzen (G1). |
| A2 | **Präparierte FIT-Datei** per WhatsApp oder „Teilen → DiveDown“: riesig oder kaputt (Speicher, Hänger), ein Dateiname mit `../` oder eine **gefälschte `file_id`**, damit ein späterer echter Import als Duplikat übersprungen wird. | niedrig bis mittel | Größenlimit (10 MB) und **Prüfung von FIT-Header und CRC** vor dem Parsen, Isolate mit Timeout und Obergrenze für Datensätze. Der **Dateiname wird nie als Pfad verwendet**, gelesen wird direkt in den Speicher. Bei gleicher `source_id`, aber anderem Inhalt gibt es **`NeedsConfirmation`**, kein stilles Überspringen. Die Vorschau zeigt Quelle und Dateiname. |
| A3 | **Lieferkette und CI**: ein fremder Pull Request mit `pull_request_target`, ein kompromittierter Upstream-Branch `submersion-patches` (✔ `.gitmodules` folgt einem **veränderlichen Branch**) oder eine gekaperte Action. Das Build-Skript `build_libdc.sh` läuft bei jedem iOS-Build über die Submodul-Quellen (✔ podspec `script_phase`). Folge: Ein schädlicher Build geht per Auto-Update an **alle Familien-iPhones**. | **mittel, der Pfad mit der größten Wirkung** | wie G6, ergänzt: `branch =` aus `.gitmodules` **entfernen** und auf einen geprüften Commit pinnen, Submodul-Diffs vor jedem Update lesen, **eigener Fork** von libdivecomputer. Der API-Schlüssel für App Store Connect bekommt nur die Rolle **„Developer“**, nicht Admin. Den Signier-Job darf nur der Projektinhaber freigeben (Environment mit Pflicht-Reviewer). **Android wird lokal signiert**, der Keystore kommt nie in die CI. |
| A4 | **Datenleck über Diagnose-Logs**: ✔ `libdc_download.c:919` setzt `DC_LOGLEVEL_ALL`, dadurch landen **komplette Protokoll-Hexdumps** (Tauchdaten, Seriennummern, bei manchen Geräten GPS) im Log. ✔ `BleScanDiagnostics.kt` loggt **Bluetooth-Geräte unbeteiligter Personen** mit Name und MAC (z. B. „Annas AirPods“). ✔ `NativeLogger.kt` spiegelt alles zusätzlich nach **logcat**, auch im Release. | **mittel**, widerspricht direkt design.md §9 | Im Release ist die **Log-Stufe von libdivecomputer `WARNING`**. HEXDUMP-Zeilen werden verworfen, ebenso nicht zugeordnete Geräte. MACs und Seriennummern werden gekürzt bzw. gehasht. logcat nur in Debug-Builds. **Positivliste strukturierter Ereignisse statt Regex-Filter.** Die Vorschau vor dem Teilen bleibt, und wir empfehlen Mail statt WhatsApp. |
| A5 | **Backups und verlorenes Handy**: Standardmäßig landet die Datenbank in Google- und iCloud-Backups. ✔ `BleIoStream.kt:1311-1324` speichert **BLE-Zugangscodes im Klartext** in SharedPreferences, die mitgesichert werden. Laut **Apple-Richtlinie 5.1.3** dürfen Daten aus HealthKit nicht in iCloud gespeichert werden. | niedrig, aber **ein Risiko für die Apple-Prüfung** | Unter Android schließt `dataExtractionRules` die Zugangscodes aus. Zur Datenbank gibt es eine Entscheidung (siehe offene Frage O1). Die Zugangscodes wandern nach `flutter_secure_storage` (Keychain bzw. Keystore). Unter iOS `NSFileProtectionComplete`, wo machbar. |

### 9.2 Lücken im Design und wie sie geschlossen werden
| Lücke | Geschlossen durch |
|---|---|
| Für das Filtern der Logs fehlte ein Mechanismus. | A4: Positivliste und Log-Stufe (Phase 40 testet beides) |
| Exportierte Log-Dateien und FIT-Kopien bleiben in Cache- und Temp-Ordnern liegen. | Beim App-Start und nach dem Teilen werden `share/` und `file_picker`-Caches geleert. |
| Keine Eingabegrenzen für `ImportedDive` | G1 und G2: Plausibilität und Obergrenzen gelten für **alle** Quellen, zentral im `ImportService`. |
| Die Geräte-Identität „Seriennummer oder Adresse“ war uneindeutig. | A1: **Seriennummer** ist der Schlüssel, die Adresse nur ein Hinweis. |
| In ADR 0005 fehlte die CI-Sicherheit. | A3 und G6. Nur der Projektinhaber darf Tags pushen (Tag-Schutzregel). |
| Keine Prüfanleitung für die APK | Der SHA-256-Fingerabdruck des Zertifikats steht in der README. Obtainium prüft das Zertifikat bei Updates. Backup des Keystores: verschlüsselt an zwei Orten, **nicht im Repo**. |
| Der Vertrag für „Teilen → DiveDown“ war offen. | Unter Android nur der MIME-Typ `application/octet-stream` bzw. `*.fit`, unter iOS Dokumenttyp FIT. Nur Inhalte werden gelesen, keine Pfade. Die Activity ist nur dafür exportiert. |
| Datenschutzerklärung und Datenschutzangaben fehlten. | Für die Apple-Prüfung voraussichtlich nötig: eine kurze **Datenschutzerklärung als GitHub-Pages-Seite**. Inhalt: keine Datenerfassung, alles lokal, Health nur lesend, Logs nur auf Wunsch. Datenschutzangabe in App Store Connect: „Data Not Collected“. |
| Das Plugin-Manifest fordert Standort und alte Bluetooth-Rechte ohne `maxSdkVersion` an. | §4: Überschreiben im App-Manifest. Sonst fragt die App unter Android 12+ grundlos nach dem Standort. |
| Bei der PIN-Abfrage ist unklar, welches Gerät fragt. | Phase 30: Der PIN-Dialog nennt Gerätename und gekürzte Adresse. |
| **ADR 0002 ist hier falsch:** Der Android-Build kompiliert C-Dateien aus `macos/Classes` (✔ `CMakeLists.txt:6`). | Den Ordner `macos/Classes` **behalten wir**. Entfernt werden nur die Flutter-Plattformkonfigurationen für Desktop. Wird in ADR 0002 korrigiert. |

### 9.3 Offene Frage an dich
- **O1: Backups und Apple Health.** Die Datenbank liegt in einer Datei. Lassen wir sie im iCloud-Backup, sind beim Handywechsel alle Tauchgänge automatisch dabei. Das kann aber mit Apples Regel „keine Health-Daten in iCloud“ kollidieren, weil Tauchgänge aus der Apple Watch mit Puls drin stehen.
  - **a)** Die Datenbank **aus dem iCloud-Backup ausschließen** und in v1.0 eine einfache Funktion **„Logbuch sichern/wiederherstellen“** (Datei über den Teilen-Dialog) einbauen. Regelkonform, braucht etwa 1–2 Tage mehr Aufwand, und der Nutzer muss selbst sichern.
  - **b)** **Puls aus Apple Health nicht speichern** (nur Tiefe und Temperatur) und die Datenbank im Backup lassen. Einfacher, aber Tiefe und Temperatur stammen trotzdem aus HealthKit, und ob Apple das akzeptiert, bleibt unklar.
  - **Empfehlung: a)**, weil die Sicherungsfunktion auch später für den Wechsel zwischen Android und iPhone nützlich ist.
  - ✅ **Entschieden am 2026-11-18: a)**
    - iOS: Die Datenbank bekommt `NSURLIsExcludedFromBackupKey`. Android: `dataExtractionRules` schließt die Datenbank aus Cloud-Backup **und** Geräte-Transfer aus.
    - Die Sicherungsdatei ist eine Kopie der SQLite-Datenbank plus Manifest (App-Version, Schema-Version, Zeitpunkt, SHA-256), als `.divedown`-ZIP. Geteilt wird sie über den Teilen-Dialog des Systems, gespeichert wird, wo der Nutzer will.
    - Wiederherstellen: Datei wählen → Manifest und Prüfsumme prüfen → Schema-Version ≤ aktueller Version → automatische Kopie der aktuellen Datenbank → ersetzen → Migration. Zur Sicherheit entspricht das der Logik von FIT-Dateien (Größenlimit, Inhalt nur aus dem Speicher, keine Pfade aus dem Archiv).
    - Die Sicherungsdatei ist **nicht verschlüsselt** (enthält Puls-Werte). Darauf weist die Oberfläche beim Teilen hin. Verschlüsselung prüfen wir später, wenn der Sync kommt.
    - Erinnerung: Nach 30 Tagen ohne Sicherung zeigt die App einen dezenten Hinweis an. Es ist nur ein lokaler Hinweis, keine Push-Benachrichtigung.

## 10. Folgen für Phase 30, 40 und 50 (Checkliste)
- [ ] Phase 30: Geräteauswahl zeigt Name und Signal. Warnung bei geänderter Seriennummer. PIN-Dialog mit Gerätename. Vorschau vor dem Import, mit Quelle und Dateiname. Vorschau der Diagnose-Logs vor dem Teilen. Hinweis, dass Profile nicht privat sind. Je nach O1: Oberfläche für „Logbuch sichern/wiederherstellen“.
- [ ] Phase 40: Fuzz-Tests für den FIT-Parser (Header, CRC, Abschneiden, riesige Felder). Plausibilitätsregeln und Obergrenzen im `ImportService`. **Positivliste der Logs** (keine HEXDUMP-Zeilen, keine fremden Geräte, gekürzte MACs und Seriennummern). Fingerprint-Schutz bei abweichender Seriennummer. `source_id`-Kollision ergibt `NeedsConfirmation`. Migrationstest.
- [ ] Phase 50: Manifest ohne INTERNET bzw. Location ≤ 30, Info.plist minimal, `dataExtractionRules`, Isolate mit Timeout. Plugin-Änderungen: Log-Stufe `WARNING` im Release, logcat nur Debug, Zugangscodes nach `flutter_secure_storage`, nicht zugeordnete Geräte nicht loggen. Submodul auf festen Commit und **eigener libdivecomputer-Fork**. CI mit `release`-Environment und Pflicht-Reviewer, gepinnten Actions, gitleaks und Tag-Schutz. API-Schlüssel mit Rolle „Developer“. Android-Signatur lokal. Caches aufräumen. Datenschutzerklärung als GitHub-Pages-Seite. Zusatzerlaubnis für den eigenen Code in LICENSE.
