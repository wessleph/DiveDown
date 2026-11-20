# EON-Core-Fixtures (T4.5)

Echte Rohdaten von drei Tauchgängen eines Suunto EON Core, so wie libdivecomputer sie pro Tauchgang liefert (`ParsedDive.rawData`, SBEM-Format der EON-Steel-Familie).

- **Aufgenommen:** 2026-11-20 per BLE mit `lib/dev/capture_main.dart` auf einem Android-Handy, libdivecomputer 0.10.0 (Fork-Commit `fbd2c42`), EON Core Firmware 4.0.1131.
- **Anonymisiert:** Die Seriennummer des Geräts (Feld `sml.DeviceLog.Device.SerialNumber`, einmal pro Datei als Text) ist durch Nullen gleicher Länge ersetzt. Andere Kennungen enthalten die Dateien nicht, auch keine Ortsdaten (das Gerät hat kein GPS). Enthalten sind Datum, Uhrzeit, Profil, Firmware, Hardware-Version und Akkustand.
- **Geprüft:** Nach dem Anonymisieren auf dem Handy erneut mit `parseRawDiveData` gelesen. Tiefe, Dauer sowie die Anzahl der Samples, Ereignisse und Flaschen stimmen mit der Aufnahme überein.
- **`*.expected.json`:** Werte des Parsers bei der Aufnahme. `avg_depth_m` ist **0,0** und `min_temperature_c` **null**, weil der EON Core diese Werte nicht mitliefert, obwohl die Samples Tiefe und Temperatur enthalten. Der Adapter (T4) muss beides aus den Samples berechnen und darf die 0,0 nicht übernehmen.
- **Lizenz:** eigene Tauchdaten, Teil von DiveDown (GPL-3.0-or-later).
