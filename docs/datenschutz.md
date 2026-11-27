---
title: Datenschutzerklärung
permalink: /datenschutz/
lang: de
---

# Datenschutzerklärung für die App DiveDown

**Stand:** 27. November 2026 · **App-Version:** 1.0

## 1. Kurz gesagt
- DiveDown speichert alle Daten **nur auf deinem Gerät**.
- Die App hat **keinen Server**, **kein Konto**, **keine Werbung**, **kein Tracking** und **keine Analyse-Dienste**.
- Die Android-Version hat nicht einmal die Berechtigung, ins Internet zu gehen.
- Daten verlassen dein Gerät nur, wenn **du selbst** eine Sicherung, ein Diagnose-Protokoll oder einen Tauchgang als Bild teilst oder mir eine Fehlermeldung bzw. einen Vorschlag per Mail schickst.

## 2. Verantwortlich
Philipp Wessler, Schweiz
E-Mail: [divedown-app@proton.me](mailto:divedown-app@proton.me)

DiveDown ist ein privates, nicht kommerzielles Open-Source-Projekt (Lizenz GPL-3.0).

## 3. Welche Daten die App auf deinem Gerät verarbeitet
| Daten | Woher | Wozu | Wo gespeichert |
|---|---|---|---|
| Dein Name als Taucherin bzw. Taucher (auch ein Spitzname genügt) und die Nummer, mit der deine Zählung beginnt | deine Eingabe | Logbuch und Nummerierung der Tauchgänge | nur lokal |
| Tauchgänge (Zeit, Dauer, Tiefe, Temperatur, Flaschendruck, Gase, Ereignisse, Tauchplatz mit Position, Blei, Sichtweite, Strömung, Tauchgangsart, Notizen, Bewertung) | Tauchcomputer, FIT-Datei, Apple Health oder deine Eingabe | Logbuch, Diagramme, Luftverbrauch, Statistik | nur lokal. Die Statistik wird jedes Mal neu berechnet und nicht gespeichert. |
| Ausrüstung (Art, Bezeichnung, Notiz, Standard-Teile) und welche Teile du bei einem Tauchgang dabei hattest | deine Eingabe | Ausrüstung pro Tauchgang anzeigen | nur lokal |
| Einstellungen (Darstellung, gewählte Werte im Diagramm, Erinnerung an die Sicherung) | deine Auswahl | die App so anzeigen, wie du es eingestellt hast | nur lokal |
| Daten des Tauchcomputers (Hersteller, Modell, Seriennummer, Firmware, Bluetooth-Kennung, Kopplungscode) | Tauchcomputer per Bluetooth | Gerät wiedererkennen, nur neue Tauchgänge laden | nur lokal; der Kopplungscode im geschützten Schlüsselspeicher des Systems |
| **Gesundheitsdaten aus Apple Health** (Tiefe, Wassertemperatur, Puls von Unterwasser-Workouts) | Apple Health, **nur mit deiner Erlaubnis**, **nur lesend** | Tauchgänge der Apple Watch übernehmen | nur lokal. DiveDown schreibt nichts in Apple Health. Apple verlangt von jeder App mit Zugriff auf Apple Health einen Hinweistext zum Schreiben; DiveDown fragt diese Erlaubnis trotzdem nie an. |
| Tauchplatz-Katalog | in der App mitgeliefert | Vorschläge beim Eintragen des Tauchplatzes | nur lokal, enthält keine persönlichen Daten |
| Diagnose-Protokoll (technische Ereignisse, Fehlercodes, Gerätemodell, Versionsnummern) | die App selbst | Fehlersuche | nur lokal, höchstens 7 Tage bzw. 5 MB. Ohne Orte, Namen, Notizen oder Gesundheitswerte. |

Die Logbuch-Datenbank wird **nicht** in iCloud- bzw. Google-Backups aufgenommen, weil darin Gesundheitsdaten stehen können. Für Sicherungen gibt es die Funktion „Logbuch sichern“ (Abschnitt 4).

**Berechtigungen:** Bluetooth (Verbindung zum Tauchcomputer) und, nur unter iOS ab Version 17, das Lesen aus Apple Health. Auf Android-Versionen bis 11 verlangt das System für Bluetooth-Suchen zusätzlich die Standort-Berechtigung. DiveDown fragt deinen Standort trotzdem nie ab.

## 4. Wann Daten dein Gerät verlassen, und nur dann
1. **Logbuch sichern:** Du erstellst eine Sicherungsdatei und wählst selbst, wohin sie geht, z. B. in „Dateien“, in einen Cloud-Speicher oder per Mail.
   Die Datei ist **nicht verschlüsselt** und kann Gesundheitsdaten (Puls) enthalten. Für den gewählten Speicherort gilt die Datenschutzerklärung des jeweiligen Anbieters.
2. **Diagnose-Logs teilen:** Du siehst vor dem Senden, was im Protokoll steht, und schickst es selbst, z. B. per Mail.
   Ich (Abschnitt 2) erhalte dann deine Nachricht samt Absender und Protokoll. Ich nutze das ausschließlich zur Fehlersuche und lösche es, sobald der Fehler behoben ist, spätestens nach 6 Monaten.
   Das geschieht freiwillig und auf deine Initiative. Für Nutzerinnen und Nutzer in der EU gilt als Rechtsgrundlage deine Einwilligung durch das aktive Senden (Art. 6 Abs. 1 lit. a DSGVO).
   Die Nachricht liegt beim Anbieter meines E-Mail-Postfachs, der seinen Sitz auch außerhalb der Schweiz haben kann.
