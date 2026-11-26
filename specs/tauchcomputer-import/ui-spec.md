# UI-Spezifikation: DiveDown 1.0

> Phase 30 · Stand: 2026-11-22 · Status: **abgenommen (2026-11-18)**, Mockups: https://claude.ai/artifact/7LP8HdXzTK33X75euzkU9X
> **Änderung 2026-11-22c (abgenommen 2026-11-22):** Sichern/Wiederherstellen für einen Taucher, Texte ergänzt (§5.2, §5.12).
> **Änderung 2026-11-22b (abgenommen 2026-11-22):** ein Taucher pro App, Einstellungen neu (§2, §5.2, §5.5, §5.9, §5.11).
> **Änderung 2026-11-22 (abgenommen 2026-11-22):** neuer Stil „Riff“ nach dem Rundgang am Handy (§1, §5.2, §5.3, §6). Entwurf: https://claude.ai/artifact/GUDfte5Mocx1SPnTG478RQ
> Grundlage: `design.md`, `security.md` (§10 Checkliste Phase 30), `docs/roadmap.md` (Muss-Umfang 1–9)
> DiveMate und Submersion dienen nur als Ablauf-Vorbild. Layout, Farben, Icons und Texte gestalten wir selbst.

## 1. Visueller Stil

**Leitidee „Riff“ (seit 2026-11-22, ersetzt „Tiefe“):** hell und freundlich wie klares Wasser über dem Riff, abgerundete Karten, eine kräftige runde Schrift.
Der Tiefenverlauf bleibt das zentrale Motiv (Sparkline im Logbuch, Profil im Detail). Farbe trägt Bedeutung und ist keine Dekoration.
Gewählt aus zwei Entwürfen („Tiefsee“ dunkel, „Riff“ hell) am 2026-11-22. Der helle Modus ist der Hauptmodus, der dunkle folgt derselben Logik.

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| `surface` | `#F2F8F8` | `#0D1E22` | Hintergrund |
| `surfaceRaised` | `#FFFFFF` | `#15292F` | Karten, Kacheln, Werte-Feld unter dem Diagramm |
| `surfaceTint` | `#DDEFF0` | `#123139` | nur Fläche (Verlauf im Detail-Kopf); darauf nur Text in `onSurface` |
| `outline` | `#D6E7E8` | `#21393F` | Kartenränder, Trennlinien, Gitter |
| `onSurface` | `#13303A` | `#E3F1F2` | Text |
| `onSurfaceMuted` | `#55727A` | `#9BB5BA` | Nebentext |
| `primary` | `#0B7A80` | `#4CC9CE` | Aktionen, aktive Navigation, Nummern, Tiefenkurve |
| `accent` | `#B9412A` | `#FF8D6E` | Koralle: Knopf „Manuell eintragen“, Luft im Diagramm |
| `depth` | = `primary` | = `primary` | Tiefenkurve, Sparkline |
| `temperature` | `#A35C00` | `#F2B14C` | Temperaturkurve (Bernstein) |
| `pressure` | = `accent` | = `accent` | Flaschendruck / Luft |
| `sac` | `#6D4BC4` | `#B49BFF` | SAC-Kurve (nur mit gemessenem Druck) |
| `ndl` | `#3B5BCC` | `#8FA8FF` | NDL-Band |
| `warning` | `#9A5B00` | `#F5B83D` | Hinweise, mögliches Duplikat |
| `error` | `#B42318` | `#FF8A80` | Fehler |

- **Kontrast nachgerechnet (WCAG 2.1, 2026-11-22):** Alle Text- und Kurvenfarben erreichen auf `surface` und `surfaceRaised` **mindestens 4,5:1**, in beiden Themes. Knappste Werte hell: `primary` 4,76:1 und `temperature` 4,78:1 auf `surface`. Weiß auf `primary` 5,11:1, Weiß auf `accent` 5,45:1; dunkel `surface` auf `primary` 8,61:1 und auf `accent` 7,58:1. Auf `surfaceTint` liegt nur `onSurface`.
- **Design:** eigenes Theme auf Basis von Material 3 (`ColorScheme` aus den Tokens), kein Standard-Blau oder -Lila. Die App folgt der Systemeinstellung (hell/dunkel), änderbar in den Einstellungen.
- **Schrift:** **Manrope** (SIL Open Font License 1.1, GPL-3-verträglich), als Datei in der App mitgeliefert, nichts wird aus dem Netz geladen. Gewichte 500, 600, 700, 800. Ziffern mit **gleicher Breite** (`FontFeature.tabularFigures`).
  Skala: Titel 30 sp/800 · Nummer im Detail 44 sp/800 · Kennzahl 21 sp/800 · Tiefe in der Liste 28 sp/800 · Tauchplatz 16–19 sp/700 · Text 14–16 sp/500 · Nebentext 12,5 sp/500 · kleine Abschnittsüberschriften 12 sp/700 in Großbuchstaben mit 1 sp Laufweite.
- **Icons:** Material Symbols Rounded. Das App-Icon ist eigenes Design.
  **Seit 2026-11-23: Variante D „Brille mit Clownfisch“** (ersetzt die „Tiefenkurve“ vom 2026-11-18, T29): Einglas-Maske mit Rahmen `#13303A`, Glas und Band `primary` `#0B7A80` auf `surface` `#F2F8F8`; im Glas spiegelt sich ein Clownfisch (`#F26B1D`, weiße, dunkel umrandete Streifen), dazu ein Lichtstreifen und drei Luftblasen in `primary`. Vorlagen in `assets/icon/` (Raster 160, als 1024 px):
  - `divedown_icon.svg`: iOS und Größen ab 60 px
  - `divedown_icon_small.svg`: unter 60 px, ohne Umrisse, Lichtstreifen und kleinste Blase
  - `divedown_icon_android_foreground.svg`: Vordergrund des adaptiven Android-Icons, Motiv auf 76 % verkleinert, Hintergrund `#F2F8F8`; in der App als Vektor `res/drawable/ic_launcher_foreground.xml` plus einfarbige Ebene (Silhouette mit ausgespartem Glas) für Themen-Icons

  Die PNG-Größen (iOS, alte Android-Launcher) zeichnet `tool/render_app_icons.py` (Pillow, nur auf dem PC) aus denselben Pfaden; sie sind eingecheckt.
