# Review: Tauchgang als Bild teilen (T43)

Datum: 2026-11-27 · Phase 60 (unabhängiges Review durch einen frischen Agenten, der die Implementierung nicht kennt)

## Umfang

- Die zwei lokalen Commits `origin/main..HEAD`: `f5128cc` (fehlschlagende Tests, Stubs, Spec-Texte) und `def7459` (Umsetzung), 35 Dateien.
- Geprüft gegen: `ui-spec.md` §5.16 (dazu §1, §4, §5.3, §6, §7), `security.md` G7, `tasks.md` T43 (T43.1 bis T43.12; T43.13 ist die offene Handprüfung am S25/iPhone und kein Befund), `docs/datenschutz.md` §4 Punkt 4, `docs/constitution.md`.
- Gelesen: `share_card.dart`, `share_card_painter.dart`, `share_dive_screen.dart`, `share_photo.dart`, `system_file_picker.dart`, `share_folder.dart`, `providers.dart`, `router.dart`, `dive_detail_screen.dart`, `drift_app_settings.dart`, `android_manifest_policy.dart`, `app_de.arb` und die T43-Tests. Generierte l10n-Dateien nicht zeilenweise.

## Selbst ausgeführt

| Befehl | Ergebnis |
|---|---|
| `flutter analyze` | „No issues found!“ |
| `dart format --output=none --set-exit-if-changed lib test tool integration_test` | 189 Dateien, 0 geändert, Exit 0 |
| `flutter test` (volle Suite) | „All tests passed!“, 606 Tests grün |
| Stub-Suche (`TODO`, `FIXME`, `UnimplementedError`, `return null`) in den hinzugefügten Zeilen von `lib/` und `tool/` | Keine Treffer. Keine hartkodierten Leerantworten. |
| Abhängigkeiten, Berechtigungen | `pubspec.yaml`, `pubspec.lock`, `android/`, `ios/` unverändert; `tool/android_manifest_policy.dart` verbietet zusätzlich `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`. Kein Netzzugriff. |
| Wegwerf-Probe EXIF (Scratch, nicht im Repo): JPEG 400 × 200, links rot, rechts blau, EXIF-Orientierung 6, durch `decodeSharePhoto` | Ergebnis 200 × 400, oben rot, unten blau, also **richtig gedreht und nicht verzerrt**; ohne EXIF 400 × 200 unverändert. Die Engine wendet die Orientierung beim Dekodieren mit `targetWidth/targetHeight` an. |
| Wegwerf-Probe Größe (Scratch): JPEG 6000 × 2400 | dekodiert als 4800 × 1920 (siehe N1) |
| Wegwerf-Probe Layout (Kopie des Repos im Scratch, `pumpTestApp`, Seite „Tauchgang teilen“, 360 × 640 dp) | Schriftgröße 1,0: Vorschau 144 × 256 dp; 1,5: 87 × 154; 2,0: 41 × 72; 3,0: Vorschau 0 × 0 und **„RenderFlex overflowed by 328 pixels on the bottom“** (siehe W1) |

## Ergebnis in Kürze

Keine kritischen Befunde. Die Sicherheitszusagen aus G7 halten: Das Bild wird mit `PictureRecorder` neu gezeichnet und als PNG kodiert, nichts außer den Pixeln des Fotos geht über; die Karte bekommt ihre Texte nur aus `ShareCardContent`, das ausschließlich Platz, Nummer, Datum, Tiefe, Dauer, Wassertemperatur und Profil kennt; das Foto liegt nur als `ui.Image` im Zustand der Seite und wird beim Entfernen, Ersetzen und Schließen freigegeben; keine neue Abhängigkeit, keine neue Berechtigung, im Protokoll steht nur „share image created“ bzw. der Typ des Fehlers. Vorschau und PNG nutzen denselben `ShareCardPainter`, die Geometrie (`cardRect`, `dragged`) ist über Anteile des freien Platzes gerechnet, die Karte kann das Bild deshalb bei keiner Größe verlassen. Die Farben stimmen mit `theme.dart` überein, die Karte bleibt im dunklen Modus hell.

Es gibt drei wichtige Befunde: Die Seite ist bei kleinem Telefon und großer Schrift kaum bzw. nicht benutzbar (Überlauf bei 3,0), sie hat keinen Lade- und Fehlerzustand, und mehrere Zeilen von T43 sind durch Tests nicht wirklich abgedeckt (Foto-Ausschnitt, 50-MB-Grenze, Zusammenziehen, gesperrter Knopf). Dazu sieben kleinere Punkte.

Geprüft und in Ordnung:

