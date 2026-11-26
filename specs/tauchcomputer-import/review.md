# Review: Apple-Health-Import (T6) und Tastatur-Fix (T36)

Datum: 2026-11-26 · Phase 60 (unabhängiges Review durch einen frischen Agenten, der die Implementierung nicht kennt)

## Umfang

- Commits `0f08217..HEAD` auf `claude/nice-cori-n4f6mx`: `dddbd47`, `d18ed91`, `6ade8dc` (T36) sowie `3476172`, `75ee604`, `b9909a0` (T6).
- Geprüft gegen: `tasks.md` (T6, T36), `ui-spec.md` §1, §4, §5.3, §5.9, §5.10, §6, §7, `design.md` §2 und §4.3, `security.md` G3, §3, §4, ADR 0003 samt Nachtrag vom 2026-11-26, `docs/datenschutz.md`, `THIRD_PARTY.md`, Konstitution Regel 3.
- Die Swift-Datei wurde nur gelesen, nicht kompiliert (kein Mac). Sie wird erst vom iOS-Job in `ci.yml` (`flutter build ios --release --no-codesign` und Simulator-Build) übersetzt.

## Selbst ausgeführt (nicht aus den Notizen übernommen)

| Befehl | Ergebnis |
|---|---|
| `flutter analyze` | „No issues found!“ |
| `dart format --output=none --set-exit-if-changed lib test tool integration_test` | 171 Dateien, 0 geändert, Exit 0 |
| `flutter test` | „All tests passed!“, 530 Tests grün |
| Stub-Suche (`TODO`, `FIXME`, `UnimplementedError`, `return null`-Stubs, Festantworten) in `lib`, `test`, `tool`, `ios/Runner` | Einziger Treffer: `appDatabaseProvider` wirft absichtlich `UnimplementedError` (muss überschrieben werden, alt, unkritisch). Keine Stubs im neuen Code. |
| Netzwerk | Kein Netzwerkzugriff im neuen Code (nur MethodChannel und lokale DB), offline-first eingehalten. |

## Ergebnis in Kürze

Keine kritischen Befunde. Der Code entspricht der Spec in den geprüften Punkten (Lesen-nur, minimale Typen, keine Health-Werte im Log, Uhrzeit-als-UTC-Konvention, Duplikaterkennung, deutsche Texte, Zustände aus §5.10). Es gibt drei wichtige Befunde (ein UI-Hänger bei unerwarteten Fehlern, stille Fehler in der Swift-Seite, die als „ohne Tiefe“ erscheinen, und Samples hinter dem Workout-Ende) und einige Kleinigkeiten. Der größte Rest-Risikopunkt bleibt die nie kompilierte Swift-Datei und T6.14 am Gerät.

## Kritisch

Keine.

Bewusst geprüft und für in Ordnung befunden:

- **Swift-API-Nutzung** (`ios/Runner/HealthDiveChannel.swift`): `HKQuantityType(_:)` (iOS 15), `.underwaterDepth`/`.waterTemperature` (iOS 16, nur unter `@available(iOS 16.0, *)` bzw. `guard #available` genutzt), `HKWorkoutActivityType.underwaterDiving` (iOS 16), `HKQuantitySeriesSampleQuery(quantityType:predicate:quantityHandler:)` mit dem Sechs-Parameter-Handler `(query, quantity, DateInterval?, sample, done, error)` stimmt mit der API überein, `requestAuthorization(toShare: nil, read:)`, `HKMetadataKeyTimeZone`, `HKUnit.meter()/.degreeCelsius()/.minute()`. Ich sehe keinen sicheren Compilerfehler. `SWIFT_VERSION = 5.0` (pbxproj), damit gibt es keine Sendable-Strenge für die `FlutterResult`-Captures.
- **Threading:** `FlutterResult` wird in allen Pfaden über `DispatchQueue.main.async` genau einmal aufgerufen (Fehler, Erfolg, Authorization). `finished` schützt gegen doppelte Handler-Aufrufe je Serie. Die Serien laufen strikt nacheinander, `out` braucht daher keine Sperre.
- **Lebensdauer:** `AppDelegate` hält `healthDiveChannel` stark, der Handler hält `self` schwach, die Query-Closures halten `self` stark bis zum Ende. Keine Zyklen.
- **Kanalvertrag:** Namen (`io.github.wessleph.divedown/health`), Methoden (`availability`, `requestReadAccess`, `diveWorkouts`), Argumente `from`/`to` in ms, Felder `uuid`, `start`, `end`, `utcOffsetS`, `depth`, `temperature`, `heartRate` mit `[ms, Wert]` stimmen in `health_channel.dart` und Swift überein.
- **Zeit:** `start` = UTC-Zeitpunkt plus `utcOffsetS`, als UTC markiert (Konvention von `Dive.start`); `startInstant` echte UTC; `utcOffsetS` von der Plattform. Test T6.1 prüft Kairo (+7200) und Zürich (+3600).
- **Duplikate:** `sourceId` = Workout-UUID, `ImportService` vergleicht über `source` + `sourceId` (`import_service.dart:134`); Test T6.8 „Bereits im Logbuch“ deckt es ab.
- **Plausibilität:** Grenzen 350 m, 24 h, 100000 Samples. Ein Watch-Tauchgang mit 1 Hz über 1 h (3600 Samples, ≤ 40 m) wird nicht abgelehnt; der Fixture-Tauchgang hat 2821 Samples und läuft durch.
- **Signing:** `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` an genau den drei Runner-Konfigurationen (Test T6.13 zählt 3). `Runner.entitlements` enthält nur `com.apple.developer.healthkit`. Die PlistBuddy-Syntax in `ios-release.yml:74-79` ist richtig (Doppelpunkt als Trenner, Punkte im Schlüsselnamen sind erlaubt; `! … >/dev/null 2>&1` bricht mit `exit 1` und `::error::` ab; `set -euo pipefail` ist wegen des `if !` unkritisch). Die Prüfung steht vor dem Kopieren des Profils. Der Workflow-Policy-Test (`test/tool/workflow_policy_test.dart`) ist Teil der 530 grünen Tests.
- **Datenschutz:** `docs/datenschutz.md` (Zeilen 27, 29, 35) nennt Apple Health, nur lesend, nur lokal, mit Erlaubnis. Das passt zu dem, was die App tut. DB-Ausschluss aus dem iCloud-Backup existiert bereits (`AppDelegate.swift:66-83`, `backup_exclusion.dart`).
- **Herkunft:** `health_dive_mapper.dart` trägt den Herkunftskopf (Submersion, Commit `4e638982`), `THIRD_PARTY.md` hat den Eintrag, der alte Abschnitt „Geplant“ ist entfernt. Regel 3 erfüllt.
- **Schichten:** `domain/import/health_import.dart` importiert nur `dive.dart` und `imported_dive.dart`, kein Flutter, Drift oder Plugin. `data/import/health/` übersetzt nur. `PlatformException` kommt aus `flutter/services.dart` in der Data-Schicht, das ist erlaubt.

## Wichtig

### W1. Unerwartete Fehler in der Suche lassen die Seite „suchend“ hängen
`lib/features/import/health_import_screen.dart:66-79`

`_search` fängt nur `HealthReadFailure`. Wirft `ref.read(activeDiverProvider.future)` (das `!` auf Zeile 71 bei fehlendem Taucher), `importService.preview(...)` (DB-Fehler) oder `mapHealthDive` (z. B. `StateError` bei `reduce` auf leerer Liste ist ausgeschlossen, aber `RangeError` bei kaputten Daten) etwas anderes, bleibt `_searching == true`: Der Knopf bleibt dauerhaft deaktiviert, der Timer `_slow` läuft nicht weiter, es erscheint weder Fehlertext noch „Erneut versuchen“. ui-spec §4 verlangt für Fehler immer einen Ausweg.