- **Ecken** 20 dp für Karten, 14 dp für Kacheln, Chips und Knöpfe ganz rund. Karten haben einen Rand in `outline` statt Schatten, nur der Knopf „Manuell eintragen“ hat einen Schatten. **Abstände** im 8-dp-Raster, **Touch-Ziele mindestens 48 dp**. Hauptaktionen bekommen 56 dp, damit man sie auch mit nassen Fingern trifft.
- **Bedeutung nie nur durch Farbe:** Jede Kurve hat zusätzlich ein Icon bzw. Label in der Legende, Fehler zusätzlich ein Icon und Text.

## 2. Navigation

```
Start (erste Nutzung) → Taucher anlegen
                         │
┌────────────────────────▼─────────────────────────────┐
│  Untere Navigationsleiste                             │
│  [ Logbuch ]      [ + Importieren ]   [ Einstellungen ]│
└──────────────────────────────────────────────────────┘
Logbuch → Tauchgang-Detail → (Bearbeiten | Profil Vollbild)
Logbuch → FAB „Manuell eintragen“ → Formular
Importieren → Tauchcomputer | FIT-Datei | Apple Health (nur iOS)
Einstellungen → Taucher · Ausrüstung · Geräte · Einheiten · Darstellung · Logbuch sichern · Wiederherstellen · Diagnose-Logs · Über & Lizenzen
```

- **Ein Taucher pro App (Entscheidung 2026-11-22):** Mehrere Taucher werden nicht gebraucht. Es gibt keinen Taucher-Wechsel, kein Anlegen oder Löschen weiterer Taucher. Der beim ersten Start angelegte Taucher lässt sich in den Einstellungen umbenennen. Das Datenmodell behält `diverId` (ADR 0004), damit ein späterer Ausbau möglich bleibt.
- Geteilte Dateien („Teilen → DiveDown“) öffnen direkt die **FIT-Vorschau** (§5.6).

## 3. Einheiten
Einstellung: **metrisch** (Standard) oder **imperial**, dazu einzeln umstellbar: m/ft, bar/psi, °C/°F, l/cuft.
Gespeichert wird immer in SI (ADR 0004). Formatierung zentral (`UnitFormatter`), Dezimaltrennzeichen nach `de`: `18,4 m`.

## 4. Gemeinsame Zustände (gelten für alle Bildschirme)
| Zustand | Darstellung |
|---|---|
| **Laden < 300 ms** | nichts anzeigen, damit nichts flackert |
| **Laden > 300 ms** | Skeleton-Platzhalter in der Form des Inhalts, kein Vollbild-Spinner |
| **Fehler (unerwartet)** | Karte mit Icon, kurzer Ursache, **„Erneut versuchen“** und **„Logs an Entwickler senden“** (öffnet §5.13) |
| **Offline** | **Kein eigener Zustand.** Version 1.0 braucht kein Netz, also zeigt die App auch keinen Offline-Hinweis. |
| **Sync ausstehend/Konflikt** | Entfällt in v1.0 (kein Sync). Kommt mit dem Sync-Feature. |
| **Speicher voll** | Dialog: „Nicht genug Speicherplatz. Gib Speicher frei und versuch es erneut.“ Die Daten bleiben unverändert. |
| **Tastatur offen** *(neu 2026-11-26, T36)* | Die Hauptaktion einer Seite („Speichern“, „Mail vorbereiten“) bleibt über der Tastatur sichtbar und antippbar. Wischen über die Seite schließt die Tastatur (unter iOS gibt es bei mehrzeiligen Feldern keine Taste dafür). |
| **Große Schrift (bis 200 %)** | Layouts brechen um statt abzuschneiden. Kennzahlen-Raster wird einspaltig. |

## 5. Bildschirme

### 5.1 Erster Start: Taucher anlegen
**Ablauf:** Begrüßung → Name (Pflicht) → optional Farbe/Avatar-Initialen → Einheiten (metrisch/imperial) → fertig → leeres Logbuch.
- Texte: Titel „Willkommen bei DiveDown“ · „Wer taucht? Du kannst später weitere Taucher hinzufügen.“ · Feld „Name“ · Knopf **„Los geht’s“**
- Hinweis klein: „Alle Daten bleiben auf diesem Gerät.“
- Zustände: Name leer → Knopf deaktiviert, mit Hinweis „Bitte gib einen Namen ein.“

### 5.2 Logbuch (Liste)
**Kopf** (Änderung 2026-11-22): Titel „Logbuch“. Kein Avatar (ein Taucher pro App, §2).
Darunter **zwei Kacheln** für den aktiven Taucher: **Anzahl Tauchgänge** und **Zeit unter Wasser** (Summe der Dauer; ab 10 h als „61 h“, darunter als „7 h 40 min“). Kein „tiefster Tauchgang“ (Wunsch vom 2026-11-22).

**Inhalt pro Eintrag** als Karte (`surfaceRaised`, Rand `outline`, 20 dp Ecken):
1. oben links die **Tauchgangsnummer** `#42`, 15 sp, extra fett, in `primary`
2. darunter der **Tauchplatz-Name**: 16 sp, 600, einzeilig, sonst mit „…“ abgeschnitten. Ohne Tauchplatz in `onSurfaceMuted` kursiv „Ohne Tauchplatz“.
3. darunter klein: Quelle als Icon (Tauchcomputer / Datei / Watch / Hand) · Datum · Startzeit · Dauer
4. rechts über zwei Zeilen: **max. Tiefe** groß (28 sp, 800, Einheit klein in `onSurfaceMuted`)
5. unten über die ganze Breite das **Mini-Tiefenprofil** (Sparkline, 34 dp hoch, Fläche `depth` mit 18 % Deckkraft). Manuell erfasste Tauchgänge ohne Samples zeigen das geschätzte Rechteckprofil gestrichelt.