- **EXIF-Drehung:** siehe Probe oben. Ein Hochformatfoto der Kamera (Orientierung 6) kommt aufrecht an. HEIC ist damit nicht belegt (ob die Engine HEIC dekodiert, hängt vom Gerät ab; bei Misserfolg erscheint ohne Absturz „Das Foto konnte nicht geöffnet werden.“); das bleibt bei T43.13.
- **Speicher:** Das Foto wird bei `dispose`, `_removePhoto` und Ersetzen freigegeben; ein nach dem Schließen der Seite eintreffendes Foto wird in `_pickPhoto` sofort freigegeben (`share_dive_screen.dart:60-63`). Deskriptor und Puffer werden im `finally` freigegeben, ebenso das `ui.Image` des PNG. `renderShareImage` zeichnet vor dem ersten `await` (`share_card_painter.dart:353-358`); ein Schließen der Seite während des Erzeugens kann das Foto deshalb nicht mehr unter dem Bild wegnehmen.
- **Doppeltipp auf „Teilen“:** `_busy` wird synchron vor dem ersten `await` gesetzt (`share_dive_screen.dart:86`), der Knopf ist danach gesperrt.
- **Geometrie:** Ziehen rechnet `delta / k / freeX`, bei `freeX <= 0` bleibt der Wert; `copyWith` klemmt auf 0 bis 1. Zusammenziehen nimmt `_pinchBase * d.scale`, `onScaleStart` setzt die Basis neu, auch wenn ein zweiter Finger später dazukommt. Karte 88 % der Breite, Achsenschrift 30 px, Größe 50 bis 100 % in 5er-Schritten (`divisions: 10`), Deckkraft 0 bis 100 % in 5er-Schritten (`divisions: 20`), „Teilen“ 56 dp, Ecken 14 dp: wie in §5.16.
- **Datenschutzerklärung:** §4 Punkt 4 beschreibt das Verhalten richtig und sagt, dass kein Zugriff auf die Galerie nötig ist.

## Kritisch

Keine.

## Wichtig

### W1. Seite ist bei kleinem Telefon und großer Schrift kaum benutzbar, bei 3,0 fach Überlauf
`lib/features/logbook/share_dive_screen.dart:118-128` (Column mit `Expanded` für die Vorschau und nicht scrollbaren Reglern darunter), `:223` (`SizedBox(width: 88)` für die Beschriftung der Regler)

Verstoß gegen ui-spec §7 (große Schrift, Seiten bleiben bedienbar) und §4. Gemessen mit `pumpTestApp` bei 360 × 640 dp: Schriftgröße 1,0 gibt der Vorschau 144 × 256 dp (noch benutzbar, aber klein), 2,0 nur 41 × 72 dp, 3,0 einen RenderFlex-Überlauf von 328 px und eine Vorschau mit Größe 0 (die iOS-Stufen der Bedienungshilfen gehen über 2,0 hinaus). Die Beschriftungen „Deckkraft“ und „Position“ stehen in einer festen Breite von 88 dp und laufen bei großer Schrift aus dem Feld. Der Hauptknopf bleibt erreichbar, aber ein Nutzer mit großer Schrift sieht die Vorschau nicht mehr. Die Tests laufen nur mit 400 × 1000 dp und Schriftgröße 1.

Vorschlag: Inhalt (Vorschau mit fester Mindesthöhe, z. B. `min(Breite * 16/9, 0,5 * Höhe)`, und Regler) in ein `SingleChildScrollView`/`ListView` legen, nur „Teilen“ bleibt unten fixiert; die Beschriftung der Regler **über** den Regler setzen (oder `Flexible` statt fester 88 dp), die Positionsknöpfe in einem `Wrap`. Test: `pumpTestApp(size: Size(360, 640), textScale: 1 / 2 / 3)`, danach ist `tester.takeException()` `null` und die Vorschau mindestens 120 dp breit bzw. die Seite scrollt.

### W2. Kein Lade- und Fehlerzustand der Seite
`lib/features/logbook/share_dive_screen.dart:111` und `:115` (`ref.watch(diveDetailProvider(...)).value?.dive`, sonst `SizedBox.shrink()`)

ui-spec §4 verlangt für jede Seite Laden, Leer und Fehler mit Ausweg. Hier zeigt die Seite bei Laden, bei einem Datenbankfehler und bei einem inzwischen gelöschten Tauchgang nur die App-Leiste und eine leere Fläche, ohne Text, Fortschrittskreis, „Erneut versuchen“ oder Hinweis für Screenreader. Es ist derselbe Mangel wie W2 im Review zur Statistik-Seite.

