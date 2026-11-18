# Recherche: Tauchcomputer-Import

> Phase 00 · Stand: 2026-11-18 · Status: **abgeschlossen.** Alle offenen Fragen sind beantwortet. Weiter mit `10-architektur`.
> Dieses Dokument trifft bewusst **keine** Entscheidung. Das passiert in Phase 10 per ADR.

## 1. Kontext

Ziel: Tauchgänge vom Tauchcomputer direkt auf das Handy (iOS + Android) übertragen
und im lokalen DiveDown-Logbuch speichern. Das muss komplett offline funktionieren,
und bei Updates soll möglichst nur die Bibliothek nachgezogen werden müssen
(siehe `docs/constitution.md`).

Noch kein Code und keine Specs, ADRs gibt es noch nicht. Das ist das erste Feature.

### Funktionale Vorlage DiveMate (nur öffentlich sichtbares Verhalten)
Laut öffentlichen Quellen (Store-Seiten, Hersteller-Blog):
- Übertragung per Bluetooth (BLE), USB und Infrarot (älter); was geht, hängt von Plattform und Modell ab.
- Shearwater Petrel 2 per BLE auch auf iOS; ältere Shearwater (Petrel, Nerd, Predator) nur auf Android.
- Anzeige von Tiefenprofil, Flaschendruck, Temperatur, dazu RMV/SAC, Gewicht, Flasche, Gase.
- Export und Backup (Google Drive, Dropbox), Import in Subsurface.

Was DiveDown davon für den Import braucht, steht in den offenen Fragen.

## 2. Technische Fakten

| Thema | Fakt | Folge für DiveDown |
|---|---|---|
| Bibliothek | `libdivecomputer` (C), Autor Jef Driesen, **LGPL 2.1**, über 300 Modelle | Kern des Imports, Lizenzfrage siehe 4. |
| BLE | libdivecomputer **implementiert BLE nicht selbst**. Die App muss den BLE-Transport liefern (Callbacks über „custom iostream“). | Wir brauchen ein Flutter-BLE-Paket und eine Brücke zu den C-Callbacks. |
| iOS | **Nur BLE.** Kein USB und kein klassisches Bluetooth (BT Classic). Ältere Geräte mit BT Classic (z. B. Aqualung i750TC) oder nur Kabel gehen auf dem iPhone nicht. | Welche Geräte wir haben, ist entscheidend (Frage 6.1). |
| Android | BLE, BT Classic und USB-Seriell (FTDI u. a.) möglich | Mehr Geräte als iOS, aber mehr Transportcode. |
| Neue Firmware | Neue Firmware kann neue BLE-Kennungen haben, die libdivecomputer noch nicht kennt (aktuelles Beispiel: Mares Puck 4, FW 01.05.01). | Genau dein Pflegefall: Bibliothek aktualisieren, Runbook in Phase 80. |
| Zwei Upstreams | Original `libdivecomputer` und der **Subsurface-Fork `subsurface/libdc`** (mehr BLE-Fixes, wird regelmäßig mit dem Original abgeglichen, zuletzt im Mai 2026) | Welche Quelle wir verwenden, muss per ADR entschieden werden. |
| Nur neue Tauchgänge | libdivecomputer nutzt einen **Fingerprint** des letzten Tauchgangs, damit nur neuere übertragen werden. | Fingerprint pro Gerät lokal speichern. Das ist schneller und schont den Akku. |
| Gelieferte Daten | Zusammenfassung (Datum, max./mittlere Tiefe, Dauer, Gase, Salzgehalt, Luftdruck) und Profil-Samples (Zeit, Tiefe, Temperatur, Flaschendruck, Deko/NDL, Events) | Grundlage für das Datenmodell in Phase 10. |
| Tests ohne Gerät | Rohdaten (Dumps) lassen sich aufzeichnen und offline parsen. | Passt zu `40-tests` (Fixtures unter `test/fixtures/divecomputer/`). |

## 3. Optionen

