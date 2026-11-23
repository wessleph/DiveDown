# ADR 0008: GPL-Code aus Submersion und die Verteilung über Apple

- Status: **vorgeschlagen** (2026-11-23)
- Datum: 2026-11-23
- Bezug: ADR 0001 (offene Frage „Verträgt sich die GPL-3 mit App Store und TestFlight?“), ADR 0002, ADR 0005, `LICENSE`, `THIRD_PARTY.md`

## Kontext
Ab Dezember 2026 geht DiveDown über **TestFlight** an Familie und Freunde, später eventuell als **nicht gelistete App** in den App Store (ADR 0005).
Die Bedingungen von Apple (Nutzungsregeln, FairPlay-Verschlüsselung) gelten nach Ansicht der FSF als **zusätzliche Einschränkungen** im Sinne von GPL-3 §10. Wer GPL-Code über Apple verteilt, an dem er die Rechte nicht selbst hält, verletzt damit möglicherweise die Lizenz.
Durchsetzen können das nur die **Rechteinhaber**. Bekannter Fall: VLC wurde 2011 nach der Beschwerde eines Mitautors aus dem App Store entfernt.

- **Eigener Code:** `LICENSE` enthält bereits eine Zusatzerlaubnis nach GPL-3 §7 für App Stores und TestFlight. Damit ist der eigene Code abgedeckt.
- **libdivecomputer (LGPL-2.1+):** Statisch gelinkt. Weil der ganze Quellcode öffentlich ist, lässt sich neu linken (ADR 0002). Das ist unkritisch.
- **Code aus Submersion (GPL-3, „Submersion Contributors“):** Die Zusatzerlaubnis deckt ihn **nicht** ab.

## Bestand (gezählt am 2026-11-23, Dateien mit Herkunftskopf)
| Teil | Dateien | Zeilen | Anmerkung |
|---|---|---|---|
| FIT-Extraktoren `lib/data/import/fit/` | 6 | 431 | überschaubar, gut durch Tests abgedeckt |
| Plugin, Dart (`packages/libdivecomputer_plugin/lib`, `pigeons`) | 6 | ~2.100 | davon ~1.500 aus Pigeon generiert |
| Plugin, Android/Kotlin | 29 | ~6.300 | davon ~930 generiert; BLE-Transport mit vielen Geräte-Sonderfällen |
| Plugin, iOS/Swift und C (`darwin`, `ios`, `macos/Classes`) | 35 | ~9.800 | davon ~1.000 generiert; C-Wrapper um libdivecomputer, BLE- und USB-Transport |
| Tests und Fixtures | 61 | ~13.700 | werden nicht an Nutzer verteilt, sind aber ebenfalls GPL-3 |

Ohne Tests und generierten Code sind das rund **15.000 Zeilen** verteiltes Produktivcode aus Submersion, fast alles im Tauchcomputer-Plugin.

**Wichtige Beobachtung:** Submersion selbst wird von seinem Hauptautor **über den App Store, TestFlight und Google Play verteilt** (siehe README von Submersion). Die Autoren akzeptieren Apples Bedingungen also für ihren eigenen Code. Eine ausdrückliche Erlaubnis für **andere**, die den Code über Apple verteilen, gibt es aber nicht.

## Optionen
1. **Nichts tun.** Das Risiko besteht nur, wenn sich ein Rechteinhaber beschwert. Bei einer privaten TestFlight-Verteilung an Familie und Freunde und weil Submersion selbst im App Store ist, ist das sehr unwahrscheinlich. Rechtlich bleibt es aber eine offene Flanke, und im schlimmsten Fall entfernt Apple die App.
2. **Erlaubnis bei Submersion einholen.** Wir bitten den Maintainer um eine Zusatzerlaubnis nach GPL-3 §7 für die übernommenen Teile (Plugin und FIT-Extraktoren), entsprechend unserer eigenen. Aufwand: eine Nachricht. Haken: Die Erlaubnis kann nur geben, wer die Rechte hält. Bei Beiträgen weiterer Mitautoren müsste der Maintainer das für sein Projekt klären.
3. **FIT-Extraktoren neu schreiben** (431 Zeilen, ca. 1 Tag mit den vorhandenen Tests). Allein löst das nichts, weil das Plugin der große Teil ist. Sinnvoll nur zusammen mit 2 oder 4.
4. **Plugin neu schreiben** (BLE-Transport und C-Wrapper für Android und iOS, ~15.000 Zeilen). Aufwand: mehrere Wochen bis Monate. Außerdem verlieren wir die Geräte-Sonderfälle, die in Submersion stecken. Das ist bis Weihnachten nicht machbar.

## Empfehlung (zur Entscheidung durch den Projektinhaber)
- **Jetzt, für TestFlight an Familie und Freunde:** Option 1, aber zusammen mit **Option 2 sofort anstoßen**. Eine freundliche Anfrage beim Maintainer von Submersion, Text-Entwurf siehe unten. Der Projektinhaber schickt sie selbst ab.
- **Vor einem Eintrag im App Store (auch nicht gelistet):** Erst wenn die Erlaubnis da ist. Ohne Erlaubnis bleibt es bei TestFlight, und wir entscheiden neu: Option 3 + 4 oder ganz ohne App Store.
- **Vor dem ersten Release unabhängig davon:** Den vollen Text der GPL-3 als `LICENSE-GPL-3.0.txt` beilegen. Das ist noch offen laut `LICENSE`, und die Datei in `submersion-referenz/` enthält nur einen Kurzhinweis, nicht den vollen Text.

## Entwurf der Anfrage (Englisch, z. B. als GitHub-Discussion oder E-Mail an den Maintainer)
> Hi, I'm building DiveDown (https://github.com/wessleph/DiveDown), a small GPL-3 dive log for my family and friends. With credit in every file header, it reuses your `libdivecomputer_plugin` and the FIT extractors from Submersion (commit e78a87cb). I plan to hand it out to about 20 people via TestFlight, and maybe later as an unlisted App Store app.
> Because Apple's terms are often seen as incompatible with GPL-3 §10, I'd like to ask whether you'd grant an additional permission under GPL-3 §7 for the parts of Submersion you hold the copyright to, allowing distribution through the App Store and TestFlight. DiveDown already grants the same permission for its own code (see its LICENSE). All source stays public under GPL-3.
> Thanks a lot for Submersion, it saved me months of work.

## Konsequenzen
- Die Frage aus ADR 0001 ist für TestFlight vorläufig beantwortet. Für den App Store bleibt sie offen, bis eine Antwort von Submersion da ist.
- `THIRD_PARTY.md` bekommt dann einen Vermerk zur Erlaubnis (mit Datum und Link).