Vorschlag: `AsyncValue.when` mit Fortschrittskreis (mit Semantics-Label), Fehlertext plus „Erneut versuchen“ (`ref.invalidate(diveDetailProvider(id))`) und für „nicht gefunden“ einen Text mit Knopf „Zurück“, wie die Detailseite. Test mit einem Repository, das wirft, und mit einer unbekannten ID.

### W3. Mehrere Zeilen von T43 sind nicht durch einen Test abgedeckt, der die Erwartung wirklich prüft
Tests: `test/features/logbook/share_image_test.dart`, `test/data/platform/share_photo_loader_test.dart`, `test/features/logbook/share_dive_test.dart`

Gegen `tasks.md` T43 und ui-spec §5.16/§4/§7:

1. **T43.5 „mit Foto Pixel aus dem Foto (formatfüllend, mittig)“:** Der Test benutzt ein **einfarbiges** 400 × 300 Foto und prüft nur den Pixel (20, 20) (`share_image_test.dart:79-100`). Ein falscher Ausschnitt (nicht mittig, gestreckt statt zugeschnitten, vertauschte Seiten) würde bestehen. Vorschlag: ein Foto aus drei senkrechten Streifen (z. B. 3000 × 1000, rot/grün/blau) und Pixel links, Mitte und rechts im PNG prüfen: bei „mittig zugeschnitten“ muss das ganze Bild grün sein; bei einem Hochformatfoto mit drei waagrechten Streifen entsprechend. Der Metadaten-Teil des Tests ist ohnehin schwach: Ein `ui.Image` trägt keine Chunks, der Test sichert nur, dass das Kodieren nichts hinzufügt. Das ist richtig, aber kein Beweis für „Pixel aus dem Foto“.
2. **T43.6 „> 50 MB → `tooLarge` ohne Dekodieren“:** Der Test reicht dem Lader ein `PickFailed(tooLarge)` vom Fake (`share_photo_loader_test.dart:27-34`) und prüft nur die Abbildung. Die eigene Prüfung `bytes.length > maxSharePhotoBytes` in `decodeSharePhoto` (`share_photo.dart:48`) und die Einstellung `SystemFilePicker(maxBytes: maxSharePhotoBytes, imagesOnly: true)` in `providers.dart:200` (nur so greifen die 50-MB-Grenze und der Bildfilter, security G7) haben keinen Test. Vorschlag: `decodeSharePhoto(Uint8List(51 * 1024 * 1024))` ergibt `tooLarge`; `ref.read(sharePhotoPickerProvider)` ist ein `SystemFilePicker` mit `maxBytes == maxSharePhotoBytes` und `imagesOnly`.
3. **T43.9 Zusammenziehen:** ui-spec §5.16 Punkt 3 verlangt Zusammenziehen mit zwei Fingern. Es gibt keinen Test; der Zweig `pointerCount > 1` (`share_dive_screen.dart:194-196`) wird nie durchlaufen. Der Ziehen-Test prüft nur „nach oben“ bei 100 % Größe. Vorschlag: zwei `TestGesture`s auf der Karte auseinanderziehen bzw. zusammenführen und `_cardLabel` („Größe 50 %“) prüfen; Ziehen nach rechts unten bei 50 % Größe prüft, dass die Karte ganz im Bild bleibt.
4. **ui-spec §4 „Bild wird erzeugt: Knopf zeigt Fortschrittskreis, ist gesperrt“:** nirgends getestet. Vorschlag: Fake-Renderer mit `Completer`, `pump()`, dann `CircularProgressIndicator` gefunden, und ein zweiter Tipp auf „Teilen“ ruft den Renderer nur **einmal** auf.
5. **ui-spec §7 „Regler lesen ihren Wert vor“:** Es wird nur das Label der Karte geprüft, nicht `semanticFormatterCallback` der Regler („Deckkraft 60 Prozent“). Vorschlag: `tester.getSemantics(_opacity).value` prüfen.
6. **EXIF-Orientierung:** von mir geprüft (siehe oben), im Repo aber durch nichts abgesichert, obwohl T43.13 („Foto richtig gedreht“) sich darauf verlässt. Vorschlag: ein kleines JPEG mit Orientierung 6 als Testdatei und ein Test, der die Maße 200 × 400 statt 400 × 200 erwartet.

## Nice-to-have

### N1. Panoramafotos können sehr viel Speicher belegen
`lib/data/platform/share_photo.dart:57-65`