Monatsüberschrift fett in `onSurfaceMuted` mit etwas Laufweite, neuester oben. Bei großer Schrift (über 130 %) steht die Tiefe unter dem Text statt daneben. FAB **„Manuell eintragen“** in `accent`.

| Zustand | Darstellung / Text |
|---|---|
| leer | Illustration (eine einfache Welle) · „Noch keine Tauchgänge“ · „Importiere vom Tauchcomputer oder trage einen Tauchgang von Hand ein.“ · Knöpfe **„Importieren“** und **„Manuell eintragen“** |
| ladend | 6 Skeleton-Zeilen |
| Erfolg | Liste |
| zu viele Daten (> 500) | Lazy-Liste, Monatsüberschriften bleiben beim Scrollen oben, Schnellscroll-Leiste mit Jahr und Monat |
| nach Import | Die Liste scrollt zum neuesten importierten Eintrag. Neue Einträge haben 3 s lang den Hintergrund `surfaceTint`, einen 4 dp breiten Rand links in `primary` und das Etikett **„Neu“** neben der Nummer; danach blenden sie in 600 ms auf normal über (mit „Animationen reduzieren“ ohne Überblendung). Vorgelesen: „Neu importiert“. Snackbar: „3 Tauchgänge importiert“. *(Ausgestaltet 2026-11-23, T32.)* |
| Sicherungs-Erinnerung (> 30 Tage) | Dezente Karte oben: „Letzte Sicherung vor 34 Tagen.“ bzw. ohne Sicherung „Noch keine Sicherung.“ · **„Jetzt sichern“** (öffnet „Logbuch sichern“) · ✕ „Erinnerung ausblenden“ (für 7 Tage). Gezählt wird ab der letzten Sicherung, ohne Sicherung ab dem ersten Start der App; ohne Tauchgänge keine Karte. |

### 5.3 Tauchgang-Detail
**Aufbau (Hochformat, Änderung 2026-11-22):**
1. **Kopf** auf einem Verlauf von `surfaceTint` nach `surface`: **Nummer groß** (`#42`, 44 sp, 800, `primary`; vorgelesen als „Tauchgang 42“) · darunter **Tauchplatz** (19 sp, 700; leer → Link „Tauchplatz hinzufügen“) · darunter klein Datum, Uhrzeit, Taucher, Quelle mit Modell und Kurzkennung (z. B. „Suunto EON Core ••3F7A“; bisher stand dort nur „Tauchcomputer“)
2. **Kennzahlen-Raster**, 3 Spalten gleicher Höhe: max. Tiefe · Dauer · Ø-Tiefe · Wasser (min. Temperatur) · Gas (z. B. „EAN32“) · Flasche (Volumen, darunter klein Start → Ende in bar). Darunter über die volle Breite **Ø-SAC** mit Herkunft: „gemessen“ oder „geschätzt aus 200 → 60 bar“.
3. **Profil-Diagramm** (§6) mit Chips darüber und dem **Werte-Feld** darunter, Knopf „Vollbild“
4. **Ereignisse** als kompakte Liste: Zeit · farbiger Punkt (Warnungen `error`, sonst `primary`) · deutscher Text. Gleiche Ereignisse innerhalb von 60 s werden zusammengefasst („Sicherheitsstopp 3×“). Jeder Ereignistyp hat einen deutschen Text (z. B. `deepstop` → „Tiefenstopp“), unbekannte Typen „Ereignis“ plus Code.
5. **Ausrüstung** *(neu 2026-11-23, T31)*: Abschnitt mit kleiner Überschrift „AUSRÜSTUNG“. Erste Zeile **„Blei 6 kg“** (fehlt der Wert: „Blei —“), darunter die zugeordneten Teile als Chips mit Icon der Art. Gelöschte Teile erscheinen weiter, in `onSurfaceMuted`. Ohne Blei und ohne Teile entfällt der Abschnitt.
6. Flaschen (falls mehrere), Notizen, Bewertung (1–5 Sterne)
- Aktionen in der App-Leiste: **Bearbeiten**, Menü: „Löschen“

| Zustand | Darstellung |
|---|---|
| keine Samples (manuell) | Statt Diagramm: vereinfachtes Rechteckprofil aus Tiefe und Dauer, gestrichelt, Hinweis „Geschätztes Profil“ |
| kein Druck | Kennzahl „Druck“ zeigt „—“, SAC zeigt „—“ und ein Info-Icon: „Für den Luftverbrauch werden Flaschendruck und Flaschengröße benötigt.“ |
| Druck, aber keine Flaschengröße | SAC „—“ und der Link **„Flaschengröße eintragen“** |
| Apple Watch | Kein Druck, kein SAC. Dafür eine Pulskurve als zuschaltbare Ebene. |
| Löschen | Dialog: „Tauchgang löschen?“ · **„Löschen“** (rot) / „Abbrechen“. Danach Snackbar mit **„Rückgängig“** für 5 s (Soft Delete macht das möglich). Geändert am 2026-11-20: Der Satz „Das kann nicht rückgängig gemacht werden.“ ist entfallen, weil er der Snackbar widersprach. |

