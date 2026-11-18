# Design: Tauchcomputer-Import

> Phase 10 · Stand: 2026-11-18 · Status: **abgenommen (2026-11-18)**
> Grundlage: `research.md` (abgeschlossen) · ADRs: 0001–0005

## 1. Umfang

**Enthalten (erste Ausbaustufe)**
- Tauchgänge vom Tauchcomputer per **BLE** auslesen, nur neue (Fingerprint). Zielgerät: **Suunto EON Core**.
- **FIT-Datei** importieren (Suunto Ocean über den Export der Suunto-App).
- **Apple Health** importieren (Apple Watch, nur iOS).
- **Manuelle Eingabe** eines Tauchgangs.
- Tauchgang speichern, mit Profil-Samples, Flaschen, Gasen und Events.
- **Profil-Ansicht** eines Tauchgangs: Tiefe, Temperatur, Flaschendruck, berechneter Luftverbrauch (SAC).
- **Diagnose-Logs teilen** (fest eingebaut, siehe §9). Nachtrag vom 2026-11-18, Wunsch des Nutzers.
- **Logbuch sichern und wiederherstellen** (Datei, siehe security.md O1). Nachtrag vom 2026-11-18.

**Nicht enthalten (spätere Features mit eigener Spec)**
Tauchplätze und Karte, Ausrüstung, Teilen und Sync über den NAS, Statistiken über mehrere Tauchgänge, USB-Übertragung, Gerätekonfiguration.

## 2. Komponenten

```
┌───────────────────────── features/ (UI + Riverpod-Provider) ─────────────────────────┐
│ dive_import/   Quelle wählen · Gerät suchen · Download-Fortschritt · Duplikat-Dialog  │
│ dive_log/      Liste · Detail · Profil-Diagramm · manuelles Formular                  │
└───────────────┬───────────────────────────────────────────────┬──────────────────────┘
                │ ruft auf                                      │ liest
┌───────────────▼────────────── domain/ (reines Dart) ──────────▼──────────────────────┐
│ import/ImportedDive · import/ImportService (Duplikate, Speichern)                     │
│ dive/Dive, Sample, Tank, GasMix, DiveEvent       metrics/SacCalculator                │
│ Schnittstellen: DiveRepository, DiveComputerRepository, DiveSource                    │
└───────▲──────────────────────▲──────────────────────▲─────────────────────▲──────────┘
        │ implementiert        │                      │                     │
┌───────┴────────┐ ┌───────────┴─────────┐ ┌──────────┴────────┐ ┌──────────┴─────────┐
│ data/local/    │ │ data/import/        │ │ data/import/fit/  │ │ data/import/health/│
│ Drift-DB +     │ │ divecomputer/       │ │ FIT-Extraktoren   │ │ HealthKit-Adapter  │
│ Repositories   │ │ ParsedDive→Imported │ │ (aus Submersion)  │ │ (aus Submersion)   │
└────────────────┘ └───────────┬─────────┘ └───────────────────┘ └────────────────────┘
                               │ Pigeon
                 ┌─────────────▼───────────────────────────┐
                 │ packages/libdivecomputer_plugin          │
                 │ Kotlin/JNI (Android) · Swift (iOS)       │
                 │ native BLE ↔ libdivecomputer (C)         │
                 └──────────────────────────────────────────┘
```

### Grenzen und Regeln
- `domain/` importiert **weder Flutter noch Drift noch Plugins**. Nur dort liegt die Geschäftslogik (Duplikate, SAC).
- `data/import/*` übersetzen **nur**. Sie prüfen nicht selbst auf Duplikate und speichern auch nicht selbst.
- `features/` sprechen nur mit Providern und Domänen-Schnittstellen, nie direkt mit Drift oder dem Plugin.
- Das Plugin bleibt so nah wie möglich am Original (ADR 0002). Eigene Änderungen werden mit `// DiveDown:` gekennzeichnet.

## 3. Schnittstellen (Domäne)