Nur die **kürzere** Seite wird auf 1920 begrenzt. Ein JPEG 6000 × 2400 wird zu 4800 × 1920 (37 MB RGBA, gemessen), ein Panorama 20000 × 2000 zu 19200 × 1920 (rechnerisch 147 MB), obwohl das Bild nur einen 1080 px breiten Ausschnitt braucht. Unter 50 MB Dateigröße sind solche Fotos möglich; security G7 (Dienstgüte) nennt die Begrenzung auf die „nötige Größe“. Vorschlag: zusätzlich die längere Seite begrenzen (z. B. auf 4096), Test mit 6000 × 1500.

### N2. Codec wird bei einem Fehler in `getNextFrame` nicht freigegeben
`lib/data/platform/share_photo.dart:62-69`

`codec.dispose()` steht nur auf dem Erfolgspfad. Bei einem Foto mit lesbarem Kopf, aber kaputten Daten wirft `getNextFrame`, und der Codec bleibt bis zur Garbage Collection liegen. `on Exception` fängt außerdem keine `Error`s. Vorschlag: `codec` im `try/finally` freigeben, `on Object` (wie in `_share`).

### N3. `TextPainter` werden nie freigegeben
`lib/features/logbook/share_card_painter.dart:311-328`

`_layoutText` erzeugt pro `paint` etwa zwanzig `TextPainter` (jeder mit nativem Absatz), die nie `dispose()` bekommen; beim Ziehen sind das bis zu 60 Durchläufe pro Sekunde. Kein Absturz, aber unnötiger Druck auf die Speicherbereinigung und im Leak-Tracking von Flutter ein Befund. Vorschlag: nach dem Zeichnen `painter.dispose()` aufrufen.

### N4. Zeitachse bei Tauchgängen unter einer Minute
`lib/domain/share/share_card.dart:119-132`, `lib/features/logbook/share_card_painter.dart:223`

Bei Dauer unter 60 s ist `marks == [0]`; die einzige Marke heißt „0“ ohne Einheit „min“ (Bedingung `i > 0`), ui-spec §5.16 verlangt die Einheit an der letzten Marke. Bei `durationS == 0` ohne Samples ist `timeScaleS == 0` und `x(t)` rechnet `t / 0` (NaN); Skia ignoriert das, das Profil fehlt aber. Beides ist selten (das Formular verlangt eine Dauer), kostet aber nichts: `timeScaleS = max(1, end)`, Beschriftung „0 min“ bei nur einer Marke, Test in `share_card_test.dart`.

### N5. Gespeicherte Lage kann Änderungen des Nutzers überschreiben, Schreibfehler sind ungefangen
`lib/features/logbook/share_dive_screen.dart:36-41`, `:54`

`initState` lädt die Lage asynchron und setzt sie, sobald sie ankommt, ohne zu prüfen, ob der Nutzer schon etwas verändert hat; bei einer langsamen Datenbank springt die Karte zurück, und kurz ist die Standardlage zu sehen. `_save` und das Lesen haben kein `catchError`, ein Datenbankfehler wäre ein unbehandelter Fehler. Vorschlag: die Lage vor dem ersten Aufbau über einen `FutureProvider` laden (Ladezustand siehe W2), `_save` mit `unawaited(...catchError(...))` und nur ein Protokolleintrag.

### N6. Datei im Cache wird nicht beim Öffnen der Seite gelöscht
`lib/features/logbook/share_dive_screen.dart` (`initState`), `lib/app/providers.dart:187-197`

Spec §5.16 und G7: „beim nächsten Öffnen der Seite bzw. App-Start gelöscht“. Umgesetzt sind App-Start (`lib/main.dart:59`) und das nächste Teilen (`prepareShareFile`, `share_folder.dart:18`). Das PNG mit dem Foto des Nutzers kann so, solange der Prozess lebt, im Cache liegen. Das „bzw.“ lässt die Umsetzung zu; wer G7 streng liest, ruft `clearShareFolder(await getTemporaryDirectory())` in `initState` der Seite auf (nicht in `dispose`, die Ziel-App liest die Datei eventuell noch).

### N7. Zusammenziehen nur auf der Karte, Titel „Tauchgang #0“
`lib/features/logbook/share_dive_screen.dart:176-201`, `lib/features/logbook/share_card_painter.dart:157`

Die Geste hängt nur an der Karte; ui-spec §5.16 Punkt 3 sagt „auf der Vorschau“. Zwei Finger neben der Karte tun nichts (die Regler sind der Ausweg, deshalb nicht wichtig). Außerdem fällt der Titel bei fehlendem Platz **und** fehlender Nummer auf „Tauchgang #0“ (`content.number ?? 0`); die Nummer wird beim Speichern vergeben, der Fall ist kaum erreichbar, „#0“ wäre aber falsch. Vorschlag: Geste auf die ganze Vorschau legen; bei `number == null` den Titel „Tauchgang“ ohne Nummer.