### Option A: Fertiges Flutter-Paket `dive_computer` (pub.dev)
- Flutter-Plugin um libdivecomputer, Plugin-Code BSD-3, die Bibliothek selbst LGPL 2.1.
- Stabil ist nur 0.0.1 (Android, Windows, Linux). Die Vorabversion 0.1.0-dev.2 meldet auch iOS und macOS, ist aber **etwa 20 Monate alt**. Die Installationsdoku ist unvollständig.
- Führt die Kommunikation in einem eigenen Isolate aus.
- **Pro:** schnellster Start, Bindings schon vorhanden.
- **Contra:** wirkt unbetreut. Wir hängen am Update-Tempo eines Dritten, was deinem Pflegeziel widerspricht. Wie es BLE auf iOS löst, ist ungeklärt.
- Offline: ja. NAS: nicht betroffen. Pflege: **hoch, wenn das Paket stehen bleibt** (dann Fork nötig).

### Option B: Eigene `dart:ffi`-Bindings an libdivecomputer (Original oder Subsurface-Fork)
- Bindings mit `ffigen` aus den C-Headern erzeugen, die Bibliothek als Git-Submodul im Repo, Bau über die Native-Toolchain von Flutter.
- BLE-Transport selbst bauen: Flutter-BLE-Paket ↔ C-Callbacks.
- **Pro:** volle Kontrolle. Ein Update heißt: Submodul hochziehen, Bindings neu erzeugen, Fixture-Tests laufen lassen. Das passt genau zu „Pflege nur bei Tauchcomputer-Updates“.
- **Contra:** größter Anfangsaufwand, besonders bei BLE-Callbacks über die Thread-Grenze (C ↔ Dart) und beim Cross-Compile für iOS und Android.
- Offline: ja. NAS: nicht betroffen. Pflege: **gering und planbar**.

### Option C: Native Wrapper pro Plattform plus Platform Channels
- iOS: z. B. `libdc-swift` (Swift, nur BLE, letzte Version 1.4.0 vom Mai 2025, Commits bis Januar 2026). Android: eigene JNI/Kotlin-Schicht.
- **Pro:** BLE läuft jeweils mit nativen APIs, die gut dokumentiert sind.
- **Contra:** **zwei Codebasen** für dieselbe Aufgabe, das widerspricht der Idee von Flutter. Dazu kommt die Abhängigkeit vom Update-Tempo von libdc-swift.
- Offline: ja. Pflege: **mittel bis hoch** (zwei Wrapper aktuell halten).

### Option D (ergänzend, keine Alternative): Import aus Dateien
- UDDF (offenes Austauschformat), Subsurface-XML, Garmin-FIT, Exporte aus Hersteller-Apps.
- **Pro:** deckt Geräte ab, die auf dem iPhone nicht per BLE gehen, und bestehende Logbücher (z. B. aus DiveMate oder Subsurface).
- **Contra:** zusätzliche Parser, kein direktes Auslesen vom Gerät.
- Offline: ja. Pflege: gering.

### BLE-Paket für Flutter (gilt für A und B)
| Paket | Hinweis |
|---|---|
| `flutter_blue_plus` | Sehr verbreitet. **Lizenz vor Einsatz prüfen**, weil sich die Lizenzbedingungen in den letzten Versionen geändert haben sollen. |
| `flutter_reactive_ble` | Verbreitet, Lizenz und Wartungsstand prüfen. |
| USB (nur Android) | z. B. `usb_serial`, Lizenz prüfen. |
Die Lizenzen und den Wartungsstand prüfe ich erst in Phase 20, nicht jetzt.

### Referenzprojekte zum Lernen (kein Kopieren ohne Lizenzprüfung)
- **Submersion:** Open-Source-Logbuch in Flutter mit libdivecomputer, über 300 Geräte, auch iOS und Android. Nachweislich funktionieren laut README Shearwater Teric sowie Aqualung i300C und i330R. **Die Lizenz habe ich noch nicht geprüft.** Falls GPL, dürfen wir Code nur übernehmen, wenn DiveDown selbst unter einer kompatiblen Lizenz steht (Frage 6.3).
- **Subsurface-mobile:** zeigt, wie BLE auf iOS mit libdivecomputer praktisch gelöst wird (GPL).

