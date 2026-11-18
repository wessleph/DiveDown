# ADR 0002: Tauchcomputer-Anbindung über das übernommene `libdivecomputer_plugin`

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18
- Ersetzt einen Punkt der Constitution: „libdivecomputer via `dart:ffi`“ (siehe Konsequenzen)

## Kontext
Die Recherche (Option B) ging von eigenen `dart:ffi`-Bindings aus. Submersion zeigt einen anderen, erprobten Weg:
- Das Paket `packages/libdivecomputer_plugin` hat rund 19.500 Zeilen und **importiert nichts aus der Submersion-App**, es ist also in sich geschlossen.
- Die Schnittstelle zu Dart ist mit **Pigeon** typsicher erzeugt (`DiveComputerHostApi` / `DiveComputerFlutterApi`):
  `getDeviceDescriptors`, `startDiscovery`, `startDownload`, `cancelDownload`, `submitPinCode`, `parseRawDiveData` sowie die Callbacks `onDiveDownloaded`, `onDownloadProgress` und `onError`.
- **BLE läuft nativ pro Plattform**: Kotlin auf Android, Swift auf iOS, jeweils mit eigenen `BleIoStream`, `BleScanner` und Diagnose-Code.
  Das ist genau der schwierige Teil, den wir sonst selbst bauen müssten (libdivecomputer hat kein eigenes BLE).
- libdivecomputer ist als Git-Submodul eingebunden: `submersion-app/libdivecomputer`, Branch `submersion-patches`, mit 10 Patches, vor allem für Shearwater.
- **Suunto EON Core** wird unterstützt (`DC_FAMILY_SUUNTO_EONSTEEL`, BLE und USB-HID).
  Für die **Suunto Ocean** gibt es in diesem Stand noch keinen Treiber.

## Optionen
1. Eigene `dart:ffi`-Bindings plus eigener BLE-Transport (Option B aus der Recherche).
2. **Das Plugin als eigenes Paket übernehmen** (`packages/libdivecomputer_plugin`).
3. Das Plugin als Git-Abhängigkeit direkt aus dem Submersion-Repo einbinden.

## Entscheidung
**Option 2.** Wir übernehmen das Plugin vollständig nach `packages/libdivecomputer_plugin/`. Änderungen am Plugin halten wir klein und kennzeichnen sie.
- Für **libdivecomputer** gibt es eine Update-Quelle: zuerst Submersions Fork (`submersion-patches`). Wir prüfen, ob wir einen eigenen Fork brauchen. Falls ja, ist das Original `libdivecomputer/libdivecomputer` mit denselben Patches die Basis.
  Damit kommt der Ocean-Treiber (PR #73), sobald er gemergt ist, mit dem nächsten Update.
- Desktop-Teile (Linux, Windows, macOS) nehmen wir zunächst **nicht** mit, es gibt nur iOS und Android.
  **Korrektur vom 2026-11-18 (security.md §9.2):** `macos/Classes/` bleibt erhalten, weil der Android-Build die C-Wrapper von dort kompiliert (`android/src/main/cpp/CMakeLists.txt:6`). Entfernt werden nur `linux/`, `windows/` und die macOS-Einträge im Plugin-`pubspec.yaml`.
- **Korrektur vom 2026-11-18 (Security A3):** Für libdivecomputer legen wir **einen eigenen Fork** an, mit Submersions Patches als Ausgangspunkt. Das Submodul wird auf einen geprüften Commit gepinnt, **ohne** `branch =`-Eintrag.
- Option 3 verwerfen wir, weil jedes Upstream-Update ungeprüft durchschlagen würde.

## Konsequenzen
- **Die Constitution wird angepasst:** „`libdivecomputer` über das native Plugin (Pigeon + Kotlin/JNI bzw. Swift)“ statt „via `dart:ffi`“.
- Plattformspezifischer Code (Kotlin und Swift) ist damit Teil von DiveDown. Wir bauen ihn aber nicht selbst neu, sondern pflegen ihn nur mit.
- iOS: libdivecomputer wird per `build_libdc.sh` statisch gebaut. Weil DiveDown unter GPL-3 steht und der gesamte Quellcode öffentlich ist, ist die LGPL-Pflicht zum Neu-Linken erfüllt.
- Mindestversionen: iOS 15, Android minSdk 26 (wie Submersion, endgültig festgelegt in ADR 0005).
- Das Runbook `docs/entwickler/runbooks/libdivecomputer-update.md` (Phase 80) beschreibt: Submodul hochziehen → Patches prüfen → Fixture-Tests → TestFlight.