## Was im Chat erklärt wurde und ins Repo gehört

Aus dem Chat war nichts bekannt; aus dem Code ergeben sich diese Punkte, die in die Spec gehören:

- **EXIF-Drehung und Fotogröße:** Die Annahme „die Engine dreht Kamerafotos beim Dekodieren richtig“ trägt T43.13, steht aber nirgends. In `security.md` G7 bzw. `tasks.md` T43.6 ergänzen (mit dem Test aus W3.6) und die Grenze für die längere Seite (N1) festhalten.
- **Karte bleibt im Bild über Anteile:** Die Lage ist ein Anteil des freien Platzes (nicht ein Pixelwert); das steht im Code und in `tasks.md`, in ui-spec §5.16 steht nur „gemerkt“. Eine Zeile zum Format `scale,opacity,x,y` dort reicht.
- **HEIC:** Ob Android HEIC dekodiert, ist offen; das Ergebnis von T43.13 in `ui-spec.md` §5.16 bei „Foto lässt sich nicht öffnen“ nachtragen.

## Befunde behoben (2026-11-27)

Vom Nutzer freigegeben: W1–W3, N1–N5, N7. N6 bleibt (laut G7 zulässig). Zu jedem Befund zuerst ein Test, rot gesehen bzw. als Absicherung sofort grün:

- [x] **W1** (rot: „RenderFlex overflowed by 328 pixels“ bei 360 × 640 und Schrift 3×): Die Vorschau behält mindestens 55 % der Höhe (wenigstens 200 dp), die Bedienelemente darunter scrollen, Beschriftungen stehen über Regler und Knöpfen. „Teilen“ bleibt unten sichtbar. Test `review W1`.
- [x] **W2** (rot: Text fehlt): Ladekreis während des Ladens, „Diesen Tauchgang gibt es nicht mehr.“ bei fehlendem Tauchgang oder Fehler. Test `review W2`.
- [x] **W3** Tests ergänzt: Ausschnitt mit drei Streifen (Mitte bleibt, Strecken oder Linksschnitt fiele auf), 50 MB direkt in `decodeSharePhoto`, Picker nur Bilder und 50 MB, EXIF-Orientierung 6 mit Fixture `test/fixtures/photos/orientation6.jpg` (kommt 200 × 400, oben rot), gesperrter Knopf mit Fortschrittskreis, vorgelesene Reglerwerte: alle sofort grün (Absicherung). Zusammenziehen auf dem Foto über der Karte: rot (nur auf der Karte möglich), siehe N7.
- [x] **N1** (rot: 4800 × 1920): auch die längere Seite höchstens 4096 px; gleicher Faktor für beide Seiten.
- [x] **N2**: Codec wird immer freigegeben, jede Ausnahme oder jeder Fehler beim Dekodieren gilt als „nicht lesbar“ (kein eigener Test, abgedeckt durch „kaputte Datei“).
- [x] **N3**: `TextPainter` werden nach dem Zeichnen freigegeben.
- [x] **N4** (rot: Achse 45 s): Zeitachse mindestens 2 min, dadurch drei Marken mit „min“ und keine Division durch 0.
- [x] **N5**: Eine Änderung vor dem Laden der gemerkten Lage wird nicht mehr überschrieben; Lesen und Speichern fangen Fehler ab (kein Test, Zeitfenster im Test nicht stabil herstellbar).
- [x] **N7** (rot): Zwei Finger überall auf der Vorschau ändern die Größe; Titel ohne Platz und Nummer „Tauchgang“ statt „Tauchgang #0“ (rot wegen `UnimplementedError` in `shareCardTitle`).
- Repo-Hinweise oben: EXIF und Größengrenzen stehen jetzt in `security.md` G7, das Format der Lage in ui-spec §5.16; HEIC wird mit T43.13 nachgetragen.
- Gesamt: `flutter test` 618/618, `flutter analyze` ohne Befund, Format sauber.

---

# Review: SAC-Stufenkurve, Ebenen, Statistik, Bedingungen (T7.3, T37 bis T40)

Datum: 2026-11-27 · Phase 60 (unabhängiges Review durch einen frischen Agenten, der die Implementierung nicht kennt)

## Umfang

- Commits `origin/main..HEAD` (Merge-Basis `4812619`) auf `claude/nice-cori-n4f6mx`: T7.3, T7.6 (zurückgestellt), T37, T38, T39, T40 samt Test-Commits, dazu zwei Doku-Commits (Roadmap, Android-Verifizierung).
- Geprüft gegen: `tasks.md` (T7, T37 bis T40), `ui-spec.md` §1, §4, §5.1, §5.3, §5.4, §5.15, §6, §7, `design.md` §2 und §6, ADR 0004, `security.md` (Backup O1). `database.g.dart` nicht zeilenweise gelesen.

