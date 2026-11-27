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

## Nachtrag 2026-11-18: Apple-Entwicklerkonto zunächst für ein Jahr
- **Entscheidung:** Das Apple-Entwicklerkonto (99 USD/Jahr) wird für das **erste Jahr** bezahlt. Damit sind alle iPhone-Funktionen verfügbar (BLE, Apple Health), und der Weihnachtstermin ist sicher.
- **Geprüfte Alternativen ohne Konto** (verworfen für v1.0):
  - Sideloading mit kostenloser Apple-ID: Ablauf nach 7 Tagen, Neusignieren am PC jede Woche
  - alternative App-Marktplätze: nur EU, nicht in der Schweiz, und auch dort Entwicklerkonto nötig
  - Gebührenbefreiung: nur für Organisationen
- **Nach Weihnachten zu prüfen, vor der ersten Verlängerung:** eine **Web-App** (Flutter Web, PWA über GitHub Pages) für die iPhones.
  Sie reicht für FIT-Import (Schwester), manuelle Eingabe (Bruder) und Diagramme. Sie reicht **nicht** für BLE und Apple Health auf dem iPhone. Für den Apple-Watch-Nutzer bräuchte sie einen UDDF-Import über eine Export-App.
  Risiko: Safari kann die Speicherdaten einer Web-App löschen.
  Wichtig: Läuft das Konto aus, funktionieren TestFlight-Builds nicht mehr. Ein Umstieg muss also **vor Ablauf** fertig sein.

## Nachtrag 2026-11-27: Android über den internen Test von Google Play
- Status: **angenommen** (2026-11-27)
- **Kontext:** Das Play-Console-Konto ist verifiziert („Kein Händler“). Ein öffentlicher Store-Eintrag braucht für neue private Konten vorher einen geschlossenen Test mit mindestens 12 Testern über 14 Tage. Der **interne Test** hat laut Google keine Vorbedingungen („Requirements to access track: None“), keine Store-Prüfung, bis zu 100 Tester per E-Mail-Liste, und Updates sind „within minutes“ bei den Testern. Quellen, abgerufen am 2026-11-27: [Testanforderungen für neue private Konten](https://support.google.com/googleplay/android-developer/answer/14151465), [Tests einrichten](https://support.google.com/googleplay/android-developer/answer/9845334), [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756).
- **Entscheidung:**
  - **Android, Stufe 1:** Familie und Freunde installieren DiveDown über den **internen Test** von Google Play, per Einladungslink. Updates kommen automatisch über den Play Store, wie bei TestFlight unter iOS.
  - **Weiterhin:** die signierte APK mit dem Fingerabdruck in der README, für alle ohne Google-Konto (z. B. über GitHub Releases und Obtainium).
  - **Signatur:** Der bestehende Schlüssel `divedown` (T33) wird **App-Signaturschlüssel bei Google** (Play App Signing, „Provide a copy of your app signing key“). Zum Hochladen dient ein **neuer, eigener Upload-Schlüssel**, wie Google es empfiehlt. Damit haben Store-App und APK **dasselbe Zertifikat**: Der Fingerabdruck in der README gilt für beide, und ein Gerät kann zwischen APK und Store wechseln, ohne neu zu installieren. Festgelegt wird das **vor dem ersten Hochladen**.
  - Hochgeladen wird ein **App-Bundle** (`flutter build appbundle --release`), gebaut wie die APK nur am PC, nie in der CI.
  - Ein öffentlicher Store-Eintrag (geschlossener Test, Produktion) bleibt offen, wie die nicht gelistete App unter iOS (Stufe 2).
- **Konsequenzen:**
  - Jeder Tester braucht ein **Google-Konto**, seine Adresse steht in der Tester-Liste der Play Console.
  - Die **Build-Nummer** in `pubspec.yaml` (`1.0.0+N`) muss bei jedem Upload steigen. Google nimmt keine Nummer zweimal.
  - Eine Kopie des App-Signaturschlüssels liegt bei Google. Der Upload-Schlüssel wird wie der bisherige gesichert (verschlüsselt an zwei Orten, nie im Repo). Geht er verloren, lässt er sich bei Google zurücksetzen; den App-Signaturschlüssel nicht.
  - Mit dem Anlegen der App in der Play Console ist der Paketname bei Google registriert (Android-Entwicklerverifizierung). Ob das auch die APK abdeckt, sagt Google nicht; wird geprüft, sobald die Pflicht für die Schweiz kommt (`android-release-einrichtung.md` §8).
  - Die Datenschutzerklärung nennt Google Play als Vertriebsweg, wie schon TestFlight.
  - Neue Apps müssen auf API 36 oder höher zielen; der Build tut das (Flutter-Standard).