Fix: `try { … } on HealthReadFailure { … } catch (_) { result = null; }` bzw. `finally`-Block, der `_searching = false` setzt; dazu einen Test mit einem `HealthDiveSource`, der `StateError` wirft, und einen mit einem ImportService-Fehler.

### W2. Stille Teilfehler in `HealthDiveChannel.series` erscheinen als „ohne Tiefe“
`ios/Runner/HealthDiveChannel.swift:158-166`

Schlägt die Abfrage der Tiefe (z. B. `errorAuthorizationDenied`, `errorDatabaseInaccessible` bei gesperrtem Gerät) fehl, liefert `series` `[]`. Das Workout kommt dann ohne Tiefe in Dart an und wird als „1 Training ohne Tiefe übersprungen.“ gezählt (`mapHealthDive` gibt `null` zurück). Der Nutzer erfährt weder „Fehler“ noch „Zugriff fehlt“; schlimmer, bei gesperrtem Telefon (`protectedDataUnavailable`) wären alle Tauchgänge „ohne Tiefe“. Das Kommentar in Swift nennt es Absicht („so the others still arrive“), gilt aber sinnvoll nur für Temperatur und Puls, nicht für die Tiefe, ohne die es keinen Tauchgang gibt.

Fix: Fehler der Tiefenserie als `FlutterError("query_failed")` für den ganzen Aufruf weiterreichen (Temperatur und Puls dürfen weiter leer bleiben). Alternativ den Fehlerfall im Kanal-Vertrag als `depthFailed` markieren und in Dart `HealthReadFailure` werfen. In `tasks.md` T6.9 dokumentieren.

### W3. Samples hinter dem Workout-Ende werden nicht abgeschnitten
`lib/data/import/health/health_dive_mapper.dart:23-30`

Vor dem Start werden Tiefenwerte verworfen (T6.3), hinter dem Ende nicht. Die Swift-Abfrage nutzt `options: []` (alles, was das Fenster überlappt), dadurch können Werte aus überlappenden Serien nach `end` liegen. Folge: `samples.last.timeS > durationS`, Profil länger als die Dauer, `maxDepthM` aus Werten außerhalb des Tauchgangs. Auch `temps` (Zeile 49-52) filtert auf `[start, end]`, die Samples aber nicht (inkonsistent).

Fix: `if (ms < 0 || ms > durationS * 1000) continue;` und einen Test „Wert hinter dem Ende wird verworfen“ in `health_dive_mapper_test.dart`. T6.3 entsprechend ergänzen.

## Nice-to-have

### N1. Zeitzone des Telefons zum Importzeitpunkt statt zur Tauchzeit
`ios/Runner/HealthDiveChannel.swift:181-185`

Fehlt `HKMetadataKeyTimeZone`, gilt `TimeZone.current` (Zeitzone beim Import, nicht beim Tauchen). Wer nach einer Reise importiert, bekommt die Uhrzeit des Heimatlandes. Das ist in `tasks.md` T6.1 als Entscheidung festgehalten, aber im UI nirgends sichtbar. Vorschlag: im Vorschau-Hinweis oder in der Doku (`docs/`) erwähnen; Apples Workout-App setzt den Schlüssel üblicherweise, daher selten.

### N2. `ui-spec.md` §5.10 „Ablauf“ nicht an die Umsetzung angepasst
`specs/tauchcomputer-import/ui-spec.md:211`

Dort steht „Vorab-Erklärung → Health-Berechtigung (System) → Zeitraum wählen → Suche“. Umgesetzt (und in `tasks.md` „Umgesetzt“ begründet) ist: Erklärung + Zeitraum auf einer Seite, die Berechtigung kommt beim ersten Suchen. Die Spec sollte nachgezogen werden, damit der Ablauf nur an einer Stelle steht.

### N3. `tasks.md` T6 „Aufbau“ nennt Daten, die der Kanal nicht liefert
`specs/tauchcomputer-import/tasks.md` (Absatz „Aufbau“)

