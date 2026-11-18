# ADR 0003: Ein gemeinsames Importmodell für alle Quellen

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18

## Kontext
Tauchgänge kommen in DiveDown auf vier Wegen in die App:

| Quelle | Wer | Weg |
|---|---|---|
| Tauchcomputer per BLE | Ich (EON Core) | `libdivecomputer_plugin` → `ParsedDive` |
| FIT-Datei | Schwester (Ocean, vorerst) | Datei aus der Suunto-App → FIT-Parser |
| Apple Health | Freund (Apple Watch) | HealthKit-Samples (Tiefe, Temperatur, Puls) |
| Manuell | Bruder, alle | Formular |

Submersion verwendet dafür ein einheitliches Zwischenmodell `ImportedDive`.
Der FIT-Parser besteht aus 11 kleinen Extraktoren, die meisten ohne interne Abhängigkeiten, und baut auf `fit_tool` auf.
HealthKit läuft über das Paket `health` und hat nur wenige interne Abhängigkeiten.

## Entscheidung
1. **Ein Zwischenmodell `ImportedDive`** in `lib/domain/import/`. Es ist vereinfacht aus Submersion abgeleitet und enthält:
   Herkunft (`source`, `sourceId`), Start- und Endzeit, max./mittlere Tiefe, Temperaturen, Flaschen, Gaswechsel, Profil-Samples und Geräteinfo.
2. **Pro Quelle ein Adapter** in `lib/data/import/<quelle>/`, der in `ImportedDive` übersetzt:
   - `divecomputer/`: `ParsedDive` → `ImportedDive`
   - `fit/`: übernommene FIT-Extraktoren (ADR 0001, Herkunft gekennzeichnet)
   - `health/`: übernommener HealthKit-Adapter, nur auf iOS
   - Manuelle Eingabe schreibt direkt ins Domänenmodell und braucht keinen Adapter.
3. **Ein Importdienst** (`lib/domain/import/import_service.dart`) nimmt `ImportedDive` entgegen, erkennt Duplikate und speichert.
   - Duplikate erkennen wir zuerst an `source` plus `sourceId` (Fingerprint bzw. Datei- oder HealthKit-UUID).
   - Als Rückfallebene gilt: gleiche Startzeit ±2 Minuten und gleiche maximale Tiefe ±0,5 m. Dann fragt die App nach, statt still zu überschreiben.
4. **Nur neue Tauchgänge vom Tauchcomputer:** Der letzte Fingerprint wird pro Gerät gespeichert (Tabelle `dive_computers`, ADR 0004) und beim nächsten Download an das Plugin übergeben.

## Konsequenzen
- Eine neue Quelle braucht nur einen neuen Adapter, Datenbank und Oberfläche bleiben gleich.
- Sobald libdivecomputer die Ocean unterstützt, kommt sie über den BLE-Adapter. Den FIT-Weg behalten wir trotzdem als Rückfallebene.
- Alle Importe laufen **vollständig offline**.
- Apple Health gibt es nur unter iOS. Health Connect unter Android lassen wir vorerst weg, weil es niemand braucht.