### 5.4 Manuell eintragen / Bearbeiten
Felder: **Nr.** (vorbelegt mit der nächsten freien Nummer, änderbar), **Tauchplatz** (Freitext mit Vorschlägen: zuerst eigene Namen, dann der mitgelieferte Katalog mit „Name · Region, Land“. Eine Zeile „‚…‘ als neuen Tauchplatz verwenden“ gibt es immer, siehe ADR 0006), Datum*, Startzeit*, Dauer* (min), max. Tiefe*, Ø-Tiefe, Wassertemp., Flasche (Volumen, Start-/Enddruck, O₂-Anteil), **Blei (kg)**, **Ausrüstung**, Wassertyp (Salz/Süß), Notizen, Bewertung.
- **Blei** *(neu 2026-11-23, T31)*: Zahlenfeld in kg (0–40, Komma erlaubt, auf 0,5 gerundet angezeigt), Fehlertext „Blei muss zwischen 0 und 40 kg liegen.“. Gibt es einen früheren Tauchgang am selben Platz mit Blei (ADR 0007), steht unter dem Feld „Zuletzt bei Elphinstone: 6 kg“ mit dem Textknopf **„Übernehmen“**; die Zeile verschwindet, wenn das Feld schon diesen Wert hat. Sie aktualisiert sich, sobald der Tauchplatz geändert wird.
- **Ausrüstung** *(neu 2026-11-23, T31)*: alle nicht gelöschten Teile als Filter-Chips (48 dp hoch, mit Icon der Art), mehrfach wählbar. Neuer Tauchgang: die Standard-Teile sind vorausgewählt. Bearbeiten: die zugeordneten Teile; ein inzwischen gelöschtes, aber zugeordnetes Teil erscheint als ausgewählter Chip in `onSurfaceMuted` und kann abgewählt werden. Ohne Ausrüstung: „Noch keine Ausrüstung. Lege sie in den Einstellungen an.“ mit Link **„Ausrüstung anlegen“**.
`*` = Pflicht.
- Validierung inline, mit denselben Grenzen wie die Plausibilitätsprüfung (security.md G1):
  „Tiefe muss zwischen 0 und 350 m liegen.“ · „Der Enddruck muss kleiner als der Startdruck sein.“ · „Das Datum darf nicht in der Zukunft liegen.“
- Zahlenfelder mit Ziffern-Tastatur.
- Speichern: **„Speichern“** (Pflichtfelder fehlen → Fokus springt zum ersten Fehler).
- Verlassen mit Änderungen: „Änderungen verwerfen?“ · **„Verwerfen“** / „Weiter bearbeiten“

### 5.5 Importieren (Quelle wählen)
Drei große Karten (je 88 dp hoch):
1. **Tauchcomputer** · „Per Bluetooth übertragen“ · Untertitel mit bekannten Geräten: „Zuletzt: EON Core, vor 3 Tagen“
2. **FIT-Datei** · „Datei aus der Suunto-App oder Garmin“ · darunter klein: **„So exportierst du aus der Suunto-App“** (öffnet eine kurze Anleitung in 3 Schritten)
3. **Apple Health** · „Tauchgänge der Apple Watch“ (nur iOS, unter Android ausgeblendet)

Oben: kein Hinweis auf den Taucher (ein Taucher pro App, §2).

### 5.6 Tauchcomputer: Suche und Auswahl
**Ablauf:** Rechte prüfen → Scan startet automatisch (max. 30 s) → Liste der gefundenen Geräte → antippen → Download (§5.7).

Pro Gerät: Name · Modell (falls erkannt) · Kennzeichnung **„Bekannt“**, wenn es bereits gekoppelt war.
*(Änderung 2026-11-20: Die Signalstärke entfällt in 1.0, weil das Plugin keinen RSSI-Wert an Dart weitergibt. Sie käme mit einer Änderung der Pigeon-Schnittstelle.)*
Vor der Suche ein kleiner Hinweis: „Aktiviere Bluetooth am Tauchcomputer: EON Core → Einstellungen → Verbindungen → Koppeln.“ Die Hilfe ist pro Modell hinterlegt, zunächst nur für die EON Core.

| Zustand | Text / Aktion |
|---|---|
| Bluetooth aus | „Bluetooth ist ausgeschaltet.“ · **„Bluetooth einschalten“** (Android: System-Dialog; iOS: Hinweis auf Kontrollzentrum) |
| Berechtigung noch nicht erteilt | Vorab-Erklärung: „DiveDown braucht Bluetooth, um Tauchgänge von deinem Tauchcomputer zu laden. Es werden keine anderen Geräte gespeichert.“ · **„Weiter“** → System-Dialog |
| Berechtigung verweigert | „Ohne Bluetooth-Berechtigung kann DiveDown keine Tauchcomputer finden.“ · **„Einstellungen öffnen“** |
| Suche läuft | Animiertes Radar-Icon (mit „Bewegung reduzieren“ nur statisch), „Suche nach Tauchcomputern …“ und Knopf „Stopp“ |
| nichts gefunden (30 s) | „Kein Tauchcomputer gefunden.“ + Checkliste: „Ist Bluetooth am Tauchcomputer aktiv?“ · „Liegt der Tauchcomputer nah am Handy?“ · „Schließe die Suunto-App ganz. Sie hält sonst die Verbindung zum EON Core, auch im Hintergrund.“ · **„Erneut suchen“** |
| Gerät nicht unterstützt | Eintrag ausgegraut: „Dieses Modell wird nicht direkt unterstützt.“ Bei **Suunto Ocean / Nautic** zusätzlich: „Nutze den Import per FIT-Datei.“ → **„Zur FIT-Anleitung“** |
| PIN nötig | Dialog: „**EON Core (••3F7A)** fragt nach einem Code. Gib den Code ein, der auf dem Tauchcomputer angezeigt wird.“ · Feld (Ziffern) · **„Bestätigen“** / „Abbrechen“ (60 s Zeitlimit, danach „Zeit abgelaufen. Bitte erneut verbinden.“) |
| **Seriennummer weicht ab** (security A1) | Nach der Übertragung, **vor** der Vorschau. Warnung: „Dieses Gerät meldet eine andere Seriennummer als dein gespeicherter ‚EON Core‘. Wenn du das Gerät nicht kennst, brich ab.“ · **„Abbrechen“** (primär) / „Als neues Gerät verwenden“ |

### 5.7 Tauchcomputer: Übertragung
- Fortschrittsbalken (bestimmt, wenn das Plugin `DownloadProgress` liefert, sonst unbestimmt) und „**3 neue Tauchgänge** gefunden …“
- Hinweis: „Halte den Tauchcomputer in der Nähe. Das kann einige Minuten dauern.“
- Bildschirm bleibt während der Übertragung an.
- Knopf **„Abbrechen“**