## Selbst ausgeführt

| Befehl | Ergebnis |
|---|---|
| `flutter analyze` | „No issues found!“ |
| `dart format --output=none --set-exit-if-changed lib test tool integration_test` | 179 Dateien, 0 geändert, Exit 0 |
| `flutter test` | „All tests passed!“, 568 Tests grün |
| Stub-Suche (`TODO`, `FIXME`, `UnimplementedError`, Festantworten) im neuen Code | Nur der alte, absichtliche `UnimplementedError` in `appDatabaseProvider` (`lib/app/providers.dart:55`). Keine Stubs. |
| Netzwerk, Abhängigkeiten | Kein neuer Netzzugriff, keine neue Abhängigkeit, `lib/domain/` ohne Flutter/Drift-Importe. |

## Ergebnis in Kürze

Keine kritischen Befunde. Die Migration ist sicher (v1→v3 und v2→v3 über `from < 2` und `from < 3`, nur `addColumn` mit nullbaren Spalten, nichts wird kopiert oder gelöscht), `schema_v2.sql` stimmt mit dem v2-Schema (`git show origin/main:lib/data/local/tables.dart`) überein, ein v2-Backup lässt sich in der v3-App einspielen (die Datei wird beim Öffnen migriert), ein v3-Backup wird von einer v2-App abgelehnt (`logbook_backup.dart:219`). Es gibt drei wichtige Befunde (veralteter Zustand der Ebenen nach Vollbild, Statistik ohne Lade-/Fehlerzustand, Roadmap widerspricht der Release-Anleitung) und einige Kleinigkeiten.

Geprüft und in Ordnung:

- **Alle `Dive(`-Konstruktoren:** `drift_dive_repository.dart:660` (`_fromRow`), `manual_dive_draft.dart:278` (`toDive`), `imported_dive.dart:119` (frischer Import, Bedingungen gehören nur dem Nutzer) und `import_service.dart` `_replace` setzen oder behalten die neuen Felder. `copyWith` bewahrt sie. Es gibt keinen Pfad, der sie unbeabsichtigt verliert.
- **Löschen über das Formular:** `toDive` baut ein frisches `Dive` mit `visibility: visibility` (null möglich); `copyWith` wird dort nicht benutzt. Test T40.2 („danach leer“) deckt es ab.
- **`lastConditionsAt`/`_newestAtSite`:** SQL entspricht Zeile für Zeile `lastWeightAt` (Mandant, `deleted_at IS NULL`, `excludeDiveId`, Katalog-ID oder Name mit `trim().lower()`, leerer Name ohne Katalog-ID → null, Sortierung `start_local desc, dive_number desc`). Die Bedingung „mindestens eines gesetzt“ ist richtig; `kinds` wird bei leerer Menge als NULL gespeichert, nie als leerer String.
- **SAC-Abschnitte:** Mathematik stimmt (Druck linear interpoliert und an den Enden geklemmt, Umgebungsdruck aus der mittleren Tiefe des Abschnitts mit Rückfall auf das nächste Sample, letzter Abschnitt je Minute gerechnet, Δp ≤ 0 → 0). Stufenlinie in `profile_chart.dart` ist stetig gezeichnet.
- **Gemerkte Ebenen:** unbekannte Namen (z. B. `ndl`) werden übersprungen, leere Liste bleibt leer, `null` = nie gewählt. Die Ersetzung Druck→Puls greift nur, wenn Druck gewählt, nicht verfügbar und Puls nicht schon gewählt ist.
- **Statistik:** Rekorde mit „früherer gewinnt bei Gleichstand“ (Sortierung aufsteigend nach der Wanduhr-`start`, strikt `>`/`<`), Jahre über `start.year` (Wanduhr, keine Zeitzonenverschiebung), Plätze zusammengeführt ohne Groß-/Kleinschreibung, gelöschte Tauchgänge fehlen (Repository-Test T39.8), Flaschen in **einer** Abfrage (`isIn`, kein N+1). Bei 500 Tauchgängen unkritisch.

## Kritisch

Keine.

## Wichtig

### W1. Ebenen-Wahl im Detail wird nach dem Vollbild veraltet angezeigt
`lib/features/logbook/profile_chart.dart` (`_chosen`, `_layersOn`, `_toggle`; `dive_detail_screen.dart:219` öffnet das Vollbild mit `context.push`)

