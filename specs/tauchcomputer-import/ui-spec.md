# UI-Spezifikation: DiveDown 1.0

> Phase 30 · Stand: 2026-11-18 · Status: **abgenommen (2026-11-18)**, Mockups: https://claude.ai/artifact/7LP8HdXzTK33X75euzkU9X
> Grundlage: `design.md`, `security.md` (§10 Checkliste Phase 30), `docs/roadmap.md` (Muss-Umfang 1–9)
> DiveMate und Submersion dienen nur als Ablauf-Vorbild. Layout, Farben, Icons und Texte gestalten wir selbst.

## 1. Visueller Stil

**Leitidee „Tiefe“:** ruhig, dunkel, gut lesbar am Boot in grellem Sonnenlicht und abends auf dem Sofa.
Der Tiefenverlauf ist das zentrale Motiv, Farbe trägt Bedeutung und ist keine Dekoration.

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| `surface` | `#F6F8FA` | `#0B1620` | Hintergrund |
| `surfaceRaised` | `#FFFFFF` | `#13212E` | Karten, Listen |
| `onSurface` | `#0E1B26` | `#E6EEF4` | Text |
| `onSurfaceMuted` | `#4A5C6B` | `#9AB0C0` | Nebentext (beide ≥ 4,5:1 auf `surface`) |
| `primary` | `#0B5C8A` | `#5CB8E8` | Aktionen, aktive Navigation |
| `depth` | `#1676B8` | `#3FA3E0` | Tiefenkurve, Tiefenwerte |
| `temperature` | `#C2410C` | `#FB923C` | Temperaturkurve |
| `pressure` | `#047857` | `#34D399` | Flaschendruck |
| `sac` | `#7C3AED` | `#A78BFA` | Luftverbrauch |
| `warning` | `#B45309` | `#FBBF24` | Hinweise, mögliches Duplikat |
| `error` | `#B91C1C` | `#F87171` | Fehler |

- **Kontrast nachgerechnet (WCAG 2.1, 2026-11-18):** Alle Tokens erreichen auf `surface` und `surfaceRaised` **mindestens 4,5:1**, in beiden Themes. Der knappste Wert ist `depth` hell auf `surface` mit 4,57:1. Damit sind alle Farben auch als Textfarbe zulässig.
- **Design:** das Theme bauen wir selbst auf Basis von Material 3 (`ColorScheme` aus den Tokens), ohne Standard-Lila. Die App folgt der Systemeinstellung (hell/dunkel), das lässt sich in den Einstellungen ändern.
- **Schrift:** Systemschrift (SF Pro bzw. Roboto). Ziffern mit **gleicher Breite** (`FontFeature.tabularFigures`), damit Werte beim Scrollen nicht springen.
  Kennzahlen groß: 28–34 sp für Tiefe und Dauer.
- **Icons:** Material Symbols Rounded. Das App-Icon ist eigenes Design: eine stilisierte, abfallende Tiefenkurve in `depth` auf `surface` (dunkel).
  **Gewählt am 2026-11-18: Variante A „Tiefenkurve“** (Mockup-Fläche, Board 7). Vorlagen in `assets/icon/`:
  - `divedown_icon.svg`: iOS und Größen ab 60 px
  - `divedown_icon_small.svg`: unter 60 px, mit dickerer Kurve und nur einer Blase
  - `divedown_icon_android_foreground.svg`: Vordergrund des adaptiven Android-Icons, Motiv auf 66 % verkleinert, Hintergrund `#0B1620`

  Die PNG-Größen werden in Phase 50 erzeugt (z. B. mit `flutter_launcher_icons`).