## 4. Lizenz: libdivecomputer (LGPL 2.1)
- Auf iOS werden Bibliotheken typischerweise **statisch** gelinkt. Die LGPL verlangt dann, dass Nutzer die App mit einer geänderten Version der Bibliothek neu linken können. Üblich ist, die Objektdateien (.o) mitzuliefern.
- Ob das mit der Verteilung über den **öffentlichen App Store** vereinbar ist, ist seit Jahren umstritten und nicht geklärt.
- **Für DiveDown wichtig:** Die App ist nur für dich, Freunde und Familie gedacht. Wird sie per TestFlight, Ad-hoc oder Android-APK verteilt und nicht öffentlich im Store angeboten, wird die Frage deutlich entspannter. Ist DiveDown **selbst Open Source**, ist die LGPL praktisch kein Thema mehr.
- Eingebettete dynamische Frameworks auf iOS wären eine technische Alternative, das prüfe ich in Phase 10 und 20.
- *Hinweis: Das ist keine Rechtsberatung. Für eine öffentliche, kommerzielle Veröffentlichung sollte jemand vom Fach draufschauen.*

## 5. Trade-off-Überblick

| | A `dive_computer` | B eigene FFI | C native Wrapper | D Datei-Import |
|---|---|---|---|---|
| Startaufwand | niedrig | hoch | mittel bis hoch | niedrig bis mittel |
| Langfristige Pflege | Risiko (Paket alt) | gering, planbar | mittel bis hoch | gering |
| Kontrolle bei neuen Geräten | gering | voll | mittel | nicht anwendbar |
| iOS-BLE geklärt | unklar | selbst gebaut | ja (libdc-swift) | nicht nötig |
| Eine Codebasis | ja | ja | nein | ja |
| Offline | ja | ja | ja | ja |

Hybride sind möglich, z. B. A als Prototyp und später B, oder B plus D.

## 6. Offene Fragen an dich

1. **Welche Tauchcomputer gibt es bei dir, Freunden und Familie?** Bitte genaues Modell, wenn möglich auch die Firmware.
   Und wer nutzt iPhone, wer Android? Das entscheidet, ob BLE reicht oder USB und BT Classic nötig sind.
2. **Wie soll die App verteilt werden?** Per TestFlight bzw. Ad-hoc (Apple-Entwicklerkonto, ca. 99 €/Jahr) und APK, oder später auch öffentlich im App Store und bei Google Play?
   Hast du schon ein Apple-Entwicklerkonto?
3. **Darf DiveDown selbst Open Source sein** (z. B. auf GitHub)? Das vereinfacht die LGPL-Frage erheblich und würde erlauben, aus Submersion und Subsurface zu lernen und, je nach Lizenz, Code zu übernehmen.
4. **Alte Logbücher übernehmen?** Hast du Tauchgänge in DiveMate oder einer anderen App, die übernommen werden sollen? Wenn ja: Welche Exportformate bietet sie dir an (z. B. UDDF, Subsurface-XML, CSV)?
5. **Welche Daten sind dir wichtig?** Nur Profil, Tiefe, Zeit und Temperatur, oder auch Flaschendruck (AI-Sender), Gase und Nitrox/Trimix, Deko-Stopps, Warnungen und Events?
6. **Umfang der ersten Version:** Nur Tauchgänge **auslesen**, oder auch Gerät **konfigurieren** (Uhrzeit setzen, Einstellungen)? Vorschlag aus Pflegesicht: nur auslesen.
7. **Priorität Prototyp vs. Fundament:** Lieber schnell etwas sehen (A als Prototyp ist denkbar) oder direkt das wartbare Fundament (B)?

## 7. Antworten (2026-11-18)