Verstoß gegen ui-spec §6 („Zustand wird gemerkt“, T38, „gilt auch im Vollbild“): `_toggle` setzt zusätzlich zum Provider die lokale Liste `_chosen`, und `_layersOn` bevorzugt sie immer vor dem gemerkten Wert. Da das Vollbild per `push` über dem Detail liegt, bleibt der Detail-Chart (und sein `_chosen`) am Leben. Schaltet man im Detail eine Ebene und danach im Vollbild eine andere, zeigt der Detail-Chart nach dem Zurück die alte Auswahl, während Provider und Datenbank schon die neue haben. Ein Test dafür fehlt (T38.3 prüft nur „Tauchgang B öffnen“ und Neustart).

Fix: `_chosen` entfernen; `_toggle` schreibt nur in den Provider (der Zustand wird dort synchron gesetzt, `ProfileLayersSetting.set` setzt `state` vor dem `await`), `_layersOn` liest nur `ref.watch(profileLayersProvider)`. Falls die Wahl je Tauchgang kurz „ohne Provider“ gelten soll (Fehler beim Speichern), reicht ein Fallback auf den Provider-Wert. Test: Detail → Ebene ändern → Vollbild (push) → andere Ebene → zurück → Chips müssen die Vollbild-Wahl zeigen.

### W2. Statistik-Seite ohne Lade- und Fehlerzustand
`lib/features/logbook/statistics_screen.dart:26-35`

ui-spec §4 verlangt für jede Seite Laden, Leer und Fehler mit Ausweg. `ref.watch(statisticsDivesProvider).value` ist bei Laden und bei Fehler `null`; beide zeigen eine leere Fläche (`SizedBox.shrink()`), ohne Text, ohne „Erneut versuchen“ und ohne Hinweis für Screenreader. Ein DB-Fehler sähe aus wie eine leere Seite. Auch `visitedCountriesProvider` im Ladezustand lässt die Zeile „Länder“ ohne Hinweis weg.

Fix: `AsyncValue.when` mit `CircularProgressIndicator` (mit Semantics-Label) und einem Fehlertext plus „Erneut versuchen“ (`ref.invalidate(statisticsDivesProvider)`), wie in den anderen Listen-Seiten; Test mit einem Repository, das wirft.

### W3. Roadmap und Release-Anleitung widersprechen sich
`docs/roadmap.md:13` gegen `docs/entwickler/android-release-einrichtung.md` §8

Die Roadmap nennt die Identitätsprüfung weiter als offen („ab 27.11. … (ca. 3 Werktage), dann Release-Schlüssel“), die Anleitung hakt sie am selben Tag als abgeschlossen ab (letzter Commit „Record the confirmed Play Console identity“). Die Roadmap ist die Quelle für „Was kommt als Nächstes“. Außerdem steht in beiden Dokumenten „seit September 2026 …“ als Tatsache; das lässt sich aus dem Repo nicht prüfen (Quelle oder „Stand der Recherche“ ergänzen, wie im zweiten Absatz schon getan).

Fix: Roadmap-Zeile auf „Identitätsprüfung bestätigt; nächster Schritt Release-Schlüssel (T33), dann App registrieren“ ändern.

## Nice-to-have