- **Ecken** 12 dp, **Abstände** im 8-dp-Raster, **Touch-Ziele mindestens 48 dp**. Hauptaktionen bekommen 56 dp, damit man sie auch mit nassen Fingern trifft.
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
Einstellungen → Taucher · Geräte · Einheiten · Darstellung · Logbuch sichern · Wiederherstellen · Diagnose-Logs · Über & Lizenzen
```

- **Taucher-Wechsel:** Avatar oben rechts im Logbuch, tippen öffnet die Auswahl (Bottom Sheet).
  Der aktive Taucher gilt für Logbuch und Import. Im Import steht deutlich „Importieren für: **Anna**“.
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
| **Große Schrift (bis 200 %)** | Layouts brechen um statt abzuschneiden. Kennzahlen-Raster wird einspaltig. |

## 5. Bildschirme

### 5.1 Erster Start: Taucher anlegen
**Ablauf:** Begrüßung → Name (Pflicht) → optional Farbe/Avatar-Initialen → Einheiten (metrisch/imperial) → fertig → leeres Logbuch.
- Texte: Titel „Willkommen bei DiveDown“ · „Wer taucht? Du kannst später weitere Taucher hinzufügen.“ · Feld „Name“ · Knopf **„Los geht’s“**
- Hinweis klein: „Alle Daten bleiben auf diesem Gerät.“
- Zustände: Name leer → Knopf deaktiviert, mit Hinweis „Bitte gib einen Namen ein.“

### 5.2 Logbuch (Liste)
**Inhalt pro Eintrag** (Änderung vom 2026-11-18 nach dem Mockup-Review):
1. **Tauchgangsnummer prominent**: `#42`, 20 sp, extra fett, in `primary`
2. darunter der **Tauchplatz-Name**: 16 sp halbfett, einzeilig, sonst mit „…“ abgeschnitten. Ohne Tauchplatz steht dort in `onSurfaceMuted` „Ohne Tauchplatz“.
3. darunter klein: Quelle als Icon (Tauchcomputer / Datei / Watch / Hand) · Datum · Dauer

Links das Mini-Tiefenprofil (Sparkline), rechts die max. Tiefe (groß, `depth`).
Gruppiert nach Monat, neuester oben. FAB **„Manuell eintragen“**.

| Zustand | Darstellung / Text |
|---|---|
| leer | Illustration (eine einfache Welle) · „Noch keine Tauchgänge“ · „Importiere vom Tauchcomputer oder trage einen Tauchgang von Hand ein.“ · Knöpfe **„Importieren“** und **„Manuell eintragen“** |
| ladend | 6 Skeleton-Zeilen |
| Erfolg | Liste |
| zu viele Daten (> 500) | Lazy-Liste, Monatsüberschriften bleiben beim Scrollen oben, Schnellscroll-Leiste mit Jahr und Monat |
| nach Import | Neue Einträge 3 s hervorgehoben, Snackbar: „3 Tauchgänge importiert“ |
| Sicherungs-Erinnerung (> 30 Tage) | Dezente Karte oben: „Letzte Sicherung vor 34 Tagen.“ · **„Jetzt sichern“** · ✕ (für 7 Tage ausblenden) |

### 5.3 Tauchgang-Detail
**Aufbau (Hochformat):**
1. Kopf: **Nummer groß** (`#42`, 34 sp, extra fett, `primary`; vorgelesen als „Tauchgang 42“) · darunter **Tauchplatz** (19 sp, fett; leer → Link „Tauchplatz hinzufügen“) · darunter klein Datum, Uhrzeit, Taucher, Quelle (z. B. „Suunto EON Core · ••3F7A“)
2. **Kennzahlen-Raster** (2 Spalten): max. Tiefe · Dauer · Ø-Tiefe · Wassertemp. min · Start/Ende-Druck · **Ø-SAC** · Gas (z. B. „EAN32“) · Wassertyp
3. **Profil-Diagramm** (§6), Höhe 280 dp, Knopf „Vollbild“
4. Flaschen (Volumen, Druck, Gas) · Ereignisse (Liste mit Zeit)
5. Notizen, Bewertung (1–5 Sterne)
- Aktionen in der App-Leiste: **Bearbeiten**, Menü: „Löschen“