| # | Antwort | Folge |
|---|---|---|
| 1 | Ich und meine Schwester haben Suunto. Mein Bruder hat keinen Tauchcomputer. Ein Freund nutzt nur die Apple Watch. | Kern ist **Suunto per BLE**. Für Bruder und Freund braucht es **manuelle Eingabe**, für den Freund zusätzlich **Import aus Apple Health** (siehe unten). **Genaue Suunto-Modelle noch offen.** |
| 2 | App Store wäre schön, aber vermutlich zu viel Aufwand | Zu klären in Phase 10 (siehe 8.3) |
| 3 | Open Source ist okay. Ähnliche Projekte suchen. | Die LGPL ist damit kein Hindernis mehr. Submersion als Basis prüfen (siehe 8). |
| 4 | Keine alten Logbücher | Option D (Datei-Import) ist nur noch für die Apple Watch relevant. |
| 5 | Alle Daten, besonders Tiefe, Flaschendruck und Luftverbrauch grafisch | Profil-, Druck- und SAC-Diagramme sind Kernumfang. |
| 6 | Nur auslesen | Keine Gerätekonfiguration |
| 7 | Wünscht eine Empfehlung | siehe 8.4 |

### Suunto
- Die EON Steel und EON Core werden von libdivecomputer per BLE unterstützt (u. a. in der Geräteliste von libdc-swift). Den D5 erkennt Subsurface seit 2019 am Bluetooth-Namen.
- Es gibt Berichte über Verbindungsprobleme nach Firmware-Updates (EON Core 2021) und auf iOS (D5 in MacDive; Abhilfe: Gerät in den iPhone-Bluetooth-Einstellungen „ignorieren“).
- **Unsere Geräte (2026-11-18):** EON Core (ich) und Ocean (Schwester).
- **EON Core:** von libdivecomputer per BLE unterstützt. Mit dem echten Gerät testen, besonders nach Firmware-Updates.
- **Ocean:** **noch nicht sicher unterstützt.** Sie gehört zur neuen Suunto-Generation „Vaasa“ (zusammen mit Nautic und Nautic S).
  - Es gibt einen offenen Pull Request bei libdivecomputer (#73) mit einem BLE-Treiber für Nautic und Ocean. Getestet wurde er laut Beschreibung nur mit Nautic-Geräten. Ob er gemergt ist, ist unklar.
  - Ein Entwickler im Subsurface-Forum meldet, dass ein Entwicklungs-Build mit seiner Ocean funktioniert.
  - **Ausweg, der heute schon geht:** In der Suunto-App die Tauchgänge als **FIT-Datei** exportieren und importieren (Subsurface kann das seit v6.0.5245).
  - Folge: DiveDown braucht neben BLE auch einen **FIT-Import**, mindestens bis der Ocean-Treiber in libdivecomputer angekommen ist.

### Apple Watch
- Die Watch (Ultra) schreibt Tiefe und Wassertemperatur als Samples in Apple Health, unabhängig von der Tauch-App. Laut Forenberichten werden Tiefen über ca. 44 m nicht erfasst (nicht offiziell bestätigt).
- Eine iOS-App kann diese Daten über HealthKit lesen. Es gibt Tiefe, Temperatur und Puls, aber **keinen Flaschendruck**.
- Daten aus Oceanic+ landen nur eingeschränkt in Apple Health.

## 8. Neuer Befund: Submersion deckt den Großteil von DiveDown ab

### 8.1 Was Submersion ist (Stand: Release v1.8.4 vom 07.11.2026)
- **GPL-3.0**, Open Source. Kostenlos, ohne Werbung, Abo oder In-App-Käufe.
  **Bereits im App Store und bei Google Play**, Betas per TestFlight.
- Stack: Flutter, Riverpod, **Drift/SQLite** (verschlüsselt), go_router, **fl_chart**, **flutter_map/OSM** und libdivecomputer per FFI (Git-Submodul). Das ist **fast identisch mit dem Stack, den wir für DiveDown geplant haben**.
- Funktionen: über 350 Tauchcomputer (iOS nur per BLE), **Import von der Apple Watch über Apple Health**, interaktive Diagramme für Tiefe, Temperatur, Druck und SAC, SAC-Trends, Ausrüstung mit Wartungsplänen, Tauchplatz-Karte mit **Offline-Regionen**, Tauchplaner, mehrere Profile für Taucher in einer App.
- Sync: Ende-zu-Ende-verschlüsselt über **den eigenen Speicher**: iCloud, Google Drive, Dropbox, **S3-kompatibel** und laut Release-Notes auch **Git**. Kein Konto und kein Server nötig.
- Teilen: Buddy-Karten per QR, NFC und Datei, Ausrüstung verleihen, Unterschrift durch den Buddy. **Geteilte Logbücher zwischen mehreren Nutzerkonten habe ich nicht gefunden.**
- Sprachen: „11 Sprachen“, **ob Deutsch dabei ist, ist unbestätigt**. Suunto wird nicht namentlich genannt.
- Aktivität: 99 Sterne, 42 Forks, 5 Contributors am letzten Release, regelmäßige Releases.

### 8.2 Neue Optionen
- **Option E: Submersion direkt nutzen** und fehlende Dinge (Deutsch, Teilen in der Familie) bei Bedarf als Beitrag ins Original-Projekt einbringen.
  Aufwand: minimal. Pflege: **keine**, das Projekt pflegt libdivecomputer selbst. Nachteil: kein eigener Stil, kein eigenes Produkt.
- **Option F: Submersion forken und als DiveDown weiterentwickeln** (GPL-3): eigener Stil, Deutsch, Teilen über den NAS.
  Aufwand: mittel. Pflege: **Änderungen aus dem Original müssen regelmäßig übernommen werden**, das widerspricht dem Ziel „Pflege nur bei Tauchcomputer-Updates“ teilweise.
- **Option G: DiveDown neu bauen, Submersion als Codequelle nutzen** (DiveDown unter GPL-3, also kompatibel). Gezielt Teile übernehmen, z. B. die libdivecomputer-FFI-Brücke oder den HealthKit-Import.
  Aufwand: hoch, aber deutlich geringer als bei Option B allein. Pflege: gering und planbar.
- Die Optionen A bis C aus Abschnitt 3 bleiben bestehen, sind aber neben F und G deutlich unattraktiver.

### 8.3 App Store oder private Verteilung
- **App Store:** Apple-Entwicklerkonto (ca. 99 €/Jahr), Review, Datenschutzerklärung, Screenshots. Bei Konten muss man das Konto in der App löschen können.
- **TestFlight:** ebenfalls mit Entwicklerkonto, bis 10.000 Tester per Link, leichteres Review. **Builds laufen nach 90 Tagen ab**, es braucht also regelmäßig einen neuen Build.
- **Android:** APK direkt oder Google Play (25 $ einmalig, interne Tests sind einfach).
- **Wichtig:** iOS-Apps lassen sich nur auf **macOS** mit Xcode bauen. Ohne Mac gehen CI-Runner, z. B. die macOS-Runner von **GitHub Actions** (für öffentliche Repos kostenlos) oder Codemagic.

### 8.4 Empfehlung (die Entscheidung liegt bei dir)
1. **Erst testen, dann bauen:** Submersion diese Woche mit den Suunto-Geräten von dir und deiner Schwester ausprobieren, dazu den Apple-Watch-Import beim Freund. Ein Nachmittag Test spart womöglich Monate Arbeit.
2. Danach entscheiden:
   - Funktioniert alles und gefällt es dir? Dann **Option E**. DiveDown wird ggf. zu Beiträgen ins Original, z. B. eine deutsche Übersetzung oder Familien-Teilen über den NAS.
   - Funktioniert es, aber du willst ein eigenes Produkt mit eigenem Stil und Familien-Sync über den NAS? Dann **Option G**: eigener, schlanker Kern, gezielt Code aus Submersion übernehmen, kein dauerhaftes Abgleichen mit einem Fork.
   - Option F nur, wenn du Submersion zu 90 % so willst, wie es ist.
3. Verteilung: **TestFlight plus APK** statt öffentlichem App Store, mit iOS-Builds über GitHub Actions. Der öffentliche Store kann später kommen.

### 8.4a Richtungsentscheidung (2026-11-18)
Submersion ist die **Grundlage für DiveDown**, und daraus entsteht eine eigene Anwendung.
**Gewählt: Option G, ein eigener Kern mit gezielt übernommenen Teilen aus Submersion** (kein dauerhafter Fork). Formal festgehalten wird das als ADR in Phase 10, zusammen mit der Liste der übernommenen Teile.
Folgen der GPL-3 für das Projekt: DiveDown steht unter GPL-3, Copyright-Hinweise von Submersion bleiben erhalten, eigener Name und eigenes Logo (Name und Logo „Submersion“ werden nicht übernommen). Für die Tauchplatz-Daten gilt die ODbL: Quelle nennen, Änderungen ebenfalls unter ODbL. Prüfen, ob die GPL-3 mit dem App Store bzw. TestFlight vereinbar ist (Phase 20).

### 8.5 Neue offene Fragen
- ~~**8.5.1** Welche genauen Suunto-Modelle habt ihr?~~ → Beantwortet: EON Core und Ocean (siehe Abschnitt 7, Suunto).
- **8.5.2** Testest du Submersion vor der Entscheidung? Dabei prüfen: Klappt die Suunto-Übertragung, gibt es Deutsch, gefällt dir die Bedienung?
- ~~**8.5.3** Mac oder Cloud?~~ → Beantwortet: **kein Mac, die iOS-Builds laufen in der Cloud** (z. B. GitHub Actions mit macOS-Runnern oder Codemagic; Entscheidung per ADR in Phase 10). Entwickelt wird unter Windows; getestet wird auf Android direkt, auf iOS über TestFlight.
- ~~**8.5.4** Eigenes Produkt oder Werkzeug?~~ → Beantwortet: eigenes Produkt (Option G).
- 8.5.2 (Submersion vorab testen) ist kein Muss mehr, bleibt aber sinnvoll: Ein Test mit der EON Core zeigt, ob der übernommene Code mit deinem Gerät funktioniert.

## Quellen
- [dive_computer auf pub.dev](https://pub.dev/packages/dive_computer) · [0.1.0-dev.2](https://pub.dev/packages/dive_computer/versions/0.1.0-dev.2)
- [libdc-swift (deepsealabs)](https://github.com/deepsealabs/libdc-swift)
- [Subsurface libdc: Upstream-Abgleich #112](https://github.com/subsurface/libdc/pull/112)
- [Subsurface-Forum: Mares Puck 4 BLE](https://groups.google.com/g/subsurface-divelog/c/wli2zJJUMSE) · [Aqualung i750TC auf iOS](https://groups.google.com/g/subsurface-divelog/c/FUAhgmV_1mM)
- [Subsurface Mobile Manual](https://platform-test.sunet.se/mifr/subsurface/raw/tag/latest/Documentation/mobile-manual-v2.txt)
- [Submersion](https://submersion.app/) · [GitHub](https://github.com/submersion-app/submersion) · [Releases](https://github.com/submersion-app/submersion/releases) · [App Store](https://apps.apple.com/us/app/submersion-dive-log/id6757456915) · [Google Play](https://play.google.com/store/apps/details?id=app.submersion)
- [Suunto D5 per Bluetooth (MacDive-Forum)](https://mac-dive.com/forum/viewtopic.php?p=11604) · [EON Core nach Firmware-Update](https://groups.google.com/g/subsurface-divelog/c/uZ6jtdblayE)
- [libdivecomputer PR #73: Suunto Nautic/Ocean BLE](https://github.com/libdivecomputer/libdivecomputer/pull/73) · [Subsurface-Forum: Suunto Ocean](https://groups.google.com/g/subsurface-divelog/c/DzD_euQVVYY) · [Suunto-Forum: Export nach Subsurface](https://forum.suunto.com/topic/11278/export-dive-logs-to-subsurface)
- [Apple Watch Ultra: Export der Tauchdaten (ScubaBoard)](https://scubaboard.com/community/goto/post?id=9868358) · [AWU2UDDF](https://apps.apple.com/us/app/awu2uddf/id1661616210?l=en)
- [Shearwater: Petrel2 und DiveMate](https://shearwater.com/blogs/community/petrel2-and-divemate-for-ios)
- [FFmpeg-Ticket #1229: LGPL und iOS](https://trac.ffmpeg.org/ticket/1229)