- **N1. Fehlende Tests (kein Befund gegen den Code, aber Lücke in der Absicherung):** (a) kein Test, der eine `.divedown`-Sicherung mit `schemaVersion: 2` in der v3-App einspielt und öffnet (T11 prüft nur `db.schemaVersion + 1`, `logbook_backup_test.dart:174`, und die Migration geschieht in T40.1 nur mit einer SQL-Datei, nicht über `restore`); (b) kein Test für die direkte Kette v1→v3 mit Daten (T30.1 prüft v1→`latestSchemaVersion` mit Ausrüstung, nicht die neuen Spalten). Beides würde ich vor dem Release als je einen kleinen Test ergänzen, weil echte Nutzer v2 haben.
- **N2. Abgeschnittene/falsch platzierte Doc-Kommentare:** `lib/features/logbook/dive_detail_screen.dart:347-349` – der Kommentar „Lead and the pieces used …“ der `_EquipmentSection` steht jetzt über `_ConditionsSection`; `lib/app/providers.dart:300-302` – „Dives of the active diver, newest first. Invalidate after changes.“ steht über `statisticsDivesProvider` statt über `logbookProvider`. Kommentare an die richtigen Klassen verschieben.
- **N3. `statisticsDivesProvider` lädt das ganze Logbuch doppelt:** `lib/app/providers.dart:303-308` beobachtet `logbookProvider` nur als Auslöser; das lädt zusätzlich alle Sparkline-Profile (`_loadProfiles`), die die Statistik nie braucht. Besser einen eigenen kleinen Zähler/Versions-Provider invalidieren oder dort, wo das Logbuch invalidiert wird, auch die Statistik invalidieren.
- **N4. Gemerkte Ebenen gehen beim Umschalten verloren:** `profile_chart.dart` `_toggle` baut die neue Liste aus `_layersOn(...)`, das nur Ebenen dieses Tauchgangs enthält. Hat man „Puls“ gewählt und schaltet bei einem Tauchgang ohne Puls „Temperatur“ aus, wird „Puls“ aus der gemerkten Wahl gestrichen. Spec sagt dazu nichts Klares; wenn die Wahl „für alle Tauchgänge“ gilt, sollte `_toggle` nicht verfügbare gemerkte Ebenen mitschleppen.
- **N5. SAC-Stufen werden bei jedem Zeichnen neu berechnet:** `profile_chart.dart` ruft `SacCalculator().segments(dive)` im Painter bei jedem Frame (Ziehen des Cursors). `depthIn` filtert je Abschnitt alle Samples (O(Samples × Minuten)); bei 3600 Samples und 60 Minuten unkritisch, bei sehr langen Aufzeichnungen (100000 Samples erlaubt) spürbar. Ergebnis einmal beim Laden der Daten (`_loadData`) berechnen und dem Painter übergeben.
- **N6. Statistik-SAC ohne Samples:** `listWithTanksForDiver` lädt keine Samples; `SacCalculator.average` fällt dann bei fehlendem `avgDepthM` auf `SacMissing.depth` zurück (`sac_calculator.dart:50`). Die Importe setzen `avgDepthM` fast immer, aber ein von Hand erfasster Tauchgang ohne mittlere Tiefe fehlt im Luftverbrauch-Verlauf. Dokumentieren oder die mittlere Tiefe bei Bedarf aus der Maximaltiefe schätzen (nur wenn die Spec es will).
- **N7. Tote Farbe:** `DiveColors.ndl` (`lib/app/theme.dart:151`) hat keinen Verbraucher mehr; ui-spec §1 behält das Token ausdrücklich, daher nur zur Kenntnis.
- **N8. Kachel-Semantik im Logbuch:** `logbook_screen.dart:502` legt `Semantics(button: true, label: 'Statistik öffnen')` um beide Kacheln; die Kindtexte werden dazugemischt („Statistik öffnen, 12, Tauchgänge …“). Gewollt laut Spec, aber mit `excludeSemantics` oder `mergeAllDescendants` klarer.

## Korrekturen an bestehenden Tests – gerechtfertigt?

- `equipment_data_test.dart` (T30.1, `user_version` 2 → `AppDatabase.latestSchemaVersion`): gerechtfertigt, der Test prüft „läuft auf die neueste Version hoch“; mit der Konstante bricht er bei v4 nicht wieder.
- Fenster 2400 px in `equipment_dive_test.dart`: gerechtfertigt, das Formular ist um drei Chipreihen länger.
- `_site`-Unfocus-Helfer (Bedingungs-Test): gerechtfertigt, die Tastatur-/Vorschlagslogik des Tauchplatzfelds würde sonst die Chips verdecken; ändert keine Aussage.
- `heart_rate_test.dart`, `welcome_test.dart`, `profile_chart_test.dart`: reine Anpassungen an die in T37/T38 beschlossenen Texte.

## Szenarien ohne Test

Alle Szenarien T7.3, T37.1–3, T38.1–6, T39.1–8, T40.1–8 haben einen Test. Nicht abgedeckt (siehe W1, N1): Vollbild-Wechsel der Ebenen, v2-Sicherung wiederherstellen, v1→v3 mit Daten, Statistik-Fehlerzustand. Keine der Tests ist trivial grün (die Task-Notizen belegen je einen roten Lauf).

## Was gehört ins Repo (Frage 6 der Skill)

Beurteilbar nur aus dem Repo, nicht aus dem Chat: Die Entscheidungen zu T7.6 (zurückgestellt), T37 (NDL entfällt), der Schema-Sprung v3 und die Statistik-Regeln stehen in `tasks.md`/`ui-spec.md`. Es fehlt (a) ein Hinweis in `docs/adr/0004-lokales-datenmodell.md` bzw. `design.md`, dass das Schema auf v3 steht und die Spalten `visibility`, `current_strength`, `kinds` (Namen, `kinds` kommagetrennt) heißen – bisher nur in `tasks.md` und im Code, (b) die Regel „Schemaänderung = Fixture `schema_vN.sql` + Migrationstest“ als Konvention (steht nur im Kopf der Fixture-Datei), (c) die Quelle für die Android-Verifizierungsfrist.

---

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