| Zustand | Darstellung |
|---|---|
| keine Samples (manuell) | Statt Diagramm: vereinfachtes Rechteckprofil aus Tiefe und Dauer, gestrichelt, Hinweis „Geschätztes Profil“ |
| kein Druck | Kennzahl „Druck“ zeigt „—“, SAC zeigt „—“ und ein Info-Icon: „Für den Luftverbrauch werden Flaschendruck und Flaschengröße benötigt.“ |
| Druck, aber keine Flaschengröße | SAC „—“ und der Link **„Flaschengröße eintragen“** |
| Apple Watch | Kein Druck, kein SAC. Dafür eine Pulskurve als zuschaltbare Ebene. |
| Löschen | Dialog: „Tauchgang löschen?“ · **„Löschen“** (rot) / „Abbrechen“. Danach Snackbar mit **„Rückgängig“** für 5 s (Soft Delete macht das möglich). Geändert am 2026-11-20: Der Satz „Das kann nicht rückgängig gemacht werden.“ ist entfallen, weil er der Snackbar widersprach. |

### 5.4 Manuell eintragen / Bearbeiten
Felder: **Nr.** (vorbelegt mit der nächsten freien Nummer, änderbar), **Tauchplatz** (Freitext mit Vorschlägen: zuerst eigene Namen, dann der mitgelieferte Katalog mit „Name · Region, Land“. Eine Zeile „‚…‘ als neuen Tauchplatz verwenden“ gibt es immer, siehe ADR 0006), Datum*, Startzeit*, Dauer* (min), max. Tiefe*, Ø-Tiefe, Wassertemp., Flasche (Volumen, Start-/Enddruck, O₂-Anteil), Wassertyp (Salz/Süß), Notizen, Bewertung.
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

Oben: „Importieren für: **Anna** ▾“

### 5.6 Tauchcomputer: Suche und Auswahl
**Ablauf:** Rechte prüfen → Scan startet automatisch (max. 30 s) → Liste der gefundenen Geräte → antippen → Download (§5.7).

Pro Gerät: Name · Modell (falls erkannt) · **Signalstärke** als 4 Balken + Text („stark“, „mittel“, „schwach“) · Kennzeichnung **„Bekannt“**, wenn es bereits gekoppelt war.
Vor der Suche ein kleiner Hinweis: „Aktiviere Bluetooth am Tauchcomputer: EON Core → Einstellungen → Verbindungen → Koppeln.“ Die Hilfe ist pro Modell hinterlegt, zunächst nur für die EON Core.

| Zustand | Text / Aktion |
|---|---|
| Bluetooth aus | „Bluetooth ist ausgeschaltet.“ · **„Bluetooth einschalten“** (Android: System-Dialog; iOS: Hinweis auf Kontrollzentrum) |
| Berechtigung noch nicht erteilt | Vorab-Erklärung: „DiveDown braucht Bluetooth, um Tauchgänge von deinem Tauchcomputer zu laden. Es werden keine anderen Geräte gespeichert.“ · **„Weiter“** → System-Dialog |
| Berechtigung verweigert | „Ohne Bluetooth-Berechtigung kann DiveDown keine Tauchcomputer finden.“ · **„Einstellungen öffnen“** |
| Suche läuft | Animiertes Radar-Icon (mit „Bewegung reduzieren“ nur statisch), „Suche nach Tauchcomputern …“ und Knopf „Stopp“ |
| nichts gefunden (30 s) | „Kein Tauchcomputer gefunden.“ + Checkliste: Bluetooth am Gerät aktiv? Gerät näher ans Handy? Tauchcomputer nicht mit einer anderen App verbunden (z. B. Suunto-App)? · **„Erneut suchen“** |
| Gerät nicht unterstützt | Eintrag ausgegraut: „Dieses Modell wird nicht direkt unterstützt.“ Bei **Suunto Ocean / Nautic** zusätzlich: „Nutze den Import per FIT-Datei.“ → **„Zur FIT-Anleitung“** |
| PIN nötig | Dialog: „**EON Core (••3F7A)** fragt nach einem Code. Gib den Code ein, der auf dem Tauchcomputer angezeigt wird.“ · Feld (Ziffern) · **„Bestätigen“** / „Abbrechen“ (60 s Zeitlimit, danach „Zeit abgelaufen. Bitte erneut verbinden.“) |
| **Seriennummer weicht ab** (security A1) | Warnung: „Dieses Gerät meldet eine andere Seriennummer als dein gespeicherter ‚EON Core‘. Wenn du das Gerät nicht kennst, brich ab.“ · **„Abbrechen“** (primär) / „Als neues Gerät verwenden“ |