```dart
/// Eine Importquelle liefert Tauchgänge im gemeinsamen Format.
abstract interface class DiveSource {
  ImportSource get kind;              // diveComputer | fit | appleHealth
}

abstract interface class DiveComputerSource implements DiveSource {
  Stream<DiscoveredComputer> discover();                     // BLE-Suche
  Stream<DownloadEvent> download(DiscoveredComputer c,       // Fortschritt, Tauchgang, Ende, Fehler
                                 {Uint8List? sinceFingerprint});
  Future<void> cancel();
}

abstract interface class FileDiveSource implements DiveSource {
  Future<List<ImportedDive>> parse(Uint8List bytes, {String? fileName});
}

abstract interface class HealthDiveSource implements DiveSource {
  Future<bool> requestPermission();
  Future<List<ImportedDive>> fetch({required DateTime from, required DateTime to});
}

class ImportService {
  /// Prüft auf Duplikate und speichert. Liefert pro Tauchgang das Ergebnis.
  Future<List<ImportResult>> importDives(String diverId, List<ImportedDive> dives);
}

sealed class ImportResult { }  // Saved · SkippedDuplicate · NeedsConfirmation(possibleMatch)
```

## 4. Datenflüsse

### 4.1 BLE vom Tauchcomputer, offline
1. Die Oberfläche startet `discover()`. Das Plugin scannt per BLE und meldet `DiscoveredComputer` (Name, Adresse, erkanntes Modell).
2. Der Nutzer wählt das Gerät. Die Oberfläche liest in `DiveComputerRepository` den **letzten Fingerprint** für die Seriennummer bzw. Adresse.
3. `download(..., sinceFingerprint)`: Das Plugin liest nur neuere Tauchgänge und liefert pro Tauchgang `ParsedDive`. Der Adapter übersetzt in `ImportedDive`.
4. Die Oberfläche zeigt die Liste der neuen Tauchgänge an, und der Nutzer bestätigt.
5. `ImportService.importDives` speichert alles in **einer Transaktion** pro Tauchgang.
   Danach wird der **neueste** Fingerprint im Gerät gespeichert, aber **erst nach erfolgreichem Speichern**.
6. Wird der Download abgebrochen (Verbindung weg, Abbruch durch den Nutzer), bleiben bereits empfangene Tauchgänge erhalten, und der Fingerprint wird **nicht** weitergesetzt. Beim nächsten Mal wird erneut geladen, und die Duplikaterkennung fängt Doppelte ab.

### 4.2 FIT-Datei, offline
Datei wählen (`file_picker`) oder aus der Suunto-App „Teilen → DiveDown“ → `FileDiveSource.parse` → Vorschau → `ImportService`.
Duplikate erkennen wir an der Datei-ID (`source_id` = FIT `file_id`-Seriennummer + Zeitstempel).

### 4.3 Apple Health (nur iOS), offline
Berechtigung anfragen → `fetch(from, to)` liefert Unterwasser-Workouts mit Tiefe, Temperatur und Puls → Vorschau → `ImportService`.
`source_id` ist die UUID des HealthKit-Workouts. Flaschendruck gibt es hier nicht, also wird auch kein SAC berechnet.

### 4.4 Manuell
Formular → Domänenobjekt `Dive` (ohne Samples oder mit wenigen Stützpunkten) → `DiveRepository.save`. Duplikate werden nicht geprüft.

### 4.5 Wieder online
Für dieses Feature ist **kein Netz nötig**. Der spätere Sync (eigenes Feature) liest die Tabellen aus ADR 0004. UUIDs und Soft Delete sind dafür bereits vorbereitet.

## 5. Datenmodell
Siehe ADR 0004 (`divers`, `dive_computers`, `dives`, `dive_samples`, `dive_tanks`, `dive_events`).
Felder, die für dieses Feature wichtig sind:
- `dives.source` (`dive_computer` | `fit` | `apple_health` | `manual`) und `dives.source_id`, eindeutig pro `(diver_id, source, source_id)`
- `dive_computers.last_fingerprint` (Blob), `serial`, `firmware`, `model`, `vendor`
- `dive_samples.tank_index` bei mehreren Flaschen; `pressure_bar` kann leer sein