„Gerät (Name, Modell)“ wird laut T6.11 nicht gespeichert und vom Swift-Kanal nicht geliefert. Zeile streichen. Ebenso nennt der Absatz den Kanal `divedown/health`, tatsächlich `io.github.wessleph.divedown/health`.

### N4. Kachel „Benötigt iOS 16“ ohne Semantik für „deaktiviert“
`lib/features/import/import_screen.dart:148-180`

Eine Karte mit `onTap: null` wird für VoiceOver nicht als „nicht verfügbar“ angesagt; der Hinweistext steht aber im Baum und wird mitgelesen, damit ist Bedeutung nicht nur über Farbe getragen. Optional: `Semantics(enabled: false)` ergänzen.

### N5. Zeitraum während der Suche änderbar
`lib/features/import/health_import_screen.dart:174-196`

Die Radio-Zeilen bleiben während `_searching` aktiv; ein Wechsel ändert nur die Anzeige, nicht die laufende Suche. Vorschlag: `RadioGroup` während der Suche deaktivieren (kein Fehler, nur Irritation).

### N6. Schwache Assertions und fehlende Randfälle in den Tests
- `store_health_dive_source_test.dart` (T6.12): Die Verbotsliste enthält `'23.'` und `'24.'`; das schließt reale Werte wie `23,4` nicht aus. Besser: Log-Zeilen gegen ein striktes Muster `^fetch: \d+ workouts, \d+ dives, \d+ without depth, \d+ samples$` prüfen.
- `healthImportFrom`: Es gibt keinen Test für den 29. Februar (`DateTime.utc(year-1, 2, 29)` wird zum 1. März, harmlos, aber ungeprüft), für einen neuesten Health-Tauchgang in der Zukunft (z. B. falsche Uhr) und für `now` am Monatsende.
- `ios_health_config_test.dart` prüft Swift nur über Zeichenketten (`toShare: nil`, `HKWorkoutActivityType.underwaterDiving`). Ob Swift kompiliert, kann nur die CI sagen; das ist im Test-Kommentar ehrlich vermerkt, könnte aber in `tasks.md` T6.13 als „Kompilierung nur in CI“ stehen (steht im „Umgesetzt“-Block).
- Kein Test für das Zurücksetzen/Beibehalten der Ebenen im Profil bei Wechsel zwischen Tauchgängen (`profile_chart.dart:83-92`) und keiner dafür, dass bei Luft **und** Puls „Luft“ vorgewählt ist (`_setDefaultLayers`, Zeile 106-113). Nach ui-spec §6 ist Puls „an, wenn es keine Luft gibt“, die Logik stimmt, ist aber nur im Fall ohne Luft getestet.
- Kein Test, dass die Pulsachse (`profile_chart.dart:897-932`) bei gleichzeitig eingeschalteter Temperatur nicht überlappt; Layout ist (obere Hälfte Temperatur, untere Hälfte Puls) vernünftig, aber nur visuell prüfbar. Beim iPhone-Test T6.14 mit ansehen.

### N7. Pulsachse ohne Einheit
`lib/features/logbook/profile_chart.dart:918-931`

Die Achsenbeschriftung zeigt `$hi`/`$lo` ohne Einheit, Temperatur zeigt `°`. Die Zahl bleibt in `accent` farbig und im Wertefeld steht „/min“, ausreichend; ein „/min“ an der Achse wäre aber eindeutiger (Bedeutung nicht nur über Farbe, ui-spec §1).

### N8. `healthImportFrom` und Wandtakt-Konvention
`lib/domain/import/health_import.dart:112-124`

`since` ist Wanduhrzeit (als UTC markiert) minus 1 Tag und wird unverändert als echter Zeitpunkt an `diveWorkouts(from, …)` gegeben. Das ist durch die Tagesreserve (Versatz ≤ ±14 h) korrekt, aber nur durch den Kommentar in Zeile 119 begründet. Ein Test mit einem Versatz von +14 h (Tauchgang am Anfang des Tages) würde die Annahme festhalten.