3. **Fehler melden und Verbesserung vorschlagen:** Die App bereitet eine Mail an mich (Abschnitt 2) vor, mit deinem Text und technischen Angaben (App-Version, Betriebssystem, Gerätemodell), beim Fehlermelden auf Wunsch mit dem Diagnose-Protokoll. Gesendet wird erst, wenn du in deiner Mail-App auf Senden tippst.
   Ich nutze die Nachricht nur, um Fehler zu beheben und die App zu verbessern, und lösche sie, sobald sie erledigt ist, spätestens nach 12 Monaten. Rechtsgrundlage und Speicherort wie unter Punkt 2.
4. **Tauchgang teilen:** Die App erstellt ein Bild mit Tauchplatz, Datum, Nummer, Tiefe, Dauer, Wassertemperatur und Tiefenprofil, auf Wunsch mit einem Foto aus deiner Galerie als Hintergrund. Du wählst im Teilen-Menü selbst, an welche App es geht (z. B. Instagram). Für das Bild gelten dann die Bedingungen dieser App.
   DiveDown liest nur das eine Foto, das du auswählst, braucht keinen Zugriff auf deine Galerie und speichert das Foto nicht. Das Bild wird neu erzeugt; Ort, Zeit und Kamera aus den Metadaten des Fotos werden **nicht** übernommen. Koordinaten, dein Name, Notizen und Gesundheitswerte stehen nie auf dem Bild. Ich erhalte davon nichts.

## 5. Verteilung der App
- **iPhone (TestFlight):** Die App wird über Apples TestFlight verteilt. Apple verarbeitet dabei Daten nach den eigenen Bedingungen ([Apple-Datenschutzrichtlinie](https://www.apple.com/legal/privacy/)).
  Wenn du in TestFlight Feedback oder Absturzberichte sendest, erhalte ich diese über App Store Connect. Je nach Einladungsart sehe ich dabei auch Name bzw. E-Mail-Adresse, die du bei TestFlight angegeben hast.
- **Android (Google Play, interner Test):** Die App wird über einen internen Test von Google Play an eingeladene Personen verteilt. Dafür trage ich die **E-Mail-Adresse deines Google-Kontos** in die Tester-Liste der Play Console ein, nur wenn du einverstanden bist. Sie liegt nur dort, und ich entferne sie, wenn du nicht mehr testen möchtest.
  Google verarbeitet bei Installation und Updates Daten nach den eigenen Bedingungen ([Google-Datenschutzerklärung](https://policies.google.com/privacy)). Hast du auf deinem Gerät erlaubt, Nutzungs- und Diagnosedaten an Google zu senden, zeigt mir die Play Console Absturzberichte und zusammengefasste Zahlen (z. B. Anzahl Installationen, Gerätemodelle, Android-Versionen), aber keine Inhalte aus der App. Schickst du über Google Play Feedback zum Test, erhalte ich diese Nachricht.
- **Android (APK):** Lädst du die APK über GitHub herunter, verarbeitet GitHub technische Daten wie deine IP-Adresse ([GitHub Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement)). Ich erhalte davon nichts.
- Bei Google ist die App auf mich als verifizierten Entwickler registriert (Paketname und Signatur, [Android-Entwicklerverifizierung](https://developer.android.com/developer-verification/guides)). Bei der Installation kann dein Gerät das bei Google prüfen; dafür gelten Googles Bedingungen. Ich erhalte davon nichts.

## 6. Deine Rechte
Da ich außer freiwillig gesendeten Mails (Diagnose-Protokoll, Fehlermeldung, Vorschlag), Feedback über TestFlight bzw. Google Play und, beim internen Test unter Android, deiner E-Mail-Adresse in der Tester-Liste keine Daten über dich habe, betreffen deine Rechte vor allem diese Daten.
Nach dem Schweizer Datenschutzgesetz (DSG) hast du das Recht auf **Auskunft** (Art. 25 DSG), **Berichtigung** und **Löschung** (Art. 32 DSG) sowie auf **Herausgabe bzw. Übertragung** deiner Daten (Art. 28 DSG). Schreib dafür einfach an die E-Mail-Adresse in Abschnitt 2.
Du kannst dich außerdem an den Eidgenössischen Datenschutz- und Öffentlichkeitsbeauftragten (EDÖB) wenden: [edoeb.admin.ch](https://www.edoeb.admin.ch).
Nutzerinnen und Nutzer in der EU haben zusätzlich die Rechte nach der DSGVO (u. a. Einschränkung und Widerspruch) und können sich bei der Aufsichtsbehörde ihres Landes beschweren.

Alle Daten in der App löschst du selbst: einzelne Tauchgänge und Ausrüstungsteile, oder alles durch Deinstallieren der App.

## 7. Kinder
DiveDown richtet sich an Taucherinnen und Taucher jeden Alters in Familie und Freundeskreis. Die App erhebt von niemandem Daten.

## 8. Änderungen
Ändert sich, wie DiveDown mit Daten umgeht (z. B. durch eine spätere Sync-Funktion über einen eigenen Server), wird diese Erklärung **vor** dem Update angepasst. In der App siehst du dann einen Hinweis.