## 6. Luftverbrauch (SAC)
`domain/metrics/SacCalculator`: SAC [l/min an der Oberfläche] = (Δp × V_Flasche) / (Dauer × mittlerer Umgebungsdruck).
- Mit Druckverlauf aus den Samples: abschnittsweise Werte für die Kurve im Diagramm.
- Nur mit Start- und Enddruck: ein Durchschnittswert.
- Ohne Druck oder ohne Flaschenvolumen: kein Wert, die Oberfläche zeigt „—“.

## 7. Fehlerfälle (Eingabe für Phase 30)
Bluetooth aus · Berechtigung verweigert · kein Gerät gefunden · Gerät nicht unterstützt (z. B. Ocean per BLE → Hinweis auf FIT) ·
Verbindung bricht ab · Pairing-PIN nötig · FIT-Datei ist kein Tauchgang oder beschädigt · keine Health-Berechtigung · keine Tauchgänge im Zeitraum ·
mögliches Duplikat · Speicher voll.

## 8. Prüfung gegen die Constitution
| Regel | Erfüllt? |
|---|---|
| Offline-first | ✅ Alle Import-Wege laufen lokal, kein Netz nötig. |
| Oberfläche auf Deutsch | ✅ Nur ARB `de` (ADR 0005). |
| Keine Fremd-Kopien | ✅ Übernahmen nur unter GPL-3 mit Herkunftsangabe (ADR 0001). DiveMate dient nur als Vorbild für Funktionen. |
| Lizenzen geprüft | ⚠️ `fit_tool`, `health`, `file_picker` und die Plugin-Abhängigkeiten werden in Phase 20 geprüft. |
| Keine verbindlichen Sicherheitsberechnungen | ✅ Deko- und NDL-Werte werden nur angezeigt, wie sie der Tauchcomputer liefert. SAC ist reine Auswertung. |
| Wartbarkeit | ✅ Updates beschränken sich weitgehend auf libdivecomputer im Plugin (ADR 0002). |
| **Constitution-Anpassung nötig** | Die Zeile zum Tauchcomputer (`dart:ffi`) wird bei Abnahme von ADR 0002 durch „natives Plugin“ ersetzt. Dazu kommen die Lizenz GPL-3 und der Build in der Cloud. |

## 9. Diagnose-Logs teilen (Nachtrag 2026-11-18)

**Warum:** Der Entwickler hat kein iPhone. Fehler auf iOS werden nur sichtbar, wenn Tester ihr Protokoll schicken.

**Komponenten**
- `domain/diagnostics/DiagnosticLog`: Schnittstelle `log(category, level, message)` und `export()`.
- `data/diagnostics/FileDiagnosticLog`: Ringpuffer in einer lokalen Datei (z. B. letzte 5 MB bzw. 7 Tage), läuft **offline**.
- Quellen: die eigenen App-Logs (Import, Datenbank, Fehler) sowie `onLogEvent` aus dem `libdivecomputer_plugin` (BLE-Details).
  Bei einem Absturz wird der Fehler mit Stacktrace über `FlutterError.onError` bzw. `PlatformDispatcher.onError` mitgeschrieben.
- `features/settings/`: Eintrag **„Diagnose-Logs teilen“**. Er erzeugt eine Textdatei mit
  App-Version, Build-Nummer, Betriebssystem und Version, Gerätemodell, libdivecomputer-Version und den Logs.
  Danach öffnet sich der Teilen-Dialog des Systems (`share_plus`) für Mail, WhatsApp usw.
- Nach einem fehlgeschlagenen Import bietet der Fehlerdialog direkt **„Logs an Entwickler senden“** an.

**Regeln**
- Es wird **nichts automatisch gesendet**. Der Nutzer entscheidet jedes Mal selbst (Constitution §6: kein Tracking).
- Logs enthalten **keine** GPS-Koordinaten, Notizen, Namen oder Health-Werte. Erlaubt sind Gerätemodell, Fehlercodes, Zeitpunkte, Anzahl der Tauchgänge und BLE-Protokollschritte.
  Wie genau gefiltert wird, prüft Phase 20.
- Vor dem Teilen zeigt die App eine Vorschau, was gesendet wird.