| Zustand | Text / Aktion |
|---|---|
| keine neuen Tauchgänge | „Alles auf dem neuesten Stand. Keine neuen Tauchgänge auf dem Tauchcomputer.“ · **„Fertig“** |
| Verbindung abgebrochen | „Die Verbindung wurde unterbrochen.“ Sind schon Tauchgänge da, kommt zusätzlich: „**2 Tauchgänge** wurden übertragen.“ (Die Gesamtzahl ist unbekannt: der Fortschritt des Plugins zählt Bytes, nicht Tauchgänge. Er treibt den Balken.) · **„Übertragene prüfen“** · **„Erneut verbinden“** · „Logs senden“ |
| Abbruch durch Nutzer | „Übertragung abgebrochen.“ Bereits übertragene Tauchgänge gehen in die Vorschau. |
| unbekannter Fehler | wie §4 Fehler, mit Fehlercode klein darunter |
| Erfolg | weiter zur Vorschau (§5.9) |

### 5.8 FIT-Datei
**Ablauf:** Datei wählen (System-Dialog) bzw. per „Teilen“ empfangen → Prüfen (Header, Größe) → Vorschau (§5.9).

| Zustand | Text |
|---|---|
| Prüfen läuft | „Datei wird gelesen …“ (unbestimmt, max. 30 s) |
| zu groß (> 10 MB) | „Die Datei ist zu groß (max. 10 MB).“ |
| keine FIT-Datei / beschädigt | „Diese Datei konnte nicht gelesen werden. Ist es eine FIT-Datei aus der Suunto- oder Garmin-App?“ · „Logs senden“ |
| FIT, aber kein Tauchgang | „Die Datei enthält keinen Tauchgang (sondern z. B. Laufen oder Radfahren).“ |
| Zeitüberschreitung | „Das Lesen hat zu lange gedauert. Die Datei ist möglicherweise beschädigt.“ |
| Anleitung Suunto | 3 Schritte mit Text: 1. „Öffne die Suunto-App und wähle den Tauchgang.“ 2. „Tippe auf ⋯ → ‚Exportieren‘ bzw. ‚Teilen‘ und wähle FIT.“ 3. „Wähle DiveDown oder speichere die Datei und öffne sie hier.“ *(Die Schritte werden mit der echten Suunto-App geprüft, bevor wir sie festlegen.)* |