### 5.7 Tauchcomputer: Übertragung
- Fortschrittsbalken (bestimmt, wenn das Plugin `DownloadProgress` liefert, sonst unbestimmt) und „**3 neue Tauchgänge** gefunden …“
- Hinweis: „Halte den Tauchcomputer in der Nähe. Das kann einige Minuten dauern.“
- Bildschirm bleibt während der Übertragung an.
- Knopf **„Abbrechen“**

| Zustand | Text / Aktion |
|---|---|
| keine neuen Tauchgänge | „Alles auf dem neuesten Stand. Keine neuen Tauchgänge auf dem Tauchcomputer.“ · **„Fertig“** |
| Verbindung abgebrochen | „Die Verbindung wurde unterbrochen.“ Sind schon Tauchgänge da, kommt zusätzlich: „**2 von 5** Tauchgängen wurden übertragen.“ · **„Übertragene prüfen“** · **„Erneut verbinden“** · „Logs senden“ |
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
Oben: Quelle + „Importieren für: **Anna**“. Bei Dateien zusätzlich der Dateiname (security A2).
Die Vorschau zeigt die **Nummern, die die Tauchgänge bekommen** (z. B. „#43“). Unter der Liste steht die Aktion **„Tauchplatz für Ausgewählte setzen“**, weil Tauchcomputer, FIT und Apple Health keinen Tauchplatz-Namen mitliefern. Vorschläge kommen aus bereits verwendeten Namen und dem Tauchplatz-Katalog (ADR 0006).
Knopf unten: **„3 Tauchgänge importieren“**, die Zahl passt sich an die Auswahl an.

| Zustand | Darstellung |
|---|---|
| mögliches Duplikat | Eintrag mit `warning`-Markierung: „Ähnlicher Tauchgang vorhanden (12.08., 18,4 m, 47 min)“. Standardmäßig **nicht** ausgewählt, mit der Aktion **„Vergleichen“** (zeigt beide nebeneinander). |
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
| Berechtigung verweigert | „DiveDown hat keinen Zugriff auf Apple Health.“ · „Erlaube den Zugriff in der Health-App → Profil → Apps → DiveDown.“ |
| keine Tauchgänge | „Keine Tauchgänge im gewählten Zeitraum gefunden.“ + Hinweis: „Tauchgänge werden von der Apple Watch Ultra mit der App ‚Tiefe‘ oder einer Tauch-App aufgezeichnet.“ |
| Hinweis Tiefe | klein: „Apple Health erfasst Tiefen nur bis ca. 40 m.“ |

### 5.11 Einstellungen
Gruppen:
1. **Taucher:** Liste, hinzufügen, umbenennen, löschen. Pro Taucher gibt es die Einstellung **„Nummerierung beginnt bei“** (für Taucher mit früheren Tauchgängen in anderen Logbüchern) (Dialog: „Anna und ihre 42 Tauchgänge löschen?“). Dazu der Hinweis: „Alle Taucher auf diesem Gerät können alle Logbücher sehen.“ (security G4)
2. **Geräte:** bekannte Tauchcomputer (Name, ••Seriennummer, letzter Import), „Vergessen“
3. **Einheiten**, **Darstellung** (System/Hell/Dunkel)
4. **Daten:** „Logbuch sichern“, „Logbuch wiederherstellen“ (§5.12)
5. **Hilfe:** „Diagnose-Logs teilen“ (§5.13)
6. **Über DiveDown:** Version, Build, libdivecomputer-Version, Lizenz GPL-3, „Open-Source-Lizenzen“ (mit dem ODbL-Hinweis zu OpenStreetMap für den Tauchplatz-Katalog), Datenschutzerklärung (Link), Quellcode (Link)

### 5.12 Logbuch sichern / wiederherstellen
**Sichern:** Info: „Erstellt eine Datei mit allen Tauchgängen aller Taucher. Speichere sie z. B. in ‚Dateien‘ oder schicke sie dir per Mail.“
Warnung (`warning`): „Die Datei ist nicht verschlüsselt und enthält Gesundheitsdaten (Puls).“ · **„Sicherung erstellen“** → System-Teilen-Dialog → „Sicherung erstellt“.

**Wiederherstellen:** Datei wählen → Prüfen → Zusammenfassung: „Sicherung vom 20.12.2026 · 3 Taucher · 128 Tauchgänge“ → Dialog: „Dein aktuelles Logbuch wird ersetzt. Vorher wird automatisch eine Kopie angelegt.“ · **„Wiederherstellen“** / „Abbrechen“ → Fortschritt → „Wiederhergestellt“.

| Zustand | Text |
|---|---|
| keine/fehlerhafte Sicherungsdatei | „Diese Datei ist keine gültige DiveDown-Sicherung.“ |
| Prüfsumme falsch | „Die Sicherung ist beschädigt und kann nicht verwendet werden.“ |
| neuere App-Version | „Diese Sicherung stammt aus einer neueren DiveDown-Version. Bitte aktualisiere die App zuerst.“ |
| Fehler beim Ersetzen | „Wiederherstellen fehlgeschlagen. Dein bisheriges Logbuch ist unverändert.“ · „Logs senden“ |

### 5.13 Diagnose-Logs teilen
Info: „Hilf bei der Fehlersuche: Schicke das Protokoll an den Entwickler. Es enthält keine Orte, Namen oder Gesundheitswerte.“
**Vorschau** (scrollbar, Monospace, die ersten 200 Zeilen und „… 1.240 weitere Zeilen“) · **„Teilen“** (öffnet den System-Dialog) · klein: „Am besten per Mail.“
- leer: „Noch keine Einträge im Protokoll.“

## 6. Profil-Diagramm
- **X-Achse:** Zeit (mm:ss bzw. h:mm). **Y-Achse:** Tiefe, **nach unten wachsend** (0 m oben), Gitter alle 5 m bzw. 10 m.
- Tiefenkurve in `depth` als Fläche mit Verlauf (oben 40 %, unten 5 % Deckkraft).
- **Zuschaltbare Ebenen** (Chips über dem Diagramm, Zustand wird gemerkt):
  Temperatur (rechte Achse) · Flaschendruck (rechte Achse, pro Flasche eine Linie, gestrichelt ab Flasche 2) · **SAC** (eigene Achse, als Stufenlinie über 1-min-Abschnitte) · Puls (nur bei Watch) · NDL/Deko (Band unten).
  Immer höchstens **zwei rechte Achsen** gleichzeitig. Bei einer dritten schaltet die älteste automatisch ab, mit kurzem Hinweis.
- **Ereignisse** als kleine Marker auf der Kurve (Gaswechsel, Warnung „Aufstieg zu schnell“, Sicherheitsstopp). Antippen zeigt einen Tooltip.
- **Antippen/Ziehen:** senkrechte Linie mit Werte-Box: „23:10 · 18,4 m · 21 °C · 142 bar · SAC 14,2 l/min“.
- **Vollbild/Querformat:** Pinch-Zoom und Verschieben auf der Zeitachse, Doppeltipp setzt zurück.
- **Barrierefreiheit:** Das Diagramm hat ein Semantics-Label mit Zusammenfassung („Tiefenprofil: max. 18,4 m nach 12 min, Dauer 47 min“). Darunter liegt der Link **„Als Tabelle anzeigen“** (Minutenwerte).
- Nicht verbindliche Werte: Unter NDL/Deko steht „Werte vom Tauchcomputer, nur zur Anzeige.“ (Constitution §5)

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