## T36 (Tastatur-Fix)

Keine Befunde, die ein Eingreifen erfordern.

- `lib/app/bottom_action.dart` legt die Aktion in den `body`, der von Scaffold für die Tastatur verkleinert wird; Feedback, Ausrüstung und Gesundheitsimport nutzen es. `manual_dive_screen.dart:518` bleibt mit `bottomNavigationBar`, weil die Seite in der Tab-Leiste steht (T36.3, Absicherungstest grün). Wischen schließt die Tastatur auf allen vier Seiten (`keyboardDismissBehavior: onDrag`, Tests T36.5).
- T36.6 (Test am iPhone) steht in `tasks.md` korrekt als „offen“, nicht als erledigt.
- Hinweis: Die Tests (`keyboard_actions_test.dart`) simulieren die Tastatur über `viewInsets`; das echte Verhalten mit Home-Indikator-Padding (`SafeArea(top: false)` im Körper) prüft erst T36.6.

## Spec-Abgleich in Stichpunkten

| Punkt | Ergebnis |
|---|---|
| ui-spec §5.10 Zustände | Vorab-Text, Hinweis 40 m, „keine Tauchgänge“ + Zugriffshinweis, „iOS 15“-Kachel, Fehler mit „Erneut versuchen“, ruhiger Ladezustand erst nach 300 ms (§4): alle vorhanden |
| Deutsch | Alle neuen Texte im ARB auf Deutsch; Info.plist-Text deutsch; Fehlercodes erscheinen nicht in der UI |
| Touch-Ziele | Hauptknopf 56 dp, `RadioListTile` ≥ 48 dp, Kachel ≥ 48 dp |
| Bedeutung nicht nur über Farbe | Hinweise haben Icon und Text (`_Notice`), Puls-Chip mit Text |
| Große Schrift | Inhalt steckt in einer `ListView`, Knopf unten über `BodyWithBottomAction`; kein starres Layout |
| G3 | Nur Lesen (`toShare: nil`), vier Typen (Workouts, Tiefe, Wassertemperatur, Puls), kein `NSHealthUpdateUsageDescription`, keine Clinical Records |
| Log (§3) | Nur Zähler und Fehlercodes, keine UUID, keine Werte |
| T6-Szenarien ohne Test | T6.14 (am Gerät, steht offen). T6.2 testet Kanalverträge per Mock, nicht gegen die echte Swift-Seite |

## Was im Chat erklärt wurde und ins Repo gehört

Ich kann nur nach dem Repo urteilen, den Chat kenne ich nicht. Aus dem Repo erkennbar fehlt:

1. Die Anleitung für den Freund mit der Apple Watch Ultra (T6.14): welche App die Tauchgänge aufzeichnet, was beim Berechtigungsdialog zu erwarten ist (vier Typen, nur Lesen), was er zurückmelden soll. Vorschlag: kurzer Abschnitt in `docs/` oder in T6.14.
2. Der Hinweis, dass das Provisioning-Profil (`IOS_PROFILE_BASE64`) einmalig mit HealthKit neu erzeugt werden muss, bevor der nächste Release-Lauf grün wird. Die Fehlermeldung des Workflows verweist auf `docs/entwickler/ios-release-einrichtung.md`; dort steht HealthKit unter E3, aber nicht der Schritt „Profil neu erzeugen und Secret ersetzen“ für ein bestehendes Profil. Das gehört dazu.
3. Die Begründung der Entscheidung „Berechtigung beim ersten Suchen statt davor“ steht in `tasks.md`, aber nicht in der ui-spec (siehe N2).

## Gate

Keine kritischen Befunde. Vor dem Merge sollten W1 bis W3 behoben oder bewusst zurückgestellt werden. Das Release hängt zusätzlich an: CI-Kompilierung der Swift-Datei, neu erzeugtem Provisioning-Profil mit HealthKit und T6.14 am Gerät.