### 5.9 Import-Vorschau (für alle Quellen)
Liste der gefundenen Tauchgänge, alle vorausgewählt (Checkbox, 48 dp). Pro Eintrag: Datum, Uhrzeit, max. Tiefe, Dauer, Sparkline.
Oben: Quelle. Bei Dateien zusätzlich der Dateiname (security A2).
Die Vorschau zeigt die **Nummern, die die Tauchgänge bekommen** (z. B. „#43“). Unter der Liste steht die Aktion **„Tauchplatz für Ausgewählte setzen“**, weil Tauchcomputer, FIT und Apple Health keinen Tauchplatz-Namen mitliefern. Vorschläge kommen aus bereits verwendeten Namen und dem Tauchplatz-Katalog (ADR 0006).
Die Aktion öffnet ein Blatt von unten: Titel „Tauchplatz für 2 Tauchgänge“, das Tauchplatz-Feld mit Vorschlägen wie in §5.4, Knopf **„Übernehmen“** (gesperrt, solange das Feld leer ist) und, wenn ein ausgewählter Tauchgang schon einen Platz hat, **„Tauchplatz entfernen“**. Danach steht der Platz mit Ort-Icon unter Tiefe und Dauer des Eintrags. Ohne Auswahl ist die Aktion gesperrt. Ersetzt ein geänderter Tauchgang einen vorhandenen, bleibt dessen Platz; der neue füllt nur einen leeren. *(Ergänzt 2026-11-23, T25.)*
Knopf unten: **„3 Tauchgänge importieren“**, die Zahl passt sich an die Auswahl an.

| Zustand | Darstellung |
|---|---|
| mögliches Duplikat | Eintrag mit `warning`-Markierung: „Ähnlicher Tauchgang vorhanden (12.08., 18,4 m, 47 min)“. Standardmäßig **nicht** ausgewählt, mit der Aktion **„Vergleichen“**: Blatt „Tauchgänge vergleichen“ mit Spalten „Neu“ und „Im Logbuch“ (Datum, Startzeit, Quelle, max. Tiefe, Dauer, Ø-Tiefe, Wassertemp.; abweichende Werte fett) und beiden Profilen in einem Diagramm (neu `depth` als Fläche, vorhandener als `accent`-Linie, gemeinsame Achsen; die Spaltenköpfe mit Farbmuster sind die Legende). Unten **„Importieren“** (wählt aus) und **„Nicht importieren“** (wählt ab). *(Ausgestaltet 2026-11-23, T26.)* |
| exaktes Duplikat (gleiche Quelle + ID, gleicher Inhalt) | ausgegraut: „Bereits im Logbuch“, nicht auswählbar |
| gleiche ID, anderer Inhalt | wie mögliches Duplikat, Text: „Gleiche Kennung, aber abweichende Daten“ |
| ungültige Werte verworfen | Info-Zeile: „Bei 1 Tauchgang wurden unplausible Messwerte entfernt.“ |
| nichts ausgewählt | Knopf deaktiviert: „Nichts ausgewählt“ |
| Speichern läuft | Knopf zeigt Fortschritt. Zurück ist erst danach möglich. |
| Erfolg | Zurück zum Logbuch, Snackbar (§5.2) |

### 5.10 Apple Health (nur iOS)
**Ablauf:** Vorab-Erklärung → Health-Berechtigung (System) → Zeitraum wählen (Standard: „Seit letztem Import“ bzw. „Letzte 12 Monate“) → Suche → Vorschau (§5.9).
- Vorab-Text: „DiveDown liest Tauchgänge deiner Apple Watch aus Apple Health: Tiefe, Wassertemperatur und Puls. DiveDown schreibt nichts in Apple Health.“

| Zustand | Text |
|---|---|
| ~~Berechtigung verweigert~~ | *Entfällt (abgenommen 2026-11-26, T6):* iOS teilt einer App nicht mit, ob der Lesezugriff verweigert wurde, es kommen dann einfach keine Daten. Der Hinweis wandert in „keine Tauchgänge“. |
| keine Tauchgänge | „Keine Tauchgänge im gewählten Zeitraum gefunden.“ + Hinweis: „Tauchgänge werden von der Apple Watch Ultra mit der App ‚Tiefe‘ oder einer Tauch-App aufgezeichnet.“ · *neu:* „Fehlt der Zugriff? Erlaube ihn in der Health-App → Profil → Apps → DiveDown.“ |
| iOS 15 *(neu, abgenommen 2026-11-26)* | Kachel „Apple Health“ deaktiviert, darunter „Benötigt iOS 16 oder neuer.“ (Tiefe und Wassertemperatur gibt es in Apple Health erst ab iOS 16) |
| Hinweis Tiefe | klein: „Apple Health erfasst Tiefen nur bis ca. 40 m.“ |

### 5.11 Einstellungen
Gruppen:
Gruppen als Abschnitte mit kleiner Überschrift in Großbuchstaben (Stil „Riff“, §1). Neu gefasst am 2026-11-22.
1. **Taucher** (ein Taucher pro App, §2):
   - **Name**: zeigt den Namen, Antippen öffnet einen Dialog „Name ändern“ (Pflichtfeld, wie §5.1) · **„Speichern“** / „Abbrechen“.
   - **„Nummerierung beginnt bei“**: zeigt die Startnummer, Antippen öffnet einen Dialog mit Zahlenfeld (1–9999). Gibt es schon Tauchgänge, fragt die App vorher: „Nummern verschieben? Aus #1–#42 werden #101–#142.“ · **„Verschieben“** / „Abbrechen“. Alle Nummern des Tauchers verschieben sich um die Differenz.
   - **„Nummern nach Datum neu vergeben“**: Dialog „Alle Tauchgänge nach Datum neu nummerieren? Der älteste bekommt #101.“ (die Startnummer) · **„Neu nummerieren“** / „Abbrechen“. Danach Snackbar „73 Tauchgänge neu nummeriert“. Nur sichtbar, wenn die Reihenfolge der Nummern nicht schon der Reihenfolge nach Datum entspricht. Importe vergeben weiterhin die nächste freie Nummer, neu nummeriert wird nur auf Wunsch (Entscheidung 2026-11-22).
2. **Ausrüstung** *(neu 2026-11-23, T30, ADR 0007)*: Liste der Teile, sortiert nach Art (Reihenfolge wie unten) und Bezeichnung. Pro Zeile Icon der Art, **Bezeichnung**, darunter klein die Art und gegebenenfalls das Etikett **„Standard“**. Antippen öffnet „Ausrüstung bearbeiten“. Letzte Zeile **„+ Ausrüstung hinzufügen“**. Ohne Teile: „Noch keine Ausrüstung. Standard-Teile werden neuen Tauchgängen automatisch zugeordnet.“
   - **Formular** (eigene Seite, Titel „Ausrüstung hinzufügen“ bzw. „Ausrüstung bearbeiten“): **Art*** als Auswahl ohne Vorgabe (Anzug · Jacket · Atemregler · Tauchcomputer · Flasche · Maske · Flossen · Lampe · Sonstiges; Fehler „Bitte eine Art wählen.“), **Bezeichnung*** (z. B. „Scubapro Hydros Pro“, höchstens 60 Zeichen, Fehler „Bitte eine Bezeichnung eingeben.“), **Notiz**, Schalter **„Standard“** mit Untertitel „Neue Tauchgänge bekommen dieses Teil automatisch.“ · **„Speichern“**. Verlassen mit Änderungen wie §5.4.
   - **Löschen** (nur beim Bearbeiten, Menü): „Hydros Pro löschen? Bei bisherigen Tauchgängen bleibt es eingetragen.“ · **„Löschen“** (rot) / „Abbrechen“.
3. **Geräte:** bekannte Tauchcomputer als Liste: „Suunto EON Core ••CC2D“, darunter „Zuletzt: 13.11.2026“ (Datum des neuesten Tauchgangs von diesem Gerät, sonst „Noch keine Tauchgänge“). Menü „Vergessen“ → Dialog „EON Core vergessen? Beim nächsten Übertragen werden alle Tauchgänge erneut gelesen; Duplikate werden erkannt.“ · **„Vergessen“** / „Abbrechen“. Die Tauchgänge bleiben. Ohne Geräte: „Noch kein Tauchcomputer verbunden.“
4. **Darstellung:** „System“ / „Hell“ / „Dunkel“ als Segmentknopf, sofort wirksam und gemerkt.
   **Einheiten** entfallen in v1.0, es gilt metrisch (Entscheidung 2026-11-22, §3 bleibt für später).
5. **Daten:** „Logbuch sichern“, „Logbuch wiederherstellen“ (§5.12) – erscheinen mit T11.
6. **Hilfe:** **„Fehler melden“** und **„Verbesserung vorschlagen“** (§5.14, ab 2026-11-24), „Diagnose-Logs teilen“ (§5.13) – erscheint mit T10.
7. **Über DiveDown:** „Version 1.0.0 (Build 42)“ · „libdivecomputer 0.9.0“ · „Lizenz: GPL-3.0-or-later“ · „Open-Source-Lizenzen“ (Lizenzseite, mit ODbL-Hinweis und Manrope-Lizenz) · „Datenschutzerklärung“ und „Quellcode“ öffnen den Browser (`url_launcher`; die App selbst braucht dafür kein Internet-Recht): https://wessleph.github.io/DiveDown/datenschutz/ und https://github.com/wessleph/DiveDown

### 5.12 Logbuch sichern / wiederherstellen
Einstieg: Einstellungen, Abschnitt **DATEN** mit „Logbuch sichern“ und „Logbuch wiederherstellen“ (§5.11).

**Sichern:** Info: „Erstellt eine Datei mit allen Tauchgängen. Speichere sie z. B. in „Dateien“ oder schicke sie dir per Mail.“ Dateiname „DiveDown-Sicherung-2026-11-22.divedown“.
Warnung (`warning`): „Die Datei ist nicht verschlüsselt und enthält Gesundheitsdaten (Puls).“ · **„Sicherung erstellen“** → System-Teilen-Dialog → „Sicherung erstellt“.

**Wiederherstellen:** Datei wählen (bis 200 MB) → Prüfen → Zusammenfassung: „Sicherung vom 20.12.2026 · 128 Tauchgänge“ → Dialog: „Dein aktuelles Logbuch wird ersetzt. Vorher wird automatisch eine Kopie angelegt.“ · **„Wiederherstellen“** / „Abbrechen“ → Fortschritt → „Wiederhergestellt“.

| Zustand | Text |
|---|---|
| keine/fehlerhafte Sicherungsdatei | „Diese Datei ist keine gültige DiveDown-Sicherung.“ |
| Prüfsumme falsch | „Die Sicherung ist beschädigt und kann nicht verwendet werden.“ |
| neuere App-Version | „Diese Sicherung stammt aus einer neueren DiveDown-Version. Bitte aktualisiere die App zuerst.“ |
| Datei über 200 MB | „Die Datei ist zu groß für eine DiveDown-Sicherung.“ |
| Fehler beim Ersetzen | „Wiederherstellen fehlgeschlagen. Dein bisheriges Logbuch ist unverändert.“ · „Logs senden“ kommt mit T10 |

### 5.13 Diagnose-Logs teilen
Info: „Hilf bei der Fehlersuche: Schicke das Protokoll an den Entwickler. Es enthält keine Orte, Namen oder Gesundheitswerte.“
**Vorschau** (scrollbar, Monospace, die ersten 200 Zeilen und „… 1.240 weitere Zeilen“) · **„Teilen“** (öffnet den System-Dialog) · klein: „Am besten per Mail.“
- leer: „Noch keine Einträge im Protokoll.“

### 5.14 Feedback: Fehler melden, Verbesserung vorschlagen *(neu 2026-11-24, T35)*
Die App hat keine Internet-Berechtigung (security.md §4): Sie **sendet nichts selbst**, sondern bereitet einen **Mail-Entwurf** an `divedown-app@proton.ch` vor, den die Mail-App des Handys öffnet. Der Nutzer sieht ihn vor dem Senden und kann ihn ändern oder verwerfen.

**„Fehler melden“** (eigene Seite, Titel „Fehler melden“):
- Textfeld **„Was ist passiert?“*** (mehrzeilig, Hinweis „z. B. Beim Übertragen vom EON Core bricht die App nach drei Tauchgängen ab.“; leer → „Bitte beschreibe kurz, was passiert ist.“)
- Schalter **„Diagnose-Protokoll anhängen“** (Standard an), darunter klein „Enthält keine Orte, Namen oder Gesundheitswerte.“ und der Link **„Protokoll ansehen“** (öffnet §5.13)
- Knopf **„Mail vorbereiten“**. Kleiner Text darunter: „Deine Mail-App öffnet sich mit der Nachricht an divedown-app@proton.ch. Gesendet wird erst, wenn du dort auf Senden tippst.“
- Mail: Betreff „DiveDown: Fehler“, Text = Beschreibung, darunter eine Trennlinie und die Gerätedaten wie im Kopf des Diagnose-Protokolls (App-Version und Build, Betriebssystem, Modell, libdivecomputer). Mit Protokoll hängt die Datei `DiveDown-Diagnose-<Datum>.txt` an (wie bei „Diagnose-Logs teilen“).

**„Verbesserung vorschlagen“** (eigene Seite, Titel „Verbesserung vorschlagen“):
- Textfeld **„Deine Idee“*** (mehrzeilig, Hinweis „z. B. Ich würde gern die Sichtweite pro Tauchgang eintragen.“; leer → „Bitte beschreibe deine Idee kurz.“)
- Knopf **„Mail vorbereiten“** mit demselben kleinen Text. Mail: Betreff „DiveDown: Verbesserungsvorschlag“, Text = Idee plus Gerätedaten, kein Anhang.

| Zustand | Darstellung |
|---|---|
| keine Mail-App | Dialog „Keine Mail-App gefunden“ · „Schreib an divedown-app@proton.ch.“ · **„Adresse kopieren“** (Snackbar „Adresse kopiert“) / „Schließen“ |
| Protokoll leer | Schalter ausgeblendet, Mail ohne Anhang |
| zurück aus der Mail-App | Die Seite bleibt mit dem Text offen (man weiß nicht, ob gesendet wurde) |

## 6. Profil-Diagramm
- **X-Achse:** Zeit (min). **Y-Achse:** Tiefe, **nach unten wachsend** (0 m oben), Gitter alle 10 m (bis 15 m max. Tiefe alle 5 m), Beschriftung in `onSurfaceMuted`.
- Tiefenkurve in `depth` als Fläche mit Verlauf (oben 5 %, unten 42 % Deckkraft) und Linie 2 dp.
- **Zuschaltbare Ebenen** (Chips über dem Diagramm, Zustand wird gemerkt): **Temperatur** (rechte Achse, `temperature`) · **Luft** (rechte Achse, `pressure`, gestrichelt wenn geschätzt; pro Flasche eine Linie) · **NDL** (Band unten, `ndl`, gestrichelt) · **SAC** (eigene Achse, Stufenlinie über 1-min-Abschnitte, **nur mit gemessenem Druck**; geschätzt wäre sie eine waagrechte Linie ohne Aussage) · **Puls** (nur bei Watch, eigene Achse in `accent`; Watch-Tauchgänge haben keine Luft-Kurve; ist an, wenn es keine Luft gibt; Werte-Feld „Puls 95 /min“, T6.11).
  Immer höchstens **zwei rechte Achsen** gleichzeitig. Bei einer dritten schaltet die älteste automatisch ab, mit kurzem Hinweis.
- **Ereignisse** als Punkte auf der Kurve (Warnungen `error`, sonst `primary`). Antippen zeigt den Text.
- **Antippen/Ziehen (Wunsch vom 2026-11-22):** senkrechte Linie und Punkt auf der Kurve. Das **Werte-Feld unter dem Diagramm** zeigt immer die Werte dieses Moments; vor dem ersten Tippen steht die Linie beim tiefsten Punkt.
  Werte: **Zeit · Tiefe · Temperatur · NDL · Umgebungsdruck · Luft jetzt** (l/min in dieser Tiefe) und darunter zwei eigene Zeilen über die volle Breite: **„Noch in der Flasche“** (z. B. „ca. 142 bar“) und **„Bisher verbraucht“** (z. B. „ca. 696 l“, Liter an der Oberfläche). Bei Schätzung folgt eine kleine Zeile „Luftwerte geschätzt aus Start- und Enddruck (200 → 60 bar, 12 l)“.
  - **Gemessen**, wenn der Tauchcomputer Druck-Samples liefert: Druck aus den Samples, verbraucht = (Startdruck − Druck) × Volumen, „Luft jetzt“ aus dem SAC der laufenden Minute × Umgebungsdruck.
  - **Geschätzt**, wenn nur Start- und Enddruck bekannt sind (z. B. EON Core ohne Sender, Druck von Hand eingetragen): Der Gesamtverbrauch (Start − Ende) × Volumen wird nach **Zeit × Umgebungsdruck** (1 + Tiefe/10 bar) auf den Tauchgang verteilt. „Luft jetzt“ = Ø-SAC × Umgebungsdruck. Gekennzeichnet durch die kleine Zeile im Werte-Feld und „Luft (geschätzt)“ am Chip.
  - **Ohne Druckangaben** steht im Werte-Feld statt der Luftwerte der Link **„Start- und Enddruck eintragen“** (öffnet Bearbeiten). Ohne Flaschengröße: „Flaschengröße eintragen“.
- **Vollbild/Querformat:** Pinch-Zoom und Verschieben auf der Zeitachse, Doppeltipp setzt zurück.
  *(Ausgestaltet 2026-11-23, T27.)* Knopf **„Vollbild“** neben „Als Tabelle anzeigen“, nur bei Tauchgängen mit Messpunkten. Die Vollbild-Seite liegt über der Tab-Leiste, dreht ins **Querformat** und blendet die Systemleisten aus (Wischen vom Rand holt sie kurz zurück). Oben: **„Schließen“** (X) und „#42 · Tauchplatz“, daneben die Ebenen-Chips. Links das Diagramm über die volle Höhe, rechts das Werte-Feld (scrollbar). Ein Finger tippt/zieht wie bisher den Zeitpunkt; **zwei Finger** zoomen (mind. 2 min sichtbar) und verschieben; **Doppeltipp** zeigt den ganzen Tauchgang. Gezoomt steht über dem Diagramm der Ausschnitt, z. B. „11:40 – 35:00“. Die Tiefenachse bleibt fest. Beim Schließen kehren Ausrichtung und Systemleisten zurück.
- **Barrierefreiheit:** Das Diagramm hat ein Semantics-Label mit Zusammenfassung („Tiefenprofil: max. 24,1 m nach 4 min, Dauer 60 min“). Das Werte-Feld ist eine Live-Region. Darunter liegt der Link **„Als Tabelle anzeigen“** (Minutenwerte).
- Nicht verbindliche Werte: Unter dem Werte-Feld steht „Werte vom Tauchcomputer, nur zur Anzeige.“, bei Schätzung ergänzt um „Luft ist geschätzt, weil kein Flaschendruck aufgezeichnet wurde.“ (Constitution §5)

## 7. Barrierefreiheit (Pflicht)
- Kontrast WCAG AA: Text ≥ 4,5:1, Kurven und Icons ≥ 3:1. Gilt für beide Themes und alle Tokens in §1.
- Touch-Ziele ≥ 48 dp, Hauptaktionen 56 dp, Abstand zwischen Zielen ≥ 8 dp.
- Dynamische Schrift bis 200 % ohne abgeschnittene Texte.
- Screenreader (VoiceOver/TalkBack): Jedes Icon-Element hat ein Label. Listenzeilen werden als ein Element vorgelesen („12. August, 18,4 Meter, 47 Minuten, vom Tauchcomputer“).
- Mit „Bewegung reduzieren“ entfallen Radar-Animation und Hervorhebungs-Animationen.
- Nichts wird nur über Farbe ausgedrückt (§1).

## 8. Layouts
| Format | Layout |
|---|---|
| Smartphone hoch (Standard) | wie beschrieben, einspaltig |
| Smartphone quer | Detail: Diagramm links (60 %), Kennzahlen rechts. Vollbild-Diagramm bevorzugt quer. Listen einspaltig mit breiterer Sparkline. |
| Tablet (≥ 840 dp) | Liste und Detail nebeneinander (Logbuch links 360 dp, Detail rechts). Navigation als seitliche Leiste statt unten. |
| Kleine Displays (< 360 dp) | Kennzahlen-Raster einspaltig |

## 9. Texte und Ton
- Du-Form, kurz, ohne Fachjargon. Fehlertexte sagen **was passiert ist** und **was du tun kannst**.
- Einheitliche Begriffe: „Tauchgang“ (nicht Dive), „Tauchcomputer“, „Logbuch“, „Flasche“, „Luftverbrauch (SAC)“, „Sicherung“.
- Alle Texte kommen aus `app_de.arb`, nichts ist hart im Code.
