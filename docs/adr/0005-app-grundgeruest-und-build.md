# ADR 0005: App-Grundgerüst, State-Management, Build und Verteilung

- Status: **angenommen** (2026-11-18)
- Datum: 2026-11-18

## Kontext
Entwickelt wird unter Windows, ein Mac ist nicht vorhanden. Zielplattformen sind iOS und Android.
Verteilt wird privat an Freunde und Familie (research.md, 8.3).
Die Grundbausteine sollen zu Submersion passen, damit sich übernommener Code leicht anpassen lässt.

## Entscheidung
**Grundgerüst**
- Flutter **3.47.0**, auf dieselbe Version festgelegt wie in Submersion (`.github/flutter-version.txt`).
- State-Management: **Riverpod 3**. Navigation: **go_router**. Diagramme: **fl_chart**. Lokalisierung: `flutter_localizations` mit ARB-Dateien; nur **de**, weitere Sprachen später möglich.
- Ordnerstruktur:
  ```
  lib/
    app/            App-Start, Router, Theme
    domain/         Modelle und Regeln, ohne Flutter-Abhängigkeit (import/, metrics/, dive/)
    data/           local/ (Drift), import/<quelle>/, später sync/
    features/<feature>/  Oberfläche + Provider pro Feature
  packages/
    libdivecomputer_plugin/   (ADR 0002)
  ```
- Mindestversionen: **iOS 15**, **Android minSdk 26**.

**Build und Verteilung**
- **Android:** lokal unter Windows bauen und testen. Verteilt wird per signierter APK, später optional über den internen Test bei Google Play.
- **iOS:** gebaut wird über **GitHub Actions** mit macOS-Runnern (kostenlos für öffentliche Repos), Upload zu **TestFlight**.
  Zertifikate und Profile laufen über die API des App Store Connect und liegen als GitHub Secrets vor. Dafür ist kein Mac nötig.
  Die Workflows von Submersion (`build-all.yml`, `beta.yml`) dienen als Vorlage.
- **Alternative**, falls GitHub Actions zu umständlich wird: Codemagic (auf Flutter spezialisiert, kostenloses Kontingent).
- CI für jeden Push: `flutter analyze`, `flutter test`, Android-Build. iOS-Build nur auf dem Haupt-Branch und bei Tags.

## Konsequenzen
- Voraussetzung ist ein **Apple-Entwicklerkonto** (ca. 99 €/Jahr).
- TestFlight-Builds laufen nach 90 Tagen ab. Deshalb brauchen wir mindestens alle drei Monate einen neuen Build, idealerweise per geplantem Workflow.
- Fehler beim iOS-BLE sind erst im TestFlight-Build sichtbar. Deshalb ist es Pflicht, die Tauchcomputer-Logik mit aufgezeichneten Fixtures zu testen (Phase 40).
- Für Builds auf eigenen Geräten bei der Entwicklung braucht es ebenfalls TestFlight, weil lokale iOS-Builds ohne Mac nicht möglich sind.

## Nachtrag 2026-11-18: Kein eigenes iPhone, alle Nutzer außer mir haben iPhone
- **Ich entwickle und teste auf Android.** iOS ist trotzdem die Hauptplattform für Familie und Freunde.
- **Verteilung iOS, Stufe 1:** TestFlight mit **öffentlichem Einladungslink**. Updates kommen automatisch über die TestFlight-App.
  Ein Release-Tag in Git löst den Build über GitHub Actions aus, der Build geht zu TestFlight, und die Tester bekommen eine Benachrichtigung bzw. ein automatisches Update.
  Ein geplanter Workflow baut spätestens alle 80 Tage neu, damit kein Build abläuft.
- **Verteilung iOS, Stufe 2 (optional):** **Nicht gelistete App im App Store** (Unlisted App Distribution, auf Antrag bei Apple).
  Die App ist dann nur per Link auffindbar, Updates laufen wie bei jeder Store-App automatisch, und es gibt kein Ablaufen nach 90 Tagen.
  Das bedeutet mehr Aufwand beim Review (Datenschutzerklärung, Screenshots).
- **Testen auf iOS:** Ohne eigenes iPhone übernehmen Familienmitglieder das Testen über TestFlight.
  Die Schwester (iPhone) ist das erste Testgerät. Um BLE auf iOS zu testen, wird die EON Core an ihr iPhone gekoppelt.
  Der Freund testet den Import aus Apple Health. Fixture-Tests (Phase 40) sind deshalb **Pflicht**, weil Fehler auf iOS nur aus der Ferne sichtbar werden.
  Zusätzlich braucht der iOS-Build einen eingebauten Export für Diagnose-Logs (z. B. „Logs teilen“ per Mail oder Messenger). Das Plugin liefert über `onLogEvent` bereits Logs.
- **Android (ich):** signierte APK über GitHub Releases. Automatische Updates sind z. B. mit **Obtainium** möglich, das neue GitHub-Releases erkennt und installiert.
- Ein Apple-Entwicklerkonto (ca. 99 €/Jahr) ist für alle sinnvollen iOS-Wege **zwingend**. Wir brauchen es erst, wenn der erste iOS-Build an Tester gehen soll.
